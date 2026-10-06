## Context

Spellbound began with only a README and an icon. Its initial user writes natural-language prompts while coding and wants a meaningful interruption after spelling mistakes. The hard part is reliable access to another application's text input, not drawing the game.

## Goals / Non-Goals

**Goals:** a useful macOS vertical slice, short active-recall practice, low false-positive rates in developer workflows, private local processing, and shared learning logic suitable for iOS.

**Non-goals for MVP:** grammar or missing-word detection, semantic correctness, arbitrary source-code checking, guaranteed prevention of Send/Return, a system-wide keyboard lock, cloud sync, multiple games, multilingual detection, an iOS app or keyboard extension. A correctly spelled but wrong word and an omitted word require context analysis beyond dictionary spelling.

## Decisions

### 1. Native app shells and one local Swift package

Proposed baseline: macOS 14+, future iOS 17+, Swift 6 language mode using a compatible installed Xcode toolchain. Confirm tooling in milestone 1. Use Tuist to generate the Xcode project/workspace and declare shared schemes in Swift manifests. Commit the manifests and pin the verified Tuist version in mise.toml; ignore generated .xcodeproj and .xcworkspace artifacts. Tuist is the chosen project and build workflow.

Planned layout (not created during planning):

```text
Tuist.swift                     # Tuist configuration
Project.swift                   # app targets, local package references, schemes
mise.toml                       # pinned Tuist version
Apps/
  SpellboundMac/                 # SwiftUI entry, menu bar, window lifecycle
Packages/
  SpellboundKit/
    Package.swift
    Sources/
      SpellboundCore/            # tokens, policy, challenge state, scheduling
      SpellboundStorage/         # versioned local records, repository adapter
      SpellboundUI/              # reusable SwiftUI practice/progress views
      SpellboundMacIntegration/  # AX, NSSpellChecker, focus, guarded edits
    Tests/
openspec/
docs/compatibility.md           # empirical results produced by milestone 1
```

The root Project.swift references the local SpellboundKit Swift package; Package.swift remains the source of truth for shared package targets. Do not duplicate those targets in Tuist manifests. Start with Tuist's generated workspace; add Workspace.swift only when multiple projects require explicit composition. The verified Tuist 4.184.1 workflow is tuist generate, tuist xcodebuild build with the SpellboundMac scheme, and package tests. The older tuist build command is deprecated in this version. Generation and builds must work locally without requiring a Tuist cloud account.

Core uses Foundation plus cross-platform CoreGraphics geometry; it never imports AppKit or ApplicationServices. UI and storage depend on Core. MacIntegration depends on Core and macOS frameworks; shared targets never import it. App shells assemble dependencies. Core interfaces include TextObservationSource, SpellingService, CorrectionApplier, LearningRepository, and Clock. Observation and correction can remain macOS-only consumers of those contracts. Prefer a small set of targets over a service per feature; a single mixed app target would make future reuse harder.

### 2. Accessibility first, with a feasibility gate

Use a single global enable switch after Accessibility onboarding. Follow the focused input automatically across non-excluded apps; the compatibility matrix is engineering evidence, not an onboarding allowlist. Optional app exclusions let users opt out specific contexts.

Use AXIsProcessTrustedWithOptions for the permission flow, frontmost application/focused element tracking, AXObserver notifications, and bounded text reads around the caret where available. Do not install a global keystroke recorder or use clipboard polling. A narrowly scoped, throttled fallback read for the current eligible element is acceptable only if the experiment proves it necessary and bounded.

Experiment in a native text editor, a browser textarea and contenteditable, and the actual coding-assistant prompt field available on the machine. Record app/OS versions, readable ranges, notifications, editable ranges, selection behavior, secure-field behavior, and focus restoration. Native editor support alone is insufficient to declare the intended workflow ready. If the target prompt is unsupported, document it and revisit an app-specific/browser integration in a separate proposal.

Observation does not synchronously intercept Send. A misspelling already submitted cannot be recalled. Bringing the game to the foreground interrupts subsequent typing best-effort; it is not an OS lock. A future strict send gate would need a separate feasibility experiment and explicit scope.

### 3. Process completed natural-language tokens locally

Pipeline: eligible focus → bounded snapshot → changed token at a completed boundary → token policy → NSSpellChecker adapter → deduplicated candidate → challenge coordinator. Check after whitespace or punctuation; a 300 ms debounce is a starting tuning value, not an SLA. Do not scan existing documents on focus, pasted paragraphs, or unfinished composition. Conservatively suspend when composition safety cannot be established for an input adapter.

Default language is English with an explicit locale setting. Skip URL/email/path tokens, digits, underscores, camelCase, fenced code where bounded context identifies it, and user-approved words. Plain lowercase identifiers can still resemble misspellings; provide Learn word and optional per-app exclusions. NSSpellChecker guesses are candidates, not calibrated probabilities: the user confirms the intended correction before practice. Do not silently choose a guess or train an uncertain candidate with no confirmed target.

Use a serial coordinator with session/generation IDs to discard stale checks when focus, text, permissions, or settings change. Keep one active challenge; discard competing observations while practicing. Suppress the same candidate for 60 seconds after dismissal, or until its source token changes, whichever happens first. Ignore the app's own edits to avoid recursive challenges.

### 4. A brief game with retrieval practice

**Approved presentation:** the horizontal letter-slot strip floats next to the misspelled word itself. Query bounds for that exact UTF-16 range, align a pointer to the word, track movement/reflow, clamp to the visible display, and flip below when needed. Dismiss when the source or word is no longer visible/valid. Missing word coordinates mean unsupported; never silently anchor to the whole input. The strip is an AppKit nonactivating panel hosting SwiftUI and a native text-input adapter. A separate playground is a testing/onboarding surface, not the real cross-app exercise.

