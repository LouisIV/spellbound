#if DEBUG
import AppKit
import SpellboundCore
import SpellboundMacIntegration

/// Exercises real native views with synthetic text; never accesses another application's input.
@MainActor
func runPrototypeSmokeTest(model: PrototypeModel, output: URL) async {
    var results: [String: Bool] = [:]
    let initialCount = model.practicedCount
    func settle() async { try? await Task.sleep(for: .milliseconds(550)) }
    func enter() {
        guard let panel = model.panel,
              let event = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [],
                    timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: panel.windowNumber,
                    context: nil, characters: "\r", charactersIgnoringModifiers: "\r", isARepeat: false, keyCode: 36) else { return }
        panel.sendEvent(event)
    }
    func type(_ word: String) {
        guard let field = model.panel?.firstResponder as? NSTextView else { return }
        field.selectAll(nil)
        field.insertText(word, replacementRange: field.selectedRange())
    }
    func capture(_ view: NSView?, name: String) {
        guard let view, let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: rep)
        if let data = rep.representation(using: .png, properties: [:]) { try? data.write(to: output.appendingPathComponent(name)) }
    }
    try? FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
    model.showPlayground()
    await settle()
    guard let playground = model.playground else { return }
    playground.textView.selectAll(nil)
    playground.textView.insertText("This is neccessary ", replacementRange: playground.textView.selectedRange())
    await settle()
    try? "\(playground.diagnostic); active=\(NSApp.isActive); visible=\(playground.window.isVisible); key=\(NSApp.keyWindow?.title ?? "nil")".write(to: output.appendingPathComponent("diagnostics.txt"), atomically: true, encoding: .utf8)
    results["stripIsKey"] = model.panel?.isKeyWindow == true
    results["caretAtEnd"] = playground.textView.selectedRange().location == (playground.textView.string as NSString).length
    results["detectedSyntheticTypo"] = model.panel?.isVisible == true && model.typo == "neccessary"
    results["proposedCorrectWord"] = model.target == "necessary"
    capture(model.panel?.contentView, name: "confirmation.png")
    enter()
    await settle()
    results["enterStartsExercise"] = model.challenge?.phase == .guided
    type("nece")
    await settle()
    capture(model.panel?.contentView, name: "guided-strip.png")
    if let field = model.panel?.firstResponder as? NSTextView {
        field.moveLeft(nil); field.moveLeft(nil)
        results["tileCaretFollowsEditingPosition"] = model.tileSelection.lowerBound == 2
        field.selectAll(nil)
        results["tileSelectionMatchesSelectAll"] = model.tileSelection == 0..<4
        capture(model.panel?.contentView, name: "selected-tiles.png")
    }
    capture(playground.window.contentView, name: "playground.png")
    let oldFrame = model.panel?.frame ?? .zero
    playground.window.setFrameOrigin(NSPoint(x: playground.window.frame.minX + 40, y: playground.window.frame.minY + 25))
    await settle()
    let newFrame = model.panel?.frame ?? .zero
    results["overlayFollowsWordWhenWindowMoves"] = abs(newFrame.minX - oldFrame.minX - 40) < 2 && abs(newFrame.minY - oldFrame.minY - 25) < 2
    if let field = model.panel?.firstResponder as? NSTextView {
        let before = model.answer
        field.paste(nil)
        results["pasteRejected"] = model.answer == before && model.message.contains("pasting")
    }
    type("necessary"); enter(); await settle()
    results["guidedAdvancesToRecall"] = model.challenge?.phase == .recall(1)
    capture(model.panel?.contentView, name: "recall-strip.png")
    type("neccessary"); enter(); await settle()
    results["errorRetriesSameRound"] = model.challenge?.phase == .recall(1) && model.showErrors
    type("necessary"); enter(); await settle()
    results["secondRecall"] = model.challenge?.phase == .recall(2)
    type("necessary"); enter(); await settle()
    results["completedThreeRounds"] = model.isComplete
    capture(model.panel?.contentView, name: "completed-strip.png")
    enter(); await settle()
    results["replacedOnlyTypo"] = playground.textView.string == "This is necessary "
    results["returnedToOriginalInput"] = playground.window.firstResponder === playground.textView && model.panel?.isVisible == false
    playground.textView.selectAll(nil)
    playground.textView.insertText("This is accomodation ", replacementRange: playground.textView.selectedRange())
    await settle()
    results["longWordDetected"] = model.target == "accommodation"
    enter(); await settle()
    type("accommo"); await settle()
    capture(model.panel?.contentView, name: "long-word-strip.png")
    model.dismiss()
    await settle()
    playground.textView.selectAll(nil)
    let paragraphs = String(repeating: "A line of sample text.\n", count: 40) + "This is neccessary "
    playground.textView.insertText(paragraphs, replacementRange: playground.textView.selectedRange())
    playground.textView.scrollRangeToVisible(playground.textView.selectedRange())
    await settle()
    results["scrolledWordInitiallyVisible"] = model.panel?.isVisible == true
    if let scroll = playground.textView.enclosingScrollView {
        scroll.contentView.scroll(to: .zero)
        scroll.reflectScrolledClipView(scroll.contentView)
    }
    await settle()
    results["offscreenWordDismissesStrip"] = model.panel?.isVisible == false
    playground.textView.selectAll(nil)
    playground.textView.insertText("", replacementRange: playground.textView.selectedRange())
    // Test instrumentation doesn't increment the user's practice count.
    model.practicedCount = initialCount
    UserDefaults.standard.set(initialCount, forKey: "practicedCount")
    if let data = try? JSONEncoder().encode(results) { try? data.write(to: output.appendingPathComponent("smoke-results.json")) }
}

