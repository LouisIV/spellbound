import AppKit
import SpellboundCore
import SpellboundMacIntegration

@MainActor
final class PlaygroundController: NSObject, NSTextViewDelegate {
    let window: NSWindow
    let textView: NSTextView
    weak var model: PrototypeModel?
    private var pending: DispatchWorkItem?
    private var suppressChanges = false
    private var isPasting = false
    var diagnostic = "idle"

    init(model: PrototypeModel) {
        self.model = model
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 820, height: 600),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        let editor = PlaygroundTextView()
        textView = editor
        super.init()
        window.title = "Spellbound · Typing playground"
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 650, height: 440)
        let content = NSView()
        content.wantsLayer = true
        content.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        window.contentView = content
        let heading = NSTextField(labelWithString: "A little practice, right where you type.")
        heading.font = .systemFont(ofSize: 25, weight: .semibold)
        let detail = NSTextField(wrappingLabelWithString: "Try typing: This is neccessary \nFinish the word with a space. The strip will point to the typo—even if you move or resize this window.")
        detail.font = .systemFont(ofSize: 14)
        detail.textColor = .secondaryLabelColor
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true; scroll.borderType = .bezelBorder
        scroll.documentView = textView
        textView.minSize = NSSize(width: 0, height: 220)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true; textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 740, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainerInset = NSSize(width: 18, height: 18)
        textView.font = .systemFont(ofSize: 20)
        textView.isRichText = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isContinuousSpellCheckingEnabled = true
        textView.delegate = self
        textView.setAccessibilityLabel("Practice prompt")
        let footer = NSTextField(labelWithString: "Nothing is sent anywhere. Escape skips an exercise. No Accessibility permission is needed here.")
        footer.font = .systemFont(ofSize: 12); footer.textColor = .secondaryLabelColor
        for view in [heading, detail, scroll, footer] {
            content.addSubview(view); view.translatesAutoresizingMaskIntoConstraints = false
        }
        NSLayoutConstraint.activate([
            heading.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 32),
            heading.topAnchor.constraint(equalTo: content.topAnchor, constant: 34),
            heading.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -32),
            detail.leadingAnchor.constraint(equalTo: heading.leadingAnchor),
            detail.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -32),
            detail.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 14),
            scroll.leadingAnchor.constraint(equalTo: heading.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -32),
            scroll.topAnchor.constraint(equalTo: detail.bottomAnchor, constant: 110),
            scroll.bottomAnchor.constraint(equalTo: footer.topAnchor, constant: -20),
            footer.leadingAnchor.constraint(equalTo: heading.leadingAnchor),
            footer.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -32),
            footer.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -24),
        ])
        editor.willPaste = { [weak self] in self?.isPasting = true }
        editor.didPaste = { [weak self] in self?.isPasting = false }
        window.center()
    }

    func show() {
        window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
        window.makeFirstResponder(textView)
    }

    func textDidChange(_ notification: Notification) {
        diagnostic = "text change"
        pending?.cancel()
        guard !suppressChanges, !isPasting else { return }
        // NSTextView can notify before updating its insertion point; inspect after the edit settles.
        let work = DispatchWorkItem { [weak self] in
            guard let self, !self.textView.hasMarkedText(), self.textView.selectedRange().length == 0,
                  let token = CompletedToken.beforeCaret(in: self.textView.string, caret: self.textView.selectedRange().location) else { return }
            self.showChallenge(for: token)
        }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    private func showChallenge(for token: CompletedToken) {
        diagnostic = "candidate: key=\(window.isKeyWindow), marked=\(textView.hasMarkedText()), valid=\(valid(token))"
        guard window.isKeyWindow, !textView.hasMarkedText(), valid(token) else { return }
        let guesses = SpellingService.suggestions(for: token.word)
        diagnostic += ", guesses=\(guesses.count)"
        guard !guesses.isEmpty else { return }
        model?.presentDemo(word: token.word, guesses: guesses,
            bounds: { [weak self] in
                guard let self, self.window.isVisible, self.valid(token) else { return nil }
                let rect = self.textView.firstRect(forCharacterRange: token.range, actualRange: nil)
                let local = self.textView.convert(self.window.convertFromScreen(rect), from: nil)
                guard rect.width > 0, rect.height > 0,
                      self.textView.visibleRect.intersects(local) else { return nil }
                return rect
            }, replace: { [weak self] word in
                guard let self, self.valid(token) else { return false }
                self.suppressChanges = true
                defer { self.suppressChanges = false }
                guard self.textView.shouldChangeText(in: token.range, replacementString: word) else { return false }
                let oldCaret = self.textView.selectedRange().location
                self.textView.textStorage?.replaceCharacters(in: token.range, with: word)
                self.textView.didChangeText()
                self.textView.setSelectedRange(NSRange(location: oldCaret + (word as NSString).length - token.range.length, length: 0))
                return true
            }, returnFocus: { [weak self] in
                self?.window.makeKeyAndOrderFront(nil)
                self?.window.makeFirstResponder(self?.textView)
            })
    }

    private func valid(_ token: CompletedToken) -> Bool {
        let text = textView.string as NSString
        return NSMaxRange(token.range) <= text.length && text.substring(with: token.range) == token.word
    }
}

private final class PlaygroundTextView: NSTextView {
    var willPaste: (() -> Void)?
    var didPaste: (() -> Void)?
    override func paste(_ sender: Any?) {
        willPaste?(); defer { didPaste?() }
        super.paste(sender)
    }
}
