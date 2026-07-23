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

## Zero-manual-steps release flow

Everything below is one command. The only inputs you supply are your Apple
Developer credentials (Apple ID, Team ID, app-specific password, Developer ID
certificate) — Apple physically requires these and no CI system can generate
them for you.

```bash
# ── one-time, on your Mac ──
git clone <this repo>
cd ProfilePilot

# 1. Install everything, generate Sparkle keys, patch Info.plist, generate icons
./scripts/bootstrap.sh

# 2. Fill in Apple values (edit the 4-line file it just created)
$EDITOR scripts/.env.local

# 3. Store notarytool credentials in the keychain (one time, survives reboots)
xcrun notarytool store-credentials "ProfilePilotNotary" \
  --apple-id     "you@icloud.com" \
  --team-id      "$DEVELOPMENT_TEAM" \
  --password     "abcd-efgh-ijkl-mnop"

# ── every release ──
export MARKETING_VERSION=0.1.0
./scripts/release.sh              # build → sign → notarise → DMG → ZIP → audit
git tag v$MARKETING_VERSION && git push --tags   # CI reruns everything and publishes
```

Not on a Mac yet? Run `./scripts/smoke-test.sh` — 30 checks that verify every
non-macOS artefact of the release pipeline. All 30 pass on Linux CI.

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
- ✅ `scripts/bootstrap.sh` — one-shot Mac environment setup.
- ✅ `scripts/dev-preview.sh` — **unsigned dev preview build** (`.app` + plain `.dmg`, no Apple Developer account required).
- ✅ `scripts/build.sh` · `sign.sh` · `notarize.sh` · `create-dmg.sh` · `package.sh` · `release.sh`
- ✅ `scripts/audit.sh` + `scripts/smoke-test.sh`
- ✅ GitHub Actions: [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) (build + test on every PR)
- ✅ GitHub Actions: [`.github/workflows/release.yml`](../.github/workflows/release.yml) (tag → signed release)

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

### Testing
- ✅ Unit tests: `ProfileDetectorTests` · `BundleFactoryTests` · `WorkspaceCodableTests`
- ✅ CI runs `xcodebuild test` on every PR
- ✅ Manual audit matrix in [`ARCHITECTURE.md §6`](./ARCHITECTURE.md#6-testing-strategy)

### Production audit
- ✅ `scripts/audit.sh` — end-to-end Mac audit (bundle, signing, hardened runtime, notarisation, universal binary, Sparkle feed, cold-start, idle RAM). Runs as the last step of `release.sh` and in CI.
- ✅ `scripts/smoke-test.sh` — Linux-runnable pre-flight (script syntax, plist/XML/YAML validity, icon generation, appiconset completeness). **30 checks green.**
- ✅ `scripts/bootstrap.sh` — one-shot Mac environment setup (brew tools, Sparkle keys, Info.plist patching, icon generation, `.env.local` scaffolding).

---

## Production audit checklist

`scripts/audit.sh` runs **every** check below automatically on a Mac and emits
`build/audit-report.txt`. It's chained into `scripts/release.sh` so a green
release automatically means a green audit. Run manually with:

```bash
./scripts/audit.sh                  # audits build/export/ProfilePilot.app
./scripts/audit.sh /Applications/ProfilePilot.app
```

Checks performed:

- Bundle structure (Info.plist, MacOS binary, PkgInfo, AppIcon.icns, `_CodeSignature`, `Sparkle.framework`)
- Info.plist keys (`CFBundleIdentifier`, `LSMinimumSystemVersion≥14.0`, `NSHighResolutionCapable`, `SUFeedURL`, `SUPublicEDKey` filled)
- Universal binary (both `x86_64` and `arm64` slices)
- Code signing (`codesign --verify --deep --strict`, Hardened Runtime, Developer ID authority, nested frameworks)
- Notarisation + Gatekeeper (`stapler validate`, `spctl -a --type execute`)
- Entitlements (App Sandbox disabled by design, Apple Events entitlement present)
- Sparkle appcast reachability (HTTP 200 on `SUFeedURL`)
- Runtime: cold-start under **800 ms**, idle RAM under **120 MB** (safety margins over the app's <100 ms / <50 MB budget)
- DMG: signed, notarised, stapled, mounts and detaches cleanly

Any red on `audit.sh` blocks the GitHub Release.

Pre-Mac smoke-test (Linux-runnable):

```bash
./scripts/smoke-test.sh   # 30 checks: script syntax, plist/XML/YAML validity, icons
```

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
