import AppKit
import SwiftUI
import SpellboundMacIntegration

@main
struct SpellboundApp: App {
    @NSApplicationDelegateAdaptor(PrototypeDelegate.self) private var delegate
    var body: some Scene { Settings { EmptyView() } }
}

@MainActor
final class PrototypeDelegate: NSObject, NSApplicationDelegate {
    let model = PrototypeModel()
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "character.cursor.ibeam", accessibilityDescription: "Spellbound")
        let menu = NSMenu()
        let home = NSMenuItem(title: "Open Spellbound", action: #selector(openHome), keyEquivalent: "")
        home.target = self; menu.addItem(home)
        let play = NSMenuItem(title: "Typing playground", action: #selector(openPlayground), keyEquivalent: "")
        play.target = self; menu.addItem(play)
        let toggle = NSMenuItem(title: "Pause / resume monitoring", action: #selector(toggleMonitoring), keyEquivalent: "")
        toggle.target = self; menu.addItem(toggle)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Spellbound", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu; statusItem = item
        let args = CommandLine.arguments
        if let index = args.firstIndex(of: "--diagnostic-status"), args.indices.contains(index + 1) {
            model.diagnosticFile = URL(fileURLWithPath: args[index + 1])
        }
        if args.contains("--monitor") || UserDefaults.standard.bool(forKey: "monitoringEnabled") { model.setMonitoring(true) }
        if let index = args.firstIndex(of: "--diagnose-output"), args.indices.contains(index + 1) {
            let output = URL(fileURLWithPath: args[index + 1])
            Task { @MainActor in
                let bundle = "com.t3tools.t3code"
                if let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundle).first {
                    app.activate(options: [.activateIgnoringOtherApps])
                    try? await Task.sleep(for: .milliseconds(600))
                    let before = AccessibilityProbe.inspect(expectedBundleIdentifier: bundle)
                    AccessibilityProbe.prepareApplication(pid: app.processIdentifier)
                    try? await Task.sleep(for: .milliseconds(800))
                    let after = AccessibilityProbe.inspect(expectedBundleIdentifier: bundle)
                    let reports = ["before": before, "after": after]
                    let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                    if let data = try? encoder.encode(reports) { try? data.write(to: output, options: .atomic) }
                }
            }
        } else { model.showHome() }
        model.writeDiagnosticState()
        #if DEBUG
        if let index = args.firstIndex(of: "--t3-smoke-output"), args.indices.contains(index + 1) {
            let output = URL(fileURLWithPath: args[index + 1], isDirectory: true)
            Task { await runT3SmokeTest(model: model, output: output) }
        }
        if let index = args.firstIndex(of: "--smoke-output"), args.indices.contains(index + 1) {
            let output = URL(fileURLWithPath: args[index + 1], isDirectory: true)
            Task { await runPrototypeSmokeTest(model: model, output: output) }
        }
        if let index = args.firstIndex(of: "--external-smoke-output"), args.indices.contains(index + 1),
           let fixtureIndex = args.firstIndex(of: "--fixture"), args.indices.contains(fixtureIndex + 1) {
            let output = URL(fileURLWithPath: args[index + 1], isDirectory: true)
            let fixture = URL(fileURLWithPath: args[fixtureIndex + 1])
            Task { await runExternalSmokeTest(model: model, fixture: fixture, output: output) }
        }
        #endif
    }

    @objc private func openHome() { model.showHome() }
    @objc private func openPlayground() { model.showPlayground() }
    @objc private func toggleMonitoring() { model.setMonitoring(!model.monitoring) }
}
