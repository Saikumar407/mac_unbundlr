import Foundation

/// A reusable bundle of "things to launch". Order matters because some items
/// (e.g. a shell command that starts `docker`) must run before others.
struct Workspace: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var name: String
    var symbol: String = "square.stack.3d.up"        // SF Symbol
    var accentHex: String = "#FFFFFF"
    var hotkey: HotkeySpec?                          // ⌥⌘L etc.
    var items: [WorkspaceItem] = []
    var restoreWindowLayout: Bool = false
    var linkedLayoutID: UUID?                        // resolves to WindowLayout
    var createdAtISO: String = ISO8601DateFormatter().string(from: Date())
}

struct HotkeySpec: Hashable, Codable {
    /// Carbon key code (kVK_ANSI_L etc.)
    var keyCode: UInt32
    /// Bitmask of Carbon modifier flags (cmdKey | optionKey | …)
    var modifiers: UInt32
    /// Human-readable representation e.g. "⌥⌘L"
    var display: String
}
