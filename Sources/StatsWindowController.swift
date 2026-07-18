import AppKit
import SwiftUI

@MainActor
final class StatsWindowController: NSWindowController, NSWindowDelegate {
    private static var shared: StatsWindowController?

    static func show() {
        if shared == nil {
            shared = StatsWindowController()
        }
        shared?.showWindow(nil)
    }

    private init() {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: CGSize(width: 560, height: 640)),
            styleMask: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        super.init(window: window)

        window.title = "Statistics"
        window.toolbarStyle = .automatic
        window.isMovableByWindowBackground = true
        window.setFrameAutosaveName("StatsWindow")
        window.minSize = NSSize(width: 480, height: 480)
        window.center()
        window.delegate = self
        window.contentViewController = NSHostingController(
            rootView: StatsView()
                .environment(PostureStore.shared)
                .environment(HistoryStore.shared)
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
        AppActivationPolicy.enter()
    }

    func windowWillClose(_ notification: Notification) {
        AppActivationPolicy.leave()
        Self.shared = nil
    }
}
