import Foundation
import AppKit

/// Launches a specific browser profile using `NSWorkspace.openApplication`
/// with the right CLI flag for that browser family.
struct ProfileLauncher {

    enum LaunchError: LocalizedError {
        case browserNotFound(String)
        case underlying(Error)
        var errorDescription: String? {
            switch self {
            case .browserNotFound(let name): return "Could not find \(name). Is it installed?"
            case .underlying(let e): return e.localizedDescription
            }
        }
    }

    /// Launch the given profile in the correct browser.
    /// Uses `createsNewApplicationInstance = true` so the launched process
    /// is a separate `NSApplication` instance — this is what allows the
    /// per-profile wrapper trick to give each profile its own Dock icon.
    func launch(profile: BrowserProfile,
                extraArguments: [String] = [],
                newInstance: Bool = false) throws {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: profile.browserBundleID) else {
            throw LaunchError.browserNotFound(profile.browserBundleID)
        }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        config.createsNewApplicationInstance = newInstance
        config.arguments = argumentsFor(profile: profile) + extraArguments

        let semaphore = DispatchSemaphore(value: 0)
        var thrown: Error?
        NSWorkspace.shared.openApplication(at: appURL, configuration: config) { _, error in
            if let error { thrown = error }
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 5)
        if let thrown { throw LaunchError.underlying(thrown) }
    }

    /// Open a specific URL inside a specific browser profile.
    func open(url: URL, inProfile profile: BrowserProfile) throws {
        try launch(profile: profile, extraArguments: [url.absoluteString])
    }

    // MARK: - Argument construction

    private func argumentsFor(profile: BrowserProfile) -> [String] {
        switch profile.browserKind {
        case .chrome, .edge, .brave, .chromium, .arc:
            return ["--profile-directory=\(profile.directory)"]
        case .firefox:
            return ["-P", profile.directory, "-no-remote"]
        case .safari:
            return []
        }
    }
}
