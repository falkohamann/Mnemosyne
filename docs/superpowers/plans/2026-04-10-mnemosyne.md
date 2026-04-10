# Mnemosyne Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS menubar clipboard manager that stores 200 items (text + images), supports paste-as-is / plain-text / trimmed modes, and persists history across restarts.

**Architecture:** Single Xcode target `MnemosyneApp`, LSUIElement background app (no Dock icon), NSStatusItem menubar icon opening a SwiftUI popover. ClipboardMonitor polls NSPasteboard every 0.5s. HistoryStore manages the in-memory capped array and delegates JSON persistence to PersistenceManager. PasteService writes to NSPasteboard and fires a CGEvent ⌘V.

**Tech Stack:** Swift 5.9+, SwiftUI, AppKit (NSStatusItem, NSPasteboard, CGEvent), SMAppService (launch at login), XCTest, macOS 13.0+

---

## File Map

| File | Responsibility |
|---|---|
| `Mnemosyne/MnemosyneApp.swift` | `@main` App entry, creates AppDelegate |
| `Mnemosyne/AppDelegate.swift` | NSApplicationDelegate, owns NSStatusItem, ClipboardMonitor, HistoryStore |
| `Mnemosyne/Models/ClipboardItem.swift` | `ClipboardItem` struct + `Content` enum |
| `Mnemosyne/Store/HistoryStore.swift` | Observable store: add, deduplicate, cap at 200, expose filtered list |
| `Mnemosyne/Store/PersistenceManager.swift` | JSON read/write to `~/Library/Application Support/Mnemosyne/history.json` |
| `Mnemosyne/Clipboard/ClipboardMonitor.swift` | 0.5s Timer, changeCount diff, calls HistoryStore.add |
| `Mnemosyne/Clipboard/PasteService.swift` | NSPasteboard write + CGEvent ⌘V, plain-text strip, trim, accessibility check |
| `Mnemosyne/UI/MenubarView.swift` | Root popover: header, action bar, search field, scrollable history list |
| `Mnemosyne/UI/ClipboardItemRow.swift` | Single row view: text preview (truncated) or image thumbnail (40×40pt) |
| `Mnemosyne/UI/SettingsView.swift` | maxHistorySize stepper, launchAtLogin toggle, clear history button |
| `Mnemosyne/Info.plist` | `LSUIElement = YES`, bundle metadata |
| `MnemosyneTests/ClipboardItemTests.swift` | Codable round-trip, equality helpers |
| `MnemosyneTests/HistoryStoreTests.swift` | add, dedup, cap, search filter |
| `MnemosyneTests/PersistenceManagerTests.swift` | save/load round-trip, empty-file handling |
| `MnemosyneTests/PasteServiceTests.swift` | trim, plain-text strip (logic only, no CGEvent in tests) |

---

## Task 1: Create Xcode Project

**Files:**
- Create: `Mnemosyne.xcodeproj` (via Xcode)
- Create: `Mnemosyne/Info.plist`
- Create: `Mnemosyne/MnemosyneApp.swift`

- [ ] **Step 1: Create the Xcode project**

  Open Xcode → File → New → Project → macOS → App.
  - Product Name: `Mnemosyne`
  - Bundle Identifier: `com.yourname.Mnemosyne`
  - Interface: SwiftUI
  - Language: Swift
  - Uncheck "Include Tests" for now (we add the test target manually in Task 2)
  - Save to `/Users/D063320/projects/Mnemosyne/`

- [ ] **Step 2: Set deployment target**

  In Xcode, select the `Mnemosyne` project → Targets → Mnemosyne → General → Minimum Deployments → set to **macOS 13.0**.

- [ ] **Step 3: Set LSUIElement in Info.plist**

  In `Mnemosyne/Info.plist`, add the key `Application is agent (UIElement)` = `YES` (raw key: `LSUIElement`, type: Boolean, value: YES).

  This hides the app from the Dock and the Cmd-Tab switcher.

- [ ] **Step 4: Replace MnemosyneApp.swift**

  Replace the generated `MnemosyneApp.swift` with:

  ```swift
  import SwiftUI

  @main
  struct MnemosyneApp: App {
      @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

      var body: some Scene {
          Settings { EmptyView() }
      }
  }
  ```

  The `Settings` scene with `EmptyView` is required to satisfy SwiftUI's `App` protocol without showing a main window.

