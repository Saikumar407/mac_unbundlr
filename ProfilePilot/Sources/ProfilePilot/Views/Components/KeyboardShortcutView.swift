import SwiftUI

/// A pill-styled key-cap for showing keyboard shortcuts like ⌥⌘L.
struct KeyboardShortcutView: View {
    let display: String

    var body: some View {
        Text(display)
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.tertiary, in: .rect(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.secondary.opacity(0.3), lineWidth: 0.5)
            )
    }
}
