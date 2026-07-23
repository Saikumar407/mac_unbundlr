import Foundation

/// Parses each browser's on-disk profile database and returns typed
/// `BrowserProfile` values. Never modifies the source files.
struct ProfileDetector {

    /// Public entry point used by `AppState`.
    func profiles(for browser: Browser) -> [BrowserProfile] {
        switch browser.kind {
        case .chrome, .edge, .brave, .chromium, .arc:
            return chromiumProfiles(browser: browser)
        case .firefox:
            return firefoxProfiles(browser: browser)
        case .safari:
            return safariProfiles(browser: browser)
        }
    }

    // MARK: - Chromium family

    /// Chromium stores profile metadata in `<UserData>/Local State`, JSON with a
    /// `profile.info_cache.<dir>` map whose entries carry the human display name.
    private func chromiumProfiles(browser: Browser) -> [BrowserProfile] {
        let localStateURL = browser.userDataDirectory.appending(path: "Local State", directoryHint: .notDirectory)
        guard FileManager.default.isReadableFile(atPath: localStateURL.path()) else {
            return []
        }
        guard let data = try? Data(contentsOf: localStateURL),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let profile = root["profile"] as? [String: Any],
              let infoCache = profile["info_cache"] as? [String: [String: Any]] else {
            return []
        }
        return infoCache.map { (dir, info) -> BrowserProfile in
            let name = (info["name"] as? String) ?? dir
            let avatar = info["gaia_picture_file_name"] as? String
            let userEmail = info["user_name"] as? String
            let lastActive = (info["active_time"] as? Double).map { ts -> String in
                let d = Date(timeIntervalSince1970: ts)
                return ISO8601DateFormatter().string(from: d)
            }
            return BrowserProfile(
                id: UUID(uuidString: deterministicUUID(from: "\(browser.id)::\(dir)")) ?? UUID(),
                browserBundleID: browser.id,
                browserKind: browser.kind,
                directory: dir,
                displayName: name.isEmpty ? dir : name,
                avatarSlug: avatar,
                userEmail: userEmail,
                lastActiveISO: lastActive
            )
        }
    }

    // MARK: - Firefox

    private func firefoxProfiles(browser: Browser) -> [BrowserProfile] {
        let iniURL = browser.userDataDirectory
            .deletingLastPathComponent()
            .appending(path: "profiles.ini", directoryHint: .notDirectory)
        guard let text = try? String(contentsOf: iniURL, encoding: .utf8) else { return [] }
        var results: [BrowserProfile] = []
        var currentName: String?
        var currentPath: String?
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("[Profile") {
                if let name = currentName, let path = currentPath {
                    results.append(makeFirefoxProfile(name: name, path: path, browser: browser))
                }
                currentName = nil
                currentPath = nil
            } else if let value = trimmed.split(separator: "=", maxSplits: 1).last, trimmed.hasPrefix("Name=") {
                currentName = String(value)
            } else if let value = trimmed.split(separator: "=", maxSplits: 1).last, trimmed.hasPrefix("Path=") {
                currentPath = String(value)
            }
        }
        if let name = currentName, let path = currentPath {
            results.append(makeFirefoxProfile(name: name, path: path, browser: browser))
        }
        return results
    }

    private func makeFirefoxProfile(name: String, path: String, browser: Browser) -> BrowserProfile {
        BrowserProfile(
            id: UUID(uuidString: deterministicUUID(from: "\(browser.id)::\(path)")) ?? UUID(),
            browserBundleID: browser.id,
            browserKind: browser.kind,
            directory: name, // Firefox -P uses profile name, not path
            displayName: name,
            avatarSlug: nil,
            userEmail: nil,
            lastActiveISO: nil
        )
    }

    // MARK: - Safari (macOS 14+ Profiles)

    private func safariProfiles(browser: Browser) -> [BrowserProfile] {
        // Safari doesn't expose profiles via a public CLI. We surface a single
        // "Default" entry and treat other Profiles via the `x-safari-profile:` URL
        // scheme (Milestone 0.4).
        [BrowserProfile(
            id: UUID(uuidString: deterministicUUID(from: "\(browser.id)::Default")) ?? UUID(),
            browserBundleID: browser.id,
            browserKind: browser.kind,
            directory: "Default",
            displayName: "Safari",
            avatarSlug: nil,
            userEmail: nil,
            lastActiveISO: nil
        )]
    }

    // MARK: - Helpers

    /// Build a deterministic UUID string from any input, so profiles keep the
    /// same `id` across launches (nice for hotkey bindings).
    private func deterministicUUID(from input: String) -> String {
        let bytes = Array(input.utf8)
        var hash: [UInt8] = Array(repeating: 0, count: 16)
        for (i, b) in bytes.enumerated() {
            hash[i % 16] &+= b &+ UInt8(i & 0xff)
        }
        // Format as UUID string.
        let hex = hash.map { String(format: "%02x", $0) }.joined()
        return "\(hex.prefix(8))-\(hex.dropFirst(8).prefix(4))-\(hex.dropFirst(12).prefix(4))-\(hex.dropFirst(16).prefix(4))-\(hex.dropFirst(20).prefix(12))"
    }
}
