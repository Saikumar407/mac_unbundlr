import SwiftUI

struct MainWindowView: View {
    @Environment(AppState.self) private var app
    @State private var selection: MainTab = .profiles

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("ProfilePilot") {
                    Label("Profiles", systemImage: "person.crop.rectangle.stack")
                        .tag(MainTab.profiles)
                    Label("Workspaces", systemImage: "square.stack.3d.up")
                        .tag(MainTab.workspaces)
                    Label("AI Workspace", systemImage: "sparkles")
                        .tag(MainTab.ai)
                    Label("Settings", systemImage: "gearshape")
                        .tag(MainTab.settings)
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220)
        } detail: {
            Group {
                switch selection {
                case .profiles:   ProfileListView()
                case .workspaces: WorkspacesView()
                case .ai:         AIWorkspaceView()
                case .settings:   SettingsView()
                }
            }
        }
        .frame(minWidth: 900, minHeight: 620)
    }
}
