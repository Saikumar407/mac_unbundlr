import Foundation
import Combine
import Sparkle
import SwiftUI

/// Sparkle 2 auto-updater integration.
///
/// The `SPUStandardUpdaterController` is created eagerly and kept alive for the
/// entire process lifetime (Sparkle requires this). Its update feed, public
/// EdDSA key and check schedule all come from `Info.plist` — see the
/// `SUFeedURL`, `SUPublicEDKey` and `SUScheduledCheckInterval` entries — so we
/// deliberately pass `nil` delegates. This mirrors the recommended SwiftUI
/// pattern from Sparkle's own documentation.
///
/// If a future release needs callbacks (custom channel gating, feed switching,
/// etc.) introduce a nested class conforming to `SPUUpdaterDelegate` and pass
/// it via `updaterDelegate:` at construction time — **do not** try to set
/// `updater.delegate` after construction; Sparkle 2.9+ removed the setter.
final class UpdaterService: NSObject, ObservableObject {

    static let shared = UpdaterService()

    let controller: SPUStandardUpdaterController

    /// Mirrors `SPUUpdater.canCheckForUpdates` so SwiftUI views can bind to it.
    @Published private(set) var canCheckForUpdates: Bool = false

    private override init() {
        // Sparkle 2 API: delegates MUST be provided at construction. `self`
        // isn't available yet (super.init hasn't run), so we pass `nil` and
        // rely on Info.plist for configuration.
        self.controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        super.init()

        // Bridge Sparkle's KVO-compliant `canCheckForUpdates` into a
        // `@Published` so SwiftUI menu items can disable themselves during
        // an in-flight check.
        controller.updater
            .publisher(for: \.canCheckForUpdates)
            .receive(on: DispatchQueue.main)
            .assign(to: &$canCheckForUpdates)
    }

    /// Menu-item entry point — wired up in `ProfilePilotApp.commands`.
    @objc func checkForUpdates(_ sender: Any?) {
        controller.checkForUpdates(sender)
    }
}

// MARK: - SwiftUI menu item

/// Renders the "Check for Updates…" menu item and automatically disables it
/// while an update check is in flight.
struct CheckForUpdatesMenuItem: View {
    @ObservedObject private var service = UpdaterService.shared

    var body: some View {
        Button("Check for Updates…") {
            service.checkForUpdates(nil)
        }
        .disabled(!service.canCheckForUpdates)
    }
}
