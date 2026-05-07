# LeoClip Scope

LeoClip is a small native clipboard history tool for Mac OS X Leopard on PowerPC.

It is designed as a Finder-adjacent menu bar utility, not as a large clipboard management suite.

## Core Behavior

LeoClip watches the general pasteboard and remembers recent text entries in memory.

The user can restore a previous clip from the menu bar item. Restoring a clip writes it back to the clipboard; the user then pastes normally with Command-V.

## Current Behavior

- text clipboard history
- in-memory history only
- duplicate clips are moved to the top
- Command-number restore shortcuts
- pause and resume Clipboard History
- visible paused status glyph
- localized menu strings

## Privacy Model

Clipboard history is never written to disk.

When LeoClip quits, the stored history is lost. This is a deliberate privacy feature, not a missing persistence layer.

LeoClip has no network behavior, no sync behavior, and no external service integration.

## Visual Language

LeoClip should feel like a small utility Apple could plausibly have shipped for Mac OS X 10.5.

Rules:

- quiet menu bar presence
- monochrome system-style glyphs
- no alert colors for normal state changes
- no blinking
- no unnecessary windows
- no unnecessary preferences
- no heavy resources

## Explicit Non-Goals

LeoClip is not:

- a snippet manager
- a JavaScript action host
- a clipboard database
- a sync service
- a launcher
- a replacement for Finder or system pasteboard behavior

## Release Direction

A typical release should be a small DMG containing LeoClip.app, README, and LICENSE.

No updater framework is planned for the initial release line.

