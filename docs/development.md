# Development

## Toolchain

Verified on 2026-10-05 with Xcode 27.0 (27A266a), Apple Swift 6.4, and Tuist 4.184.1. Source uses Swift 6 language mode with a Swift tools 6.0 package manifest. Deployment targets are macOS 14 and, for shared code, iOS 17.

Install the pinned Tuist with `mise install` (or use an existing Tuist 4.184.1 installation). Select Xcode with `xcode-select` if necessary. No Tuist cloud account or external package dependency is required.

## Generate and build

From the repository root:

```sh
tuist generate --no-open --cache-profile none
tuist xcodebuild build \
  -workspace Spellbound.xcworkspace \
  -scheme SpellboundMac \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath .build/DerivedData \
  CODE_SIGNING_ALLOWED=NO
```

The pinned Tuist deprecates `tuist build`; use its `tuist xcodebuild build` wrapper. The unsigned build checks compilation without a developer account. It does not validate signing, launch permission identity, distribution, or notarization. Configure signing before device/distribution and Accessibility acceptance testing.

Project.swift owns app targets and schemes. Packages/SpellboundKit/Package.swift owns package targets. Never hand-edit generated Xcode files. Generated projects, workspaces, Derived files, and build products are ignored.

## Shared logic tests

```sh
swift test --package-path Packages/SpellboundKit --scratch-path .build/package-tests
```

Tests cover challenge progression, retry, pasted-submission rejection, skip, Unicode normalization, target validation, and observation eligibility. The prototype input adapter rejects paste and draws caret/selection in its letter tiles. The native smoke test exercises the actual views. See prototype.md for the runnable app and smoke commands.

## iOS boundary check

Run from the package directory; package schemes are not exposed in the generated app workspace:

```sh
cd Packages/SpellboundKit
xcodebuild -scheme SpellboundCore \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath ../../.build/iOSCore \
  CODE_SIGNING_ALLOWED=NO build
```

This builds shared domain code only. There is no iOS app target yet.

## Accessibility capability probe

Build and run the metadata-only probe against an explicit disposable test input:

```sh
swift run --package-path Packages/SpellboundKit spellbound-probe \
  --bundle-id com.apple.TextEdit --delay 5
```

Switch to a blank TextEdit document during the delay. For the installed T3 Code app use `com.t3tools.t3code`; focus a disposable, unsent prompt. The explicit bundle argument confines this engineering probe to one test target. Production observation will follow focused inputs automatically across non-excluded apps, without app-specific onboarding.

If the probe reports `permission-required`, explicitly request the system permission flow:

```sh
swift run --package-path Packages/SpellboundKit spellbound-probe --request-permission
```

Enable the executable or responsible terminal that macOS identifies in System Settings → Privacy & Security → Accessibility. Then rerun the probe using the same executable path. Permission granted to a terminal/probe does not prove permission for the future signed app.

The probe reads only focused-control role/subrole and advertised AX capability names. It never reads field values, selected text, titles, descriptions, clipboard contents, or global keystrokes, and never writes into another app. Advertised capabilities are not proof of working observation or safe replacement. Unknown and secure controls are excluded. The current probe does not yet test notifications, composition, or actual bounded text retrieval; those remain explicit feasibility tasks.
