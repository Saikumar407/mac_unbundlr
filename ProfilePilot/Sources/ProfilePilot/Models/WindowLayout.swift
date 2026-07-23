import Foundation
import CoreGraphics

/// Snapshot of every currently-open window's frame across all displays.
/// Restored via the Accessibility API in `WindowLayoutManager`.
struct WindowLayout: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var name: String
    var capturedAtISO: String = ISO8601DateFormatter().string(from: Date())
    var entries: [Entry]

    struct Entry: Hashable, Codable {
        var appBundleID: String
        var windowTitle: String?
        var frame: CGRect
        var displayIndex: Int
    }
}