- [ ] **Step 5: Create AppDelegate.swift**

  Create `Mnemosyne/AppDelegate.swift`:

  ```swift
  import AppKit
  import SwiftUI

  class AppDelegate: NSObject, NSApplicationDelegate {
      private var statusItem: NSStatusItem!
      private var popover: NSPopover!

      func applicationDidFinishLaunching(_ notification: Notification) {
          statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
          if let button = statusItem.button {
              button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Mnemosyne")
              button.action = #selector(togglePopover)
              button.target = self
          }

          popover = NSPopover()
          popover.contentSize = NSSize(width: 320, height: 480)
          popover.behavior = .transient
          popover.contentViewController = NSHostingController(rootView: Text("Coming soon"))
      }

      @objc func togglePopover() {
          guard let button = statusItem.button else { return }
          if popover.isShown {
              popover.performClose(nil)
          } else {
              popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
          }
      }
  }
  ```

- [ ] **Step 6: Build and run**

  Press `⌘R`. The app should launch with no Dock icon, no window, and a clipboard icon in the menubar. Clicking it should show a popover with "Coming soon".

- [ ] **Step 7: Commit**

  ```bash
  cd /Users/D063320/projects/Mnemosyne
  git add Mnemosyne.xcodeproj Mnemosyne/
  git commit -m "feat: scaffold Xcode project, menubar icon, empty popover"
  ```

---

## Task 2: Add Test Target

**Files:**
- Create: `MnemosyneTests/` target in Xcode
- Create: `MnemosyneTests/ClipboardItemTests.swift` (placeholder)

- [ ] **Step 1: Add test target**

  In Xcode → File → New → Target → macOS → Unit Testing Bundle.
  - Product Name: `MnemosyneTests`
  - Target to be Tested: `Mnemosyne`

- [ ] **Step 2: Create placeholder test file**

  Delete the generated `MnemosyneTests.swift` and create `MnemosyneTests/ClipboardItemTests.swift`:

  ```swift
  import XCTest
  @testable import Mnemosyne

  final class ClipboardItemTests: XCTest Case {
      func test_placeholder() {
          XCTAssertTrue(true)
      }
  }
  ```

  Note: fix the space in `XCTest Case` above — that was to avoid a parser conflict. Write it as `XCTestCase`.

- [ ] **Step 3: Run tests**

  Press `⌘U`. Expected: 1 test passes.

- [ ] **Step 4: Commit**

  ```bash
  git add MnemosyneTests/
  git commit -m "chore: add unit test target"
  ```

---

## Task 3: ClipboardItem Model

**Files:**
- Create: `Mnemosyne/Models/ClipboardItem.swift`
- Modify: `MnemosyneTests/ClipboardItemTests.swift`

- [ ] **Step 1: Write the failing tests**

  Replace `MnemosyneTests/ClipboardItemTests.swift`:

  ```swift
  import XCTest
  @testable import Mnemosyne

  final class ClipboardItemTests: XCTestCase {

      func test_textItem_codableRoundTrip() throws {
          let item = ClipboardItem(content: .text("hello world"))
          let data = try JSONEncoder().encode(item)
          let decoded = try JSONDecoder().decode(ClipboardItem.self, from: data)
          guard case .text(let str) = decoded.content else {
              XCTFail("Expected text content")
              return
          }
          XCTAssertEqual(str, "hello world")
          XCTAssertEqual(item.id, decoded.id)
      }

      func test_imageItem_codableRoundTrip() throws {
          let pngData = Data([0x89, 0x50, 0x4E, 0x47]) // PNG magic bytes
          let item = ClipboardItem(content: .image(pngData))
          let data = try JSONEncoder().encode(item)
          let decoded = try JSONDecoder().decode(ClipboardItem.self, from: data)
          guard case .image(let decoded Data) = decoded.content else {
              XCTFail("Expected image content")
              return
          }
          XCTAssertEqual(decodedData, pngData)
      }

      func test_textItem_isText_true() {
          let item = ClipboardItem(content: .text("hi"))
          XCTAssertTrue(item.isText)
          XCTAssertFalse(item.isImage)
      }

      func test_imageItem_isImage_true() {
          let item = ClipboardItem(content: .image(Data()))
          XCTAssertTrue(item.isImage)
          XCTAssertFalse(item.isText)
      }

      func test_textPreview_truncatesLongText() {
          let long = String(repeating: "a", count: 200)
          let item = ClipboardItem(content: .text(long))
          XCTAssertLessThanOrEqual(item.textPreview.count, 100)
      }

      func test_textPreview_fullShortText() {
          let item = ClipboardItem(content: .text("short"))
          XCTAssertEqual(item.textPreview, "short")
      }
  }
  ```

  Note: fix `decoded Data` — no space: `decodedData`.

- [ ] **Step 2: Run tests — verify they fail**

  Press `⌘U`. Expected: compile error — `ClipboardItem` not defined.

