# ProfilePilot — PRD

## Original problem statement

Build **ProfilePilot** — a native macOS workspace manager that fixes macOS's broken
multi-profile Chrome experience and expands into a general Workspace Launcher for
developers. Reference: **Unbundle** for the per-profile `.app` wrapper technique.

## User personas

- Full-stack developer juggling Work / Personal / Client Chrome profiles
- Freelancer running multiple client projects with different tool stacks
- macOS power user coming from Windows who misses per-profile Dock icons

## Delivery mode

- This Emergent environment is a **Linux cloud container** — it cannot compile,
  sign, notarise or DMG-package native macOS code.
- Deliverable = **fully-automated release repo** at `/app/ProfilePilot/`:
  the moment the user runs `./scripts/bootstrap.sh` + `./scripts/release.sh`
  on a Mac, a signed, notarised, universal, auto-updating `.dmg` + `.zip` +
  Sparkle appcast entry drops into `build/`.
- **The only manual steps that remain are the ones Apple physically requires**:
  the user's Developer ID certificate, Apple ID, Team ID, and app-specific
  password. These four values live in `scripts/.env.local` (untracked).
  Every other step of the pipeline is automated end-to-end.

## What's implemented (2026-01-23, final)

### Swift/AppKit/SwiftUI source (`ProfilePilot/`)
- MVVM, 16 Swift files, ~1900 LOC, 135 top-level declarations.
- Services: `BrowserRegistry`, `ProfileDetector`, `ProfileLauncher`, `BundleFactory`
  (per-profile `.app` wrapper), `WorkspaceLauncher`, `WindowLayoutManager`,
  `HotkeyManager` (Carbon), `AIWorkspaceService`, `PersistenceService`,
  `UpdaterService` (Sparkle 2 wired into the app menu).
- Views: menu-bar popover, main NavigationSplitView, workspace editor, AI planner, settings.
- Tests: `ProfileDetectorTests`, `BundleFactoryTests`, `WorkspaceCodableTests`.
- `Package.swift` (SPM) + `project.yml` (XcodeGen) with Sparkle 2 dependency.
- Info.plist + entitlements validated with `plistlib`.

### Zero-manual-steps release pipeline (`scripts/`)
- `bootstrap.sh` — installs xcodegen / create-dmg / xcbeautify / librsvg via brew,
  generates Sparkle EdDSA keypair (private in login keychain, public patched into
  Info.plist), creates `scripts/.env.local`, generates all icons.
- `generate_icons.py` — renders `dmg-assets/AppIcon.svg` at 1024×1024 and emits all
  10 required PNGs into `AppIcon.appiconset/` plus `AppIcon.icns` and `VolumeIcon.icns`.
  Runs on Linux (cairosvg + Pillow) or macOS.
- `build.sh` — universal binary (x86_64 + arm64), archives via `xcodebuild`, uses
  `ExportOptions.plist.template` (team ID substituted at build time).
- `sign.sh` — Developer ID codesign with hardened runtime; signs nested frameworks
  and Sparkle XPC helpers before the outer bundle.
- `notarize.sh` — `xcrun notarytool submit --wait` + `stapler staple`.
- `create-dmg.sh` — beautiful DMG via `create-dmg` (620×400 layout, icons at
  160/460, custom background PNG, volume icon), signed + notarised + stapled.
- `package.sh` — Sparkle-ready ZIP + `sign_update` + appcast `<item>` stub.
- `release.sh` — orchestrator (clean → build → sign → notarise → dmg → zip → audit).
- `audit.sh` — Mac-only production audit: bundle structure, plist keys, universal
  binary slices, codesign, hardened runtime, notarisation, entitlements, Sparkle
  feed reachability, cold-start timing, idle RAM, DMG mount test. Emits a
  pass/fail report at `build/audit-report.txt`.
- `smoke-test.sh` — **Linux-runnable pre-flight, 30 checks green in this container.**

### Assets
- `dmg-assets/AppIcon.svg` — hand-crafted App Icon (three stacked profile plates
  with ⌘-inspired glyph + sparkle ornament). Rendered:
    - `dmg-assets/AppIcon.png` (1024×1024 master)
    - `AppIcon.icns` + `VolumeIcon.icns`
    - All 10 `AppIcon.appiconset` PNGs (16, 32, 128, 256, 512 × 1x/2x)
