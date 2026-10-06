## ADDED Requirements

### Requirement: Explicit observation eligibility
The app SHALL observe the focused input across applications without per-app onboarding while Accessibility permission is granted, monitoring is active, and the focused input is positively classified as supported and non-secure, and the app is not excluded.

#### Scenario: Eligible field
- **WHEN** a non-excluded app exposes a supported editable text input
- **THEN** the observer processes bounded changes in that field

#### Scenario: Permission unavailable
- **WHEN** permission is absent or revoked
- **THEN** observation stops, transient text is cleared, and permission-required status is shown

#### Scenario: Excluded field
- **WHEN** focus enters a secure, unknown, excluded, or unsupported input
- **THEN** no input text is read and unsupported status is shown where applicable

### Requirement: Bounded transient observation
The observer SHALL keep text snapshots in memory only, discard stale work on focus changes, and avoid collecting a global keystroke stream.

#### Scenario: Focus changes during check
- **WHEN** a pending spelling check belongs to a previously focused element
- **THEN** its result is discarded and cannot open a challenge

#### Scenario: Existing or bulk text
- **WHEN** a user focuses existing text or pastes multiple words
- **THEN** the app does not generate challenges for the existing or bulk text

### Requirement: Compatibility evidence
The MVP SHALL document tested app/control versions and distinguish observation, safe replacement, and unsupported capabilities before declaring target support.

#### Scenario: Primary workflow gate
- **WHEN** the intended coding-assistant prompt cannot be observed reliably
- **THEN** the compatibility report marks it unsupported and the target workflow is not declared complete

### Requirement: Automatic focus following
The app SHALL follow focus between eligible inputs in different applications after one global enablement, without asking the user to onboard each application. Optional exclusions SHALL stop observation in excluded applications.

#### Scenario: Newly focused application
- **WHEN** monitoring is active and focus moves to a supported input in an application never seen before
- **THEN** observation begins without an app-specific setup step unless that app is excluded

#### Scenario: Excluded application
- **WHEN** the user excludes an application
- **THEN** any observation of that application stops and its transient input state is cleared
