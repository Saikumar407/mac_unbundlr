import Foundation

struct BrowserProfile: Identifiable, Hashable, Codable {
    let id: UUID
    let browserBundleID: String        // com.google.Chrome
    let browserKind: Browser.Kind
    let directory: String              // "Default", "Profile 1", …
    let displayName: String            // "FG Designs"
    let avatarSlug: String?            // path fragment for chrome://theme/…
    let userEmail: String?
    let lastActiveISO: String?

    /// Stable identifier used to build wrapper bundle IDs, hotkey keys, etc.
    var stableKey: String {
        "\(browserBundleID)::\(directory)"
    }
}
