# Practice-screen concepts

Status: the original separate-window concepts below were rejected. The confirmed placement is a small floating overlay immediately above the user’s active input, with the host app visible. The user selected the horizontal typing strip, with a further requirement that its pointer anchor directly to the misspelled word rather than the input box. These are generated visual concepts, not screenshots of running software.

## Current anchored concepts

- [Compact correction popover](anchored-popover.png): word comparison and a small practice field above the host input.
- [Horizontal typing strip](anchored-typing-strip.png): letter slots and keyboard-first practice immediately above the host input.
- [Exact generation prompts](anchored-prompts.md)

Generated using the built-in image-generation tool. The surrounding coding app is illustrative. Anchoring, focus transfer, and screen-edge behavior still require implementation and verification.

## Superseded separate-window concepts

- [Quiet native panel](quiet-native.png): white surface, blue action, restrained native typography.
- [Playful letter tiles](playful-tiles.png): warm surface, coral action, tactile spelling tiles.

Both show the same guided first round for “necessary”, followed by two recall rounds. Skip and Pause remain available. The product follows focused text inputs globally after one-time Accessibility setup and global enablement; no per-app setup is implied by either concept.

Generated with the built-in image-generation tool on 2026-10-05. Prompts specified a front-on macOS floating window titled Spellbound, traffic lights, “Make this one stick.”, “Type the correct spelling, then recall it twice.”, the typo “neccessary” and target “necessary”, focused entry “nece”, Check spelling, Skip for now, Pause Spellbound, and “1 of 3 · Guided”. No scores, countdown, app list, or sidebar. The first prompt requested quiet native styling; the second requested warm letter tiles with coral and green accents.

Visual details are proposals rather than additional requirements. The mockups' small secondary text and focus colors will need native accessibility verification when a direction is implemented.
