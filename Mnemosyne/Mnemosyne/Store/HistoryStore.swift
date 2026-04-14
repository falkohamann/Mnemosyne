import Foundation
import Combine

@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []

    private let persistence: PersistenceManager
    private let maxSize: Int

    init(persistence: PersistenceManager? = nil, maxSize: Int = 200) {
        self.persistence = persistence ?? PersistenceManager()
        self.maxSize = maxSize
        loadFromDisk()
    }

    func add(_ item: ClipboardItem) {
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
                return true
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
