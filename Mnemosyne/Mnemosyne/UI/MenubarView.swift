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
                // Quick action bar for current clipboard item
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
