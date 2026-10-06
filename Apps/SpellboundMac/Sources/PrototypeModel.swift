import AppKit
import SwiftUI
import SpellboundCore
import SpellboundMacIntegration

@MainActor
final class PrototypeModel: ObservableObject {
    @Published var monitoring = false
    @Published var status = "Monitoring is paused" {
        didSet { if status != oldValue { writeDiagnosticState() } }
    }
    var diagnosticFile: URL?
    private var observationDiagnostic = ""
    private var observationEvents: [String] = []
    private var presentationCount = 0
    private var lastSourceBundle = ""

    func writeDiagnosticState() {
        guard let diagnosticFile else { return }
        let state = ["status": status, "monitoring": String(monitoring),
                     "permissionGranted": String(AccessibilityProbe.isTrusted),
                     "observation": observationDiagnostic, "recentObservations": observationEvents.joined(separator: "\n"),
                     "presentations": String(presentationCount), "lastSourceBundle": lastSourceBundle]
        if let data = try? JSONEncoder().encode(state) { try? data.write(to: diagnosticFile, options: .atomic) }
    }
    @Published var permissionGranted = AccessibilityProbe.isTrusted
    @Published var challenge: TypingChallenge?
    @Published var answer = ""
    @Published var answerSelection = NSRange(location: 0, length: 0)
    @Published var stripWidth: CGFloat = 570
    @Published var message = ""
    @Published var confirming = true
    @Published var suggestions: [String] = []
    @Published var target = ""
    @Published var typo = ""
    @Published var pointerX: CGFloat = 240
    @Published var isAbove = true
    @Published var inputGeneration = 0
    @Published var showErrors = false
    @Published var practicedCount = UserDefaults.standard.integer(forKey: "practicedCount")
    @Published var excludedApps = Set(UserDefaults.standard.stringArray(forKey: "excludedApps") ?? [])
    @Published var ignoredWords = Set(UserDefaults.standard.stringArray(forKey: "ignoredWords") ?? [])

    let monitor = FocusedTextMonitor()
    var panel: TypingPanel?
    var playground: PlaygroundController?
    var home: NSWindow?
    private var tracker: Timer?
    private var permissionTimer: Timer?
    private var boundsProvider: (() -> CGRect?)?
    private var replacement: ((String) async -> Bool)?
    private var finishing = false
    private var returnFocus: (() -> Void)?
    private var sourcePID: pid_t?
    private var sourceBundle: String?
    private var demoSession = false
    private var dismissalInProgress = false
    private var observation: NSObjectProtocol?

    var tileSelection: Range<Int> {
        let start = min(answerSelection.location, answer.count)
        return start..<min(start + answerSelection.length, answer.count)
    }

    var isComplete: Bool { challenge?.phase == .completed }
    var isGuided: Bool { challenge?.phase == .guided }
    var roundNumber: Int {
        switch challenge?.phase {
        case .recall(1): 2
        case .recall: 3
        default: 1
        }
    }

