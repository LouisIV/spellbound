import AppKit

@main
@MainActor
struct Fixture {
    static func main() {
        let app = NSApplication.shared
        let delegate = FixtureDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
        withExtendedLifetime(delegate) {}
    }
}

@MainActor
final class FixtureDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var editor: NSTextView!
    var timer: Timer?
    var remaining = Array("neccessary ")
    var reportURL: URL?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let args = CommandLine.arguments
        if let index = args.firstIndex(of: "--report"), args.indices.contains(index + 1) {
            reportURL = URL(fileURLWithPath: args[index + 1])
        }
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 760, height: 440),
                          styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.title = "Spellbound · Disposable AX test input"
        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 760, height: 440))
        scroll.hasVerticalScroller = true
        editor = NSTextView(frame: NSRect(x: 0, y: 0, width: 760, height: 440))
        editor.isRichText = false
        editor.font = .systemFont(ofSize: 22)
        editor.textContainerInset = NSSize(width: 36, height: 230)
        editor.isAutomaticSpellingCorrectionEnabled = false
        editor.isAutomaticTextCompletionEnabled = false
        editor.isContinuousSpellCheckingEnabled = true
        editor.autoresizingMask = [.width]
        editor.isVerticallyResizable = true
        editor.textContainer?.widthTracksTextView = true
        editor.textContainer?.containerSize = NSSize(width: 760, height: CGFloat.greatestFiniteMagnitude)
        scroll.documentView = editor
        window.contentView = scroll
        window.center(); window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window.makeFirstResponder(editor)
        editor.insertText("This is ", replacementRange: editor.selectedRange())
        // Leave time for the observer to establish a baseline, then type a disposable word.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in self?.startTyping() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 16) { [weak self] in self?.writeResult() }
    }

    func startTyping() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                guard !self.remaining.isEmpty else { self.timer?.invalidate(); return }
                self.editor.insertText(String(self.remaining.removeFirst()), replacementRange: self.editor.selectedRange())
            }
        }
    }

    func writeResult() {
        let result = ["targetedReplacement": editor.string == "This is necessary ",
                      "focusReturned": window.firstResponder === editor]
        if let reportURL, let data = try? JSONEncoder().encode(result) { try? data.write(to: reportURL) }
        NSApp.terminate(nil)
    }
}
