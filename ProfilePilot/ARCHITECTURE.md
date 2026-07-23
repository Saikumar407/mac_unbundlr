# ProfilePilot — Architecture

This document explains the technical decisions behind ProfilePilot, the macOS capability research that shaped them, and the internal module layout.

---

## 1. macOS capability matrix

We answered one question first: **can a native macOS application give each Chrome profile its own Dock identity, its own Cmd+Tab entry, and its own window group?**

The naive assumption is "no, because macOS groups all windows of a running process under a single `NSApplication` and a single Dock icon". That's true — for a single running process.

The real answer:

> **Yes — but only by launching Chrome under different `.app` bundles.** macOS routes Dock identity, Cmd+Tab identity and window grouping through `LSApplicationIdentifier` (bundle ID) and the `.app` bundle that was **opened** to spawn the process. If you spawn Chrome from two different bundles with two different bundle IDs, macOS treats them as two different applications.

Chrome itself uses this technique internally on some platforms. Tools like Unbundle and Chrome Shortcuts (Windows), Site Specific Browsers, and `nativefier` all rely on the same insight.

### API-by-API research summary

| API / concept | What it does | ProfilePilot uses it? |
|---|---|---|
| `NSWorkspace.openApplication(at:configuration:)` | Launches an app with custom arguments/env. | ✅ Primary launch path for profiles and workspace apps. |
| `NSWorkspace.launchApplication(withBundleIdentifier:...)` | Deprecated in macOS 11+, still works. | ❌ We prefer the modern API. |
| `LSRegisterURL` / `LSRegisterFSRef` | Register a bundle with Launch Services. | ✅ Called after we generate a wrapper bundle so macOS "sees" it in Cmd+Tab and Dock. |
| `LSCopyApplicationURLsForBundleIdentifier` | Locate installed apps by bundle ID. | ✅ Used by `BrowserRegistry`. |
| `Info.plist` keys: `CFBundleIdentifier`, `CFBundleName`, `CFBundleIconFile`, `LSUIElement`, `NSHumanReadableCopyright` | Determine app identity. | ✅ Set for every generated wrapper. |
| `LSUIElement = true` | Hide from Dock and Cmd+Tab. | ✅ On the *ProfilePilot menu-bar app itself* (optional dual mode). |
| Apple Events / `NSAppleScript` | Automate other apps. | ⚠️ Optional; used only to position windows when Accessibility API is denied. |
| Accessibility API (`AXUIElement`, `AXObserverCreate`) | Read/write window frames, focus. | ✅ For Window Layout Memory. Requires explicit user consent in *System Settings → Privacy → Accessibility*. |
| Carbon `RegisterEventHotKey` + `EventHotKeyRef` | Global keyboard shortcuts. | ✅ Used by `HotkeyManager`. Modern replacement `NSEvent.addGlobalMonitor…` cannot swallow events, so we still use Carbon. |
| Chrome CLI flags: `--profile-directory`, `--user-data-dir` | Launch a specific profile / storage folder. | ✅ Passed to `NSWorkspace.openApplication`. |
| `Chrome/Local State` JSON | Contains `profile.info_cache` with real profile names & avatars. | ✅ Parsed read-only by `ProfileDetector`. |
| App Sandbox | Restricts filesystem, spawning, etc. | ❌ ProfilePilot ships **unsandboxed** because bundle-wrapper generation requires writing to `~/Applications`. A sandboxed variant with a security-scoped bookmark for that folder is on the roadmap. |
| Hardened Runtime + Notarisation | Required for Gatekeeper. | ✅ Enabled in `project.yml`. |

### What we can *not* do — and why we're honest about it

1. **We cannot make Chrome itself split into multiple Dock icons from a single running process.** Chrome ships as one bundle (`com.google.Chrome`); macOS keys Dock identity on the *launching* bundle, and Chrome consolidates all profile windows under that one bundle at runtime. The only workaround is to spawn Chrome via a different bundle — which is exactly what we do.
2. **We cannot rename the running Chrome process in the Menu Bar** (the menu title always reads "Google Chrome"). Users who need this typically use the wrapper's title inference or [`chrome://flags/#enable-window-naming`].
3. **We cannot legally re-distribute a modified Chrome.** Wrappers only *launch* the user's already-installed Chrome; they do not embed or ship Chrome binaries.

---

## 2. Bundle-wrapper technique in detail

`BundleFactory.createWrapper(for:profile:in:)` performs the following steps:

1. Compute a stable bundle ID: `com.profilepilot.wrapper.<browserSlug>.<profileHash>`, where `profileHash` is SHA-256 of `browserBundleID + profile.directory` truncated to 12 chars.
2. Create the bundle skeleton in `~/Applications/ProfilePilot/`:
   ```
   Chrome — FG Designs.app/
   ├── Contents/
   │   ├── Info.plist
   │   ├── PkgInfo               ("APPL????")
   │   ├── MacOS/
   │   │   └── launcher          (executable shim, mode 0755)
   │   └── Resources/
   │       └── AppIcon.icns      (auto-generated from Chrome's avatar or SF Symbol)
   ```
