import Foundation
import AppKit

/// Sequentially launches every item in a workspace, honouring per-item
/// delays and reporting the first error (if any) back to the caller.
final class WorkspaceLauncher {

    private let profileLauncher = ProfileLauncher()

    func launch(workspace: Workspace,
                profiles: [BrowserProfile],
                completion: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [profileLauncher] in
            for item in workspace.items {
                do {
                    try Self.executeItem(item, profiles: profiles, launcher: profileLauncher)
                } catch {
                    DispatchQueue.main.async { completion(error) }
                    return
                }
                let delay = Self.delayForItem(item)
                if delay > 0 {
                    Thread.sleep(forTimeInterval: TimeInterval(delay) / 1000.0)
                }
            }
            DispatchQueue.main.async { completion(nil) }
        }
    }

    // MARK: - Item execution

    private static func executeItem(_ item: WorkspaceItem,
                                    profiles: [BrowserProfile],
                                    launcher: ProfileLauncher) throws {
        switch item {

        case .browserProfile(_, let key, _):
            guard let profile = profiles.first(where: { $0.stableKey == key }) else {
                throw LauncherError.profileMissing(key)
            }
            try launcher.launch(profile: profile)

        case .app(_, let path, _):
            let url = URL(fileURLWithPath: path)
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            let sem = DispatchSemaphore(value: 0)
            var thrown: Error?
            NSWorkspace.shared.openApplication(at: url, configuration: config) { _, error in
                thrown = error
                sem.signal()
            }
            _ = sem.wait(timeout: .now() + 5)
            if let thrown { throw thrown }

        case .url(_, let raw, let profileKey, _):
            guard let url = URL(string: raw) else { throw LauncherError.badURL(raw) }
            if let key = profileKey,
               let profile = profiles.first(where: { $0.stableKey == key }) {
                try launcher.open(url: url, inProfile: profile)
            } else {
                NSWorkspace.shared.open(url)
            }

        case .shell(_, let command, let workingDirectory, _):
            let process = Process()
            process.launchPath = "/bin/bash"
            process.arguments = ["-lc", command]
            if let wd = workingDirectory, !wd.isEmpty {
                process.currentDirectoryURL = URL(fileURLWithPath: wd)
            }
            try process.run()
            // We deliberately do NOT wait — many workspace shell commands are long-lived servers.
        }
    }

    private static func delayForItem(_ item: WorkspaceItem) -> Int {
        switch item {
        case .browserProfile(_, _, let d),
             .app(_, _, let d),
             .url(_, _, _, let d),
             .shell(_, _, _, let d): return d
        }
    }

    enum LauncherError: LocalizedError {
        case profileMissing(String)
        case badURL(String)
        var errorDescription: String? {
            switch self {
            case .profileMissing(let k): return "Profile no longer exists: \(k)"
            case .badURL(let u):         return "Invalid URL: \(u)"
            }
        }
    }
}
