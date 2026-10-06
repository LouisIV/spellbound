# Accessibility feasibility

Status: **working native-control prototype; third-party app matrix still open**.

One-time Accessibility setup plus a global enable switch is the product model. The app follows supported focused inputs across apps. This matrix measures compatibility; users do not onboard each app.

## Verified 2026-10-05

Environment: macOS 27.0.1 (26A434), Xcode 27.0 (27A266a), Swift 6.4, Tuist 4.184.1. The user granted Accessibility to the signed `dist/Spellbound.app`.

A separate process, `SpellboundFixture.app` (`dev.spellbound.fixture`), exposes a standard NSTextView and types only disposable synthetic text. The running Spellbound app then observes it through the same AX adapter used for other apps.

Cross-app checks passed:

- Accessibility trust available to the packaged app.
- Bounded focused-text observation detected `neccessary` after a word boundary.
- NSSpellChecker suggested `necessary`.
- Exact-range AX word bounds produced the floating exercise.
- Three practice rounds completed.
- AX selected-range/selected-text replacement was accepted.
- The independent source fixture confirmed its entire resulting text was exactly `This is necessary ` and focus returned to its editor.

Local evidence (generated, ignored): `.build/external-smoke/external-results.json`, `fixture-results.json`, and `external-strip.png`. No source text from user applications was persisted in these checks.

| Control | Observation / word bounds | Exercise / replacement | Remaining checks |
| --- | --- | --- | --- |
| Separate native NSTextView fixture | Passed via actual cross-process AX calls | Passed; fixture independently confirmed text and focus | Long-running behavior, revocation during edits |
| Spellbound playground | Passed via native editor adapter | Passed | Manual VoiceOver and multiple physical displays |
| TextEdit | Not yet tested | Not yet tested | Full flow |
| Browser textarea / contenteditable | Not yet tested | Not yet tested | App/control-specific AX support |
| T3 Code 0.0.45, `com.t3tools.t3code` | Passed actual detection and text-marker word geometry | Stable strip, focused practice field, and three rounds passed; selected-text replacement reports success without applying the correction, so use explicit Copy | Broader rich-editor cases |
| Secure / unknown control | Eligibility policy unit-tested | Never permitted | Actual secure-app/manual verification |

The playground's native smoke runner also verifies window-move anchoring, error retry, pasted-answer rejection, and original-input focus return. Shared placement tests cover display-edge clamping and placing below a word on a secondary display coordinate system.

## Limitations

Following a report that T3's prompt did not trigger practice, diagnostics confirmed Accessibility trust and the prompt's advertised AX capabilities. Monitoring now persists across launches, and observation checks all newly completed words even when typing has continued into the next word between polls. Three regression tests cover continued typing, new boundaries only, and UTF-16 offsets. The adapter also requests Electron's accessibility tree when first encountering an application.

T3 advertises `AXBoundsForRange` but returns an unusable rectangle. The adapter falls back to a bounded walk backward from the selected text marker, measures UTF-16 distances, verifies the exact word, and requests `AXBoundsForTextMarkerRange`. It retains those markers through the nonactivating panel's focus handoff, checking the original source window and bounded context. This fixed the user-observed flashing strip. An explicit debug-only smoke runner then verified detection, a stable strip, actual practice-field input through all three rounds, and the Copy fallback in the actual T3 prompt (`.build/t3-smoke-final/results.json`). The disposable sample was cleared. It never sends messages and refuses existing drafts. Synthetic key events are confined to this developer test; the production adapter does not inject keystrokes.

Practice-field focus is acquired after SwiftUI attaches the native text view to the panel, as well as when a new exercise round starts. Final native cross-process regression results (`.build/external-regression3`) confirm actual field focus, three completed rounds, targeted replacement, and original editor focus. The native playground's 18 checks and the shared package's 16 tests also passed.

Correction restores source focus, revalidates the selected range and bounded context, and checks the resulting text after the targeted edit. T3's selected-text setter returned success without the expected change; the app now keeps the explicit Copy fallback rather than claiming replacement succeeded. Other rich editors still require empirical testing.

Opt-in launch diagnostics (`--diagnostic-status PATH` and `--diagnose-output PATH`) record monitoring state, presentation counts, source bundle identifier, and AX capability metadata only. They do not persist input text or practice words. The latter diagnostic activates T3 Code to inspect its focused control.

The current adapter uses bounded 350 ms polling, not AXObserver notifications. It requires character count, selected range, bounded string retrieval, and exact word bounds; unknown or missing capabilities fail closed. Input text is never read through a whole-value fallback. The actual adapter can advertise support in inputs that implement these APIs, but only the controls listed as passed above are empirically verified.

Small pasted edits may resemble typing. IME/composition behavior in external apps is not verified. Input methods beyond completed English/Latin tokens are outside this prototype's tested scope. Source replacement remains conditional on focus, unchanged bounded context, range, permission, and app exclusion state.

Do not generalize one successful NSTextView fixture to every browser, editor, password control, or third-party application.