3. `Info.plist` uses the computed bundle ID, sets `LSUIElement=false`, `LSBackgroundOnly=false`, `NSHighResolutionCapable=true`, and declares `LSApplicationCategoryType = public.app-category.productivity`.
4. The `launcher` binary is a small compiled Swift executable (or, as a fallback, a bash shim) that does:
   ```swift
   let chromeURL = URL(fileURLWithPath: "/Applications/Google Chrome.app")
   let cfg = NSWorkspace.OpenConfiguration()
   cfg.arguments = ["--profile-directory=Profile 1"]
   cfg.activates = true
   cfg.createsNewApplicationInstance = true      // KEY LINE — forces a fresh process
   NSWorkspace.shared.openApplication(at: chromeURL, configuration: cfg) { _, _ in exit(0) }
   RunLoop.main.run()
   ```
   The `createsNewApplicationInstance = true` flag is the second half of the trick: it tells macOS to spawn a *new* Chrome process rather than reactivate the existing one. Combined with the unique bundle ID of the wrapper, macOS grants the new process its own Dock icon.
5. `LSRegisterURL` is called on the new bundle so it appears in Cmd+Tab immediately (otherwise a logout is required).
6. Optional: `sips` + `iconutil` build an `.icns` from the profile avatar PNG that Chrome stores in `Local State`.

### Caveats

- The user must grant **read access to `~/Library/Application Support/Google/Chrome`** on first launch. We ask via `NSOpenPanel` if a direct read fails.
- The generated wrapper is user-writable and un-signed by default. macOS Gatekeeper flags it on first launch (`right-click → Open`). A future release will code-sign wrappers with the user's Developer ID if configured.
- Chrome updates never touch our wrappers — the wrapper only launches whatever Chrome is currently installed.

---

## 3. Module layout

MVVM. All state flows through `AppState`, a single `@Observable` container injected via `@Environment`.

```
App/
  ProfilePilotApp.swift        // @main, MenuBarExtra + Settings scene
  AppDelegate.swift            // Life-cycle hooks (Launch Services registration, hotkey unregister)
  AppState.swift               // @Observable root state, wires services + view-models

Models/
  Browser.swift                // enum: chrome / edge / brave / chromium / arc / firefox / safari
  BrowserProfile.swift         // id, displayName, directory, avatarURL, lastActive, browser
  Workspace.swift              // id, name, symbol, hotkey, items[]
  WorkspaceItem.swift          // enum: .browserProfile / .app(URL) / .url(String) / .shell(String)
  WindowLayout.swift           // captures NSScreen + AXUIElement frames
  AIPlanRequest / AIPlanResponse (Codable)

Services/
  BrowserRegistry              // enumerate installed browsers via LaunchServices
  ProfileDetector              // read Local State JSON per browser
  ProfileLauncher              // NSWorkspace.openApplication with args
  BundleFactory                // create per-profile .app wrappers
  WorkspaceLauncher            // sequential/parallel launch of WorkspaceItems
  WindowLayoutManager          // capture + restore window frames (AX API)
  HotkeyManager                // Carbon RegisterEventHotKey
  AIWorkspaceService           // POST to ProfilePilot companion API (or user's own key)
  PersistenceService           // Codable JSON in ~/Library/Application Support/ProfilePilot/

ViewModels/
  MenuBarViewModel             // list of profiles + workspaces
  WorkspaceViewModel           // editor state
  SettingsViewModel            // permissions, hotkeys, AI config

Views/
  MenuBarContentView           // popover content when clicking the status item
  ProfileListView              // Profiles tab
  WorkspacesView               // Workspaces tab
  WorkspaceEditorView          // create/edit a workspace
  AIWorkspaceView              // "type Laravel" prompt
  SettingsView                 // scene shown by SettingsLink
  Components/
    ProfileRowView
    KeyboardShortcutView
    BrowserIconView
```

---

## 4. Performance budget

| Metric | Budget | How we achieve it |
|---|---|---|
| Cold start | <100 ms | No storyboard, no Combine, no heavy frameworks. `MenuBarExtra` opens on demand. |
| Idle RAM | <50 MB | No embedded webview, no background daemons, `Local State` parsed lazily. |
| Binary size | <5 MB | Pure Swift, no third-party dependencies except `KeyboardShortcuts` (~200 KB) which we vendor. |

---

## 5. Security & privacy

- **No network access** except: (a) the *opt-in* AI Workspace request to a user-configured endpoint, (b) the built-in "Check for updates" (opt-in).
- **No profile data leaves the machine.** `Local State` is read; only profile names + avatars are cached to disk under `~/Library/Application Support/ProfilePilot/cache.json`.
- **No passwords, cookies, history or bookmarks are ever accessed.**
- **Accessibility permission** is requested only when the user enables Window Layout Memory. We never request `Full Disk Access`.
- **Sandboxing note:** the initial release runs unsandboxed to allow writing wrapper bundles to `~/Applications`. A sandboxed variant using a security-scoped bookmark to `~/Applications` is planned.

---

## 6. Testing strategy

- Unit tests for pure logic: `ProfileDetector`, `BundleFactory` (against a fixture `Local State`), `WorkspaceLauncher` planning, `HotkeyManager` binding math.
- UI tests via `XCUITest` for the menu-bar popover, workspace editor and AI prompt view.
- Manual QA matrix: macOS 14 / 15 / 26 × Intel / Apple Silicon × Chrome / Edge / Brave.

Run tests:

```bash
swift test
# or
xcodebuild test -scheme ProfilePilot -destination 'platform=macOS'
```

---

## 7. Future work

See [ROADMAP.md](./ROADMAP.md).
