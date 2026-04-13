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
