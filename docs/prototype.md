# Using the Spellbound prototype

## Open it

Open `/Applications/Spellbound.app` (the installed copy), or the matching `dist/Spellbound.app`. The prototype lives in the menu bar; its first window explains setup.

### Try the complete exercise immediately

1. Click **Open typing playground**.
2. Type `This is neccessary `, including the final space.
3. A floating strip points directly to **neccessary**. Confirm **necessary** with Return (or choose another suggestion).
4. Type `necessary` and press Return. Repeat twice from memory.
5. Press **Replace & return**. Only the misspelled word changes, and typing focus returns to the playground.

The strip follows the word when the window moves or text reflows. It flips below the word when there is insufficient room above. If the word leaves the visible editor viewport, the strip dismisses.

Escape skips. “Learn word” suppresses that spelling in future. Paste does not count as typing practice. Arrow keys, Backspace, Select All, and clicking the letter slots edit the answer; the tiles show the insertion position and selection.

### Use it in other apps (experimental)

1. Click **Allow Accessibility access…** in Spellbound.
2. In macOS Settings → Privacy & Security → Accessibility, enable **Spellbound**. If it is absent, add `/Applications/Spellbound.app` with the + button.
3. Return to Spellbound and enable the switch under **Use it in other apps**.
4. Type a new misspelling followed by a space in a supported input. The app follows focused inputs globally; no app-specific onboarding is required.

The menu bar lets you pause or reopen the app. During an exercise, the ellipsis menu can exclude the source application. Preferences can clear exclusions and learned vocabulary. Monitoring starts paused on first launch and remembers subsequent changes to the global enable switch.

The prototype requires bounded Accessibility text ranges and exact word geometry, using text markers when rich editors return unusable range bounds. Browser/Electron/custom editors may expose only some of these APIs. It never substitutes the whole input rectangle for missing word coordinates. T3 Code's prompt now supports detection and the practice strip; use **Copy & return** after practice because its targeted text setter does not apply the correction in the tested version.

**Cross-app support is experimental, not universally verified.** If targeted replacement is unavailable or source validation fails, use the explicit **Copy & return** action. The app never blindly overwrites an entire text input, simulates backspaces, or automatically changes the clipboard.

## Current scope

Implemented: a word-anchored typing strip, guided/recall rounds, skip, paste rejection, retry feedback, local spelling suggestions, a native playground, experimental focused-input monitoring, optional exclusions, approved vocabulary, a local count of completed exercises, and guarded correction/copy handoff.

Not included yet: per-word history, spaced review, iOS app, guaranteed Send blocking, grammar/missing-word detection, multilingual composition support, or distribution/notarization. The prototype is a locally signed development build.

## Privacy and detection limits

- No network service, global keystroke recorder, clipboard polling, or raw-text logging.
- Only a bounded span near the caret is read in the eligible focused control. Context used for source validation is retained in memory only while needed.
- Secure controls, unknown roles, known password-manager apps, excluded apps, and Spellbound's own windows are not observed by the global monitor.
- Completed English/Latin words only. Identifiers, paths, URLs, and bulk changes are filtered conservatively.
- External observation uses a 350 ms focused-control poll in this prototype. Small pasted edits cannot always be distinguished from typing through these AX APIs; the playground explicitly suppresses paste-triggered detection. Complex input-method composition remains unverified; leave monitoring paused in those workflows.
- Existing text is not scanned on focus. Only small append edits with increased document length qualify, reducing interruptions from caret navigation or large pastes.
- Learning data currently consists of explicitly approved words, app exclusions, and an exercise count in local preferences. No source drafts are persisted.

## Rebuild

With Tuist 4.184.1 and the documented Xcode toolchain:

```sh
./scripts/build-prototype.sh
open dist/Spellbound.app
```

Quit a running Spellbound before the packaging step. Set `SPELLBOUND_SIGN_IDENTITY` to an available development signing identity to keep a consistent signing identity across rebuilds. The default is local ad-hoc signing; changing signing identity or moving the app may require re-enabling Accessibility. Do not move it after granting access unless necessary.

## Verification

Core tests: `swift test --package-path Packages/SpellboundKit --scratch-path .build/package-tests`.

A Debug-only native smoke runner operates exclusively on synthetic text in Spellbound's own playground. Launch the app with `--smoke-output /absolute/writable/output-directory`. It checks the real text view, overlay, typing rounds, pasted input rejection, window-move tracking, caret/selection, targeted replacement, focus return, and scrolling. It saves native view renders and a JSON result file. It does not certify third-party app compatibility or grant system permissions.

## Local installation

On 2026-10-05, a universal arm64/x86_64 Release build was signed with the existing local Apple Development identity and installed at `/Applications/Spellbound.app`. The installed signature and bundled icon were verified, and the installed copy was launched with monitoring requested. This is a local development-signed build, not a notarized distribution release.

The app uses the mint “s” typing-key icon. The alternate and generation prompts are in `assets/icons/`. Run `scripts/generate-app-icon.sh` to rebuild the standard macOS icon family.
