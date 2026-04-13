//
//  MnemosyneTests.swift
//  MnemosyneTests
//
//  Created by Hamann, Falko on 13.04.26.
//

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
        let pngData = Data([0x89, 0x50, 0x4E, 0x47])
        let item = ClipboardItem(content: .image(pngData))
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(ClipboardItem.self, from: data)
        guard case .image(let decodedData) = decoded.content else {
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
        XCTAssertLessThanOrEqual(item.textPreview.count, 101) // 100 chars + ellipsis
    }

    func test_textPreview_fullShortText() {
        let item = ClipboardItem(content: .text("short"))
        XCTAssertEqual(item.textPreview, "short")
    }
}
