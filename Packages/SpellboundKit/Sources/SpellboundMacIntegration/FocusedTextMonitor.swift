#if os(macOS)
import AppKit
@preconcurrency import ApplicationServices
import SpellboundCore

/// Polls only the focused, eligible control, reading at most 512 UTF-16 units near the caret.
/// No snapshots are persisted. No event tap, clipboard polling, or whole-document fallback.
@MainActor
public final class FocusedTextMonitor {
    public struct Candidate {
        public let word: String
        public let suggestions: [String]
        public let bounds: CGRect
        public let source: Source
    }

    @MainActor
    public final class Source {
        public let element: AXUIElement
        public let pid: pid_t
        public let bundleID: String
        public let range: NSRange
        private let contextRange: NSRange
        private let context: String
        private let selection: NSRange
        private let markers: AXTextMarkerRange?
        private let sourceWindow: CFTypeRef?
        private let diagnostic: ((String) -> Void)?

        fileprivate init(element: AXUIElement, pid: pid_t, bundleID: String, range: NSRange,
                         contextRange: NSRange, context: String, selection: NSRange, diagnostic: ((String) -> Void)?) {
            self.element = element; self.pid = pid; self.bundleID = bundleID; self.range = range
            self.contextRange = contextRange; self.context = context; self.selection = selection
            self.markers = AXBridge.markerRange(element, range: range)
            self.sourceWindow = AXBridge.value(element, kAXWindowAttribute)
            self.diagnostic = diagnostic
        }

        public func currentBounds() -> CGRect? {
            guard AXIsProcessTrusted(), AXBridge.eligible(element) else { diagnostic?("anchor-permission-or-role"); return nil }
            let panelHasFocus = NSApp.keyWindow is NSPanel && NSApp.keyWindow?.isVisible == true
            let focusedMatches = AXBridge.focused(pid: pid).map { CFEqual($0, element) } ?? false
            // A nonactivating practice panel can blur a web editor while its app stays frontmost.
            // In that case retain only the original window, element, text fingerprint, and word markers.
            if !focusedMatches {
                let app = AXUIElementCreateApplication(pid)
                guard panelHasFocus, let sourceWindow,
                      let currentWindow = AXBridge.value(app, kAXFocusedWindowAttribute),
                      CFEqual(sourceWindow, currentWindow) else { diagnostic?("anchor-focus-changed"); return nil }
            }
            guard AXBridge.text(element, range: contextRange) == context else { diagnostic?("anchor-context-changed"); return nil }
            return AXBridge.bounds(element, range: range, markers: markers, diagnostic: diagnostic)
        }

        public var canReplace: Bool {
            AXBridge.settable(element, kAXSelectedTextRangeAttribute) && AXBridge.settable(element, kAXSelectedTextAttribute)
        }

        public func replace(with word: String) async -> Bool {
            guard canReplace, currentBounds() != nil,
                  NSWorkspace.shared.frontmostApplication?.processIdentifier == pid,
                  let focused = AXBridge.focused(pid: pid), CFEqual(focused, element),
                  AXBridge.range(element, kAXSelectedTextRangeAttribute) == selection else { diagnostic?("replacement-focus-or-selection"); return false }
            // Targeted selected-text edits only; never overwrite AXValue or inject keystrokes.
            guard AXBridge.setRange(element, range: range) else { diagnostic?("replacement-selection-failed"); return false }
            try? await Task.sleep(for: .milliseconds(80))
            // Revalidate immediately after selection; a hostile/stale adapter must not edit.
            guard NSWorkspace.shared.frontmostApplication?.processIdentifier == pid,
                  AXBridge.focused(pid: pid).map({ CFEqual($0, element) }) == true,
                  AXBridge.range(element, kAXSelectedTextRangeAttribute) == range,
                  AXBridge.text(element, range: contextRange) == context else {
                diagnostic?("replacement-selection-or-context-mismatch")
                if AXBridge.range(element, kAXSelectedTextRangeAttribute) == range { _ = AXBridge.setRange(element, range: selection) }
                return false
            }
            let result = AXUIElementSetAttributeValue(element, kAXSelectedTextAttribute as CFString, word as CFString)
            if result != .success {
                _ = AXBridge.setRange(element, range: selection)
                return false
            }
            try? await Task.sleep(for: .milliseconds(100))
            let delta = (word as NSString).length - range.length
            let expected = (context as NSString).replacingCharacters(in: NSRange(location: range.location - contextRange.location, length: range.length), with: word)
            let updatedRange = NSRange(location: contextRange.location, length: contextRange.length + delta)
            guard AXBridge.text(element, range: updatedRange) == expected else {
                diagnostic?("replacement-not-confirmed"); return false
            }
            let newCaret = selection.location + delta
            _ = AXBridge.setRange(element, range: NSRange(location: max(0, newCaret), length: 0))
            return true
        }
    }

