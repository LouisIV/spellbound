#if os(macOS)
import AppKit
// AX exposes immutable option constants as C globals without concurrency annotations.
@preconcurrency import ApplicationServices
import SpellboundCore

/// Metadata only: never reads value, selected text, title, description, or clipboard.
@MainActor
public enum AccessibilityProbe {
    public struct Report: Codable, Sendable {
        public let permissionGranted: Bool
        public let bundleIdentifier: String?
        public let role: String?
        public let subrole: String?
        public let status: String
        public let supportsValue: Bool
        public let supportsSelectedRange: Bool
        public let selectedTextSettable: Bool
        public let supportsBoundedText: Bool
        public let supportsCharacterCount: Bool
        public let supportsWordBounds: Bool
        public let attributes: [String]
        public let parameters: [String]
    }

    public static var isTrusted: Bool { AXIsProcessTrusted() }

    public static func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// Electron exposes its focused web controls only after assistive technology requests its AX tree.
    /// Unsupported attributes simply return AXError; this does not read or alter input text.
    public static func prepareApplication(pid: pid_t) {
        guard isTrusted else { return }
        let app = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(app, 0.15)
        _ = AXUIElementSetAttributeValue(app, "AXManualAccessibility" as CFString, kCFBooleanTrue)
        _ = AXUIElementSetAttributeValue(app, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue)
    }

    public static func inspect(expectedBundleIdentifier: String) -> Report {
        func report(_ status: String, bundle: String? = nil, role: String? = nil,
                    subrole: String? = nil, attributes: [String] = [],
                    parameters: [String] = [], settable: Bool = false) -> Report {
            Report(permissionGranted: isTrusted, bundleIdentifier: bundle, role: role,
                   subrole: subrole, status: status,
                   supportsValue: attributes.contains(kAXValueAttribute),
                   supportsSelectedRange: attributes.contains(kAXSelectedTextRangeAttribute),
                   selectedTextSettable: settable,
                   supportsBoundedText: parameters.contains(kAXStringForRangeParameterizedAttribute),
                   supportsCharacterCount: attributes.contains(kAXNumberOfCharactersAttribute),
                   supportsWordBounds: parameters.contains(kAXBoundsForRangeParameterizedAttribute),
                   attributes: attributes, parameters: parameters)
        }
        guard isTrusted else { return report("permission-required") }
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.bundleIdentifier == expectedBundleIdentifier else {
            return report("target-not-frontmost")
        }
        let application = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(application, 0.5)
        var focused: CFTypeRef?
        guard AXUIElementCopyAttributeValue(application, kAXFocusedUIElementAttribute as CFString,
                                            &focused) == .success,
              let focused, CFGetTypeID(focused) == AXUIElementGetTypeID() else {
            return report("no-focused-element", bundle: expectedBundleIdentifier)
        }
        let element = unsafeDowncast(focused, to: AXUIElement.self)
        func string(_ name: String) -> String? {
            var value: CFTypeRef?
            guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success
            else { return nil }
            return value as? String
        }
        let role = string(kAXRoleAttribute)
        let subrole = string(kAXSubroleAttribute)
        guard ObservationEligibility.permitsRead(permissionGranted: true, appExcluded: false,
                monitoringActive: true, role: role, subrole: subrole) else {
            return report("excluded-control", bundle: expectedBundleIdentifier, role: role, subrole: subrole)
        }
        var attributes: CFArray?
        var parameters: CFArray?
        AXUIElementCopyAttributeNames(element, &attributes)
        AXUIElementCopyParameterizedAttributeNames(element, &parameters)
        var settable = DarwinBoolean(false)
        AXUIElementIsAttributeSettable(element, kAXSelectedTextAttribute as CFString, &settable)
        return report("metadata-only-unverified", bundle: expectedBundleIdentifier, role: role,
                      subrole: subrole, attributes: attributes as? [String] ?? [],
                      parameters: parameters as? [String] ?? [], settable: settable.boolValue)
    }
}
#endif
