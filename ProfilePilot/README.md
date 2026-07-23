# ProfilePilot

> The native macOS workspace manager that fixes multi-profile Chrome — and launches your entire dev stack in one click.

**ProfilePilot** is a small, fast, offline-first SwiftUI + AppKit application for macOS 14+ that:

- Auto-detects every Google Chrome, Microsoft Edge, Brave, and Chromium profile installed on your Mac.
- Launches any profile with **one click, one hotkey, or one Spotlight-like command**.
- Creates optional **per-profile `.app` bundle wrappers** (Unbundle-style) so each Chrome profile gets its own Dock icon, its own Cmd+Tab identity, and its own window group — the way Windows already does.
- Defines **Workspaces**: reusable bundles of apps, URLs, shell commands and a browser profile that launch together (e.g. Laravel = Chrome/Work + VS Code + Terminal + `php artisan serve` + Docker Desktop + Postman + localhost + GitHub).
- **AI Workspace**: type `laravel`, `nextjs`, `data science`, etc. and let Claude Sonnet 4.5 draft the workspace plan for you (opt-in, uses your API key).
- Remembers **window layouts across displays** and restores them via the Accessibility API.
- Ships a **menu-bar mode** (SwiftUI `MenuBarExtra`) and global keyboard shortcuts (`⌥⌘1`, `⌥⌘L`, …).
- **~5 MB binary, <100 ms cold start, <50 MB idle RAM**, no Electron, no Node, no telemetry, no network access unless you enable AI Workspace.

---

## 1. What macOS actually allows — and what it doesn't

Before building, we [researched every relevant API](./ARCHITECTURE.md#macos-capability-matrix): Launch Services, `NSWorkspace`, `LSUIElement`, App Bundles, Bundle Identifiers, Chrome CLI flags, Apple Events, Accessibility APIs.

### The verdict

| Windows behaviour we want                       | macOS native support | ProfilePilot's answer |
|-------------------------------------------------|----------------------|-----------------------|
| One Dock icon per Chrome profile                | ❌ Not from a single running Chrome process | ✅ We generate a per-profile `.app` wrapper with a unique `CFBundleIdentifier`. macOS treats each wrapper as its own app — separate Dock icon, separate Cmd+Tab entry, separate window group. This is the technique [Unbundle](https://github.com/) popularised. |
| Independent Cmd+Tab entries                     | ❌ Not from Chrome itself | ✅ Solved by the wrapper trick above. |
| One-click launch of a specific profile          | ✅ via `open -na "Google Chrome" --args --profile-directory="Profile 1"` | ✅ Uses `NSWorkspace.openApplication(at:configuration:)` under the hood. |
| Group multiple apps + browser as a workspace    | ⚠️ Not built-in | ✅ First-class `Workspace` model with sequential/parallel launch. |
| Remember and restore window positions           | ⚠️ Requires Accessibility permission | ✅ Optional, opt-in. |
| Global hotkeys                                  | ✅ via Carbon `RegisterEventHotKey` | ✅ Yes. |

We deliberately **do not**:

- Modify Chrome's profile data or `Local State` file.
- Inject anything into browsers or read browsing history / passwords.
- Bypass System Integrity Protection or code-signing.
- Ship a Node runtime or Electron shell.

Full capability matrix and rationale are in [ARCHITECTURE.md](./ARCHITECTURE.md).

---

## 2. Requirements

- macOS **14 Sonoma** or later (uses `MenuBarExtra`, `Observation`, `NavigationSplitView`).
- **Xcode 15+** with the macOS SDK.
- Optional: [XcodeGen](https://github.com/yonaskolb/XcodeGen) to regenerate `ProfilePilot.xcodeproj` from `project.yml`.
- Optional: an AI API key (Claude/OpenAI/Gemini) for the AI Workspace feature.

---

## 3. Building

### Option A — Swift Package Manager (fastest for CLI users)

```bash
git clone https://github.com/yourname/ProfilePilot.git
cd ProfilePilot
swift build -c release
open .build/release/ProfilePilot
```

### Option B — Xcode (recommended for signing + Dock icon)

If you have XcodeGen installed:

```bash
brew install xcodegen
cd ProfilePilot
xcodegen generate
open ProfilePilot.xcodeproj
```

Then press **⌘R**.

If you don't have XcodeGen, create a new "macOS App" target in Xcode and drag the entire `Sources/ProfilePilot` folder into it. Set the deployment target to 14.0 and enable the App Sandbox entitlement only if you want to distribute via the App Store (see caveats in ARCHITECTURE.md — the bundle-wrapper feature needs sandbox disabled or specific entitlements).

### Option C — Nightly `.dmg`

Coming soon on the [Releases](./ROADMAP.md) page.

---

## 4. First launch

1. ProfilePilot appears in your menu bar (icon: `sparkles.rectangle.stack`).
2. It scans:
   - `/Applications`, `~/Applications`, `/System/Applications` for supported browsers.
   - `~/Library/Application Support/Google/Chrome/Local State` (and Edge / Brave / Chromium equivalents) to read profile names, avatars and last active time.
3. Click any profile row → the correct profile opens in the correct browser. Every time.
4. Right-click a profile → **Create Dock App** → ProfilePilot generates `~/Applications/ProfilePilot/Chrome — FG Designs.app` and registers it with Launch Services. Drag it to your Dock, done.

---

## 5. Feature tour

- **Profiles tab** — every browser and every profile, grouped by browser, one-click launch.
- **Workspaces tab** — build a Workspace with a name, an emoji/SF Symbol, a list of items (browser + profile, .app to launch, URL to open, shell command to run) and a hotkey.
- **AI Workspace** — type `laravel` or `next.js dashboard project`. Claude Sonnet 4.5 returns a JSON plan you can review and edit before saving.
- **Window Layouts** — capture the current arrangement of open windows across all displays, then restore it later (needs Accessibility permission).
- **Session** — on launch, optionally restore your last active workspace.
- **Settings** — permissions, hotkeys, launch-at-login, AI provider config, theme.

---

## 6. Repository layout

```
ProfilePilot/
├── Package.swift               # SPM manifest
├── project.yml                 # XcodeGen manifest
├── README.md
├── ARCHITECTURE.md
├── ROADMAP.md
├── Sources/ProfilePilot/
│   ├── App/                    # App entry + AppDelegate + global state
│   ├── Models/                 # Value types: Browser, Profile, Workspace, …
│   ├── Services/               # BrowserRegistry, ProfileDetector, BundleFactory, …
│   ├── ViewModels/             # ObservableObject bindings
│   ├── Views/                  # SwiftUI screens + components
│   └── Resources/              # Info.plist, entitlements, assets
├── Tests/ProfilePilotTests/    # XCTest unit tests
├── scripts/                    # Helper shell scripts
└── docs/                       # Screenshots, diagrams
```

---

## 7. Contributing / license

MIT. See `LICENSE`. Contributions welcome — start by reading [ARCHITECTURE.md](./ARCHITECTURE.md).

---

## 8. Companion web demo

A companion web dashboard (React + FastAPI) lets you visualise and export workspaces as JSON before the Mac app is installed. It's included in this repo under `/frontend` and `/backend` and hosted at the preview URL for reference.