    public var onCandidate: ((Candidate) -> Void)?
    public var onStatus: ((String) -> Void)?
    public var onDiagnostic: ((String) -> Void)?
    public var excludedApps: Set<String> = []
    public var ignoredWords: Set<String> = []
    public var suspended = false
    private var timer: Timer?
    private var previousElement: AXUIElement?
    private var previousText = ""
    private var previousStart = 0
    private var previousDocumentLength = 0
    private var suppressed: [String: Date] = [:]
    private var lastReadDiagnostic = ""
    private var preparedPIDs: Set<pid_t> = []

    public init() {}

    public func start() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
    }

    public func stop() {
        timer?.invalidate(); timer = nil
        reset()
    }

    public func reset() {
        previousElement = nil; previousText = ""; previousStart = 0; previousDocumentLength = 0
    }

    public func suppress(_ word: String) {
        suppressed = suppressed.filter { $0.value > Date() }
        suppressed[word.lowercased()] = Date().addingTimeInterval(60)
        reset()
    }

    private func poll() {
        guard !suspended else { return }
        guard AXIsProcessTrusted() else {
            reset(); onStatus?("Accessibility access needed"); return
        }
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier,
              let bundleID = app.bundleIdentifier else { reset(); return }
        guard !excludedApps.contains(bundleID), !Self.sensitiveApps.contains(bundleID) else {
            reset(); onStatus?("Paused in this app"); return
        }
        if preparedPIDs.insert(app.processIdentifier).inserted {
            AccessibilityProbe.prepareApplication(pid: app.processIdentifier)
        }
        guard let element = AXBridge.focused(pid: app.processIdentifier), AXBridge.eligible(element),
              let selection = AXBridge.range(element, kAXSelectedTextRangeAttribute), selection.length == 0,
              let documentLength = AXBridge.characterCount(element), selection.location <= documentLength else {
            reset(); onStatus?("Focused input not supported"); return
        }
        let start = max(0, selection.location - 512)
        let range = NSRange(location: start, length: selection.location - start)
        guard let text = AXBridge.text(element, range: range) else {
            reset(); onStatus?("This input doesn’t expose text ranges"); return
        }
        let readDiagnostic = "read caret=\(selection.location) document=\(documentLength) requested=\(range.length) returned=\((text as NSString).length)"
        if readDiagnostic != lastReadDiagnostic {
            lastReadDiagnostic = readDiagnostic; onDiagnostic?(readDiagnostic)
        }
        onStatus?("Watching the focused input")
        defer { previousElement = element; previousText = text; previousStart = start; previousDocumentLength = documentLength }
        guard let previousElement, CFEqual(previousElement, element), start >= previousStart, start - previousStart <= (previousText as NSString).length,
              text != previousText else {
            if text != previousText { onDiagnostic?("baseline-reset elementChanged=\(self.previousElement.map { !CFEqual($0, element) } ?? true) length=\((text as NSString).length)") }
            return
        }
        // Only small append-only changes qualify. Existing text, selections, deletions and bulk pastes are ignored.
        let comparablePrevious = (previousText as NSString).substring(from: start - previousStart)
        let insertedLength = (text as NSString).length - (comparablePrevious as NSString).length
        guard documentLength > previousDocumentLength, documentLength - previousDocumentLength == insertedLength,
              text.hasPrefix(comparablePrevious), insertedLength > 0, insertedLength <= 12 else {
            onDiagnostic?("edit-rejected inserted=\(insertedLength) documentDelta=\(documentLength - previousDocumentLength) prefix=\(text.hasPrefix(comparablePrevious))")
            return
        }
        let completed = CompletedToken.newlyCompleted(in: text, after: (comparablePrevious as NSString).length,
                                                      caret: (text as NSString).length)
        var match: (CompletedToken, [String])?
        for token in completed where !ignoredWords.contains(token.word.lowercased()) &&
            (suppressed[token.word.lowercased()] ?? .distantPast) < Date() {
            let suggestions = SpellingService.suggestions(for: token.word)
            if !suggestions.isEmpty { match = (token, suggestions); break }
        }
        onDiagnostic?("append inserted=\(insertedLength) completed=\(completed.count) spellingMatch=\(match != nil)")
        guard let (token, suggestions) = match else { return }
        let absolute = NSRange(location: start + token.range.location, length: token.range.length)
        guard let bounds = AXBridge.bounds(element, range: absolute, diagnostic: onDiagnostic), bounds.width > 1, bounds.height > 1 else {
            onStatus?("This input doesn’t expose word positions"); return
        }
        // Retain only a bounded fingerprint, not an entire document.
        let contextStart = max(start, absolute.location - 32)
        let contextRange = NSRange(location: contextStart, length: selection.location - contextStart)
        guard let context = AXBridge.text(element, range: contextRange) else { return }
        let source = Source(element: element, pid: app.processIdentifier, bundleID: bundleID,
                            range: absolute, contextRange: contextRange, context: context, selection: selection, diagnostic: onDiagnostic)
        onCandidate?(Candidate(word: token.word, suggestions: suggestions, bounds: bounds, source: source))
    }

    private static let sensitiveApps: Set<String> = [
        "com.1password.1password", "com.agilebits.onepassword7", "com.apple.keychainaccess",
        "com.apple.Passwords", "com.bitwarden.desktop"
    ]
}

