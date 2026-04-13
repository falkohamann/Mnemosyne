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
