import Foundation
import Sparkle
import SwiftUI

/// Thin wrapper around Sparkle's standard updater controller so the rest of
/// the app can stay unaware of the SDK. Also exposes a small SwiftUI menu item.
final class UpdaterService: NSObject, SPUUpdaterDelegate {

    static let shared = UpdaterService()

    let controller: SPUStandardUpdaterController

    override init() {
        // startingUpdater: true schedules the first background check on launch.
        self.controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        super.init()
        self.controller.updater.delegate = self
    }

    /// Public entry point wired to the "Check for Updates…" menu item.
    @objc func checkForUpdates(_ sender: Any?) {
        controller.checkForUpdates(sender)
    }

    var canCheckForUpdates: Bool { controller.updater.canCheckForUpdates }

    // MARK: - SPUUpdaterDelegate

    func feedURLString(for updater: SPUUpdater) -> String? {
        // Prefer the value from Info.plist. Return nil to let Sparkle read
        // SUFeedURL itself.
        nil
    }

    func allowedChannels(for updater: SPUUpdater) -> Set<String> {
        // We could ship "beta" and "stable" channels; for now, one channel.
        []
    }
}

// MARK: - SwiftUI menu item

struct CheckForUpdatesMenuItem: View {
    @State private var canCheck: Bool = UpdaterService.shared.canCheckForUpdates
    var body: some View {
        Button("Check for Updates…") {
            UpdaterService.shared.checkForUpdates(nil)
        }
        .disabled(!canCheck)
        .onAppear { canCheck = UpdaterService.shared.canCheckForUpdates }
    }
}