@MainActor
private enum AXBridge {
    static func value(_ element: AXUIElement, _ key: String) -> CFTypeRef? {
        var result: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, key as CFString, &result) == .success else { return nil }
        return result
    }

    static func focused(pid: pid_t) -> AXUIElement? {
        let app = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(app, 0.15)
        guard let item = value(app, kAXFocusedUIElementAttribute), CFGetTypeID(item) == AXUIElementGetTypeID() else { return nil }
        let element = unsafeDowncast(item, to: AXUIElement.self)
        AXUIElementSetMessagingTimeout(element, 0.15)
        return element
    }

    static func eligible(_ element: AXUIElement) -> Bool {
        ObservationEligibility.permitsRead(permissionGranted: AXIsProcessTrusted(), appExcluded: false,
            monitoringActive: true, role: value(element, kAXRoleAttribute) as? String,
            subrole: value(element, kAXSubroleAttribute) as? String)
    }

    static func range(_ element: AXUIElement, _ key: String) -> NSRange? {
        guard let raw = value(element, key), CFGetTypeID(raw) == AXValueGetTypeID() else { return nil }
        let value = unsafeDowncast(raw, to: AXValue.self)
        var range = CFRange()
        guard AXValueGetValue(value, .cfRange, &range), range.location >= 0, range.length >= 0 else { return nil }
        return NSRange(location: range.location, length: range.length)
    }

    static func parameter(_ element: AXUIElement, _ key: String, range: NSRange) -> CFTypeRef? {
        var cfRange = CFRange(location: range.location, length: range.length)
        guard let parameter = AXValueCreate(.cfRange, &cfRange) else { return nil }
        var result: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(element, key as CFString, parameter, &result) == .success else { return nil }
        return result
    }

    static func text(_ element: AXUIElement, range: NSRange) -> String? {
        parameter(element, kAXStringForRangeParameterizedAttribute, range: range) as? String
    }

    static func markerParameter(_ element: AXUIElement, _ key: String, _ argument: CFTypeRef) -> CFTypeRef? {
        var result: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(element, key as CFString, argument, &result) == .success else { return nil }
        return result
    }

    /// Rich web editors expose geometry through text markers even when AXBoundsForRange is advertised.
    /// Walk back from the caret, measuring UTF-16 distances instead of assuming a marker equals one code unit.
    static func markerRange(_ element: AXUIElement, range: NSRange) -> AXTextMarkerRange? {
        guard let selection = self.range(element, kAXSelectedTextRangeAttribute), selection.length == 0,
              selection.location >= NSMaxRange(range), selection.location - range.location <= 512,
              let selected = value(element, "AXSelectedTextMarkerRange"),
              CFGetTypeID(selected) == AXTextMarkerRangeGetTypeID() else { return nil }
        let caret = AXTextMarkerRangeCopyEndMarker(unsafeDowncast(selected, to: AXTextMarkerRange.self))
        var cursor = caret
        var end: AXTextMarker? = selection.location == NSMaxRange(range) ? caret : nil
        let distanceToEnd = selection.location - NSMaxRange(range)
        let distanceToStart = selection.location - range.location
        let deadline = ContinuousClock.now.advanced(by: .milliseconds(250))
        for _ in 0..<512 {
            guard ContinuousClock.now < deadline,
                  let raw = markerParameter(element, "AXPreviousTextMarkerForTextMarker", cursor),
                  CFGetTypeID(raw) == AXTextMarkerGetTypeID() else { return nil }
            cursor = unsafeDowncast(raw, to: AXTextMarker.self)
            let tail = AXTextMarkerRangeCreate(nil, cursor, caret)
            guard let length = markerParameter(element, "AXLengthForTextMarkerRange", tail) as? NSNumber else { return nil }
            let distance = length.intValue
            if distance == distanceToEnd { end = cursor }
            if distance > distanceToStart { return nil }
            if distance == distanceToStart {
                guard let end else { return nil }
                let markers = AXTextMarkerRangeCreate(nil, cursor, end)
                guard let expected = text(element, range: range),
                      let actual = markerParameter(element, "AXStringForTextMarkerRange", markers) as? String,
                      actual == expected else { return nil }
                return markers
            }
        }
        return nil
    }

    static func bounds(_ element: AXUIElement, range: NSRange, markers: AXTextMarkerRange? = nil, diagnostic: ((String) -> Void)? = nil) -> CGRect? {
        let direct = parameter(element, kAXBoundsForRangeParameterizedAttribute, range: range)
        func rectangle(_ raw: CFTypeRef?) -> CGRect? {
            guard let raw, CFGetTypeID(raw) == AXValueGetTypeID() else { return nil }
            var rect = CGRect.zero
            guard AXValueGetValue(unsafeDowncast(raw, to: AXValue.self), .cgRect, &rect),
                  rect.width > 1, rect.height > 1, !rect.isInfinite, !rect.isNull else { return nil }
            return rect
        }
        var fallback: CFTypeRef?
        if rectangle(direct) == nil, let anchor = markers ?? markerRange(element, range: range),
           let expected = text(element, range: range),
           let actual = markerParameter(element, "AXStringForTextMarkerRange", anchor) as? String, actual == expected {
            fallback = markerParameter(element, "AXBoundsForTextMarkerRange", anchor)
        }
        let rawBounds = rectangle(direct) != nil ? direct : fallback
        diagnostic?("word-bounds direct=\(direct != nil) directValid=\(rectangle(direct) != nil) resolved=\(rawBounds != nil)")
        guard let raw = rawBounds,
              CFGetTypeID(raw) == AXValueGetTypeID() else { return nil }
        var rect = CGRect.zero
        guard AXValueGetValue(unsafeDowncast(raw, to: AXValue.self), .cgRect, &rect),
              rect.width > 0, rect.height > 0, !rect.isInfinite, !rect.isNull,
              let primary = NSScreen.screens.first else { return nil }
        // AX screen coordinates have the origin at the primary display's top left.
        rect.origin.y = primary.frame.maxY - rect.maxY
        guard NSScreen.screens.contains(where: { $0.visibleFrame.intersects(rect) }) else { diagnostic?("bounds-offscreen"); return nil }
        if let visible = self.range(element, kAXVisibleCharacterRangeAttribute),
           visible.length > 0, NSIntersectionRange(range, visible) != range { diagnostic?("bounds-outside-visible-range"); return nil }
        // Clip against the input and any ancestor scroll viewport, not just the display.
        guard let inputRect = frame(element), inputRect.intersects(rect) else { diagnostic?("bounds-outside-input"); return nil }
        var ancestor = element
        for _ in 0..<8 {
            guard let rawParent = value(ancestor, kAXParentAttribute),
                  CFGetTypeID(rawParent) == AXUIElementGetTypeID() else { break }
            ancestor = unsafeDowncast(rawParent, to: AXUIElement.self)
            if value(ancestor, kAXRoleAttribute) as? String == kAXScrollAreaRole,
               let viewport = frame(ancestor), !viewport.contains(CGPoint(x: rect.midX, y: rect.midY)) { diagnostic?("bounds-outside-scroll-viewport"); return nil }
        }
        return rect
    }

    static func characterCount(_ element: AXUIElement) -> Int? {
        (value(element, kAXNumberOfCharactersAttribute) as? NSNumber)?.intValue
    }

    static func frame(_ element: AXUIElement) -> CGRect? {
        guard let position = value(element, kAXPositionAttribute), let size = value(element, kAXSizeAttribute),
              CFGetTypeID(position) == AXValueGetTypeID(), CFGetTypeID(size) == AXValueGetTypeID(),
              let primary = NSScreen.screens.first else { return nil }
        var point = CGPoint.zero
        var dimensions = CGSize.zero
        guard AXValueGetValue(unsafeDowncast(position, to: AXValue.self), .cgPoint, &point),
              AXValueGetValue(unsafeDowncast(size, to: AXValue.self), .cgSize, &dimensions) else { return nil }
        return CGRect(x: point.x, y: primary.frame.maxY - point.y - dimensions.height,
                      width: dimensions.width, height: dimensions.height)
    }

    static func settable(_ element: AXUIElement, _ key: String) -> Bool {
        var result = DarwinBoolean(false)
        return AXUIElementIsAttributeSettable(element, key as CFString, &result) == .success && result.boolValue
    }

    static func setRange(_ element: AXUIElement, range: NSRange) -> Bool {
        var cfRange = CFRange(location: range.location, length: range.length)
        guard let value = AXValueCreate(.cfRange, &cfRange) else { return false }
        return AXUIElementSetAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, value) == .success
    }
}
#endif