- [ ] **Step 3: Create ClipboardItem.swift**

  Create `Mnemosyne/Models/ClipboardItem.swift`:

  ```swift
  import Foundation

  struct ClipboardItem: Identifiable, Codable {
      let id: UUID
      let timestamp: Date
      let content: Content

      enum Content: Codable {
          case text(String)
          case image(Data)

          private enum CodingKeys: String, CodingKey {
              case type, value
          }

          init(from decoder: Decoder) throws {
              let container = try decoder.container(keyedBy: CodingKeys.self)
              let type = try container.decode(String.self, forKey: .type)
              switch type {
              case "text":
                  let value = try container.decode(String.self, forKey: .value)
                  self = .text(value)
              case "image":
                  let value = try container.decode(Data.self, forKey: .value)
                  self = .image(value)
              default:
                  throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown type: \(type)")
              }
          }

          func encode(to encoder: Encoder) throws {
              var container = encoder.container(keyedBy: CodingKeys.self)
              switch self {
              case .text(let str):
                  try container.encode("text", forKey: .type)
                  try container.encode(str, forKey: .value)
              case .image(let data):
                  try container.encode("image", forKey: .type)
                  try container.encode(data, forKey: .value)
              }
          }
      }

      init(id: UUID = UUID(), timestamp: Date = Date(), content: Content) {
          self.id = id
          self.timestamp = timestamp
          self.content = content
      }

      var isText: Bool {
          if case .text = content { return true }
          return false
      }

      var isImage: Bool {
          if case .image = content { return true }
          return false
      }

      var textPreview: String {
          guard case .text(let str) = content else { return "" }
          let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
          return trimmed.count > 100 ? String(trimmed.prefix(100)) + "…" : trimmed
      }
  }
  ```

- [ ] **Step 4: Run tests — verify they pass**

  Press `⌘U`. Expected: all 6 ClipboardItemTests pass.

- [ ] **Step 5: Commit**

  ```bash
  git add Mnemosyne/Models/ClipboardItem.swift MnemosyneTests/ClipboardItemTests.swift
  git commit -m "feat: add ClipboardItem model with Codable Content enum"
  ```

---

## Task 4: PersistenceManager

**Files:**
- Create: `Mnemosyne/Store/PersistenceManager.swift`
- Create: `MnemosyneTests/PersistenceManagerTests.swift`

- [ ] **Step 1: Write the failing tests**

  Create `MnemosyneTests/PersistenceManagerTests.swift`:

  ```swift
  import XCTest
  @testable import Mnemosyne

  final class PersistenceManagerTests: XCTestCase {
      var manager: PersistenceManager!
      var tempURL: URL!

      override func setUp() {
          super.setUp()
          tempURL = FileManager.default.temporaryDirectory
              .appendingPathComponent(UUID().uuidString)
              .appendingPathExtension("json")
          manager = PersistenceManager(fileURL: tempURL)
      }

      override func tearDown() {
          try? FileManager.default.removeItem(at: tempURL)
          super.tearDown()
      }

      func test_saveAndLoad_roundTrip() throws {
          let items = [
              ClipboardItem(content: .text("first")),
              ClipboardItem(content: .text("second"))
          ]
          try manager.save(items)
          let loaded = try manager.load()
          XCTAssertEqual(loaded.count, 2)
          guard case .text(let first) = loaded[0].content,
                case .text(let second) = loaded[1].content else {
              XCTFail("Unexpected content types")
              return
          }
          XCTAssertEqual(first, "first")
          XCTAssertEqual(second, "second")
      }

      func test_load_returnsEmptyArray_whenFileDoesNotExist() throws {
          let loaded = try manager.load()
          XCTAssertEqual(loaded.count, 0)
      }

      func test_save_overwritesPreviousData() throws {
          let original = [ClipboardItem(content: .text("original"))]
          try manager.save(original)
          let updated = [ClipboardItem(content: .text("updated"))]
          try manager.save(updated)
          let loaded = try manager.load()
          XCTAssertEqual(loaded.count, 1)
          guard case .text(let str) = loaded[0].content else {
              XCTFail(); return
          }
          XCTAssertEqual(str, "updated")
      }
  }
  ```

- [ ] **Step 2: Run tests — verify they fail**

  Press `⌘U`. Expected: compile error — `PersistenceManager` not defined.

- [ ] **Step 3: Create PersistenceManager.swift**

  Create `Mnemosyne/Store/PersistenceManager.swift`:

  ```swift
  import Foundation

  final class PersistenceManager {
      private let fileURL: URL

      /// Production initialiser — uses ~/Library/Application Support/Mnemosyne/history.json
      convenience init() {
          let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
          let dir = appSupport.appendingPathComponent("Mnemosyne", isDirectory: true)
          try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
          self.init(fileURL: dir.appendingPathComponent("history.json"))
      }

      /// Testable initialiser — accepts any file URL
      init(fileURL: URL) {
          self.fileURL = fileURL
      }

      func save(_ items: [ClipboardItem]) throws {
          let data = try JSONEncoder().encode(items)
          try data.write(to: fileURL, options: .atomic)
      }

      func load() throws -> [ClipboardItem] {
          guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
          let data = try Data(contentsOf: fileURL)
          return try JSONDecoder().decode([ClipboardItem].self, from: data)
      }
  }
  ```

