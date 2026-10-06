import AppKit
import SwiftUI
import SpellboundUI

@MainActor
final class TypingPanel: NSPanel {
    weak var model: PrototypeModel?
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    init(model: PrototypeModel) {
        self.model = model
        super.init(contentRect: NSRect(x: 0, y: 0, width: 570, height: 188),
                   styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isFloatingPanel = true
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isReleasedWhenClosed = false
        contentView = NSHostingView(rootView: TypingStrip(model: model))
        setAccessibilityLabel("Spellbound spelling practice")
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { model?.dismiss() }
        else if event.keyCode == 36 || event.keyCode == 76 { model?.submit() }
        else { super.keyDown(with: event) }
    }
}

struct TypingStrip: View {
    @ObservedObject var model: PrototypeModel

    var body: some View {
        VStack(spacing: 0) {
            if !model.isAbove { pointer }
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Spellbound").font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                    Spacer()
                    if model.confirming {
                        Text("You typed “\(model.typo)”").font(.system(size: 13))
                    } else if model.isComplete {
                        Label("Word practiced", systemImage: "checkmark.circle.fill").foregroundStyle(.mint)
                    } else {
                        Text(model.isGuided ? "Type **\(model.target)**" : "Spell it from memory")
                            .font(.system(size: 14))
                    }
                    Spacer()
                    if !model.confirming { Text("\(model.isComplete ? 3 : model.roundNumber) / 3").font(.system(size: 12).monospacedDigit()).foregroundStyle(.secondary) }
                    Button { model.dismiss() } label: { Image(systemName: "xmark").font(.system(size: 12)) }
                        .buttonStyle(.plain).help("Skip this word (Escape)").accessibilityLabel("Skip this word")
                }

                if model.confirming {
                    HStack(spacing: 12) {
                        Menu {
                            ForEach(model.suggestions, id: \.self) { word in
                                Button(word) { model.target = word }
                            }
                        } label: {
                            HStack {
                                Text(model.target).font(.system(size: 24, weight: .medium, design: .rounded))
                                Image(systemName: "chevron.down").font(.system(size: 11))
                            }
                            .foregroundStyle(.mint)
                        }
                        .menuStyle(.borderlessButton).fixedSize()
                        Spacer()
                        Button("Practice this word ↵") { model.begin() }
                            .buttonStyle(StripButtonStyle())
                    }.frame(height: 44)
                } else if model.isComplete {
                    HStack {
                        Text(model.target).font(.system(size: 24, weight: .medium, design: .rounded)).foregroundStyle(.mint)
                        Spacer()
                        Button("Replace & return ↵") { model.finish() }.buttonStyle(StripButtonStyle())
                    }.frame(height: 44)
                } else {
                    HStack(spacing: 12) {
                        ZStack(alignment: .leading) {
                            LetterTiles(target: model.target, answer: model.answer,
                                        guided: model.isGuided, showErrors: model.showErrors,
                                        selection: model.tileSelection)
                            PracticeInput(model: model)
                        }.frame(height: 44)
                        Button("Check ↵") { model.submit() }.buttonStyle(StripButtonStyle())
                    }
                }

                HStack(alignment: .center) {
                    Text(model.message)
                        .font(.system(size: 11))
                        .foregroundStyle(model.showErrors ? Color.orange : Color.white.opacity(0.7))
                        .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel(model.message)
                    Spacer(minLength: 10)
                    if model.confirming {
                        Button("Learn word") { model.learnWord() }.help("Don’t flag this spelling again")
                    } else if model.isComplete {
                        Button("Copy & return") { model.copyAndReturn() }
                    } else {
                        Button("Skip") { model.dismiss() }
                    }
                    Menu {
                        Button("Pause monitoring") { model.setMonitoring(false) }
                        if model.canExcludeSource { Button("Exclude this app") { model.excludeSourceApp() } }
                        Button("Open Spellbound") { model.dismiss(restoreFocus: false); model.showHome() }
                    } label: { Image(systemName: "ellipsis") }
                    .menuStyle(.borderlessButton).fixedSize().accessibilityLabel("More options")
                }
                .buttonStyle(.plain).font(.system(size: 11))
            }
            .padding(.horizontal, 20).padding(.vertical, 16)
            .frame(width: model.stripWidth, height: 178)
            .background(Color(red: 0.115, green: 0.13, blue: 0.15), in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Color.white.opacity(0.16), lineWidth: 1))
            if model.isAbove { pointer }
        }
        .preferredColorScheme(.dark)
    }

    private var pointer: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: max(0, model.pointerX - 9))
            PointerTriangle().fill(Color(red: 0.115, green: 0.13, blue: 0.15)).frame(width: 18, height: 10)
                .rotationEffect(.degrees(model.isAbove ? 0 : 180))
            Spacer(minLength: 0)
        }.frame(width: model.stripWidth, height: 10)
    }
}

