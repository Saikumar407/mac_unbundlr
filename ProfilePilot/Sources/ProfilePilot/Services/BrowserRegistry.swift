import Foundation
import AppKit

/// Discovers installed browsers on the current machine via Launch Services.
struct BrowserRegistry {

    /// Ordered list of every browser we know about, filtered to those actually installed.
    func installedBrowsers() -> [Browser] {
        candidates.compactMap { candidate in
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: candidate.bundleID) else {
                return nil
            }
            return Browser(
                id: candidate.bundleID,
                kind: candidate.kind,
                displayName: candidate.displayName,
                executableURL: url,
                userDataDirectory: candidate.userDataDirectory()
            )
        }
    }

    // MARK: - Candidate table

    private struct Candidate {
        let bundleID: String
        let kind: Browser.Kind
        let displayName: String
        let userDataSubpath: String
        func userDataDirectory() -> URL {
            let home = FileManager.default.homeDirectoryForCurrentUser
            return home.appending(path: "Library/Application Support/\(userDataSubpath)", directoryHint: .isDirectory)
        }
    }

    private let candidates: [Candidate] = [
        .init(bundleID: "com.google.Chrome",
              kind: .chrome,
              displayName: "Google Chrome",
              userDataSubpath: "Google/Chrome"),
        .init(bundleID: "com.google.Chrome.canary",
              kind: .chrome,
              displayName: "Google Chrome Canary",
              userDataSubpath: "Google/Chrome Canary"),
        .init(bundleID: "com.microsoft.edgemac",
              kind: .edge,
              displayName: "Microsoft Edge",
              userDataSubpath: "Microsoft Edge"),
        .init(bundleID: "com.brave.Browser",
              kind: .brave,
              displayName: "Brave Browser",
              userDataSubpath: "BraveSoftware/Brave-Browser"),
        .init(bundleID: "org.chromium.Chromium",
              kind: .chromium,
              displayName: "Chromium",
              userDataSubpath: "Chromium"),
        .init(bundleID: "company.thebrowser.Browser",
              kind: .arc,
              displayName: "Arc",
              userDataSubpath: "Arc/User Data"),
        .init(bundleID: "org.mozilla.firefox",
              kind: .firefox,
              displayName: "Firefox",
              userDataSubpath: "Firefox/Profiles"),
        .init(bundleID: "com.apple.Safari",
              kind: .safari,
              displayName: "Safari",
              userDataSubpath: "Safari")
    ]
}
