# Global Hotkey — Design Spec

**Date:** 2026-04-14
**Status:** Approved

---

## Overview

Add a global keyboard shortcut `⌥Space` that opens and closes the Mnemosyne panel from any app, without requiring the user to click the menubar icon.

---

## Architecture

Single-file change: `Mnemosyne/AppDelegate.swift`.

A persistent `NSEvent` global monitor is registered once at app launch. It listens for `.keyDown` events system-wide. When it detects `⌥Space` (keyCode `49`, modifier flag `.optionKey`), it calls the existing `togglePanel()` method.

The monitor is stored as a property on `AppDelegate` and lives for the entire app lifetime — it is never removed.

---

## Data flow

```
User presses ⌥Space (any app)
    → NSEvent global monitor callback fires
    → keyCode == 49 && flags == .optionKey?
        → yes: togglePanel()
        → no: ignore
```

---

## Interaction with existing behaviour

- Menubar icon click continues to call `togglePanel()` unchanged.
- The hotkey is a second trigger for the same action — no new state.
- The click-outside event monitor (closes the panel on external click) is unaffected.

---

## Permissions

Requires Accessibility permission (`NSEvent.addGlobalMonitorForEvents` is gated on it). Mnemosyne already requests and holds this permission for the CGEvent paste feature.

---

## Files changed

| File | Change |
|---|---|
| `Mnemosyne/AppDelegate.swift` | Add `hotkeyMonitor` property, register global monitor in `applicationDidFinishLaunching` |

---

## Out of scope

- User-configurable shortcut (v2)
- Visual indicator when hotkey is pressed
- Conflict detection with other apps using `⌥Space`
