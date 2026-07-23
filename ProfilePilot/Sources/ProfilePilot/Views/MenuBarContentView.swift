import SwiftUI

/// Shown from the status-bar `MenuBarExtra`. Compact, fast, keyboard-friendly.
struct MenuBarContentView: View {
    @Environment(AppState.self) private var app
    @State private var query: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().opacity(0.4)
            searchField
            Divider().opacity(0.4)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !filteredWorkspaces.isEmpty {
                        sectionHeader("Workspaces", systemImage: "square.stack.3d.up.fill")
                        ForEach(filteredWorkspaces) { ws in
                            workspaceRow(ws)
                        }
                    }
                    sectionHeader("Profiles", systemImage: "person.crop.rectangle.stack.fill")
                    ForEach(groupedProfiles, id: \.0) { (browserName, items) in
                        Text(browserName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 12)
                        ForEach(items) { profile in
                            profileRow(profile)
                        }
                    }
                }
                .padding(.vertical, 12)
            }
            Divider().opacity(0.4)
            footer
        }
        .background(.background)
        .task(id: app.profiles.isEmpty) {
            if app.profiles.isEmpty {
                await app.refreshAll()
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .foregroundStyle(.primary)
            Text("ProfilePilot")
                .font(.headline)
            Spacer()
            Button {
                Task { await app.refreshAll() }
            } label: {
                Image(systemName: app.isRefreshing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Rescan browsers and profiles")
            SettingsLink {
                Image(systemName: "gear")
            }
            .buttonStyle(.borderless)
            .help("Preferences")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search profiles or workspaces…", text: $query)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button {
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
                if let win = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) {
                    win.makeKeyAndOrderFront(nil)
                } else {
                    NSWorkspace.shared.open(URL(string: "profilepilot://main")!)
                }
            } label: {
                Label("Open Window", systemImage: "macwindow")
            }
            .buttonStyle(.borderless)

            Spacer()

            Button(role: .destructive) {
                NSApp.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Rows

    private func workspaceRow(_ workspace: Workspace) -> some View {
        Button {
            app.launch(workspace)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: workspace.symbol)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(workspace.name).font(.body)
                    Text("\(workspace.items.count) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let hk = workspace.hotkey {
                    KeyboardShortcutView(display: hk.display)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    private func profileRow(_ profile: BrowserProfile) -> some View {
        ProfileRowView(profile: profile) {
            app.launch(profile)
        }
    }

    // MARK: - Filtering

    private var filteredWorkspaces: [Workspace] {
        if query.isEmpty { return app.workspaces }
        return app.workspaces.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private var filteredProfiles: [BrowserProfile] {
        if query.isEmpty { return app.profiles }
        return app.profiles.filter {
            $0.displayName.localizedCaseInsensitiveContains(query) ||
            $0.userEmail?.localizedCaseInsensitiveContains(query) == true
        }
    }

    private var groupedProfiles: [(String, [BrowserProfile])] {
        let grouped = Dictionary(grouping: filteredProfiles, by: { $0.browserKind.rawValue.capitalized })
        return grouped.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }
}
