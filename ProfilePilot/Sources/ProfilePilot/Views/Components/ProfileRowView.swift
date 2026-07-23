import SwiftUI

/// A row that renders a single browser profile.
struct ProfileRowView: View {
    let profile: BrowserProfile
    let onLaunch: () -> Void

    var body: some View {
        Button(action: onLaunch) {
            HStack(spacing: 10) {
                Image(systemName: profile.browserKind.sfSymbol)
                    .foregroundStyle(.primary)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 1) {
                    Text(profile.displayName)
                        .font(.body)
                    if let email = profile.userEmail {
                        Text(email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(profile.directory)
                    .font(.caption.monospaced())
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
