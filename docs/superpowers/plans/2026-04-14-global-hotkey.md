# Global Hotkey Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a global `⌥Space` keyboard shortcut that opens and closes the Mnemosyne panel from any app.

**Architecture:** A persistent `NSEvent` global monitor is registered at app launch in `AppDelegate`. It filters for keyCode `49` (Space) with `.optionKey` modifier and calls the existing `togglePanel()`. No new files needed.

**Tech Stack:** Swift, AppKit (`NSEvent.addGlobalMonitorForEvents`)

---

## File Map

| File | Change |
|---|---|
| `Mnemosyne/AppDelegate.swift` | Add `hotkeyMonitor: Any?` property, register global key monitor in `applicationDidFinishLaunching` |

---

## Task 1: Register global ⌥Space hotkey in AppDelegate

**Files:**
- Modify: `Mnemosyne/Mnemosyne/AppDelegate.swift`

- [ ] **Step 1: Add the `hotkeyMonitor` property**

  In `AppDelegate`, add a property to hold the monitor reference alongside the existing `eventMonitor`:

  ```swift
  private var hotkeyMonitor: Any?
  ```

  Full property list after change:
  ```swift
  private var statusItem: NSStatusItem!
  private var panel: NSPanel!
  let store = HistoryStore()
  private var monitor: ClipboardMonitor!
  private var eventMonitor: Any?
  private var hotkeyMonitor: Any?
  ```

- [ ] **Step 2: Register the global key monitor at the end of `applicationDidFinishLaunching`**

  Add these lines at the end of `applicationDidFinishLaunching`, after the panel setup:

  ```swift
  // Global ⌥Space hotkey — opens/closes the panel from any app
  hotkeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
      // keyCode 49 = Space, optionKey = ⌥
      guard event.keyCode == 49,
            event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .optionKey
      else { return }
      DispatchQueue.main.async {
          self?.togglePanel()
      }
  }
  ```

- [ ] **Step 3: Build — verify no compile errors**

  In Xcode press `⌘B`.
  Expected: Build Succeeded, no errors.

- [ ] **Step 4: Run and test manually**

  Press `⌘R`. Then:
  1. Click into any other app (e.g. Notes, Safari)
  2. Press `⌥Space`
  3. Expected: Mnemosyne panel opens without stealing focus from the other app
  4. Press `⌥Space` again
  5. Expected: panel closes
  6. Click the menubar icon
  7. Expected: panel still opens/closes as before

- [ ] **Step 5: Commit**

  ```bash
  git add Mnemosyne/Mnemosyne/AppDelegate.swift
  git commit -m "feat: add global ⌥Space hotkey to toggle panel"
  ```

---

## Self-Review

**Spec coverage:**

| Spec requirement | Covered |
|---|---|
| `⌥Space` opens/closes panel | Task 1 Step 2 |
| Menubar click still works | Not changed — existing code untouched |
| Requires Accessibility permission | Already granted — no change needed |
| Monitor lives for app lifetime | `hotkeyMonitor` stored as property, never removed |

No gaps found. No placeholders. Single task, single commit.
