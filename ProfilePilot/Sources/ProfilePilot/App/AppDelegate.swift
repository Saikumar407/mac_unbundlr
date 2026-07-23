import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Kick off an async detection pass so the menu-bar popover has data
        // the moment the user first clicks it.
        Task.detached(priority: .userInitiated) {
            await AppState.shared.refreshAll()
        }

        // Register any hotkeys the user has previously configured.
        AppState.shared.hotkeys.rebindAll(from: AppState.shared.workspaces)
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppState.shared.hotkeys.unbindAll()
        AppState.shared.persistence.saveAll(state: AppState.shared)
    }

    // Keep the app alive when the last window is closed — the menu bar is the primary UI.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
