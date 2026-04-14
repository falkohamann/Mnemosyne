import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var store: HistoryStore
    @AppStorage("maxHistorySize") private var maxHistorySize: Int = 200
    @State private var launchAtLogin: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)

            HStack {
                Text("Max history size")
                Spacer()
                Stepper("\(maxHistorySize)", value: $maxHistorySize, in: 10...500, step: 10)
            }

            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin, perform: { enabled in
                    do {
                        if enabled {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        launchAtLogin = !enabled
                    }
                })

            Divider()

            Button(role: .destructive) {
                store.clear()
            } label: {
                Label("Clear history", systemImage: "trash")
            }
        }
        .padding()
        .frame(width: 280)
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
