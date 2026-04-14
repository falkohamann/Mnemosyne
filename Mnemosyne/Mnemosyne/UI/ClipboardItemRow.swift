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