- [ ] **Step 4: Run tests — verify they pass**

  Press `⌘U`. Expected: all 3 PersistenceManagerTests pass.

- [ ] **Step 5: Commit**

  ```bash
  git add Mnemosyne/Store/PersistenceManager.swift MnemosyneTests/PersistenceManagerTests.swift
  git commit -m "feat: add PersistenceManager for JSON history persistence"
  ```

---

## Task 5: HistoryStore

**Files:**
- Create: `Mnemosyne/Store/HistoryStore.swift`
- Create: `MnemosyneTests/HistoryStoreTests.swift`

- [ ] **Step 1: Write the failing tests**

  Create `MnemosyneTests/HistoryStoreTests.swift`:

  ```swift
  import XCTest
  @testable import Mnemosyne

  final class HistoryStoreTests: XCTestCase {
      var store: HistoryStore!
      var tempURL: URL!

      override func setUp() {
          super.setUp()
          tempURL = FileManager.default.temporaryDirectory
              .appendingPathComponent(UUID().uuidString)
              .appendingPathExtension("json")
          let persistence = PersistenceManager(fileURL: tempURL)
          store = HistoryStore(persistence: persistence, maxSize: 5)
      }

      override func tearDown() {
          try? FileManager.default.removeItem(at: tempURL)
          super.tearDown()
      }

      func test_add_appendsItem() {
          store.add(ClipboardItem(content: .text("hello")))
          XCTAssertEqual(store.items.count, 1)
      }

      func test_add_newestItemFirst() {
          store.add(ClipboardItem(content: .text("first")))
          store.add(ClipboardItem(content: .text("second")))
          guard case .text(let top) = store.items[0].content else { XCTFail(); return }
          XCTAssertEqual(top, "second")
      }

      func test_add_deduplicates_consecutiveIdenticalText() {
          store.add(ClipboardItem(content: .text("dup")))
          store.add(ClipboardItem(content: .text("dup")))
          XCTAssertEqual(store.items.count, 1)
      }

      func test_add_allowsDuplicateIfNotConsecutive() {
          store.add(ClipboardItem(content: .text("a")))
          store.add(ClipboardItem(content: .text("b")))
          store.add(ClipboardItem(content: .text("a")))
          XCTAssertEqual(store.items.count, 3)
      }

      func test_add_capsAtMaxSize() {
          for i in 0..<6 {
              store.add(ClipboardItem(content: .text("item \(i)")))
          }
          XCTAssertEqual(store.items.count, 5)
      }

      func test_clear_removesAllItems() {
          store.add(ClipboardItem(content: .text("x")))
          store.clear()
          XCTAssertTrue(store.items.isEmpty)
      }

      func test_filteredItems_returnsMatchingText() {
          store.add(ClipboardItem(content: .text("hello world")))
          store.add(ClipboardItem(content: .text("goodbye")))
          let results = store.filteredItems(query: "hello")
          XCTAssertEqual(results.count, 1)
          guard case .text(let str) = results[0].content else { XCTFail(); return }
          XCTAssertEqual(str, "hello world")
      }

      func test_filteredItems_emptyQueryReturnsAll() {
          store.add(ClipboardItem(content: .text("a")))
          store.add(ClipboardItem(content: .text("b")))
          XCTAssertEqual(store.filteredItems(query: "").count, 2)
      }

      func test_filteredItems_imagesAlwaysIncluded() {
          let pngData = Data([0x89, 0x50, 0x4E, 0x47])
          store.add(ClipboardItem(content: .image(pngData)))
          store.add(ClipboardItem(content: .text("unrelated")))
          let results = store.filteredItems(query: "xyz")
          XCTAssertEqual(results.count, 1)
          XCTAssertTrue(results[0].isImage)
      }
  }
  ```

- [ ] **Step 2: Run tests — verify they fail**

  Press `⌘U`. Expected: compile error — `HistoryStore` not defined.

