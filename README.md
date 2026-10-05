<img src="assets/icon.svg" width="64" height="64" alt="">

# Spellbound

A planned macOS spelling coach that turns everyday typos into short typing exercises. Built around native SwiftUI app shells and shared Swift packages, with a future iOS practice app in mind.

## Project status

Planning only; no application code has been implemented.

The proposed MVP observes supported, explicitly enabled text inputs, checks completed words locally, opens a three-round spelling exercise, and schedules later reviews. Cross-app support and safe correction must pass an Accessibility feasibility gate first. Interruption is best-effort; preventing every submission and detecting missing words are outside this first version.

The planned build workflow uses **Tuist** with committed Swift manifests and a pinned version. Generated Xcode projects and workspaces will stay out of version control; reusable modules remain local Swift packages.

## OpenSpec plan

- [Proposal](openspec/changes/macos-spelling-coach/proposal.md)
- [Architecture, decisions, scope, and sources](openspec/changes/macos-spelling-coach/design.md)
- [Implementation checklist](openspec/changes/macos-spelling-coach/tasks.md)
- [Capability requirements](openspec/changes/macos-spelling-coach/specs/)

Validate the proposal with the installed OpenSpec CLI:

```sh
openspec validate macos-spelling-coach --strict --no-interactive
openspec status --change macos-spelling-coach
```

Next phase: prove text observation in the intended coding-assistant prompt, then implement the native app and shared learning loop.
