import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: NSPanel!
    let store = HistoryStore()
    private var monitor: ClipboardMonitor!
    private var eventMonitor: Any?

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

        let hostingController = NSHostingController(rootView: MenubarView(store: store))
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 320, height: 480)

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 480),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.level = .popUpMenu
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.contentViewController = hostingController
    }

    @objc func togglePanel() {
        guard let button = statusItem.button else { return }

        if panel.isVisible {
            panel.orderOut(nil)
            if let m = eventMonitor { NSEvent.removeMonitor(m); eventMonitor = nil }
            return
        }

        let buttonFrame: NSRect
        if let buttonWindow = button.window {
            buttonFrame = buttonWindow.convertToScreen(button.frame)
        } else {
            let screen = NSScreen.main ?? NSScreen.screens[0]
            buttonFrame = NSRect(x: screen.visibleFrame.maxX - 160, y: screen.visibleFrame.maxY, width: 0, height: 0)
        }

        let panelSize = panel.frame.size
        let origin = NSPoint(
            x: buttonFrame.midX - panelSize.width / 2,
            y: buttonFrame.minY - panelSize.height - 4
        )
        panel.setFrameOrigin(origin)
        panel.orderFrontRegardless()

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.panel.orderOut(nil)
            if let m = self?.eventMonitor { NSEvent.removeMonitor(m); self?.eventMonitor = nil }
        }
    }
}
