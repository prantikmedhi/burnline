import AppKit
import QuartzCore
import SwiftUI

@main
struct BurnlineApp: App {
    @NSApplicationDelegateAdaptor(BurnlineAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

@MainActor
final class BurnlineAppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private let store = UsageStore()
    private let popover = NSPopover()
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item

        if let button = item.button {
            button.image = menuBarIcon()
            button.imagePosition = .imageOnly
            button.imageScaling = .scaleProportionallyDown
            button.target = self
            button.action = #selector(togglePopover(_:))
            button.toolTip = "Burnline"
            button.setAccessibilityLabel("Burnline usage monitor")
            button.wantsLayer = true
        }

        let controller = NSHostingController(rootView: DashboardView(store: store))
        popover.contentViewController = controller
        popover.contentSize = NSSize(width: 388, height: 600)
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        animatePress(sender)
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        }
    }

    private func menuBarIcon() -> NSImage? {
        if let url = Bundle.main.url(forResource: "Burnline", withExtension: "icns"),
           let icon = NSImage(contentsOf: url) {
            icon.size = NSSize(width: 18, height: 18)
            icon.isTemplate = false
            return icon
        }

        let fallback = NSImage(
            systemSymbolName: "waveform.path.ecg.rectangle.fill",
            accessibilityDescription: "Burnline"
        )
        fallback?.isTemplate = true
        return fallback
    }

    private func animatePress(_ button: NSStatusBarButton) {
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }
        let pulse = CAKeyframeAnimation(keyPath: "transform.scale")
        pulse.values = [1.0, 0.86, 1.0]
        pulse.keyTimes = [0, 0.42, 1]
        pulse.duration = 0.22
        pulse.timingFunction = CAMediaTimingFunction(name: .easeOut)
        button.layer?.add(pulse, forKey: "burnline.press")
    }
}