private struct PointerTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY)); p.closeSubpath()
        }
    }
}

private struct StripButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.black.opacity(0.88)).padding(.horizontal, 14).frame(height: 38)
            .background(Color.mint.opacity(configuration.isPressed ? 0.7 : 1), in: RoundedRectangle(cornerRadius: 7))
    }
}

private struct PracticeInput: NSViewRepresentable {
    @ObservedObject var model: PrototypeModel

    func makeNSView(context: Context) -> PracticeTextView {
        let view = PracticeTextView()
        view.model = model
        view.isRichText = false; view.drawsBackground = false
        view.textColor = .clear; view.insertionPointColor = .clear
        view.selectedTextAttributes = [.backgroundColor: NSColor.clear, .foregroundColor: NSColor.clear]
        view.font = .systemFont(ofSize: 23)
        view.isAutomaticSpellingCorrectionEnabled = false
        view.isAutomaticTextCompletionEnabled = false
        view.isAutomaticQuoteSubstitutionEnabled = false
        view.isAutomaticDashSubstitutionEnabled = false
        view.isContinuousSpellCheckingEnabled = false
        view.isGrammarCheckingEnabled = false
        view.isHorizontallyResizable = true
        view.textContainer?.widthTracksTextView = false
        view.delegate = context.coordinator
        view.setAccessibilityLabel("Type the spelling")
        return view
    }

    func updateNSView(_ view: PracticeTextView, context: Context) {
        view.model = model
        if view.string != model.answer { view.string = model.answer }
        view.setAccessibilityLabel(model.isGuided ? "Type \(model.target)" : "Spell the word from memory")
        if context.coordinator.generation != model.inputGeneration {
            context.coordinator.generation = model.inputGeneration
            DispatchQueue.main.async {
                view.window?.makeFirstResponder(view)
                if model.showErrors { view.setSelectedRange(NSRange(location: 0, length: (view.string as NSString).length)) }
                else { view.setSelectedRange(NSRange(location: (view.string as NSString).length, length: 0)) }
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(model) }
    final class Coordinator: NSObject, NSTextViewDelegate {
        let model: PrototypeModel
        var generation = -1
        init(_ model: PrototypeModel) { self.model = model }
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let view = notification.object as? NSTextView else { return }
            model.answerSelection = view.selectedRange()
        }
        func textDidChange(_ notification: Notification) {
            guard let view = notification.object as? NSTextView else { return }
            if view.string.count > 24 { view.string = String(view.string.prefix(24)) }
            model.answer = view.string
            model.answerSelection = view.selectedRange()
        }
    }
}

private final class PracticeTextView: NSTextView {
    weak var model: PrototypeModel?
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else { return }
        // SwiftUI can update the representable before attaching it to a nonactivating panel.
        // Acquire focus after attachment as well as on subsequent exercise generations.
        DispatchQueue.main.async { [weak self, weak window] in
            guard let self, let window, self.window === window,
                  self.model?.confirming == false, self.model?.isComplete == false else { return }
            window.makeFirstResponder(self)
        }
    }
    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        guard let model else { return }
        let point = convert(event.locationInWindow, from: nil)
        let count = max(model.target.count, model.answer.count)
        let spacing: CGFloat = count > 14 ? 3 : 5
        let tileWidth = min(31, max(10, (bounds.width - CGFloat(max(0, count - 1)) * spacing) / CGFloat(max(1, count))))
        let index = min(model.answer.count, max(0, Int((point.x + spacing / 2) / (tileWidth + spacing))))
        setSelectedRange(NSRange(location: index, length: 0))
    }
    override func paste(_ sender: Any?) { model?.rejectPaste() }
    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool { model?.rejectPaste(); return false }
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { model?.dismiss(); return }
        if event.keyCode == 36 || event.keyCode == 76 { model?.submit(); return }
        super.keyDown(with: event)
    }
}
