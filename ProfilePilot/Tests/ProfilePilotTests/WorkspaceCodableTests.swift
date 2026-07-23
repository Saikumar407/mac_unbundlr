import XCTest
@testable import ProfilePilot

final class WorkspaceCodableTests: XCTestCase {

    func test_workspace_roundtrips_via_json() throws {
        let ws = Workspace(
            name: "Laravel",
            symbol: "hammer.fill",
            hotkey: HotkeySpec(keyCode: 37, modifiers: 0, display: "⌥⌘L"),
            items: [
                .browserProfile(id: UUID(), profileKey: "com.google.Chrome::Profile 1"),
                .app(id: UUID(), appPath: "/Applications/Visual Studio Code.app"),
                .url(id: UUID(), url: "https://github.com", browserProfileKey: nil),
                .shell(id: UUID(), command: "php artisan serve", workingDirectory: "~/dev/laravel")
            ]
        )
        let data = try JSONEncoder().encode(ws)
        let decoded = try JSONDecoder().decode(Workspace.self, from: data)
        XCTAssertEqual(decoded.name, ws.name)
        XCTAssertEqual(decoded.items.count, ws.items.count)
    }
}
