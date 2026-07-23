import SwiftUI

struct ProfileListView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Profiles")
                .font(.largeTitle.weight(.semibold))
                .padding(.horizontal, 24)
                .padding(.top, 20)
            Text("\(app.profiles.count) profiles across \(app.browsers.count) browsers")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            List {
                ForEach(app.browsers) { browser in
                    Section {
                        let profs = app.profiles.filter { $0.browserBundleID == browser.id }
                        if profs.isEmpty {
                            Text("No profiles detected.").foregroundStyle(.secondary)
                        }
                        ForEach(profs) { profile in
                            ProfileRowView(profile: profile) {
                                app.launch(profile)
                            }
                            .contextMenu {
                                Button("Launch") { app.launch(profile) }
                                Button("Create Dock App…") { createDockApp(for: profile, browser: browser) }
                            }
                        }
                    } header: {
                        HStack(spacing: 8) {
                            Image(systemName: browser.kind.sfSymbol)
                            Text(browser.displayName).font(.headline)
                        }
                    }
                }
            }
            .listStyle(.inset)
        }
    }

    private func createDockApp(for profile: BrowserProfile, browser: Browser) {
        do {
            let url = try app.bundleFactory.createWrapper(for: profile,
                                                          browserExecutableURL: browser.executableURL)
            NSWorkspace.shared.selectFile(url.path(), inFileViewerRootedAtPath: "")
        } catch {
            app.lastError = error.localizedDescription
        }
    }
}
