#if DEBUG
import AppKit
@preconcurrency import ApplicationServices
import SpellboundMacIntegration

/// Explicit developer-only test. Never sends a message or touches an existing draft.
@MainActor
func runT3SmokeTest(model: PrototypeModel, output: URL) async {
    try? FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
    var results: [String: Bool] = [:]
    let initialCount = model.practicedCount
    defer {
        model.practicedCount = initialCount
        UserDefaults.standard.set(initialCount, forKey: "practicedCount")
        if let data = try? JSONEncoder().encode(results) {
            try? data.write(to: output.appendingPathComponent("results.json"))
        }
    }
    guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: "com.t3tools.t3code").first else { return }
    app.activate()
    try? await Task.sleep(for: .seconds(2))
    let application = AXUIElementCreateApplication(app.processIdentifier)
    func value(_ element: AXUIElement, _ key: String) -> CFTypeRef? {
        var result: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, key as CFString, &result) == .success else { return nil }
        return result
    }
    var focusedInput: CFTypeRef?
    for _ in 0..<120 {
        if let item = value(application, kAXFocusedUIElementAttribute), CFGetTypeID(item) == AXUIElementGetTypeID(),
           value(unsafeDowncast(item, to: AXUIElement.self), kAXRoleAttribute) as? String == kAXTextAreaRole {
            focusedInput = item; break
        }
        try? await Task.sleep(for: .milliseconds(500))
    }
    guard let raw = focusedInput else { results["focusedPrompt"] = false; return }
    let input = unsafeDowncast(raw, to: AXUIElement.self)
    func text() -> String? {
        guard let count = value(input, kAXNumberOfCharactersAttribute) as? NSNumber, count.intValue <= 64 else { return nil }
        var range = CFRange(location: 0, length: count.intValue)
        guard let parameter = AXValueCreate(.cfRange, &range) else { return nil }
        var result: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(input, kAXStringForRangeParameterizedAttribute as CFString, parameter, &result) == .success else { return nil }
        return result as? String
    }
    // Chromium may report a lone newline for an otherwise empty contenteditable.
    guard value(input, kAXRoleAttribute) as? String == kAXTextAreaRole,
          let original = text(), original == "" || original == "\n" else {
        results["emptyPrompt"] = false; return
    }
    results["emptyPrompt"] = true
    model.setMonitoring(true)
    try? await Task.sleep(for: .milliseconds(700))
    var expected = ""
    for character in "neccessary " {
        guard NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier,
              let focused = value(application, kAXFocusedUIElementAttribute), CFEqual(focused, input),
              let actual = text(), actual == expected || (expected.isEmpty && actual == original) else {
            results["unchangedDuringTyping"] = false
            results["frontmost"] = NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier
            results["sameElement"] = value(application, kAXFocusedUIElementAttribute).map { CFEqual($0, input) } ?? false
            results["matchingText"] = text() == expected
            results["firstCharacter"] = expected.isEmpty
            results["duplicatedInsertion"] = text() == expected + expected
            results["trailingNewline"] = text() == expected + "\n"
            return
        }
        guard let down = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true),
              let up = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else { return }
        let units = Array(String(character).utf16)
        down.keyboardSetUnicodeString(stringLength: units.count, unicodeString: units)
        // Unicode payload belongs to key-down only; Electron can treat payloads on key-up as another insertion.
        down.postToPid(app.processIdentifier); up.postToPid(app.processIdentifier)
        expected.append(character)
        try? await Task.sleep(for: .milliseconds(200))
    }
    results["typingSupported"] = true
    try? await Task.sleep(for: .seconds(1))
    results["stripVisible"] = model.panel?.isVisible == true
    results["correctSuggestion"] = model.target == "necessary"
    if model.panel?.isVisible == true {
        if let view = model.panel?.contentView, let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
            view.cacheDisplay(in: view.bounds, to: rep)
            try? rep.representation(using: .png, properties: [:])?.write(to: output.appendingPathComponent("strip.png"))
        }
        model.begin()
        try? await Task.sleep(for: .milliseconds(550))
        results["practiceFieldFocused"] = model.panel?.firstResponder is NSTextView
        for _ in 0..<3 {
            guard let field = model.panel?.firstResponder as? NSTextView else { break }
            field.selectAll(nil); field.insertText("necessary", replacementRange: field.selectedRange())
            model.submit()
            try? await Task.sleep(for: .milliseconds(550))
        }
        results["practiceComplete"] = model.isComplete
        model.finish()
        try? await Task.sleep(for: .milliseconds(900))
        results["replacementVerified"] = text() == "necessary "
        results["copyFallbackAvailable"] = model.panel?.isVisible == true && model.message.contains("Copy the word")
    }
    model.dismiss(restoreFocus: true)
    try? await Task.sleep(for: .milliseconds(300))
    // Clear only the exact disposable sample, with focus and content rechecked.
    if NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier,
       let focused = value(application, kAXFocusedUIElementAttribute), CFEqual(focused, input),
       let actual = text(), actual == "neccessary " || actual == "necessary " {
        var range = CFRange(location: 0, length: (actual as NSString).length)
        if let selected = AXValueCreate(.cfRange, &range),
           AXUIElementSetAttributeValue(input, kAXSelectedTextRangeAttribute as CFString, selected) == .success,
           text() == actual {
            try? await Task.sleep(for: .milliseconds(100))
            if text() == actual, let selectedRaw = value(input, kAXSelectedTextRangeAttribute), CFGetTypeID(selectedRaw) == AXValueGetTypeID() {
                var checked = CFRange()
                if AXValueGetValue(unsafeDowncast(selectedRaw, to: AXValue.self), .cfRange, &checked), checked.location == 0, checked.length == range.length,
                   NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier,
                   value(application, kAXFocusedUIElementAttribute).map({ CFEqual($0, input) }) == true {
                    CGEvent(keyboardEventSource: nil, virtualKey: 51, keyDown: true)?.postToPid(app.processIdentifier)
                    CGEvent(keyboardEventSource: nil, virtualKey: 51, keyDown: false)?.postToPid(app.processIdentifier)
                    try? await Task.sleep(for: .milliseconds(200))
                    results["sampleCleared"] = text() == "" || text() == "\n"
                }
            }
        }
    }
}
#endif
