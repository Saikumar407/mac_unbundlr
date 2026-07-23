# ProfilePilot — PRD

## Original problem statement

Build **ProfilePilot** — a native macOS workspace manager that fixes macOS's broken multi-profile
Chrome experience and expands into a general Workspace Launcher for developers (browser profiles +
VS Code + Terminal + Docker + Postman + shell commands + AI-drafted workspaces + hotkeys + window
layout memory).

Reference: **Unbundle** for the per-profile `.app` wrapper technique.

## User personas

- Full-stack developer juggling Work / Personal / Client Chrome profiles
- Freelancer running multiple client projects with different tool stacks
- macOS power user coming from Windows who misses per-profile Dock icons

## Delivery constraints

- This Emergent environment is a **Linux cloud container** — it cannot compile, sign, notarise or
  DMG-package native macOS Swift/SwiftUI/AppKit code.
- Deliverable therefore = **Hybrid (Option C, production-ready):**
  1. Complete SwiftPM + XcodeGen Swift source project under `/app/ProfilePilot/`.
  2. Full production release scaffolding: build / sign / notarise / DMG / ZIP / appcast scripts,
     GitHub Actions CI + Release pipelines, Homebrew Cask template, Sparkle 2 integration,
     DMG artwork.
  3. Companion web landing/docs site (React + FastAPI + MongoDB) previewable at
     `REACT_APP_BACKEND_URL`.
  4. Companion AI Workspace API endpoint using Claude Sonnet 4.5 (Emergent LLM key).

## Core requirements (static)

- Auto-detect Chrome / Edge / Brave / Chromium / Arc / Firefox profiles.
- Per-profile `.app` wrapper generation (Unbundle-style) with unique `CFBundleIdentifier`.
- Workspaces: browser profile + apps + URLs + shell commands + hotkey.
- AI Workspace: prompt → Claude Sonnet 4.5 → editable plan.
- Global Carbon hotkeys.
- Menu-bar `MenuBarExtra` popover.
- Window layout memory via Accessibility API (Milestone 0.2).
- Offline, no telemetry, no history access, no code injection.
- `<100 ms` cold start, `<50 MB` RAM, pure Swift.
- Signed, notarised, universal-binary, auto-updating release.

## What's been implemented (2026-01-23)

### Swift/AppKit/SwiftUI source under `/app/ProfilePilot/`
- MVVM architecture (16 Swift files, ~1900 LOC).
- Services: `BrowserRegistry`, `ProfileDetector`, `ProfileLauncher`, `BundleFactory`
  (per-profile `.app` wrapper), `WorkspaceLauncher`, `WindowLayoutManager` (AX API),
  `HotkeyManager` (Carbon), `AIWorkspaceService`, `PersistenceService`, **`UpdaterService`
  (Sparkle 2)**.
- Views: menu-bar popover, main NavigationSplitView, workspace editor, AI planner, settings.
- Unit tests: `ProfileDetectorTests`, `BundleFactoryTests`, `WorkspaceCodableTests`.

### Production release scaffolding (delivered 2026-01-23)
- **`scripts/`**: `_env.sh` (shared config + `.env.local` support), `build.sh`, `sign.sh`,
  `notarize.sh`, `create-dmg.sh`, `package.sh`, `release.sh` (one-command orchestrator).
  All scripts pass `bash -n` syntax check. Insertion points for Developer ID clearly marked.
- **`Package.swift`** and **`project.yml`** both include Sparkle 2 as a SwiftPM dependency.
- **Info.plist / entitlements** wired for Sparkle (`SUFeedURL`, `SUPublicEDKey`, …) and
  Hardened Runtime; validated with `plistlib`.
- **`appcast.xml`** template + **`Sparkle/README.md`** with key-gen instructions.
- **DMG assets**: hand-drawn SVG background, rasterised PNG (1240×800 @2×),
  `dmg-assets/README.md` covering `iconutil`/`sips` volume icon workflow.
- **GitHub Actions**: `ci.yml` (build + test on every PR) + `release.yml` (tag →
  signed + notarised + DMG + ZIP + appcast + published GH Release).
- **Homebrew Cask** template `homebrew/profilepilot.rb`.
- **`.gitignore`** covering build artifacts, secrets, .p12s, keys.

### Documentation
- `README.md` (with production-audit checklist), `INSTALL.md`, `BUILD.md`,
  `RELEASE.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, `ARCHITECTURE.md`, `ROADMAP.md`,
  `LICENSE`. All XML/plist artifacts syntactically validated.

### Web companion
- FastAPI backend (`/app/backend/server.py`):
  - `POST /api/ai-workspace` → Claude Sonnet 4.5 workspace planner
  - `POST /api/workspaces/export` + `GET /api/workspaces` → Mongo-backed storage
- React landing page (`/app/frontend/src/pages/Landing.jsx`) with hero,
  Windows-vs-macOS problem comparison, bento features, **live interactive AI demo**,
  architecture walkthrough, downloads, roadmap, security manifesto, FAQ, footer.

## Testing status

- `/app/test_reports/iteration_1.json` — **100% pass** on both backend (6/6) and every
  frontend flow. Minor UX improvement (clipboard fallback) applied.
- All 6 build shell scripts pass `bash -n` syntax check.
- All `.plist` and `.xml` release artefacts validated with `plistlib`/`xml.etree`.

## Prioritized backlog

**P0**: None blocking.

**P1**:
- Real per-profile `.icns` generation via `sips`/`iconutil` in `BundleFactory` (currently uses
  a default icon).
- Hotkey capture UI in `SettingsView`.
- Ship a real AppIcon design in `Assets.xcassets/AppIcon.appiconset`.

**P2**:
- Session restore on reboot.
- Window Layout Memory UI panel.
- Notarised nightly `.dmg` in GitHub Releases (workflow is ready — user just needs to push
  a `v*` tag with secrets configured).

**Future / research**: iCloud sync, team templates, `profilepilot://` share URLs, App Sandbox mode.

## What CANNOT be verified in this Linux container

Explicitly deferred to the user's Mac (documented in `README.md` "Production audit checklist"):
- `xcodebuild archive` succeeds
- Developer-ID code signing
- Apple notarisation
- Signed DMG creation
- Runtime memory / start-up measurement
- macOS Gatekeeper acceptance

Everything needed to accomplish all of those on a real Mac is now committed to the repo.

## Next tasks

- User pushes to GitHub via "Save to GitHub".
- Configure the seven GitHub Actions secrets (see `RELEASE.md`).
- On their Mac, `cp scripts/.env.local.example scripts/.env.local`, fill in
  `DEVELOPER_ID_APPLICATION`, then `./scripts/release.sh`.
- Publish the resulting `.dmg` on the GitHub Release and update Homebrew Cask.
