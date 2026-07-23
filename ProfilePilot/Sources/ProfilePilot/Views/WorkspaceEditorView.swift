import SwiftUI

struct WorkspaceEditorView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State var workspace: Workspace
    var onSave: (Workspace) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Workspace name", text: $workspace.name)
                    .font(.title2)
                    .textFieldStyle(.plain)
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") { onSave(workspace) }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            Form {
                Section("Appearance") {
                    TextField("SF Symbol", text: $workspace.symbol)
                }
                Section("Items") {
                    ForEach(workspace.items) { item in
                        HStack {
                            Image(systemName: item.sfSymbol).frame(width: 20)
                            Text(item.displayLabel).lineLimit(1)
                            Spacer()
                            Button {
                                workspace.items.removeAll { $0.id == item.id }
                            } label: { Image(systemName: "minus.circle") }
                            .buttonStyle(.borderless)
                        }
                    }
                    Menu("Add Item") {
                        Button("Browser Profile…") { addBrowserProfile() }
                        Button("Application…")     { addApp() }
                        Button("URL…")             { addURL() }
                        Button("Shell command…")   { addShell() }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 640, height: 520)
    }

    // MARK: - Adders

    private func addBrowserProfile() {
        if let first = app.profiles.first {
            workspace.items.append(.browserProfile(id: UUID(),
                                                    profileKey: first.stableKey,
                                                    delayMs: 200))
        }
    }
    private func addApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        if panel.runModal() == .OK, let url = panel.url {
            workspace.items.append(.app(id: UUID(), appPath: url.path(), delayMs: 200))
        }
    }
    private func addURL() {
        workspace.items.append(.url(id: UUID(),
                                    url: "https://",
                                    browserProfileKey: nil,
                                    delayMs: 200))
    }
    private func addShell() {
        workspace.items.append(.shell(id: UUID(),
                                       command: "echo hello",
                                       workingDirectory: nil,
                                       delayMs: 400))
    }
}
