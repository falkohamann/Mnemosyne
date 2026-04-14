import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: NSPanel!
    let store = HistoryStore()
    private var monitor: ClipboardMonitor!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        monitor = ClipboardMonitor(store: store)
        monitor.start()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Mnemosyne")
            button.action = #selector(togglePanel)
            button.target = self
        }

        // NSNonactivatingPanelMask: panel appears without stealing focus from other apps
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 480),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.level = .popUpMenu
        panel.isMovable = false
        panel.hidesOnDeactivate = true
        panel.backgroundColor = NSColor.windowBackgroundColor
        panel.contentViewController = NSHostingController(rootView: MenubarView(store: store))
    }

    @objc func togglePanel() {
        guard let button = statusItem.button,
              let buttonWindow = button.window else { return }

        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            // Position panel below the status item button
            let buttonFrame = buttonWindow.convertToScreen(button.frame)
            let panelSize = panel.frame.size
            let origin = NSPoint(
                x: buttonFrame.midX - panelSize.width / 2,
                y: buttonFrame.minY - panelSize.height - 4
            )
            panel.setFrameOrigin(origin)
            panel.orderFrontRegardless()  // show without activating this app
        }
    }
}
