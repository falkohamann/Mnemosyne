import AppKit

enum PasteService {

    // MARK: - Pure logic (tested)

    /// Trims leading and trailing whitespace/newlines from a string.
    static func trimmed(_ string: String) -> String {
        string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Strips rich-text formatting from data, returning plain text.
    /// Falls back to the raw string for plain-string types.
    static func plainText(from data: Data, type pasteboardType: NSPasteboard.PasteboardType) throws -> String {
        let docType: NSAttributedString.DocumentType
        switch pasteboardType {
        case .rtf:
            docType = .rtf
        case .html:
            docType = .html
        default:
            return String(data: data, encoding: .utf8) ?? ""
        }
        let attributed = try NSAttributedString(
            data: data,
            options: [.documentType: docType],
            documentAttributes: nil
        )
        return attributed.string
    }

    // MARK: - Paste action

    /// Returns true if Accessibility permission is granted.
    /// Passes `prompt: true` so macOS shows the system dialog on first call.
    static func checkAccessibility() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Writes a ClipboardItem to the general pasteboard and fires ⌘V to the frontmost app.
    ///
    /// - Parameters:
    ///   - item: The clipboard item to paste.
    ///   - mode: Controls text transformation before writing to the pasteboard.
    ///
    /// TODO: Implement the paste logic here.
    /// Steps to follow:
    ///   1. Call `checkAccessibility()` — return early if permission is not granted.
    ///   2. Call `pasteboard.clearContents()` on `NSPasteboard.general`.
    ///   3. Switch on `item.content`:
    ///      - `.text(let str)`: apply the mode transform (asIs / trimmed / plainText),
    ///        then `pasteboard.setString(finalStr, forType: .string)`.
    ///      - `.image(let data)`: `pasteboard.setData(data, forType: .png)`.
    ///   4. Fire ⌘V using CGEvent:
    ///      - `CGKeyCode` for 'v' is 9.
    ///      - Create keyDown + keyUp events with `.maskCommand` flag.
    ///      - Post both to `.cgAnnotatedSessionEventTap`.
    ///
    /// Tip: For the `.plainText` mode you can call `Self.plainText(from:type:)` or just
    /// use `String(str)` — the text is already plain at this point; no RTF to strip.
    @MainActor
    static func paste(item: ClipboardItem, mode: PasteMode) {
        guard checkAccessibility() else { return }

        // Close the popover so the previous app regains focus before we paste
        NSApp.keyWindow?.close()

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.content {
        case .text(let str):
            let finalStr: String
            switch mode {
            case .asIs:      finalStr = str
            case .trimmed:   finalStr = trimmed(str)
            case .plainText: finalStr = str
            }
            pasteboard.setString(finalStr, forType: .string)
        case .image(let data):
            pasteboard.setData(data, forType: .png)
        }

        // Small delay so the previous app has time to become key before ⌘V fires
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let src = CGEventSource(stateID: .hidSystemState)
            let vKey: CGKeyCode = 9
            let keyDown = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: true)
            let keyUp   = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: false)
            keyDown?.flags = .maskCommand
            keyUp?.flags   = .maskCommand
            keyDown?.post(tap: .cgAnnotatedSessionEventTap)
            keyUp?.post(tap: .cgAnnotatedSessionEventTap)
        }
    }
}

enum PasteMode {
    case asIs
    case trimmed
    case plainText
}
