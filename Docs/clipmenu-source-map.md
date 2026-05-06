# ClipMenu master source map for LeoClip

Source archive inspected: `ClipMenu-master.zip` (2014-10-20 snapshot, 223 archive entries).  
Target interpretation: Leopard-Crew `LeoClip`, Mac OS X 10.5.8 / PowerPC / Xcode 3.1.4, Cocoa-first, no universal/runtime ballast.

## Executive summary

ClipMenu is a strong LeoClip seed because the real clipboard engine is small and Leopard-native. The bulk of the project is not pasteboard logic; it is preferences UI, menu rendering, snippets, JavaScript actions, Sparkle updating, localization, and compatibility code for 10.6+.

The clean LeoClip path is not a direct build of the original Xcode project. The safer path is a new Xcode 3.1.4 project that imports a curated subset of the original sources from `vendor/ClipMenu`.

## Build/project findings

| Area | Finding | LeoClip action |
|---|---|---|
| Xcode project | `objectVersion = 46`, `compatibilityVersion = "Xcode 3.2"` | Prefer a new Xcode 3.1.4 project instead of opening/saving the original blindly. |
| SDK | `SDKROOT = macosx10.6` | Change to `macosx10.5` for LeoClip. |
| Architectures | `ARCHS = $(ARCHS_STANDARD_32_64_BIT)` | Replace with `ppc` for LeoClip V1. |
| Deployment target | `MACOSX_DEPLOYMENT_TARGET = 10.5` | Good. Keep. |
| Model tuning | `GCC_MODEL_TUNING = G5` | Good for the iMac G5 direction. Keep if Xcode 3.1.4 accepts it. |
| Info.plist | `LSMinimumSystemVersion = 10.5.0`, but per-arch entries include `ppc64`/`x86_64 = 10.6.0` | Remove 64-bit entries and rename bundle id/product. |
| External frameworks | References `Sparkle.framework`, `ShortcutRecorder.framework`, `BWToolkitFramework.framework`; not included in archive | Remove/defer; do not make V1 depend on them. |
| Localizations | English + Japanese in original archive; Xcode project still references Japanese variant files and a localization shell script | If Japanese files are removed, clean the project references and shell script too. |

## Main topology

| Layer | Files | Meaning | LeoClip disposition |
|---|---|---|---|
| App lifecycle | `main.m`, `AppController.*`, `Info.plist`, `English.lproj/MainMenu.xib` | Launch, defaults, hotkeys, update setup, menu actions | Keep only the launch/defaults/hotkey/menu subset. Remove Sparkle and action/snippet plumbing for V1. |
| Clipboard model | `Clip.*` | Stores one clipboard item: text, RTF/RTFD, PDF, filenames, URL, TIFF/PICT image | Keep, but simplify equality/hash and possibly defer PDF/PICT. |
| Clipboard controller | `ClipsController.*` | Polls `NSPasteboard` via `changeCount`, stores history, autosaves with `NSKeyedArchiver`, excludes apps | Highest-value core. Keep and trim. |
| Menus/status item | `MenuController.*`, `resource/StatusMenuIcons/*` | Status bar item, pop-up menus, history menu rendering, thumbnails/icons | Keep, but reduce to one menu path first. |
| Hotkeys | `Source/PTHotKeys/*` | Carbon Event Manager global hotkey implementation | Good candidate to keep bundled. Remove ShortcutRecorder dependency initially. |
| Preferences | `PrefsWindowController.*`, `DBPrefsWindowController/*`, `English.lproj/Preferences.xib` | Large preference UI, export, exclude list, hotkey editor | Defer/rebuild smaller. Original is large and dependency-heavy. |
| Snippets | `SnippetsController.*`, `SnippetEditorController.*`, `Snippets.xcdatamodel`, `FolderNode.*`, `IndexedArrayController.*` | Core Data snippet system and editor | Defer entirely for LeoClip 0.1. Good V0.3+ feature. |
| Actions | `ActionController.*`, `ActionFactory.*`, `ActionNode*`, `BuiltInActionController.*`, `JavaScriptSupport.*`, `ScriptableClip.*`, `resource/script/*` | Built-in and JavaScript transforms for clips/snippets | Defer/remove for V1. This pulls in WebKit and most complexity. |
| Utilities/extensions | `CMUtilities.*`, `CocoaExtensions/*`, `NaoAdditions/*` | Paste injection, folders, icons, login items, helper categories/cells | Keep only required subset. |
| Deployment/update | `Sparkle`, `resource/dsa_pub.pem`, `script/deploy.sh`, appcast scripts | Auto-update and release tooling | Remove for LeoClip V1. DMG/manual release later. |

