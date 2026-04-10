# Mnemosyne — Design Spec

**Date:** 2026-04-10
**Status:** Approved
**Minimum macOS:** 13.0 (required for `SMAppService` launch-at-login API)

---

## Overview

Mnemosyne is a macOS menubar clipboard manager. It monitors the system clipboard, stores a history of up to 200 text and image items, and lets the user paste any previous item — with optional trimming or plain-text stripping. Named after the Greek goddess of memory and mother of the Muses.

---

## Architecture

- **Single Xcode target:** `MnemosyneApp` (no XPC, no separate packages)
- **No Dock icon:** `LSUIElement = YES` in Info.plist — pure background app
- **Menubar entry point:** `NSStatusItem` with a `doc.on.clipboard` SF Symbol icon
- **UI:** SwiftUI popover attached to the status item
- **Clipboard monitoring:** `ClipboardMonitor` — a repeating `Timer` (0.5s interval) that compares `NSPasteboard.general.changeCount`
- **History management:** `HistoryStore` — in-memory array, max 200 items, persisted to JSON on disk
- **Settings:** `UserDefaults`

### Data flow

```
NSPasteboard → ClipboardMonitor → HistoryStore → SwiftUI MenubarView
                                                        ↓
                                               User selects item
                                                        ↓
                                            Write to NSPasteboard → CGEvent ⌘V paste
```

---

## Data Model

```swift
struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let content: Content

    enum Content {
        case text(String)
        case image(Data)  // PNG data, Base64-encoded in JSON
    }
}
```

- **Deduplication:** New item identical to the most recent item is not added
- **Cap:** When 200 items are reached, the oldest is dropped
- **Persistence file:** `~/Library/Application Support/Mnemosyne/history.json`
  - Written async on every new item
  - Read once at app launch
- **Settings in UserDefaults:**
  - `maxHistorySize` (default: 200)
  - `launchAtLogin` (default: false) — implemented via `SMAppService.mainApp` (macOS 13+)

---

## UI

### Popover layout

```
┌─────────────────────────────┐
│ Mnemosyne          [⚙] [✕] │
├─────────────────────────────┤
│ [Trim spaces] [Plain text]  │  ← actions for current clipboard item
├─────────────────────────────┤
│ 🔍 Search...                │
├─────────────────────────────┤
│ 📝 "Hello world..."    10:41│
│ 📸 Screenshot          10:39│
│ 📝 "git commit -m..."  10:35│
│ ...                         │
└─────────────────────────────┘
```

### Paste modes

| Interaction | Behavior |
|---|---|
| Click | Paste as-is (original formatting preserved) |
| ⌥ + Click | Paste as plain text (strips all formatting) |
| ⇧ + Click | Paste trimmed (strips leading/trailing whitespace) |

### Images

- Shown as 40×40pt thumbnail with timestamp
- Click pastes the image as-is
- No plain-text or trim mode for images

### Search

- Live filter on text content of items
- Images always visible, filtered only by timestamp label

### Settings panel (⚙ button)

- Max history size (slider or stepper)
- Launch at login toggle
- Clear history button

---

## Clipboard Monitoring

- Timer fires every 0.5s, reads `NSPasteboard.general.changeCount`
- On change: read text first (`NSPasteboard.string(forType: .string)`), then image (`NSPasteboard.data(forType: .tiff)` → convert to PNG)
- If neither text nor image: ignore the change (e.g. file copy — out of scope for v1)

---

## Paste Implementation

1. Write selected item's content to `NSPasteboard.general`
2. Close the popover
3. Post `CGEvent` key down + key up for `⌘V` targeting the frontmost app

**Plain text stripping:** `NSAttributedString(data:options:documentAttributes:)` → `.string` property → write as `.string` pasteboard type only.

**Trim:** `.trimmingCharacters(in: .whitespacesAndNewlines)` applied before writing.

---

## Permissions

- **Accessibility** (`AXIsProcessTrusted()`) required to send `CGEvent` for paste
- On first launch, if not granted: show a one-time alert directing user to System Settings → Privacy & Security → Accessibility
- App functions for browsing history without the permission; only auto-paste is blocked

---

## Out of Scope (v1)

- File/folder clipboard entries
- Cloud sync
- Encryption of stored history
- XPC service architecture
- iOS/iPadOS companion
