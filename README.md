# LeoClip

LeoClip is a small clipboard history tool for Mac OS X Leopard on PowerPC.

It is designed as a quiet, native menu bar utility that feels at home on Mac OS X 10.5.8. LeoClip is not a productivity platform, not a snippet manager, and not a clipboard database.

Design rule:

> Copy. Remember. Restore.

## Features

- remembers recent text clipboard entries
- restores clips from the menu bar
- supports Command-number restore shortcuts
- detects duplicate clips and moves them to the top
- can pause and resume Clipboard History
- shows a distinct paused status glyph
- keeps history in memory only
- uses localized menu strings

<p align="center">
  <img src="assets/images/leoclip-screenshot.png" alt="LeoClip status menu with clipboard history" width="520">
</p>

<p align="center">
  <em>LeoClip status menu with clipboard history on Mac OS X Leopard.</em>
</p>

## Privacy

LeoClip keeps clipboard history in memory only.

Quitting LeoClip clears the stored history. LeoClip does not write clipboard history to disk, does not sync clipboard contents, does not use the network, and does not send data anywhere.

This is intentional.

## Status Item

LeoClip uses compact Unicode status glyphs instead of image resources:

- normal: Clipboard History active
- paused: Clipboard History paused

This keeps the menu bar item small and avoids additional image assets.

## Localization

LeoClip includes localized menu strings for:

- English
- German
- French
- Italian
- Japanese
- Spanish
- Polish
- Swedish
- Russian
- Finnish
- Dutch

## Scope

LeoClip currently handles text clipboard history only.

This is intentional. The goal is a small, stable Leopard PowerPC clipboard-history utility before any additional clipboard types are considered.

Not included:

- snippets
- JavaScript actions
- updater framework
- login item management
- cloud sync
- persistent clipboard database
- preferences window

## Building

LeoClip builds with Xcode 3.1.4 on Mac OS X 10.5.8 Leopard PowerPC.

```sh
xcodebuild -project LeoClip.xcodeproj \
  -target LeoClip \
  -configuration Debug \
  -sdk macosx10.5 \
  ARCHS=ppc \
  ONLY_ACTIVE_ARCH=YES \
  build
````

The built app appears at:

```text
build/Debug/LeoClip.app
```

## Repository Layout

```text
Source/LeoClip/        active LeoClip source
*.lproj/               localized strings
docs/                  project notes
LeoClip.xcodeproj/     Xcode 3.1.4 project
Info.plist             application bundle metadata
```

## Internal Structure

LeoClip is intentionally small, but its code is split by responsibility:

    LCAppDelegate
      App lifecycle, status item, menu construction, timer orchestration.

    LCClipboardHistory
      In-memory clipboard history model, duplicate handling, history limit, clear behavior.

    LCPasteboardMonitor
      Leopard pasteboard bridge, changeCount tracking, text extraction, restore synchronization.

The app delegate orchestrates. The model and pasteboard bridge own their own logic.

## Cupertino-2009 UX

LeoClip follows native Leopard menu bar behavior where possible.

The status menu is intentionally small:

    About LeoClip
    -
    Clipboard history items
    -
    Pause or Resume Clipboard History
    Clear History
    -
    Quit LeoClip

About LeoClip is placed first as a separated item, matching classic Mac application-menu expectations.

The About window uses Cocoa's standard About panel instead of a custom window.

Clear History asks for confirmation before removing stored clips. The menu item does not use an ellipsis because the alert is a warning/confirmation step, not a request for additional information needed to complete the command.

LeoClip activates itself before showing About or Clear History dialogs, so those windows appear in front of other applications.

Clipboard history remains in memory only.

## History

LeoClip started as a ClipMenu source-tree exploration. The current repository contains a separate, minimal Leopard PowerPC implementation.

## License

MIT License.

