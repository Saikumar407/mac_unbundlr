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

- This Emergent environment is a **Linux cloud container** — it cannot compile, run, sign or
  preview native macOS Swift/SwiftUI/AppKit code.
- Deliverable therefore = **Hybrid (Option C):**
  1. Full Xcode/SPM Swift source project under `/app/ProfilePilot/` (readable, builds on any Mac
     with Xcode 15+).
  2. Companion web landing/docs site (React + FastAPI + MongoDB) previewable at
     `REACT_APP_BACKEND_URL`.
  3. Companion AI Workspace API endpoint using Claude Sonnet 4.5 (Emergent LLM key).

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

## What has been implemented (2026-01-23)

**Swift source (delivered as read-only source under `/app/ProfilePilot/`):**
- MVVM architecture, SwiftUI + AppKit.
- `MenuBarExtra` + main window + Settings scene.
- Services: `BrowserRegistry`, `ProfileDetector` (Chromium + Firefox + Safari),
  `ProfileLauncher`, `BundleFactory` (per-profile `.app` wrapper), `WorkspaceLauncher`,
  `WindowLayoutManager` (AX API), `HotkeyManager` (Carbon), `AIWorkspaceService`,
  `PersistenceService` (JSON in `Application Support`).
- Views: `MenuBarContentView`, `MainWindowView`, `ProfileListView`, `WorkspacesView`,
  `WorkspaceEditorView`, `AIWorkspaceView`, `SettingsView` + components.
- Models: `Browser`, `BrowserProfile`, `Workspace`, `WorkspaceItem` (Codable tagged union),
  `WindowLayout`, `AIPlan`.
- Package.swift + XcodeGen `project.yml` + Info.plist + entitlements.
- Unit tests: `ProfileDetectorTests`, `BundleFactoryTests`, `WorkspaceCodableTests`.
- Docs: `README.md`, `ARCHITECTURE.md` (with full macOS capability matrix + honest limitations),
  `ROADMAP.md`, `LICENSE` (MIT).

**Web companion:**
- FastAPI backend (`/app/backend/server.py`):
  - `POST /api/ai-workspace` → Claude Sonnet 4.5 workspace planner
  - `POST /api/workspaces/export` + `GET /api/workspaces` → MongoDB-backed workspace storage
  - Legacy `/api/status` retained
- React landing page (`/app/frontend/src/pages/Landing.jsx`) with:
  Header · Hero · Windows-vs-macOS problem comparison · Bento feature grid · Interactive AI Demo
  (live, hits the API) · Architecture (bundle wrapper explanation) · Downloads · Roadmap timeline ·
  Security manifesto · FAQ accordion · Footer.
- Design guidelines followed: Geist font, dark palette, radial glows, grain overlay,
  glassmorphism header, macOS window chrome mockups, kbd caps, lucide icons.

## Testing status

- `/app/test_reports/iteration_1.json` — **100% pass** on both backend (6/6) and frontend flows.
- One minor UX improvement applied (clipboard fallback).

## Prioritized backlog

**P0 (blocking further work)**: none.

**P1**:
- Xcode project committed via XcodeGen (users must currently run `xcodegen generate`).
- Real `.icns` generation for wrappers using `sips`/`iconutil` (currently uses default icon).
- Hotkey editor UI in `SettingsView` (Carbon key-code capture).

**P2**:
- Session restore on reboot.
- Window Layout Memory UI panel in the main window.
- Notarised nightly `.dmg` in GitHub Releases.

**Future / research**: iCloud sync, team templates, `profilepilot://` share URLs, App Sandbox mode.

## Next tasks

- Ship the source repo (user pushes via "Save to GitHub").
- User builds on their Mac and reports first-launch UX findings.
