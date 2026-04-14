import XCTest
@testable import Mnemosyne

final class PasteServiceTests: XCTestCase {

    func test_trimmed_stripsLeadingAndTrailingWhitespace() {
        let input = "  hello world  "
        let result = PasteService.trimmed(input)
        XCTAssertEqual(result, "hello world")
    }

    func test_trimmed_stripsNewlines() {
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
