# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] — 2026-01-23

### Added
- Menu-bar first native macOS app (SwiftUI `MenuBarExtra`, no Electron).
- Automatic profile detection for Google Chrome, Chrome Canary, Microsoft Edge,
  Brave, Chromium, Arc and Firefox by parsing each browser's on-disk
  `Local State` / `profiles.ini` file — never modifies the source data.
- One-click profile launch via `NSWorkspace.openApplication(at:configuration:)`
  with the correct `--profile-directory` / `-P` argument per browser family.
- **Per-profile `.app` wrapper generator** (Unbundle-style) that creates a tiny
  bundle in `~/Applications/ProfilePilot/` with a unique `CFBundleIdentifier`
  and registers it with Launch Services — giving each Chrome profile its own
  Dock icon and Cmd+Tab entry.
- Workspaces model (browser profile + apps + URLs + shell commands) with
  per-item delays and sequential launch.
- Global keyboard shortcuts via Carbon `RegisterEventHotKey`.
- Window Layout Manager (opt-in Accessibility permission).
- AI Workspace: type a stack name, get an editable workspace plan drafted by
  a configurable LLM endpoint (Claude Sonnet 4.5 in the reference companion).
- JSON persistence in `~/Library/Application Support/ProfilePilot/`.
- Unit tests for `ProfileDetector`, `BundleFactory`, `Workspace` codable.
- Sparkle 2 auto-update integration (EdDSA-signed) with appcast template and
  `UpdaterService` + "Check for Updates…" menu item.

### Release automation
- Fully-automated icon pipeline: `dmg-assets/AppIcon.svg` renders via
  `scripts/generate_icons.py` into all 10 `AppIcon.appiconset` PNGs plus
  `AppIcon.icns` and `VolumeIcon.icns`.
- `scripts/bootstrap.sh` installs every macOS build tool, generates the Sparkle
  key-pair once (private key stays in the login keychain), patches the public
  key into `Info.plist`, and creates `scripts/.env.local` from the template.
- `scripts/release.sh` — one-command orchestrator (build → sign → notarise → DMG → ZIP → appcast → audit).
- `scripts/audit.sh` — automated production audit: bundle structure, plist keys,
  universal binary, codesign, hardened runtime, notarisation, entitlements,
  Sparkle feed reachability, cold-start timing, idle RAM. Emits `build/audit-report.txt`.
- `scripts/smoke-test.sh` — Linux-runnable pre-flight checks (script syntax,
  plist/XML/YAML validity, icon generation, appiconset completeness).
- `ExportOptions.plist.template` with team-ID templating.
- GitHub Actions workflows at repo root: `ci.yml` (build + XCTest on every PR)
  and `release.yml` (tag → sign → notarise → DMG → ZIP → GH Release with audit
  report attached). Seven documented secrets.
- Homebrew Cask template `homebrew/profilepilot.rb` with `zap` cleanup.

### Documentation
- `README.md` (with production-audit checklist and monorepo overview),
  `INSTALL.md`, `BUILD.md`, `RELEASE.md`, `CONTRIBUTING.md`, `ARCHITECTURE.md`,
  `ROADMAP.md`, `CHANGELOG.md`, `LICENSE`.

### Known limitations
- macOS cannot give a single running Chrome process multiple Dock identities;
  that's why we generate wrapper `.app`s. Without wrappers, the classic macOS
  fused-Dock-icon behaviour persists — this is a macOS design, not a bug.
- App Sandbox is disabled because wrapper generation writes to `~/Applications`.
  A sandboxed variant with a security-scoped bookmark is planned for 1.0.
- Apple code-signing and notarisation must be executed on a Mac with a valid
  Developer ID certificate — every other step of the release is fully automated.

[Unreleased]: https://github.com/YOURUSER/ProfilePilot/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/YOURUSER/ProfilePilot/releases/tag/v0.1.0
