## ADDED Requirements

### Requirement: Onboarding and monitoring control
The app SHALL explain cross-app text access, start monitoring disabled, offer one global enable switch and optional per-app exclusions, and expose pause/resume and permission status from the menu bar.

#### Scenario: First launch
- **WHEN** the app has not completed Accessibility onboarding and global enablement
- **THEN** onboarding explains access and observes no text

#### Scenario: Pause
- **WHEN** the user pauses monitoring
- **THEN** observation and pending challenges stop until resumed

### Requirement: Accessible independent practice
The app SHALL support keyboard navigation, VoiceOver, reduced motion, and standalone practice without Accessibility permission.

#### Scenario: Permission declined
- **WHEN** the user declines observation permission
- **THEN** settings, progress, and manual practice remain usable

#### Scenario: Accessible recall
- **WHEN** a VoiceOver user enters a recall round
- **THEN** the round and feedback are announced without disclosing the hidden spelling
