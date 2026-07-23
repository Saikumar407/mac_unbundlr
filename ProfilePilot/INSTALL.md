# Installing ProfilePilot

There are three supported install paths. Pick whichever matches your workflow.

---

## 1. DMG installer (recommended)

1. Download the latest **`ProfilePilot-<version>.dmg`** from the
   [Releases page](https://github.com/YOURUSER/ProfilePilot/releases).
2. Double-click the DMG.
3. Drag **ProfilePilot** into the **Applications** folder alias shown in the window.
4. Eject the DMG.
5. Launch ProfilePilot from Launchpad or Spotlight.

On first launch macOS may show *"ProfilePilot is an app downloaded from the internet"*.
Because the DMG is notarised, clicking **Open** just works — no right-click required.

If you built the DMG yourself and it is not notarised, right-click the app and
choose **Open**, then confirm the dialog.

---

## 2. Homebrew Cask

If you use [Homebrew](https://brew.sh):

```bash
brew tap YOURUSER/tap
brew install --cask profilepilot
```

Uninstall with:

```bash
brew uninstall --cask profilepilot --zap
```

`--zap` also removes `~/Library/Application Support/ProfilePilot` and the
generated wrapper apps under `~/Applications/ProfilePilot`.

---

## 3. Build from source

See [BUILD.md](./BUILD.md) for the full guide. TL;DR on a Mac with Xcode 15+:

```bash
git clone https://github.com/YOURUSER/ProfilePilot.git
cd ProfilePilot
brew install xcodegen create-dmg
xcodegen generate
open ProfilePilot.xcodeproj    # ⌘R
# or as a signed release:
./scripts/release.sh --skip-notary
```

---

## First-run checklist

- [ ] Menu bar shows the ProfilePilot icon (a sparkles.rectangle.stack glyph).
- [ ] The popover lists your Chrome / Edge / Brave profiles.
- [ ] Clicking a profile launches it — **the correct one, every time**.
- [ ] *(Optional)* Right-click a profile → **Create Dock App** to generate a
      per-profile `.app` wrapper in `~/Applications/ProfilePilot/`.
- [ ] *(Optional)* Grant Accessibility permission in *System Settings →
      Privacy & Security → Accessibility* if you want Window Layout Memory.

---

## Requirements

| Component | Minimum |
|-----------|---------|
| macOS     | 14 Sonoma (universal binary — runs on Intel and Apple Silicon) |
| Disk      | 12 MB free |
| RAM       | 50 MB idle |
| Network   | **None** required (AI Workspace is optional and configurable) |