- [ ] **Step 3: Create HistoryStore.swift**

  Create `Mnemosyne/Store/HistoryStore.swift`:

  ```swift
  import Foundation
  import Combine

  @MainActor
  final class HistoryStore: ObservableObject {
      @Published private(set) var items: [ClipboardItem] = []

      private let persistence: PersistenceManager
      private let maxSize: Int

      init(persistence: PersistenceManager = PersistenceManager(), maxSize: Int = 200) {
          self.persistence = persistence
          self.maxSize = maxSize
          loadFromDisk()
      }

      func add(_ item: ClipboardItem) {
          // Deduplication: ignore if identical to most recent item
          if let first = items.first {
              if case .text(let newStr) = item.content, case .text(let existingStr) = first.content, newStr == existingStr {
                  return
              }
              if case .image(let newData) = item.content, case .image(let existingData) = first.content, newData == existingData {
                  return
              }
          }
          items.insert(item, at: 0)
          if items.count > maxSize {
              items.removeLast()
          }
          saveToDisk()
      }

      func clear() {
          items.removeAll()
          saveToDisk()
      }

      func filteredItems(query: String) -> [ClipboardItem] {
          guard !query.isEmpty else { return items }
          return items.filter { item in
              switch item.content {
              case .text(let str):
                  return str.localizedCaseInsensitiveContains(query)
              case .image:
                  return true // images always shown
              }
          }
      }

      private func loadFromDisk() {
          items = (try? persistence.load()) ?? []
      }

      private func saveToDisk() {
          Task.detached(priority: .background) { [items = self.items, persistence = self.persistence] in
              try? persistence.save(items)
          }
      }
  }
  ```

- [ ] **Step 4: Run tests — verify they pass**

  Press `⌘U`. Expected: all 9 HistoryStoreTests pass.

- [ ] **Step 5: Commit**

  ```bash
  git add Mnemosyne/Store/HistoryStore.swift MnemosyneTests/HistoryStoreTests.swift
  git commit -m "feat: add HistoryStore with deduplication, cap, search filter"
  ```

---

## Task 6: ClipboardMonitor

**Files:**
- Create: `Mnemosyne/Clipboard/ClipboardMonitor.swift`

No unit tests for ClipboardMonitor — it wraps `NSPasteboard` directly and requires manual integration testing.

- [ ] **Step 1: Create ClipboardMonitor.swift**

  Create `Mnemosyne/Clipboard/ClipboardMonitor.swift`:

  ```swift
  import AppKit

  @MainActor
  final class ClipboardMonitor {
      private var timer: Timer?
      private var lastChangeCount: Int = NSPasteboard.general.changeCount
      private let store: HistoryStore

      init(store: HistoryStore) {
          self.store = store
      }

      func start() {
          timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
              Task { @MainActor in
                  self?.checkForChanges()
              }
          }
      }

      func stop() {
          timer?.invalidate()
          timer = nil
      }

      private func checkForChanges() {
          let pasteboard = NSPasteboard.general
          guard pasteboard.changeCount != lastChangeCount else { return }
          lastChangeCount = pasteboard.changeCount

          // Try text first
          if let string = pasteboard.string(forType: .string), !string.isEmpty {
              store.add(ClipboardItem(content: .text(string)))
              return
          }

          // Try image (TIFF → PNG conversion)
          if let tiffData = pasteboard.data(forType: .tiff),
             let image = NSImage(data: tiffData),
             let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
              let rep = NSBitmapImageRep(cgImage: cgImage)
              if let pngData = rep.representation(using: .png, properties: [:]) {
                  store.add(ClipboardItem(content: .image(pngData)))
              }
          }
      }
  }
  ```

- [ ] **Step 2: Wire ClipboardMonitor into AppDelegate**

  Modify `Mnemosyne/AppDelegate.swift` — add store and monitor properties and start the monitor:

  ```swift
  import AppKit
  import SwiftUI

  class AppDelegate: NSObject, NSApplicationDelegate {
      private var statusItem: NSStatusItem!
      private var popover: NSPopover!
      let store = HistoryStore()
      private var monitor: ClipboardMonitor!

      func applicationDidFinishLaunching(_ notification: Notification) {
          monitor = ClipboardMonitor(store: store)
          monitor.start()

          statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
          if let button = statusItem.button {
              button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Mnemosyne")
              button.action = #selector(togglePopover)
              button.target = self
          }

          popover = NSPopover()
          popover.contentSize = NSSize(width: 320, height: 480)
          popover.behavior = .transient
          popover.contentViewController = NSHostingController(rootView: Text("Coming soon"))
      }

      @objc func togglePopover() {
          guard let button = statusItem.button else { return }
          if popover.isShown {
              popover.performClose(nil)
          } else {
              popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
          }
      }
  }
  ```

- [ ] **Step 3: Build and verify manually**

  Press `⌘R`. Copy some text in any app. Open the popover (still shows "Coming soon"). The monitor should be silently capturing to the store in the background — no visible feedback yet.

- [ ] **Step 4: Commit**

  ```bash
  git add Mnemosyne/Clipboard/ClipboardMonitor.swift Mnemosyne/AppDelegate.swift
  git commit -m "feat: add ClipboardMonitor, wire into AppDelegate"
  ```

---

## Task 7: PasteService

**Files:**
- Create: `Mnemosyne/Clipboard/PasteService.swift`
- Create: `MnemosyneTests/PasteServiceTests.swift`