    init() {
        monitor.onDiagnostic = { [weak self] event in
            guard let self, self.diagnosticFile != nil else { return }
            self.observationDiagnostic = event
            guard self.observationEvents.last != event else { return }
            self.observationEvents.append(event)
            self.observationEvents = Array(self.observationEvents.suffix(40))
            self.writeDiagnosticState()
        }
        monitor.onStatus = { [weak self] in self?.status = $0 }
        monitor.onCandidate = { [weak self] in self?.present($0) }
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.permissionGranted = AccessibilityProbe.isTrusted
                if self.monitoring && !self.permissionGranted {
                    self.setMonitoring(false)
                    self.status = "Accessibility access needed"
                }
            }
        }
        observation = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] note in
            let pid = (note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.processIdentifier
            Task { @MainActor in
                guard let self, self.panel?.isVisible == true, let pid,
                      pid != self.sourcePID, pid != ProcessInfo.processInfo.processIdentifier else { return }
                self.dismiss(restoreFocus: false)
            }
        }
    }

    func setMonitoring(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "monitoringEnabled")
        if !enabled {
            monitoring = false; monitor.stop(); dismiss(restoreFocus: false)
            status = "Monitoring is paused"
            return
        }
        guard AccessibilityProbe.isTrusted else {
            status = "Allow Accessibility access, then enable monitoring"
            AccessibilityProbe.requestPermission()
            return
        }
        permissionGranted = true; monitoring = true
        monitor.excludedApps = excludedApps; monitor.ignoredWords = ignoredWords
        monitor.start(); status = "Watching the focused input"
    }

    func openAccessibilitySettings() {
        AccessibilityProbe.requestPermission()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func showHome() {
        if home == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 490),
                                  styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
            window.title = "Spellbound"
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: HomeView(model: self))
            window.center(); home = window
        }
        home?.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
    }

    func showPlayground() {
        dismiss(restoreFocus: false)
        if playground == nil { playground = PlaygroundController(model: self) }
        playground?.show()
    }

    private func present(_ candidate: FocusedTextMonitor.Candidate) {
        guard monitoring, panel?.isVisible != true else { return }
        presentationCount += 1
        lastSourceBundle = candidate.source.bundleID
        writeDiagnosticState()
        let source = candidate.source
        present(word: candidate.word, guesses: candidate.suggestions, pid: source.pid, bundle: source.bundleID,
                demo: false, bounds: { source.currentBounds() },
                replace: { [weak self] word in
                    guard let self, self.monitoring, !self.excludedApps.contains(source.bundleID) else { return false }
                    return await source.replace(with: word)
                }, returnFocus: {
                    NSRunningApplication(processIdentifier: source.pid)?.activate()
                })
    }

    func presentDemo(word: String, guesses: [String], bounds: @escaping () -> CGRect?,
                     replace: @escaping (String) -> Bool, returnFocus: @escaping () -> Void) {
        guard panel?.isVisible != true, !ignoredWords.contains(word.lowercased()) else { return }
        present(word: word, guesses: guesses, pid: ProcessInfo.processInfo.processIdentifier,
                bundle: nil, demo: true, bounds: bounds, replace: replace, returnFocus: returnFocus)
    }

    private func present(word: String, guesses: [String], pid: pid_t, bundle: String?, demo: Bool,
                         bounds: @escaping () -> CGRect?, replace: @escaping (String) async -> Bool,
                         returnFocus: @escaping () -> Void) {
        guard let first = guesses.first, bounds() != nil else { return }
        typo = word; suggestions = guesses; target = first
        challenge = nil; answer = ""; confirming = true; showErrors = false
        message = "Choose the word you meant."
        sourcePID = pid; sourceBundle = bundle; demoSession = demo
        boundsProvider = bounds; replacement = replace; self.returnFocus = returnFocus
        monitor.suspended = true
        if panel == nil { panel = TypingPanel(model: self) }
        panel?.setContentSize(NSSize(width: stripWidth, height: 188))
        reposition()
        panel?.makeKeyAndOrderFront(nil)
        inputGeneration += 1
        tracker?.invalidate()
        tracker = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.reposition() }
        }
    }

    private func reposition() {
        guard let wordRect = boundsProvider?(), let screen = NSScreen.screens.first(where: { $0.visibleFrame.intersects(wordRect) }) else {
            dismiss(restoreFocus: false); return
        }
        let placement = OverlayPlacement.anchored(to: wordRect, size: NSSize(width: max(570, CGFloat(target.count) * 30 + 160), height: 188), visibleScreen: screen.visibleFrame)
        stripWidth = placement.frame.width
        pointerX = placement.pointerX; isAbove = placement.isAbove
        panel?.setFrame(placement.frame, display: true)
    }

    func begin() {
        guard let exercise = try? TypingChallenge(word: target) else { return }
        challenge = exercise; confirming = false; answer = ""; showErrors = false
        message = "Type the word, then press Return."
        inputGeneration += 1
    }

    func submit() {
        if confirming { begin(); return }
        if isComplete { finish(); return }
        guard var exercise = challenge else { return }
        let result = exercise.submit(answer)
        challenge = exercise
        switch result {
        case .correct:
            answer = ""; showErrors = false; inputGeneration += 1
            if exercise.phase == .completed {
                practicedCount += 1
                UserDefaults.standard.set(practicedCount, forKey: "practicedCount")
                message = "Three correct spellings. Ready to return."
            } else {
                message = "Now spell it from memory."
            }
        case .incorrect:
            showErrors = true
            message = "Not quite. Check the highlighted letters and try again."
            inputGeneration += 1
        case .pasteRejected: rejectPaste()
        case .inactive: break
        }
    }

    func rejectPaste() { message = "Type this one yourself—pasting doesn’t count." }

    func finish() {
        guard isComplete, !finishing, let replacement else { return }
        finishing = true
        let expectedPID = sourcePID
        let word = target
        tracker?.invalidate(); tracker = nil
        panel?.orderOut(nil)
        returnFocus?()
        Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .milliseconds(180))
            guard self.isComplete, self.sourcePID == expectedPID, self.monitoring else { self.finishing = false; return }
            let replaced = await replacement(word)
            self.finishing = false
            guard self.isComplete, self.sourcePID == expectedPID else { return }
            if replaced { self.dismiss(restoreFocus: true) }
            else {
                self.message = "This input couldn’t be safely edited. Copy the word, then return."
                self.panel?.makeKeyAndOrderFront(nil)
                self.tracker = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
                    Task { @MainActor in self?.reposition() }
                }
            }
        }
    }

    func copyAndReturn() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(target, forType: .string)
        dismiss(restoreFocus: true)
    }

    func learnWord() {
        ignoredWords.insert(typo.lowercased())
        UserDefaults.standard.set(Array(ignoredWords).sorted(), forKey: "ignoredWords")
        monitor.ignoredWords = ignoredWords
        dismiss(restoreFocus: true)
    }

    func excludeSourceApp() {
        guard let bundle = sourceBundle else { return }
        excludedApps.insert(bundle)
        saveExclusions()
        dismiss(restoreFocus: true)
    }

    func clearExclusions() { excludedApps = []; saveExclusions() }
    func clearVocabulary() {
        ignoredWords = []; monitor.ignoredWords = []
        UserDefaults.standard.removeObject(forKey: "ignoredWords")
    }
    private func saveExclusions() {
        monitor.excludedApps = excludedApps
        UserDefaults.standard.set(Array(excludedApps).sorted(), forKey: "excludedApps")
    }
    var canExcludeSource: Bool { sourceBundle != nil }

    func dismiss(restoreFocus: Bool = true) {
        guard !dismissalInProgress else { return }
        dismissalInProgress = true
        let restore = returnFocus
        tracker?.invalidate(); tracker = nil
        panel?.orderOut(nil)
        monitor.suppress(typo); monitor.suspended = false
        boundsProvider = nil; replacement = nil; returnFocus = nil; sourcePID = nil; sourceBundle = nil
        challenge = nil; answer = ""; typo = ""; target = ""; suggestions = []
        if restoreFocus { restore?() }
        dismissalInProgress = false
    }
}
