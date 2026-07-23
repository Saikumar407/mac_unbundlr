import Foundation

/// A Chromium-family (and later Firefox / Safari / Arc) browser that we can
/// enumerate profiles for and launch.
struct Browser: Identifiable, Hashable, Codable {
    let id: String                // bundle identifier
    let kind: Kind
    let displayName: String       // "Google Chrome", "Microsoft Edge", …
    let executableURL: URL        // /Applications/Google Chrome.app
    let userDataDirectory: URL    // ~/Library/Application Support/…

    enum Kind: String, Codable, CaseIterable {
        case chrome, edge, brave, chromium, arc, firefox, safari

        var sfSymbol: String {
            switch self {
            case .chrome:   return "globe"
            case .edge:     return "globe.europe.africa"
            case .brave:    return "shield.lefthalf.filled"
            case .chromium: return "globe.badge.chevron.backward"
            case .arc:      return "arc.browser"           // custom asset fallback in ui
            case .firefox:  return "flame"
            case .safari:   return "safari"
            }
        }

        var supportsMultipleProfiles: Bool {
            switch self {
            case .chrome, .edge, .brave, .chromium, .arc, .firefox: return true
            case .safari: return false // Safari Profiles exist macOS 14+ but launch model differs
            }
        }

        /// The command-line flag used to select a profile at launch.
        var profileArgumentName: String {
            switch self {
            case .chrome, .edge, .brave, .chromium: return "--profile-directory"
            case .firefox:                          return "-P"
            case .arc:                              return "--profile-directory"
            case .safari:                           return ""
            }
        }
    }
}