- [ ] **Step 1: Write the failing tests**

  Create `MnemosyneTests/PasteServiceTests.swift`:

  ```swift
  import XCTest
  @testable import Mnemosyne

  final class PasteServiceTests: XCTestCase {

      func test_plainText_stripsLeadingAndTrailingWhitespace() {
          let input = "  hello world  "
          let result = PasteService.trimmed(input)
          XCTAssertEqual(result, "hello world")
      }

      func test_plainText_stripsNewlines() {
          let input = "\nhello\nworld\n"
          let result = PasteService.trimmed(input)
          XCTAssertEqual(result, "hello\nworld")
      }

      func test_plainText_stripsRTFFormatting() throws {
          // RTF string with bold formatting
          let rtf = "{\\rtf1\\ansi {\\b hello world}}"
          let rtfData = rtf.data(using: .ascii)!
          let result = try PasteService.plainText(from: rtfData, type: .rtf)
          XCTAssertEqual(result, "hello world")
      }

      func test_plainText_returnsOriginalForPlainString() throws {
          let plain = "just plain text"
          let data = plain.data(using: .utf8)!
          let result = try PasteService.plainText(from: data, type: .string)
          XCTAssertEqual(result, "just plain text")
      }
  }
  ```

- [ ] **Step 2: Run tests — verify they fail**

  Press `⌘U`. Expected: compile error — `PasteService` not defined.

- [ ] **Step 3: Create PasteService.swift**

  Create `Mnemosyne/Clipboard/PasteService.swift`:

  ```swift
  import AppKit

  enum PasteService {

      /// Trims leading and trailing whitespace/newlines from a string.
      static func trimmed(_ string: String) -> String {
          string.trimmingCharacters(in: .whitespacesAndNewlines)
      }

      /// Strips rich-text formatting from data, returning plain text.
      /// Falls back to the raw string if parsing fails.
      static func plainText(from data: Data, type: NSPasteboard.PasteboardType) throws -> String {
          let docType: NSAttributedString.DocumentType
          switch type {
          case .rtf:
              docType = .rtf
          case .html:
              docType = .html
          default:
              // Already plain text
              return String(data: data, encoding: .utf8) ?? ""
          }
          let attributed = try NSAttributedString(
              data: data,
              options: [.documentType: docType],
              documentAttributes: nil
          )
          return attributed.string
      }

      /// Writes a ClipboardItem to the general pasteboard and fires ⌘V to the frontmost app.
      /// - Parameter mode: .asis, .plainText, or .trimmed
      @MainActor
      static func paste(item: ClipboardItem, mode: PasteMode) {
          guard checkAccessibility() else { return }

          let pasteboard = NSPasteboard.general
          pasteboard.clearContents()

          switch item.content {
          case .text(let str):
              let finalStr: String
              switch mode {
              case .asIs:
                  finalStr = str
              case .trimmed:
                  finalStr = trimmed(str)
              case .plainText:
                  finalStr = (try? plainText(from: Data(str.utf8), type: .string)) ?? str
              }
              pasteboard.setString(finalStr, forType: .string)

          case .image(let data):
              pasteboard.setData(data, forType: .png)
          }

          // Fire ⌘V to frontmost app
          let src = CGEventSource(stateID: .hidSystemState)
          let vKey: CGKeyCode = 9
          let keyDown = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: true)
          let keyUp   = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: false)
          keyDown?.flags = .maskCommand
          keyUp?.flags   = .maskCommand
          keyDown?.post(tap: .cgAnnotatedSessionEventTap)
          keyUp?.post(tap: .cgAnnotatedSessionEventTap)
      }

      /// Returns true if Accessibility permission is granted.
      /// Shows a system prompt to request it if not.
      static func checkAccessibility() -> Bool {
          let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
          return AXIsProcessTrustedWithOptions(options)
      }
  }

  enum PasteMode {
      case asIs
      case trimmed
      case plainText
  }
  ```

- [ ] **Step 4: Run tests — verify they pass**

  Press `⌘U`. Expected: all 4 PasteServiceTests pass.

- [ ] **Step 5: Commit**

  ```bash
  git add Mnemosyne/Clipboard/PasteService.swift MnemosyneTests/PasteServiceTests.swift
  git commit -m "feat: add PasteService with trim, plain-text strip, CGEvent paste"
  ```

---

## Task 8: ClipboardItemRow UI

**Files:**
- Create: `Mnemosyne/UI/ClipboardItemRow.swift`

