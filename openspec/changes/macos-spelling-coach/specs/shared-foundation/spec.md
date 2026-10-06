## ADDED Requirements

### Requirement: Platform-isolated monorepo
The repository SHALL contain a macOS SwiftUI app shell and local shared Swift package targets with domain logic independent of AppKit and ApplicationServices.

#### Scenario: Core tests
- **WHEN** domain tests execute
- **THEN** challenge progression, scheduling, and filtering run without Accessibility permission or app UI

#### Scenario: Future iOS reuse
- **WHEN** shared Core, Storage, and UI targets are built for an iOS simulator
- **THEN** they compile without the macOS integration target

### Requirement: Reproducible development checks
The project SHALL document the Xcode toolchain, deployment targets, app build, package tests, and supported-input verification steps.

#### Scenario: Clean checkout
- **WHEN** a developer follows the documented setup using the required toolchain
- **THEN** they can build the macOS app and run shared logic tests

### Requirement: Tuist-managed Xcode project
The repository SHALL use committed Tuist Swift manifests as the source of truth for Xcode project generation and app schemes, pin a compatible Tuist version, and exclude generated Xcode projects and workspaces from version control. Shared package targets SHALL remain defined in Package.swift and referenced by the app manifest without duplicate target definitions.

#### Scenario: Clean generation and build
- **WHEN** a developer installs the documented toolchain and pinned Tuist version in a clean checkout
- **THEN** tuist generate and tuist xcodebuild build with the SpellboundMac scheme produce a buildable macOS app without manually editing project files or requiring a Tuist cloud account

#### Scenario: Project configuration changes
- **WHEN** an app target or scheme needs to change
- **THEN** the change is made in the committed Tuist manifests and reproduced by regenerating the project
