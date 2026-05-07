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
## Internal Architecture

LeoClip uses small Cocoa-style classes split by responsibility:

    LCAppDelegate
      Owns the application lifecycle, status item, menu, timer, and command actions.

    LCClipboardHistory
      Owns clipboard history data rules:
      - add text
      - remove duplicates
      - keep newest item first
      - enforce history limit
      - clear all clips

    LCPasteboardMonitor
      Owns the Leopard pasteboard bridge:
      - keep NSPasteboard reference
      - track changeCount
      - detect clipboard changes
      - read current text
      - write restored text back to the pasteboard
      - synchronize changeCount after restore

The timer remains in LCAppDelegate. The pasteboard monitor does not become a controller.

## Test Strategy

Automated checks:

    tools/smoke_test_history.sh
    tools/release_check.sh

The history smoke test verifies the core data behavior without fragile menu bar UI scripting.

The release check verifies:

    Release build
    history smoke test
    localized resource bundling
    DMG creation
    DMG verification
    SHA-256 generation

Manual UI smoke testing remains intentionally small:

    status item visible
    restore from menu
    Command-number restore
    pause/resume
    clear history
    quit

## Version 0.7.0 UX Scope

LeoClip 0.7.0 adds Mac-style polish without changing the core product scope.

Added behavior:

    About LeoClip
      First item in the status menu.
      Separated from the rest of the menu.
      Uses the standard Cocoa About panel.

    Clear History confirmation
      Clear History remains without an ellipsis.
      The confirmation alert explains that LeoClip's stored clips are removed.
      The current clipboard contents are not changed.
      Cancel leaves the history untouched.

    Frontmost dialogs
      LeoClip activates itself before opening About or Clear History dialogs.
      This avoids panels appearing behind other application windows.

Still out of scope:

    preferences window
    persistent history
    sync
    network features
    custom About window
    custom alert UI
    "do not ask again" setting
