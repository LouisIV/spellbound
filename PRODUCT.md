# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

Current implementation is native macOS; a future iOS practice app is planned, not implemented.

## Stack

SwiftUI with AppKit for macOS integration. Tuist generates Xcode projects. Local Swift packages share domain logic and views.

## Users

A developer writing prompts into coding assistants who wants to stop repeating spelling mistakes.

## Product Purpose

Interrupt a completed misspelling with a short typing exercise and help the user learn the correct word.

## Operating Context

The user keeps working in the original app. The exercise floats above the misspelled word itself, tracks its screen position, and points to that word. It is not a separate practice window in the normal workflow. A playground is available to try the prototype without permissions.

## Capabilities and Constraints

One-time Accessibility setup and one global enable switch; no per-app onboarding. Optional exclusions. Local spelling checks and processing; no raw input persistence. Secure or unsupported controls are skipped. Shared learning and UI modules should remain reusable for iOS, while macOS Accessibility stays isolated.

The prototype handles confirmed spelling, one guided entry, two recall entries, skip, and guarded replacement or explicit copy. It does not promise universal input support, guaranteed Send blocking, or missing-word detection. Per-word history and spaced review remain planned.

## Brand Commitments

Name: Spellbound. The approved concept is the compact dark horizontal typing strip with letter slots and a mint accent. The user rejected separate-window mockups and explicitly required a pointer anchored to the word rather than the input field.

## Evidence on Hand

OpenSpec change macos-spelling-coach; approved concept docs/mockups/anchored-typing-strip.png, qualified by the later word-anchoring requirement. Implemented native views and smoke evidence are documented in docs/prototype.md and docs/compatibility.md.

## Product Principles

- Keep the interruption at the user's point of work.
- Practice retrieval, not only copying a correction.
- Follow focused text automatically after global enablement.
- Never edit a stale source or hide platform limitations.

## Accessibility & Inclusion

Native keyboard interaction, visible caret/selection, Escape to skip, readable text, hidden spelling cues during recall, and no required countdown. Manual VoiceOver and broader input-method validation remain pending.
