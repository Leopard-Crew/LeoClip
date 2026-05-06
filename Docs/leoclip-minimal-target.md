# LeoClip Minimal Target

LeoClip is a small Leopard PowerPC clipboard history tool.

The original ClipMenu target remains in the repository as reference material.
The new LeoClip target is intentionally minimal:

- no preferences window
- no snippets
- no JavaScript actions
- no Sparkle updater
- no ShortcutRecorder
- no login item handling
- no external helper frameworks

Current target:

- Cocoa menu bar application
- LSUIElement background app
- in-memory text clipboard history
- manual restore to pasteboard
- clear history
- quit

Design rule:

Copy. Remember. Restore.
Nothing else.
