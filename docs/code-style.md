# LeoClip Code Style

LeoClip follows a small, native Mac OS X Leopard style.

The goal is not abstract portability or framework architecture. The goal is a small, readable, Cocoa-native utility that feels like it belongs on Mac OS X 10.5.

## Core Principles

- Use Cocoa and Foundation directly.
- Prefer small explicit classes over hidden magic.
- Split code by responsibility, not by arbitrary line count.
- Keep the app small enough that every file is understandable.
- Avoid feature growth unless it directly improves the core clipboard-history task.
- Keep clipboard history private and in memory only.

## Responsibility First

A class should have one clear reason to change.

Good examples:

```text
LCClipboardHistory
- stores clipboard entries
- removes duplicates
- enforces the history limit
- clears history
````

```text
LCAppDelegate
- starts the app
- owns the status item
- builds and updates the menu
- connects the pasteboard to the history model
```

A class is too broad when it mixes unrelated roles such as:

```text
UI construction
data rules
file persistence
network behavior
format parsing
release logic
```

## Size Guidelines

LeoClip does not use hard line-count limits.

Useful guidelines:

```text
0-150 lines
  Ideal for model and helper classes.

150-300 lines
  Acceptable for small controller classes.

300-450 lines
  Review carefully. The class may be doing too much.

450+ lines
  Usually too large for LeoClip.
```

Line count alone is not a design rule. Responsibility is.

## AppDelegate Rule

`LCAppDelegate` may orchestrate.

It should not become a storage class, parser, database, updater, sync layer, or generic application framework.

Acceptable:

```text
status item setup
menu item actions
pasteboard polling orchestration
application lifecycle
```

Prefer extraction when logic becomes independently testable.

Example:

```text
History rules belong in LCClipboardHistory.
```

## Naming

Use Cocoa-style descriptive names.

Prefer:

```objc
- (void)addHistoryItemsToMenu;
- (void)addControlItemsToMenu;
- (void)addString:(NSString *)string;
```

Avoid:

```objc
- (void)doMenu;
- (void)add;
- (void)process;
```

Method names should explain intent without comments.

## Constants

Do not leave magic numbers in code.

Use named constants for behavior and visual tuning:

```objc
static const NSUInteger LCMaxHistoryItems = 20;
static const NSUInteger LCMenuTitleLimit = 56;
static const NSTimeInterval LCPasteboardPollInterval = 0.5;
```

Constants document intent and make deliberate design choices visible.

## Comments

Prefer clear code over comments.

Use comments when explaining why something is done, especially when the choice is system-driven.

Good example:

```text
NSPasteboard has no simple Leopard-era notification hook for general clipboard changes.
Polling changeCount is intentional here.
```

Avoid comments that merely repeat the code.

## Localization

All user-visible strings must go through `NSLocalizedString`.

Do not hardcode menu labels in control logic unless they are internal test-only strings.

Localized resources should be proper `.lproj` resources and must be verified in the built app bundle.

## Privacy

Clipboard history must remain in memory only.

Release work must not introduce:

```text
disk persistence
sync
network behavior
telemetry
automatic upload
external updater behavior
```

Any future exception must be explicit, documented, and intentionally accepted.

## Testing

Prefer small tests for independently testable logic.

Current example:

```text
LCClipboardHistorySmoke
```

Do not rely on fragile menu bar UI scripting when Leopard accessibility does not expose the status item reliably.

Manual UI smoke testing remains acceptable for the visible status menu.

## Release Quality

A release is not complete because it builds.

A release must pass:

```sh
tools/release_check.sh
```

The release check verifies:

```text
Release build
history smoke test
localized resource bundling
DMG creation
DMG verification
SHA-256 generation
```

## Non-Goals

LeoClip should not become:

```text
a snippet manager
a sync tool
a clipboard database
a launcher
a scripting host
a cloud service
a general productivity framework
```

Small is a feature.  

