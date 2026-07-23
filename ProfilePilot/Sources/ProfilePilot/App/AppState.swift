import Foundation
import Observation

/// Global, observable app state. All services are lazily instantiated here so
/// views can inject them via `@Environment`.
@Observable
final class AppState {
    static let shared = AppState()

    // MARK: - Domain state
    var browsers: [Browser] = []
    var profiles: [BrowserProfile] = []
    var workspaces: [Workspace] = []
    var recentLaunches: [UUID] = []

    // MARK: - UI state
    var selectedTab: MainTab = .profiles
    var isRefreshing: Bool = false
    var lastError: String?

    // MARK: - Services
    let registry = BrowserRegistry()
    let detector = ProfileDetector()
    let launcher = ProfileLauncher()
    let bundleFactory = BundleFactory()
    let workspaceLauncher = WorkspaceLauncher()
    let layoutManager = WindowLayoutManager()
    let hotkeys = HotkeyManager()
    let ai = AIWorkspaceService()
    let persistence = PersistenceService()

    private init() {
        let snapshot = persistence.loadAll()
        self.workspaces = snapshot.workspaces
        self.recentLaunches = snapshot.recentLaunches
    }

    // MARK: - Refresh
    @MainActor
    func refreshAll() async {
        isRefreshing = true
        defer { isRefreshing = false }

        let installed = registry.installedBrowsers()
        self.browsers = installed

        var collected: [BrowserProfile] = []
        for browser in installed {
            collected.append(contentsOf: detector.profiles(for: browser))
        }
        self.profiles = collected.sorted { $0.displayName < $1.displayName }
    }

    // MARK: - Actions
    @MainActor
    func launch(_ profile: BrowserProfile) {
        do {
            try launcher.launch(profile: profile)
            recentLaunches.insert(profile.id, at: 0)
            recentLaunches = Array(recentLaunches.prefix(8))
            persistence.saveAll(state: self)
        } catch {
            lastError = error.localizedDescription
        }
    }

    @MainActor
    func launch(_ workspace: Workspace) {
        workspaceLauncher.launch(workspace: workspace, profiles: profiles) { [weak self] error in
            if let error { self?.lastError = error.localizedDescription }
        }
    }

    @MainActor
    func addWorkspace(_ workspace: Workspace) {
        workspaces.append(workspace)
        persistence.saveAll(state: self)
        hotkeys.rebindAll(from: workspaces)
    }

    @MainActor
    func updateWorkspace(_ workspace: Workspace) {
        guard let idx = workspaces.firstIndex(where: { $0.id == workspace.id }) else { return }
        workspaces[idx] = workspace
        persistence.saveAll(state: self)
        hotkeys.rebindAll(from: workspaces)
    }

    @MainActor
    func deleteWorkspace(_ id: UUID) {
        workspaces.removeAll { $0.id == id }
        persistence.saveAll(state: self)
        hotkeys.rebindAll(from: workspaces)
    }
}

enum MainTab: String, CaseIterable, Identifiable {
    case profiles, workspaces, ai, settings
    var id: String { rawValue }
}