@MainActor
func runExternalSmokeTest(model: PrototypeModel, fixture: URL, output: URL) async {
    try? FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
    var results: [String: Bool] = ["accessibilityPermissionGranted": AccessibilityProbe.isTrusted]
    let initialCount = model.practicedCount
    guard AccessibilityProbe.isTrusted else {
        if let data = try? JSONEncoder().encode(results) { try? data.write(to: output.appendingPathComponent("external-results.json")) }
        return
    }
    // The user's enabled global monitoring authorizes this disposable-fixture verification.
    model.setMonitoring(true)
    let config = NSWorkspace.OpenConfiguration()
    config.arguments = ["--report", output.appendingPathComponent("fixture-results.json").path]
    do { _ = try await NSWorkspace.shared.openApplication(at: fixture, configuration: config) }
    catch {
        results["fixtureLaunched"] = false
        if let data = try? JSONEncoder().encode(results) { try? data.write(to: output.appendingPathComponent("external-results.json")) }
        return
    }
    results["fixtureLaunched"] = true
    for _ in 0..<30 {
        if model.panel?.isVisible == true { break }
        try? await Task.sleep(for: .milliseconds(550))
    }
    results["detectedExternalTypo"] = model.panel?.isVisible == true && model.typo == "neccessary"
    results["correctSuggestion"] = model.target == "necessary"
    if model.panel?.isVisible == true {
        model.begin()
        try? await Task.sleep(for: .milliseconds(550))
        if let view = model.panel?.contentView, let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
            view.cacheDisplay(in: view.bounds, to: rep)
            try? rep.representation(using: .png, properties: [:])?.write(to: output.appendingPathComponent("external-strip.png"))
        }
        results["practiceFieldFocused"] = model.panel?.firstResponder is NSTextView
        for _ in 0..<3 {
            guard let field = model.panel?.firstResponder as? NSTextView else { break }
            field.selectAll(nil); field.insertText("necessary", replacementRange: field.selectedRange())
            model.submit()
            try? await Task.sleep(for: .milliseconds(550))
        }
        results["completedExternalExercise"] = model.isComplete
        model.finish()
        try? await Task.sleep(for: .milliseconds(900))
        results["sourceEditAccepted"] = model.panel?.isVisible == false
    }
    try? model.status.write(to: output.appendingPathComponent("status.txt"), atomically: true, encoding: .utf8)
    model.practicedCount = initialCount
    UserDefaults.standard.set(initialCount, forKey: "practicedCount")
    if let data = try? JSONEncoder().encode(results) { try? data.write(to: output.appendingPathComponent("external-results.json")) }
}
#endif
