---
name: Spellbound
description: A compact native spelling exercise at the word being written.
colors:
  strip-surface: "rgb(11.5%, 13%, 15%)"
  strip-border: "rgba(255, 255, 255, 0.16)"
  slot-surface: "rgba(255, 255, 255, 0.06)"
  slot-border: "rgba(255, 255, 255, 0.13)"
  guided-cue: "rgba(255, 255, 255, 0.5)"
  strip-message: "rgba(255, 255, 255, 0.7)"
  action-ink: "rgba(0, 0, 0, 0.88)"
typography:
  strip-instruction:
    fontFamily: "system-ui"
    fontSize: "14pt"
  strip-label:
    fontFamily: "system-ui"
    fontSize: "12pt"
    fontWeight: 500
  strip-action:
    fontFamily: "system-ui"
    fontSize: "12pt"
    fontWeight: 600
  strip-message:
    fontFamily: "system-ui"
    fontSize: "11pt"
  word:
    fontFamily: "ui-rounded"
    fontSize: "24pt"
    fontWeight: 500
rounded:
  strip: "13pt"
  action: "7pt"
  slot: "6pt"
spacing:
  strip-horizontal: "20pt"
  strip-vertical: "16pt"
  strip-rows: "14pt"
  exercise-gap: "12pt"
  slot-gap: "5pt"
  long-slot-gap: "3pt"
components:
  typing-strip:
    backgroundColor: "{colors.strip-surface}"
    rounded: "{rounded.strip}"
    padding: "16pt 20pt"
    height: "178pt"
  letter-slot:
    backgroundColor: "{colors.slot-surface}"
    rounded: "{rounded.slot}"
    height: "40pt"
  strip-action:
    textColor: "{colors.action-ink}"
    typography: "{typography.strip-action}"
    rounded: "{rounded.action}"
    padding: "0 14pt"
    height: "38pt"
---

# Design System: Spellbound

## Overview

**Creative North Star: "Practice at the word"**

The approved visual direction is a compact dark horizontal strip with letter slots and a mint accent. It floats at the misspelled word while the original writing context remains visible. The name above describes that existing direction; it does not introduce a new brand metaphor.

**Key Characteristics:**
- Compact horizontal practice, with a pointer to the word.
- Rounded native type, restrained dark surfaces, and mint interaction cues.
- Native setup and playground windows supporting the floating exercise.

This records the implemented macOS prototype. Source authority is `TypingStrip.swift`, `LetterTiles.swift`, `HomeView.swift`, and `PlaygroundController.swift`; screenshots are in `.build/smoke-final/`. Native flow checks (18) and a separate native Accessibility fixture passed. Browser/T3 compatibility and manual VoiceOver remain unverified. There is no implemented iOS visual system.

## Colors

### Primary

**System mint** (`Color.mint`) marks primary actions, entered letters, active slot outlines, selection, the proposed/correct word, and completion. Preserve the native semantic color rather than freezing a sampled screenshot color into an application token. Selection uses mint at 20% opacity; pressed primary actions use 70% opacity.

### Secondary

**System orange** (`Color.orange`) marks incorrect submitted letters and their corrective message. Do not flag each keystroke as an error before submission.

### Neutral

The frontmatter records the strip's actual fixed surface, border, cue, and message colors. Home and playground use native window backgrounds and semantic primary/secondary labels, following system appearance; only the exercise strip forces dark appearance.

## Typography

Use native system type. Strip metadata and controls remain small and quiet; the instruction is the central header, with the target word bold during guided practice. Progress uses monospaced digits. Proposed and completed words use medium rounded type; tile glyphs use the same rounded character at `min(23, slotWidth × 0.72)` points.

Home uses native title2 semibold, headline, body, and caption roles. The playground uses a semibold heading (25pt), explanatory text (14pt), editor text (20pt), and footer (12pt). These are existing surface roles, not a new global type scale.

## Layout

**The Word Anchor Rule.** Point to the misspelled word's bounds, never the enclosing input field. Keep surrounding text visible and dismiss when valid visible word bounds are lost.

The strip has three rows: identity/instruction/progress; practice or confirmation/action; feedback/secondary actions. Its body is 178pt tall, plus a 10pt pointer. Preferred width is `max(570, target.count × 30 + 160)` points, capped by the screen's visible width with edge margins. Position above the word when space permits and below otherwise; the pointer follows the word when the panel is clamped.

Tiles occupy a 44pt row. Their width fits the available space, clamped between 10pt and 31pt. The gap tightens from 5pt to 3pt beyond 14 slots; glyphs shrink with slot width. Use the larger of target and answer length for slot count, preserving excess typed characters for feedback. Native practice entry caps answers at 24 characters.

Home is 600 × 490pt with 30pt padding and 24pt major section gaps. The playground starts at 820 × 600pt, resizes down to 650 × 440pt, and uses 32pt horizontal margins. Its deliberately generous space above the editor accommodates the anchored strip.

## Elevation & Depth

The strip is a transparent, borderless floating `NSPanel` with the platform shadow enabled. Its opaque charcoal body, subtle white outline, and matching triangular pointer distinguish it from the source app. Keep native shadow rendering; there is no custom shadow scale, blur material, or authored motion system.

## Shapes

Use the recorded rounded strip, action, and slot shapes. The pointer is a solid triangle (18 × 10pt) matching the body. Inactive slot outlines are 1pt; current and selected outlines are 1.5pt mint. The terminal caret is a mint bar (2 × 24pt) after the final slot. Home and playground keep native control shapes.

## Components

- **Typing strip:** confirmation offers a correction menu and “Practice this word”; guided entry exposes the cue once; two recall entries hide target cues; completion offers “Replace & return” and “Copy & return.” Preserve the compact row structure across states.
- **Letter slots:** entered characters are mint; guided unentered characters are muted; recall slots show no target letters. Selected slots have mint fill and outlines. Current position uses the slot outline or terminal caret, synchronized with the native text selection.
- **Primary action:** mint background, dark semibold label, and reduced mint opacity while pressed. Return activates the current action. Close and Skip are quiet plain controls; Escape skips.
- **Feedback and overflow:** footer text can wrap to two lines; orange feedback explains submitted errors. The plain ellipsis menu exposes monitoring, app exclusion when available, and home navigation.
- **Home:** native sections separated by dividers, a prominent mint playground action, monitoring switch, permission status, and preferences. It is a support surface, not the normal exercise destination.
- **Playground:** native resizable text editor, visible instructional heading, and understated privacy/keyboard footer. It preserves ordinary editing context around the exercise.

**The Recall Rule.** Hide the target in both visible cues and accessibility labels during recall. Keep the editable input accessible and preserve native keyboard selection even though the slot layer draws its visual state.

## Do's and Don'ts

### Do:
- Do anchor the pointer to the word and preserve the user's surrounding writing context.
- Do keep visible caret and selection synchronized with native editing.
- Do adapt tile widths and glyph sizes to long words within the available screen.
- Do use native semantic mint, orange, and supporting-window colors.

### Don't:
- Don't replace the normal anchored exercise with a separate practice window.
- Don't attach the pointer to the whole input box.
- Don't expose target spelling during recall, including to assistive technology.
- Don't present unverified browser or VoiceOver behavior as established support.
