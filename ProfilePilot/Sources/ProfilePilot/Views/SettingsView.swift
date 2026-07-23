import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var app
    @State private var endpointURL: String = ""
    @State private var authHeader: String = ""

    var body: some View {
        TabView {
            general.tabItem { Label("General", systemImage: "gear") }
            ai.tabItem { Label("AI", systemImage: "sparkles") }
            permissions.tabItem { Label("Permissions", systemImage: "lock.shield") }
            about.tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 540, height: 420)
        .onAppear {
            endpointURL = app.ai.endpoint?.url.absoluteString ?? ""
            authHeader = app.ai.endpoint?.authHeader ?? ""
        }
    }

    private var general: some View {
        Form {
            Section("Startup") {
                Toggle("Launch ProfilePilot at login", isOn: .constant(false))
                Toggle("Restore last workspace on launch", isOn: .constant(false))
            }
            Section("Refresh") {
                Button("Rescan browsers & profiles") {
                    Task { await app.refreshAll() }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var ai: some View {
        Form {
            Section("AI Workspace endpoint") {
                TextField("https://your-companion/api/ai-workspace", text: $endpointURL)
                TextField("Authorization header (optional)", text: $authHeader)
                Button("Save") {
                    if let u = URL(string: endpointURL), !endpointURL.isEmpty {
                        app.ai.endpoint = .init(url: u,
                                                authHeader: authHeader.isEmpty ? nil : authHeader)
                    } else {
                        app.ai.endpoint = nil
                    }
                }
            }
            Text("ProfilePilot never sends your profile data to any endpoint — only the free-text prompt you type.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }

    private var permissions: some View {
        Form {
            Section("Accessibility") {
                LabeledContent("Status") {
                    Text(app.layoutManager.isTrusted ? "Granted" : "Not granted")
                        .foregroundStyle(app.layoutManager.isTrusted ? .green : .orange)
                }
                Button("Request Accessibility access") {
                    _ = app.layoutManager.requestTrust()
                }
                Text("Only used for optional Window Layout Memory.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var about: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles.rectangle.stack.fill").font(.system(size: 48))
            Text("ProfilePilot").font(.title.weight(.semibold))
            Text("v0.1 · MIT").font(.caption).foregroundStyle(.secondary)
            Text("Native macOS workspace + browser-profile launcher.\n No telemetry. No cloud. No tracking.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
