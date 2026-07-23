import Foundation

/// Persists user data (workspaces, recent launches, layouts) as JSON in
/// `~/Library/Application Support/ProfilePilot/`.
final class PersistenceService {

    struct Snapshot: Codable {
        var workspaces: [Workspace]
        var recentLaunches: [UUID]
        var layouts: [WindowLayout]
    }

    private var rootURL: URL {
        let base = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = (base ?? FileManager.default.homeDirectoryForCurrentUser
                    .appending(path: "Library/Application Support"))
            .appending(path: "ProfilePilot", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private var storeURL: URL { rootURL.appending(path: "state.json") }

    func loadAll() -> Snapshot {
        guard let data = try? Data(contentsOf: storeURL),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else {
            return .init(workspaces: [], recentLaunches: [], layouts: [])
        }
        return snap
    }

    func saveAll(state: AppState) {
        let snap = Snapshot(
            workspaces: state.workspaces,
            recentLaunches: state.recentLaunches,
            layouts: [] // wired in 0.2
        )
        do {
            let data = try JSONEncoder().encode(snap)
            try data.write(to: storeURL, options: [.atomic])
        } catch {
            // Non-fatal — surface via lastError elsewhere if needed.
        }
    }
}
