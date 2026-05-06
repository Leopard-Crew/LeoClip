# LeoClip

LeoClip is a small clipboard history tool for Mac OS X Leopard on PowerPC.

It is based on the idea of ClipMenu, but the LeoClip target is intentionally kept small, native, and Leopard-focused.

## Current Features

- remembers recent text clipboard entries
- restores clips from a menu bar item
- supports Command-number restore shortcuts
- detects duplicate clips and moves them to the top
- can pause and resume Clipboard History
- shows a distinct paused status glyph
- keeps history in memory only

## Design Goals

LeoClip is a tool, not a platform.

It should feel like a small utility Apple could have shipped for Mac OS X 10.5:

- native Cocoa
- menu bar based
- quiet visual language
- no unnecessary preferences
- no snippets
- no JavaScript actions
- no updater framework
- no sync
- no cloud
- no database

Design rule:

> Copy. Remember. Restore.

## Status Item

LeoClip uses a compact Unicode status item instead of an image resource:

- normal: clipboard history active
- paused: clipboard history paused

This keeps the menu bar item small and avoids additional image assets.

## Building

LeoClip currently builds with Xcode 3.1.4 on Mac OS X 10.5.8 Leopard PowerPC.

```sh
xcodebuild -project ClipMenu.xcodeproj \
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

The original ClipMenu material remains in the repository as reference material.

The active LeoClip implementation lives in:

```text
Source/LeoClip/
Info-LeoClip.plist
```

The original ClipMenu target is not the primary development target.

## Scope

LeoClip currently handles text clipboard history only.

This is intentional. The first goal is a small, stable Leopard PowerPC clipboard-history utility before any additional clipboard types are considered.

## License

LeoClip started as a ClipMenu source-tree exploration. The original ClipMenu material remains in this repository as MIT-licensed reference material. The active LeoClip target is a small, separate Leopard PowerPC implementation. 

