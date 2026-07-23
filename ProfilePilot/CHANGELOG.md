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
- Sparkle 2 auto-update integration (EdDSA-signed) with appcast template.
- Full production tooling: XcodeGen manifest, universal-binary build,
  Developer-ID sign / notarise / DMG / ZIP scripts, GitHub Actions CI + release
  pipeline, Homebrew Cask, DMG background artwork.
- Companion web landing page (React + FastAPI) with live AI Workspace demo.
- Docs: README, ARCHITECTURE, INSTALL, BUILD, RELEASE, ROADMAP, CONTRIBUTING.

### Known limitations
- macOS cannot give a single running Chrome process multiple Dock identities;
  that's why we generate wrapper `.app`s. Without wrappers, the classic macOS
  fused-Dock-icon behaviour persists — this is a macOS design, not a bug.
- Wrapper icons currently reuse a default `.icns`. Milestone 0.3 will build a
  per-profile `.icns` from the Chrome profile avatar via `sips` + `iconutil`.
- App Sandbox is disabled because wrapper generation writes to `~/Applications`.
  A sandboxed variant with a security-scoped bookmark is planned for 1.0.

[Unreleased]: https://github.com/YOURUSER/ProfilePilot/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/YOURUSER/ProfilePilot/releases/tag/v0.1.0
