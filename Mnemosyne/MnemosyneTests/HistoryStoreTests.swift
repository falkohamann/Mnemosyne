import XCTest
@testable import Mnemosyne

@MainActor
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
