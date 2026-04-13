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
                self = .text(try container.decode(String.self, forKey: .value))
            case "image":
                self = .image(try container.decode(Data.self, forKey: .value))
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