## Core clipboard path

The essential flow is:

```text
NSPasteboard generalPasteboard
  -> changeCount polling in ClipsController::_updateClips:
  -> _makeClipFromPasteboard:
  -> Clip model
  -> NSMutableSet history
  -> MenuController updateStatusMenu
  -> user selects item
  -> ClipsController::copyClipToPasteboard:
  -> CMUtilities::paste posts Cmd-V
```

Key methods:

| Method | Role |
|---|---|
| `ClipsController::_startPasteboardObservingTimer` | Starts periodic pasteboard polling. |
| `ClipsController::_updateClips:` | Compares pasteboard `changeCount`, applies exclude list, creates a new `Clip`. |
| `ClipsController::_makeClipFromPasteboard:` | Reads supported pasteboard types into a `Clip`. |
| `ClipsController::copyClipToPasteboard:` | Writes a stored clip back to the general pasteboard. |
| `MenuController::createStatusItem` | Creates the menu bar item. |
| `MenuController::updateStatusMenu` | Rebuilds status menu after history changes. |
| `CMUtilities::paste` | Optionally synthesizes Cmd-V after restoring a clip. |

## Clipboard data types currently supported

From `Clip::availableTypes`:

| Pasteboard type | Stored as | V1 recommendation |
|---|---|---|
| `NSStringPboardType` | `NSString *stringValue` | Keep. Essential. |
| `NSRTFPboardType` | `NSData *RTFData` | Keep if easy; otherwise V0.2. |
| `NSRTFDPboardType` | `NSData *RTFData` | Defer; RTFD can be heavier. |
| `NSPDFPboardType` | `NSData *PDF` | Defer for V1. |
| `NSFilenamesPboardType` | `NSArray *filenames` | Keep or V0.2; very Mac-like. |
| `NSURLPboardType` | `NSArray *URL` | Keep or V0.2. |
| `NSTIFFPboardType` | `NSImage *image` | Keep only after text path is stable. |
| `NSPICTPboardType` | `NSImage *image` | Defer; legacy only. |

## Dependency triage

| Dependency | Where used | V1 decision |
|---|---|---|
| PTHotKey | `AppController`, `PrefsWindowController`, `Source/PTHotKeys` | Keep PTHotKeys as vendored source; it is small and Carbon-native. |
| Shortcut Recorder | `PrefsWindowController`, `Preferences.xib` | Remove/defer. Use fixed default hotkey first. |
| Sparkle | `AppController`, Info.plist, resources | Remove. Not needed for V1. |
| DBPrefsWindowController | Preferences window | Defer. Rebuild simpler preferences later. |
| Google Toolbox | Claimed in README; login-items code carries adapted Google license text | Avoid depending on GTM. Existing `NMLoginItems` can be audited or replaced. |
| BWToolkit | Xcode project/framework reference and likely XIB custom controls | Remove/defer by avoiding old Preferences.xib. |
| WebKit | JavaScript actions | Remove/defer with entire Actions layer. |
| CoreData | Snippets | Remove/defer with snippets. |
| Carbon | Hotkeys, front process/exclude list, paste event synthesis | Keep; this is valid Leopard-native glue. |

## Recommended LeoClip 0.1 import set

Minimal viable source import:

```text
Source/main.m
Source/AppController.h/.m            trimmed
Source/Clip.h/.m                     mostly kept
Source/ClipsController.h/.m          trimmed
Source/MenuController.h/.m           trimmed
Source/CMUtilities.h/.m              trimmed
Source/PTHotKeys/*                   kept
Source/constants.h                   trimmed/renamed
English.lproj/MainMenu.xib           or rebuild fresh in Xcode 3.1.4
resource/StatusMenuIcons/*           pick one icon set only
resource/ClipMenu3.icns              replace with LeoClip icon later
Info.plist                           rewrite for LeoClip
```