- [ ] **Step 1: Create ClipboardItemRow.swift**

  Create `Mnemosyne/UI/ClipboardItemRow.swift`:

  ```swift
  import SwiftUI

  struct ClipboardItemRow: View {
      let item: ClipboardItem

      private static let timeFormatter: DateFormatter = {
          let f = DateFormatter()
          f.timeStyle = .short
          f.dateStyle = .none
          return f
      }()

      var body: some View {
          HStack(spacing: 8) {
              contentView
              Spacer()
              Text(Self.timeFormatter.string(from: item.timestamp))
                  .font(.caption2)
                  .foregroundStyle(.secondary)
          }
          .padding(.vertical, 4)
          .contentShape(Rectangle())
      }

      @ViewBuilder
      private var contentView: some View {
          switch item.content {
          case .text:
              HStack(spacing: 6) {
                  Image(systemName: "doc.text")
                      .foregroundStyle(.secondary)
                      .frame(width: 16)
                  Text(item.textPreview)
                      .font(.system(size: 12))
                      .lineLimit(1)
                      .truncationMode(.tail)
              }
          case .image(let data):
              HStack(spacing: 6) {
                  Image(systemName: "photo")
                      .foregroundStyle(.secondary)
                      .frame(width: 16)
                  if let nsImage = NSImage(data: data) {
                      Image(nsImage: nsImage)
                          .resizable()
                          .scaledToFill()
                          .frame(width: 40, height: 40)
                          .clipShape(RoundedRectangle(cornerRadius: 4))
                  }
                  Text("Screenshot")
                      .font(.system(size: 12))
                      .foregroundStyle(.secondary)
              }
          }
      }
  }
  ```

- [ ] **Step 2: Build — verify no compile errors**

  Press `⌘B`.

- [ ] **Step 3: Commit**

  ```bash
  git add Mnemosyne/UI/ClipboardItemRow.swift
  git commit -m "feat: add ClipboardItemRow view for text and image items"
  ```

---

## Task 9: SettingsView UI

**Files:**
- Create: `Mnemosyne/UI/SettingsView.swift`

- [ ] **Step 1: Create SettingsView.swift**

  Create `Mnemosyne/UI/SettingsView.swift`:

  ```swift
  import SwiftUI
  import ServiceManagement

  struct SettingsView: View {
      @ObservedObject var store: HistoryStore
      @AppStorage("maxHistorySize") private var maxHistorySize: Int = 200
      @State private var launchAtLogin: Bool = (SMAppService.mainApp.status == .enabled)

      var body: some View {
          VStack(alignment: .leading, spacing: 16) {
              Text("Settings")
                  .font(.headline)

              HStack {
                  Text("Max history size")
                  Spacer()
                  Stepper("\(maxHistorySize)", value: $maxHistorySize, in: 10...500, step: 10)
              }

              Toggle("Launch at login", isOn: $launchAtLogin)
                  .onChange(of: launchAtLogin) { _, enabled in
                      do {
                          if enabled {
                              try SMAppService.mainApp.register()
                          } else {
                              try SMAppService.mainApp.unregister()
                          }
                      } catch {
                          launchAtLogin = !enabled // revert on failure
                      }
                  }

              Divider()

              Button(role: .destructive) {
                  store.clear()
              } label: {
                  Label("Clear history", systemImage: "trash")
              }
          }
          .padding()
          .frame(width: 280)
      }
  }
  ```

- [ ] **Step 2: Build — verify no compile errors**

  Press `⌘B`.

- [ ] **Step 3: Commit**

  ```bash
  git add Mnemosyne/UI/SettingsView.swift
  git commit -m "feat: add SettingsView with max size, launch at login, clear history"
  ```

---

## Task 10: MenubarView UI — Wire Everything Together

**Files:**
- Create: `Mnemosyne/UI/MenubarView.swift`
- Modify: `Mnemosyne/AppDelegate.swift`