**Prototype implementation:** bounded 350 ms polling, explicit global enablement, English/Latin token filtering, and experimental standard AX adapters. Actual cross-app compatibility remains gated by permission and empirical checks. Per-word history/scheduling are not claimed complete by this prototype.


Flow: candidate confirmation → one guided correct entry → two correct recall entries with the spelling hidden → completion → optional correction → return to work. The target appears for confirmation, then hides during recall. An incorrect submitted entry gets specific character feedback and repeats that round; it does not reset completed rounds. No countdown or speed score. Enter submits a round and cannot leak into the source app. Pasted answers do not advance rounds. VoiceOver gets appropriate cue/feedback announcements without reading the hidden target during recall.

Normal progression requires finishing the exercise. Escape/Skip and Pause remain available as escape routes and do not count as mastery. A menu bar status shows monitoring/paused/permission-required/unsupported; settings and the practice window remain accessible without observation permission.

### 5. Source corrections must be conditional

Capture only an ephemeral source reference: application/process, AX element identity, UTF-16 range, original token, and bounded context fingerprint. On completion, offer Replace and return only for proven adapters. Revalidate that the same editable field and token/context still exist, and that permission and exclusion status remain valid. If the user has switched to an unrelated app, offer a return action rather than stealing focus automatically. Use a supported selected-range edit, never overwrite the entire field or simulate blind backspaces. Preserve surrounding text and selection where the adapter supports it. On stale/read-only/unsupported state, show an explicit Copy correction action without writing to the clipboard automatically.

Replacement is separate from learning completion: failing to edit the source does not erase practice credit. If an adapter cannot provide adequately safe targeted editing, keep it observation-only.

### 6. Local learning records and review

Use a versioned Codable JSON store written atomically to Application Support through an actor, behind LearningRepository. This is adequate for a small vocabulary and avoids coupling Core to persistence frameworks. Reconsider SwiftData/SQLite only if scale or query requirements justify it.

Persist normalized confirmed target + locale, occurrence count, last practiced timestamp, correct/incorrect attempt totals, review stage, and next due date. Store approved vocabulary and app/settings preferences separately. Never persist original input snapshots, surrounding text, raw keystrokes, or source document identifiers; diagnostic logs exclude text. A candidate rejected as a false positive creates no learning record. User-approved words are intentional stored vocabulary.

Schedule first review one day after successful practice. Successful due reviews advance through 3, 7, 14, and 30 day intervals, then repeat at 30 days. Any incorrect submitted round resets the resulting interval to one day even if the session is ultimately completed. A fresh observed mistake resets that word's stage; abandoned sessions do not advance it. Inject Clock for deterministic tests. On corrupt storage, preserve the file and expose a recovery/reset action instead of silently deleting it. Support individual-word deletion and delete-all learning data.

### 7. Future iOS is a shared practice product first

The planned iOS shell reuses challenge state, scheduling, storage interfaces, and SwiftUI practice views; UIKit provides its own spelling adapter if needed. macOS Accessibility observation stays platform-specific. A later custom keyboard extension has separate lifecycle, limited surrounding context, and host restrictions, including exclusion from secure fields. It cannot deliver the macOS model of observing arbitrary other apps. Sync and App Groups remain future decisions; do not build unused iOS scaffolding now.

## Risks / Trade-offs

- AX support differs by app and control → publish an empirical compatibility matrix before production integration; skip unsupported controls visibly.
- Focus change can divert in-flight keystrokes → defer interruption until the completed-token check settles, test rapid typing, and retain an immediate escape route.
- Code vocabulary produces false positives → optional app exclusions, conservative filters, confirmed corrections, and personal dictionary.
- Secure or unknown field classification → fail closed before reading text; ignore password managers and secure controls, and clear transient buffers on ineligibility.
- Text can change between read and edit → revalidate immediately and offer copy whenever safety is uncertain; no claim of universal atomic edits.
- Rapid typing and submission can outrun observation → describe best-effort interruption plainly, measure latency, and do not advertise a guaranteed send gate.
- Cross-app access affects distribution options → start with direct macOS distribution; verify signing, permissions, and notarization in the release milestone.

## Migration Plan

No existing app data or users require migration. Land foundations, prove the observation adapter, then build a vertical slice before adding review history. Ship monitoring off until Accessibility onboarding and global enablement finish. Version the local store from its first release; test decode compatibility before schema changes. Roll back monitoring by disabling the adapter while retaining standalone practice and local data.

## Open Questions

Defaults below make implementation actionable and remain easy to revise:

- Which coding prompt field is the first must-support target? Discover installed options in the feasibility milestone and record a primary target before calling the slice complete.
- Is best-effort interruption enough, or is preventing Send essential? MVP uses best-effort; strict blocking would materially change scope.
- Proposed defaults: English, three correct entries per challenge, global monitoring with optional app exclusions, macOS 14 baseline, direct distribution.
- Visual styling and additional mini-games follow validation of the core learning loop.

## Sources

Platform facts inform the design; app compatibility remains unproven until milestone 1.

- [Apple Accessibility API](https://developer.apple.com/documentation/applicationservices/axuielement_h)
- [Apple NSSpellChecker](https://developer.apple.com/documentation/appkit/nsspellchecker)
- [Apple custom keyboard restrictions](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html)
- [Tuist generated Xcode projects](https://tuist.dev/en/docs/guides/get-started/generated-xcode-project)
- [OpenSpec workflow](https://github.com/Fission-AI/OpenSpec)