Do not import into V1:

```text
Source/Action*
Source/BuiltInActionController.*
Source/JavaScriptSupport.*
Source/ScriptableClip.*
Source/SnippetEditorController.*
Source/SnippetsController.*
Source/FolderNode.*
Source/IndexedArrayController.*
Source/DBPrefsWindowController/*
Source/CocoaExtensions/* except what MenuController still requires
Snippets.xcdatamodel
resource/script/*
resource/SnippetEditor/*
script/deploy.sh
script/generate_appcast.py
resource/dsa_pub.pem
Japanese.lproj/*
```

## First technical cuts

1. Create a fresh Xcode 3.1.4 Cocoa application project named `LeoClip`.
2. Set:

```text
SDKROOT = macosx10.5
MACOSX_DEPLOYMENT_TARGET = 10.5
ARCHS = ppc
PRODUCT_NAME = LeoClip
GCC_ENABLE_OBJC_EXCEPTIONS = YES
GCC_C_LANGUAGE_STANDARD = c99
```

3. Rename app identity:

```text
kApplicationName = @"LeoClip"
CFBundleIdentifier = org.quietcode.leoclip
CFBundleName = LeoClip
LSUIElement = 1
LSMinimumSystemVersion = 10.5.0
```

4. First running milestone:

```text
Status bar item appears.
Clipboard text changes are captured.
Menu shows last N text clips.
Selecting a clip restores it to the pasteboard.
Optional Cmd-V injection works.
No preferences window yet.
No snippets.
No actions.
No Sparkle.
No ShortcutRecorder.
No WebKit.
No CoreData.
```

## Red flags / watchlist

| Issue | Why it matters | Recommended handling |
|---|---|---|
| Original project is Xcode 3.2 + 10.6 SDK | Xcode 3.1.4/PPC may not open or build it cleanly | New project, curated imports. |
| `NSOpenPanel URLs`, `NSBundle bundleWithURL`, `URLByAppendingPathComponent`, `NSImage bestRepresentationForRect` | 10.6-era code paths or SDK declarations | Remove/defer affected UI paths or use 10.5 alternatives. |
| `NSMutableSet` for clips with hash-based equality | Hash collisions could falsely treat clips as equal | Good enough for old app, but LeoClip should eventually use stronger equality. |
| Autosave uses `NSThread detachNewThreadSelector` and archives whole history | Acceptable for small histories; can be simplified | Keep initially, later replace with explicit storage policy. |
| JavaScript actions pull in WebKit | Big feature blast radius | Remove from V1. |
| Snippets pull in Core Data + large editor UI | Useful, but not clipboard-core | V0.3+ only. |
| Japanese localization references in pbx + localization shell script | Removing files alone can leave broken references | Clean pbx or rebuild project. |

## Suggested phase plan

### Phase 0 — Archaeology commit

- Add `vendor/ClipMenu` unchanged.
- Add `docs/clipmenu-source-map.md`.
- Document license and third-party components.

### Phase 1 — Native LeoClip skeleton

- Fresh Xcode 3.1.4 project.
- Menu bar app with empty menu.
- LeoClip Info.plist, icon placeholder, LSUIElement.

### Phase 2 — Text clipboard history

- Import `Clip` and trimmed `ClipsController`.
- Store only `NSStringPboardType`.
- Show menu entries.
- Restore selected entry to pasteboard.

### Phase 3 — Hotkey and paste behavior

- Import `PTHotKeys`.
- Fixed default hotkey first.
- Optional Cmd-V injection via `CMUtilities::paste`.

### Phase 4 — Privacy basics

- `Pause Capture` menu item.
- `Clear History` menu item.
- Default excluded bundle IDs.
- No persistent storage by default, or explicit opt-in.

### Phase 5 — Preferences lite

- Small native preferences window.
- History size, polling interval, save history, excluded apps.
- Hotkey editor later; fixed hotkey first.

### Phase 6 — Rich types

- RTF, URLs, files, images.
- Snippets and actions remain optional modules, not core.