- [ ] **Step 1: Create MenubarView.swift**

  Create `Mnemosyne/UI/MenubarView.swift`:

  ```swift
  import SwiftUI

  struct MenubarView: View {
      @ObservedObject var store: HistoryStore
      @State private var searchQuery = ""
      @State private var showSettings = false

      var body: some View {
          VStack(spacing: 0) {
              // Header
              HStack {
                  Text("Mnemosyne")
                      .font(.headline)
                  Spacer()
                  Button { showSettings.toggle() } label: {
                      Image(systemName: "gearshape")
                  }
                  .buttonStyle(.plain)
                  Button { NSApp.terminate(nil) } label: {
                      Image(systemName: "xmark.circle")
                  }
                  .buttonStyle(.plain)
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 8)

              Divider()

              if showSettings {
                  SettingsView(store: store)
              } else {
                  // Quick action bar for current clipboard
                  if let topItem = store.items.first, topItem.isText {
                      HStack(spacing: 8) {
                          Button("Trim spaces") {
                              PasteService.paste(item: topItem, mode: .trimmed)
                          }
                          .buttonStyle(.bordered)
                          Button("Plain text") {
                              PasteService.paste(item: topItem, mode: .plainText)
                          }
                          .buttonStyle(.bordered)
                          Spacer()
                      }
                      .padding(.horizontal, 12)
                      .padding(.vertical, 6)

                      Divider()
                  }

                  // Search field
                  HStack {
                      Image(systemName: "magnifyingglass")
                          .foregroundStyle(.secondary)
                      TextField("Search...", text: $searchQuery)
                          .textFieldStyle(.plain)
                  }
                  .padding(.horizontal, 12)
                  .padding(.vertical, 6)

                  Divider()

                  // History list
                  ScrollView {
                      LazyVStack(spacing: 0) {
                          ForEach(store.filteredItems(query: searchQuery)) { item in
                              ClipboardItemRow(item: item)
                                  .padding(.horizontal, 12)
                                  .background(Color.clear)
                                  .onTapGesture {
                                      PasteService.paste(item: item, mode: .asIs)
                                  }
                                  .simultaneousGesture(
                                      TapGesture()
                                          .modifiers(.option)
                                          .onEnded { _ in
                                              PasteService.paste(item: item, mode: .plainText)
                                          }
                                  )
                                  .simultaneousGesture(
                                      TapGesture()
                                          .modifiers(.shift)
                                          .onEnded { _ in
                                              PasteService.paste(item: item, mode: .trimmed)
                                          }
                                  )
                              Divider()
                                  .padding(.leading, 12)
                          }
                      }
                  }
                  .frame(maxHeight: 360)
              }
          }
          .frame(width: 320)
      }
  }
  ```

- [ ] **Step 2: Update AppDelegate to use MenubarView**

  Replace `Mnemosyne/AppDelegate.swift` with:

  ```swift
  import AppKit
  import SwiftUI

  class AppDelegate: NSObject, NSApplicationDelegate {
      private var statusItem: NSStatusItem!
      private var popover: NSPopover!
      let store = HistoryStore()
      private var monitor: ClipboardMonitor!

      func applicationDidFinishLaunching(_ notification: Notification) {
          monitor = ClipboardMonitor(store: store)
          monitor.start()

          statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
          if let button = statusItem.button {
              button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Mnemosyne")
              button.action = #selector(togglePopover)
              button.target = self
          }

          popover = NSPopover()
          popover.contentSize = NSSize(width: 320, height: 480)
          popover.behavior = .transient
          popover.contentViewController = NSHostingController(
              rootView: MenubarView(store: store)
          )
      }

      @objc func togglePopover() {
          guard let button = statusItem.button else { return }
          if popover.isShown {
              popover.performClose(nil)
          } else {
              popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
              NSApp.activate(ignoringOtherApps: true)
          }
      }
  }
  ```

- [ ] **Step 3: Build and run**

  Press `⌘R`. Test the full flow:
  1. Copy some text — it should appear in the history list
  2. Copy an image (⌘⇧4 screenshot) — it should appear as a thumbnail
  3. Click a text item — it should paste into the frontmost app (grant Accessibility if prompted)
  4. ⌥+Click a rich-text item — should paste plain text
  5. ⇧+Click a padded text item — should paste trimmed
  6. Type in the search field — list should filter live
  7. Open Settings — stepper, toggle, and clear button should be present

- [ ] **Step 4: Commit**

  ```bash
  git add Mnemosyne/UI/MenubarView.swift Mnemosyne/AppDelegate.swift
  git commit -m "feat: wire MenubarView into popover, complete UI integration"
  ```

---

## Task 11: Push and Tag v0.1

- [ ] **Step 1: Run all tests**

  Press `⌘U`. Expected: all tests pass.

- [ ] **Step 2: Push to GitHub**

  ```bash
  git push origin main
  ```

- [ ] **Step 3: Tag v0.1**

  ```bash
  git tag v0.1.0
  git push origin v0.1.0
  ```

---

## Self-Review

**Spec coverage check:**

| Spec requirement | Covered in task |
|---|---|
| Menubar app, LSUIElement | Task 1 |
| ClipboardItem model (text + image, Codable) | Task 3 |
| Persistence to JSON on disk | Task 4 |
| HistoryStore: cap 200, dedup, search | Task 5 |
| ClipboardMonitor: 0.5s polling | Task 6 |
| PasteService: trim, plain-text, CGEvent | Task 7 |
| Accessibility permission check | Task 7 |
| ClipboardItemRow: text preview + thumbnail | Task 8 |
| SettingsView: maxSize, launchAtLogin, clear | Task 9 |
| MenubarView: header, action bar, search, list | Task 10 |
| ⌥+Click plain text, ⇧+Click trim | Task 10 |
| Image paste as-is | Task 10 |
| Persist history across restarts | Tasks 4+5 |

All spec requirements covered. No gaps found.
