# ProfilePilot — Roadmap

## Milestone 0.1 — "Profile Pilot" *(current)*

- Auto-detect Chrome, Edge, Brave, Chromium profiles.
- One-click launch via `NSWorkspace.openApplication` with `--profile-directory`.
- Menu-bar mode with `MenuBarExtra`.
- Per-profile Dock-icon wrapper generator ("Unbundle-style").
- Workspaces v1 — apps + URLs + shell commands + browser profile.
- Global hotkeys via Carbon.
- Persistence in `~/Library/Application Support/ProfilePilot/`.
- Companion web demo + AI Workspace endpoint.

## Milestone 0.2 — "Workspace Pro"

- Window Layout Memory (capture + restore) via Accessibility API.
- Session Restore on reboot.
- Import / export workspaces as JSON.
- Per-workspace environment variables + `.envrc` integration.
- Terminal profile targeting (iTerm2 tabs, Warp workspaces, Ghostty windows).

## Milestone 0.3 — "Design & Polish"

- Custom wrapper icon designer (drag an image, generate `.icns`).
- Rich profile metadata (color tag, description).
- Command palette (`⌘K`) inside the menu-bar popover.
- Sparkle auto-updater.
- Notarised, code-signed nightly builds.

## Milestone 0.4 — "Beyond Chromium"

- Arc profiles (via `~/Library/Application Support/Arc/User Data`).
- Firefox profiles (`profiles.ini`, `--P "profile name"`).
- Safari Profiles (macOS 14+, via `x-safari-profile:` URL scheme).

## Milestone 0.5 — "Team & Sync"

- Optional iCloud sync of workspaces (CloudKit).
- Shareable workspace URIs (`profilepilot://workspace?spec=…`).
- Team templates for onboarding (JSON in git).

## Milestone 1.0 — "GA"

- App Sandbox mode with security-scoped bookmarks for `~/Applications`.
- Full VoiceOver / accessibility audit.
- Localised to fr / de / ja / zh-Hant.
- App Store submission (subset of features that fit the sandbox).
- Optional paid Pro tier for AI Workspace, iCloud sync, team templates.

## Wishlist / research

- Deep integration with Raycast + Alfred (extensions).
- Docker Compose graph awareness (start dependent containers first).
- Kubernetes namespace-based workspaces.
- Vision Pro (`visionOS`) companion? — probably later.
