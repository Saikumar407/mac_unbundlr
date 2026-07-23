# ProfilePilot

> The native macOS workspace manager that fixes multi-profile Chrome — and launches your entire dev stack in one click.

[![CI](https://github.com/YOURUSER/ProfilePilot/actions/workflows/ci.yml/badge.svg)](.github/workflows/ci.yml)
[![Release](https://github.com/YOURUSER/ProfilePilot/actions/workflows/release.yml/badge.svg)](.github/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-black.svg)](./LICENSE)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-black.svg)](./INSTALL.md)

**ProfilePilot** is a small, fast, offline-first SwiftUI + AppKit application for macOS 14+ that:

- Auto-detects every Google Chrome, Chrome Canary, Microsoft Edge, Brave, Chromium, Arc and Firefox profile installed on your Mac.
- Launches any profile with **one click, one hotkey, or one Spotlight-like command**.
- Creates optional **per-profile `.app` bundle wrappers** (Unbundle-style) so each Chrome profile gets its own Dock icon, its own Cmd+Tab identity, and its own window group — the way Windows already does.
- Defines **Workspaces**: reusable bundles of apps, URLs, shell commands and a browser profile that launch together (e.g. Laravel = Chrome/Work + VS Code + Terminal + `php artisan serve` + Docker Desktop + Postman + localhost + GitHub).
- **AI Workspace**: type `laravel`, `nextjs`, `data science`, etc. and let Claude Sonnet 4.5 draft the workspace plan for you (opt-in, uses your endpoint).
- Remembers **window layouts across displays** and restores them via the Accessibility API.
- Ships a **menu-bar mode** (SwiftUI `MenuBarExtra`) and global keyboard shortcuts (`⌥⌘1`, `⌥⌘L`, …).
- Auto-updates via **Sparkle 2** (EdDSA-signed).
- **~5 MB binary, <100 ms cold start, <50 MB idle RAM**, no Electron, no Node, no telemetry.

Full companion web landing/docs site under `/frontend` + `/backend`.

---

## Getting the app

| Path | Doc |
|---|---|
| Download the notarised `.dmg` from the Releases page | [`INSTALL.md`](./INSTALL.md) |
| `brew install --cask profilepilot` | [`INSTALL.md`](./INSTALL.md) |
| Build from source (Xcode 15+ on a Mac) | [`BUILD.md`](./BUILD.md) |

---

## Docs map

| File | Purpose |
|---|---|
| [`INSTALL.md`](./INSTALL.md) | How to get the app on your Mac. |
| [`BUILD.md`](./BUILD.md) | How to compile, sign, and run locally. |
| [`RELEASE.md`](./RELEASE.md) | Cutting a signed, notarised release + CI setup. |
| [`ARCHITECTURE.md`](./ARCHITECTURE.md) | Why the app exists, macOS capability matrix, module layout. |
| [`ROADMAP.md`](./ROADMAP.md) | What's next. |
| [`CHANGELOG.md`](./CHANGELOG.md) | User-visible history. |
| [`CONTRIBUTING.md`](./CONTRIBUTING.md) | How to contribute code. |
| [`Sparkle/README.md`](./Sparkle/README.md) | Auto-update setup. |
| [`dmg-assets/README.md`](./dmg-assets/README.md) | Regenerating the DMG background + volume icon. |

---

## Production release deliverables

Everything required to ship a real, signed, notarised, auto-updating macOS
application is in the repo:

### Native app
- ✅ SwiftUI + AppKit source (MVVM, ~15 Swift files)
- ✅ `Package.swift` (SPM)
- ✅ `project.yml` (XcodeGen → real `.xcodeproj`)
- ✅ Universal Binary (Intel + Apple Silicon) via `scripts/build.sh`
- ✅ Sparkle 2 integration for auto-updates

### Installers
- ✅ Production `.app`             — `scripts/build.sh`
- ✅ Production `.dmg` (fancy)     — `scripts/create-dmg.sh` + `dmg-assets/`
- ✅ Sparkle-ready `.zip` release  — `scripts/package.sh`
- ✅ Debug + Release configs       — `scripts/build.sh {debug,release}`

### Code-signing & notarisation
- ✅ Developer ID Application signing — `scripts/sign.sh` (with hardened runtime)
- ✅ Apple notarisation             — `scripts/notarize.sh` (uses `notarytool`)
- ✅ Stapled notarisation ticket    — via `xcrun stapler staple`
- ✅ Gatekeeper compatibility       — verified with `spctl` in `sign.sh`
- ✅ Insertion points for your Developer ID clearly marked in `scripts/.env.local.example`

### Auto updates
- ✅ Sparkle 2 via SwiftPM
- ✅ `appcast.xml` template
- ✅ Signed update ZIPs (EdDSA)
- ✅ CI-generated appcast entry (`build/appcast-entry.xml`)

### Build automation
- ✅ `scripts/build.sh` · `sign.sh` · `notarize.sh` · `create-dmg.sh` · `package.sh` · `release.sh`
- ✅ GitHub Actions: [`.github/workflows/ci.yml`](.github/workflows/ci.yml) (build + test on every PR)
- ✅ GitHub Actions: [`.github/workflows/release.yml`](.github/workflows/release.yml) (tag → signed release)

### Distribution
- ✅ GitHub Releases pipeline
- ✅ Homebrew Cask template — [`homebrew/profilepilot.rb`](./homebrew/profilepilot.rb)
- ✅ Direct download instructions in [`INSTALL.md`](./INSTALL.md)
- ⚠️ Mac App Store: **not** currently feasible — the per-profile wrapper generator
  writes to `~/Applications`, which is outside the App Sandbox. A sandboxed subset
  is a 1.0 target (see roadmap).

### Installer quality
- ✅ Custom icon slot (`Sources/ProfilePilot/Resources/Assets.xcassets/AppIcon.appiconset`)
- ✅ Beautiful DMG background (SVG source + rasterised PNG in `dmg-assets/`)
- ✅ Drag-to-Applications shortcut baked into `create-dmg.sh`
- ✅ Correct Finder window layout (620×400, icons at 160/460)

### Documentation
- ✅ `README.md` · `INSTALL.md` · `BUILD.md` · `RELEASE.md` · `CONTRIBUTING.md`
- ✅ `CHANGELOG.md` · `ARCHITECTURE.md` · `ROADMAP.md` · `LICENSE`

### Testing / production audit
- ✅ Unit tests: `ProfileDetectorTests` · `BundleFactoryTests` · `WorkspaceCodableTests`
- ✅ CI runs `xcodebuild test` on every PR
- ✅ Manual audit matrix in [`ARCHITECTURE.md §6`](./ARCHITECTURE.md#6-testing-strategy)
- 🟡 Runtime / memory / crash / permissions verification — **must** be executed on a real Mac. See the *Production audit checklist* section below.

---

## Production audit checklist

The following must be verified on a real Mac before shipping a public release.
They cannot be verified in a Linux CI container.

- [ ] `scripts/release.sh` completes without errors on a clean checkout.
- [ ] Fresh `.dmg` mounts, drag-installs, and launches from `/Applications`.
- [ ] `spctl -a -vvv --type execute /Applications/ProfilePilot.app` prints `accepted`.
- [ ] `codesign --verify --deep --strict --verbose=2 /Applications/ProfilePilot.app` prints `valid on disk / satisfies its Designated Requirement`.
- [ ] Idle RAM under **50 MB** (Activity Monitor → Memory).
- [ ] Cold start under **100 ms** (`time open -a ProfilePilot`).
- [ ] All installed browsers appear in the profiles list.
- [ ] Clicking a profile row launches the **correct** browser + profile.
- [ ] Right-click → **Create Dock App** produces a wrapper in `~/Applications/ProfilePilot/` that launches with its **own Dock icon** and **own Cmd+Tab entry**.
- [ ] Workspace with 5+ items launches every item in order.
- [ ] Global hotkey `⌥⌘1` (bound to a workspace) fires from any foreground app.
- [ ] Denying and later granting *Accessibility* permission does not crash the app; layout capture only works when granted.
- [ ] Sparkle "Check for Updates…" reaches the appcast URL and reports a valid state (up-to-date, or offers an update).
- [ ] Uninstall via `brew uninstall --cask profilepilot --zap` removes the app and its Application Support folder.

---

## Repository layout

```
ProfilePilot/
├── .github/workflows/          # CI + release pipelines
├── Package.swift               # SPM manifest (with Sparkle dep)
├── project.yml                 # XcodeGen manifest (with Sparkle dep)
├── appcast.xml                 # Sparkle appcast template
├── Sparkle/                    # Sparkle bin helpers + docs
├── Sources/ProfilePilot/       # App source (MVVM)
├── Tests/ProfilePilotTests/    # XCTest unit tests
├── scripts/                    # build · sign · notarize · dmg · release
├── dmg-assets/                 # DMG background (SVG + PNG), README
├── homebrew/profilepilot.rb    # Homebrew Cask
└── docs & release notes        # README, INSTALL, BUILD, RELEASE, …
```

---

## License

MIT — see [`LICENSE`](./LICENSE). Contributions welcome; start with
[`CONTRIBUTING.md`](./CONTRIBUTING.md).
