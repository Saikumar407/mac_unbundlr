import SwiftUI
import AppKit

@main
struct ProfilePilotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appState = AppState.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environment(appState)
                .frame(width: 420, height: 560)
        } label: {
            Image(systemName: "sparkles.rectangle.stack")
                .accessibilityLabel("ProfilePilot")
        }
        .menuBarExtraStyle(.window)

        Window("ProfilePilot", id: "main") {
            MainWindowView()
                .environment(appState)
                .frame(minWidth: 900, minHeight: 620)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }

        Settings {
            SettingsView()
                .environment(appState)
                .frame(width: 560, height: 480)
        }
    }
}
