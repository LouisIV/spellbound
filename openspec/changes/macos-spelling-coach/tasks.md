## 1. Tooling and macOS feasibility gate

- [x] 1.1 Confirm the installed Xcode/Swift toolchain and a compatible Tuist version and proposed macOS 14/iOS 17 baselines; document reproducible build prerequisites.
- [x] 1.2 Build a minimal disposable Accessibility probe that reports capabilities without logging input text.
- [ ] 1.3 Test native text input, browser textarea/contenteditable, and an available coding-assistant prompt; record exact versions and choose the primary target in docs/compatibility.md.
- [ ] 1.4 Verify secure-field exclusion, notifications, composition handling, rapid typing, permission revocation, and focus transitions; record unsupported cases.
- [ ] 1.5 Test targeted replacement and source revalidation separately; classify observation-only controls. If the primary prompt cannot be observed, revise this proposal before production integration.

## 2. Monorepo foundation

- [ ] 2.1 Create Tuist.swift and Project.swift declaring the macOS SwiftUI target and shared scheme, plus the local SpellboundKit package described in design.md; pin Tuist in mise.toml and ignore generated Xcode projects/workspaces.
- [ ] 2.2 Add Core types and dependency interfaces for spelling, observation, correction, storage, and time; keep macOS imports isolated.
- [ ] 2.3 Document and run tuist generate, tuist xcodebuild build with the SpellboundMac scheme, Swift package tests, and shared-target iOS simulator builds from a clean checkout without pre-existing generated projects or a Tuist cloud account.

## 3. Standalone learning loop

- [x] 3.1 Implement and test challenge state transitions: guided entry, two recall rounds, error retry, paste rejection, and skip.
- [ ] 3.2 Build reusable SwiftUI challenge views with keyboard, VoiceOver, and reduced-motion support; exercise manual practice without observation permission.
- [ ] 3.3 Implement versioned atomic local storage and test read/write, corrupted-file preservation, and deletion across restart.
- [ ] 3.4 Implement and test deterministic review scheduling including due success, error reset, fresh mistake, and abandonment.

## 4. Observation and spelling pipeline

- [ ] 4.1 Implement one-time permission onboarding, global enablement, optional per-app exclusions, menu bar states, and pause/resume.
- [ ] 4.2 Implement the proven AX observer with bounded reads, secure/unsupported exclusion, cleanup, and generation-based cancellation.
- [ ] 4.3 Implement the NSSpellChecker adapter, completed-token detection, developer-token filtering, explicit locale, and editable personal dictionary.
- [ ] 4.4 Test stale callbacks, duplicate suppression, bulk paste, unfinished composition, and absence of input text in persistence/logging.

## 5. Integrated interruption and return

- [ ] 5.1 Connect confirmed candidates to a single foreground challenge; suppress self-observation and competing detections.
- [ ] 5.2 Implement guarded targeted replacement for proven adapters and explicit copy fallback; test stale/read-only/permission-loss conditions and unchanged surrounding text.
- [ ] 5.3 Verify Skip/Escape, Pause, focus return, rapidly typed trailing characters, app switching, and non-leaking Enter handling in the primary target.
- [ ] 5.4 Complete an end-to-end primary-target exercise: type a typo, confirm correction, finish three rounds, safely correct or copy, and see the next review date.

## 6. Progress and release readiness

- [ ] 6.1 Add progress/word-list and due-review views with individual deletion and delete-all controls.
- [ ] 6.2 Run domain/storage checks and macOS builds; compile shared targets for an iOS simulator to verify boundaries without building an iOS app.
- [ ] 6.3 Re-run the compatibility matrix and accessibility interaction checks; measure detection latency and idle behavior without collecting input text.
- [ ] 6.4 Document direct-distribution signing/notarization steps and verify permission onboarding with a signed build when signing credentials are available; record release blockers explicitly.
- [ ] 6.5 Update setup/user docs with supported controls and best-effort limitations, validate OpenSpec, and archive the change only after its implementation acceptance criteria are met.

## Implementation evidence (2026-10-05)

- Specs initially committed as `0b5d5c8`; subsequent user clarification replaces per-app onboarding with global focused-input observation and optional exclusions.
- Tuist 4.184.1 generates the app project; the macOS menu bar shell builds with Xcode 27 / Swift 6.4. The pinned CLI deprecates `tuist build`, so documented builds use `tuist xcodebuild build`.
- Nine shared-logic tests pass; Core also builds for iOS Simulator. Shared UI and Storage targets are deferred until they contain implementation; foundation tasks stay open until those boundaries are delivered.
- Initial metadata probe reported permission-required. The user subsequently granted the packaged app Accessibility; native cross-process observation and replacement now pass. See docs/compatibility.md.
- User selected the horizontal letter-slot strip, anchored to the word itself. Implemented with an AppKit panel, shared SwiftUI tiles, and a native text input adapter.
- Native playground and separate-process AX fixture both complete the guided/recall/correction flow. The fixture independently confirms corrected text and focus return.
- Global monitoring, optional exclusions, approved vocabulary, and guarded targeted replacement are implemented as an experimental prototype. Third-party browser/T3 compatibility and composition tests remain open.
- Shared tests now include token filtering and screen placement. Shared UI builds for iOS Simulator. Per-word storage and scheduling remain unimplemented.

### Prototype handoff evidence

- Packaged app: `dist/Spellbound.app`, signed with an existing local Apple Development identity; not notarized.
- 13 Swift Testing tests pass. Shared SwiftUI/Core build for iOS Simulator passes.
- All 18 native smoke assertions pass, including caret/selection, long words, scroll dismissal, word tracking during window movement, three rounds, and exact correction/focus return.
- Separate native AX fixture confirms Accessibility trust, detection, word bounds, practice, targeted source replacement, and focus return. The user enabled Accessibility for this app.
- Finish review: all three material findings resolved. Full production tasks remain open for storage/reviews, untested app classes, composition, and accessibility verification.
