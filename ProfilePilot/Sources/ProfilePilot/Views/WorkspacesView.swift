import SwiftUI

struct WorkspacesView: View {
    @Environment(AppState.self) private var app
    @State private var editing: Workspace?
    @State private var showEditor: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Workspaces")
                        .font(.largeTitle.weight(.semibold))
                    Text("Bundles of apps, URLs, and shell commands.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    editing = Workspace(name: "New Workspace")
                    showEditor = true
                } label: {
                    Label("New Workspace", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            if app.workspaces.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(app.workspaces) { ws in
                        row(ws)
                    }
                    .onDelete { indexSet in
                        for i in indexSet { app.deleteWorkspace(app.workspaces[i].id) }
                    }
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            if let editing {
                WorkspaceEditorView(workspace: editing) { updated in
                    if app.workspaces.contains(where: { $0.id == updated.id }) {
                        app.updateWorkspace(updated)
                    } else {
                        app.addWorkspace(updated)
                    }
                    showEditor = false
                }
            }
        }
    }

    private func row(_ ws: Workspace) -> some View {
        HStack(spacing: 12) {
            Image(systemName: ws.symbol).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(ws.name).font(.headline)
                Text("\(ws.items.count) items")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
            Spacer()
            if let hk = ws.hotkey {
                KeyboardShortcutView(display: hk.display)
            }
            Button("Launch") { app.launch(ws) }
                .buttonStyle(.borderedProminent)
            Button("Edit") {
                editing = ws
                showEditor = true
            }
        }
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No workspaces yet")
                .font(.title3.weight(.semibold))
            Text("Create a workspace to launch your dev stack in one click.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
