## Why

Typing rough prompts into coding assistants makes it easy to repeatedly misspell words without learning them. Spellbound turns those moments into a brief, deliberate spelling exercise so correct spelling becomes a habit.

## What Changes

- Create a native macOS menu bar app with SwiftUI onboarding, settings, practice, and progress views.
- Observe completed words in explicitly enabled, supported text inputs through macOS Accessibility.
- Identify likely spelling errors locally, with filters for code, URLs, paths, and personal vocabulary.
- Interrupt with a short typing game: confirm the intended word, type it with a cue, then recall it twice without the cue.
- Offer a guarded replacement of the original typo where supported; otherwise let the user copy the correction explicitly.
- Keep a local word history and a small spaced-review queue.
- Use Tuist Swift manifests to generate and build the Xcode project, with a pinned tool version and generated project files excluded from version control.
- Organize app shells and reusable Swift packages in one repository, keeping a future iOS practice app possible.
- Start implementation with a compatibility experiment; do not promise universal monitoring or prevention of prompt submission.

## Capabilities

### New Capabilities

- `text-observation`: Permission-aware, opt-in observation of eligible macOS text fields.
- `spelling-detection`: Local spelling checks, token filtering, vocabulary, and duplicate suppression.
- `typing-challenge`: Interruptive practice, safe dismissal, and guarded correction handoff.
- `learning-history`: Local progress, deterministic review scheduling, and deletion.
- `app-controls`: Onboarding, menu bar status, per-app settings, and accessible interaction.
- `shared-foundation`: Native monorepo boundaries and future iOS reuse.

### Modified Capabilities

None; this is a new project.

## Impact

New macOS app target, local Swift package targets, tests, and build documentation. Platform integrations will use AppKit, ApplicationServices Accessibility APIs, and NSSpellChecker behind interfaces. No backend, accounts, cloud model, or network dependency is required for the MVP. Proposed distribution is a directly distributed, signed and notarized macOS app; App Store distribution is not assumed.

This change is a proposal only. Application implementation starts in the next phase.