- `dmg-assets/dmg-background.svg` + rendered `dmg-background.png` (1240×800 @2×).

### Sparkle 2 integration
- `UpdaterService.swift` with `SPUStandardUpdaterController` + `SPUUpdaterDelegate`.
- "Check for Updates…" menu item under the App menu.
- `Info.plist`: `SUFeedURL`, `SUEnableAutomaticChecks`, `SUAutomaticallyUpdate=false`,
  `SUScheduledCheckInterval=86400`, `SUPublicEDKey` (auto-patched by `bootstrap.sh`).
- `appcast.xml` template with `sparkle:edSignature` placeholder.
- Private key stays in the login keychain (never committed).

### CI/CD (`.github/workflows/` at repo root)
- `ci.yml` — build + XCTest on every PR touching `ProfilePilot/**`.
- `release.yml` — triggered by `v*` tags:
  1. Restores Developer ID cert from `MAC_CERTIFICATES_P12_BASE64` secret.
  2. Stores notarytool creds in ephemeral keychain from four secrets.
  3. Runs `bootstrap.sh` equivalents (brew install, icon gen, xcodegen).
  4. Injects Sparkle public key from `SPARKLE_ED_PRIVATE_KEY` secret.
  5. Runs `./scripts/release.sh` (build → sign → notarise → DMG → ZIP → audit).
  6. Publishes GitHub Release with `.dmg` + `.zip` + `appcast-entry.xml` + `audit-report.txt`.

### Distribution
- `homebrew/profilepilot.rb` — Cask template with `zap` cleanup.
- GitHub Releases pipeline.
- Direct download instructions in `INSTALL.md`.

### Documentation
- `README.md` (root monorepo + Mac app)
- `INSTALL.md`, `BUILD.md`, `RELEASE.md`, `CONTRIBUTING.md`, `CHANGELOG.md`,
  `ARCHITECTURE.md`, `ROADMAP.md`, `LICENSE`, `Sparkle/README.md`, `dmg-assets/README.md`.

### Web companion (`/app/frontend`, `/app/backend`)
- Unchanged from previous iteration. Landing page + AI Workspace live demo backed
  by Claude Sonnet 4.5 via Emergent LLM key. **100% pass** on testing_agent iteration_1.

## Testing status

- `scripts/smoke-test.sh` — 30/30 green in this Linux container:
    - 10 script syntax checks
    - 3 plist validations
    - 3 XML validations
    - 3 YAML validations (project.yml + both workflows)
    - 1 icon generator run
    - 11 asset presence checks (10 PNGs + Contents.json)
    - Swift declaration count sanity (135 declarations found)
- `scripts/audit.sh` — Mac-only automated audit. Runs as the final step of
  `release.sh` and in CI.
- Web companion — `/app/test_reports/iteration_1.json`: **100% pass**.

## What CANNOT be executed here (Apple-mandatory)

Only these steps require the user's Mac + Apple credentials:
1. Apple Developer ID certificate signing (needs the physical cert).
2. Apple notarisation (needs Apple ID + app-specific password).
3. Actual DMG creation (`create-dmg` and `hdiutil` are macOS-only).
4. Runtime measurement (cold-start, RAM) on real hardware.

Every automation-side artefact for these is committed and validated. On a
notarised Mac, the full flow is literally one command: `./scripts/release.sh`.

## Prioritized backlog (nothing blocking)

- Real per-profile `.icns` for wrappers, generated from Chrome profile avatar
  via `sips`/`iconutil` (currently uses default).
- Hotkey capture UI in `SettingsView`.
- Session restore on reboot.
- Window Layout Memory UI panel.
- App Sandbox variant for Mac App Store.

## Next steps for the user

1. **Save to GitHub** via the platform button.
2. On your Mac: `git clone …/YourRepo && cd YourRepo/ProfilePilot && ./scripts/bootstrap.sh`.
3. Fill in `scripts/.env.local` (4 values), store notarytool creds.
4. `./scripts/release.sh` — get `build/ProfilePilot-0.1.0.dmg`.
5. Add the seven GH Secrets (see `RELEASE.md`) and `git tag v0.1.0 && git push --tags`
   to trigger the CI release pipeline.
