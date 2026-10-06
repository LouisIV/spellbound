#if os(macOS)
import Foundation
import SpellboundMacIntegration

@main
struct Probe {
    @MainActor
    static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())
        if args == ["--request-permission"] {
            AccessibilityProbe.requestPermission()
            print("Enable this executable or its responsible terminal in System Settings > Privacy & Security > Accessibility, then rerun the probe.")
            return
        }
        guard let index = args.firstIndex(of: "--bundle-id"), args.indices.contains(index + 1) else {
            print("Usage: spellbound-probe --bundle-id <explicit-target> [--delay <0...30>]\n       spellbound-probe --request-permission\nReports capabilities only; never captures input text or edits another app.")
            return
        }
        let bundle = args[index + 1]
        var delay = 0
        if let index = args.firstIndex(of: "--delay") {
            guard args.indices.contains(index + 1), let value = Int(args[index + 1]),
                  (0...30).contains(value) else {
                print("Delay must be an integer from 0 through 30 seconds.")
                return
            }
            delay = value
        }
        if delay > 0 {
            print("Focus a disposable input in the target app. Inspecting metadata in \(delay) seconds.")
            try? await Task.sleep(for: .seconds(delay))
        }
        let report = AccessibilityProbe.inspect(expectedBundleIdentifier: bundle)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let data = try encoder.encode(report)
            print(String(decoding: data, as: UTF8.self))
        } catch {
            print("Could not encode capability report.")
        }
    }
}
#else
@main
struct Probe {
    static func main() { print("Accessibility probing requires macOS.") }
}
#endif
