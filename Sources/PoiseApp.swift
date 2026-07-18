import AppKit
import SwiftUI

@main
struct PoiseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store = PostureStore.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(store)
        } label: {
            HStack(spacing: 3) {
                Image(nsImage: MenuBarIcon.image(for: store))
                if store.showScoreInMenuBar,
                   store.connection == .tracking,
                   let score = store.displayScore {
                    Text("\(score)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    // Created eagerly so Sparkle's updater exists before launch finishes.
    private let updateService = UpdateService.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = PostureStore.shared
        store.startMonitoring()
        if !store.hasCompletedOnboarding {
            OnboardingWindowController.show()
        }
    }
}
