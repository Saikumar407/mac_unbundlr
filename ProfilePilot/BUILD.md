# Building ProfilePilot

Everything you need to build the app locally on your Mac.

---

## Prerequisites

| Tool | Why | Install |
|------|-----|---------|
| **Xcode 15+** | Compiler, code-signing, notarytool | Mac App Store |
| **XcodeGen**  | Regenerates `ProfilePilot.xcodeproj` from `project.yml` | `brew install xcodegen` |
| **xcbeautify** | Pretty xcodebuild logs (optional) | `brew install xcbeautify` |
| **create-dmg** | Fancy DMG layout (optional but recommended) | `brew install create-dmg` |
| **swiftlint**  | Style checks (optional) | `brew install swiftlint` |

Verify the toolchain:

```bash
xcodebuild -version         # Xcode 15.x
xcode-select -p             # /Applications/Xcode.app/Contents/Developer
swift --version             # Swift 5.9+
xcodegen --version
```

---

## Quick build (unsigned, dev only)

```bash
git clone https://github.com/YOURUSER/ProfilePilot.git
cd ProfilePilot
xcodegen generate
open ProfilePilot.xcodeproj
# In Xcode: press ⌘R
```

Or via SPM (no Xcode UI):

```bash
swift build -c release
open .build/release/ProfilePilot
```

Note: SPM builds don't produce a proper `.app` bundle — use Xcode / `scripts/build.sh`
for anything you plan to distribute.

---

## Signed release build

1. Copy `scripts/.env.local.example` to `scripts/.env.local` and fill in:
    - `DEVELOPER_ID_APPLICATION` — the exact string from
      `security find-identity -p codesigning -v`.
    - `DEVELOPMENT_TEAM` — your 10-character team ID.
2. Store notarytool credentials once (survives reboots):
    ```bash
    xcrun notarytool store-credentials "ProfilePilotNotary" \
      --apple-id     "you@icloud.com" \
      --team-id      "TEAMID1234" \
      --password     "abcd-efgh-ijkl-mnop"    # app-specific pwd
    ```
3. Run the release:
    ```bash
    ./scripts/release.sh
    ```

Artifacts land in `build/`:

- `build/export/ProfilePilot.app` — signed + notarised + stapled
- `build/ProfilePilot-<ver>.dmg`  — signed + notarised + stapled
- `build/ProfilePilot-<ver>.zip`  — Sparkle-ready ZIP
- `build/appcast-entry.xml`       — paste into `appcast.xml`

---

## Individual build phases

Run any phase alone — each script is idempotent.

```bash
./scripts/build.sh          # or `build.sh debug`
./scripts/sign.sh           # requires DEVELOPER_ID_APPLICATION
./scripts/notarize.sh       # requires notarytool profile
./scripts/create-dmg.sh
./scripts/package.sh
./scripts/release.sh --skip-notary   # everything except notarisation
./scripts/release.sh --skip-dmg
```

---

## Universal binary

`scripts/build.sh` passes `ARCHS="x86_64 arm64"` and `ONLY_ACTIVE_ARCH=NO` so the
archived `.app` runs natively on both Intel and Apple Silicon. Verify:

```bash
file build/export/ProfilePilot.app/Contents/MacOS/ProfilePilot
# Mach-O universal binary with 2 architectures: [x86_64] [arm64]
lipo -info build/export/ProfilePilot.app/Contents/MacOS/ProfilePilot
```

---

## Common pitfalls

**`xcodegen: command not found`** — install with `brew install xcodegen`.

**`errSecInternalComponent` during codesign** — your keychain is locked. Run:

```bash
security unlock-keychain -p "$USER_PASSWORD" login.keychain
```

**Notarisation stuck on "In Progress"** — Apple usually completes within 5–15 min,
but occasionally hours. Check with:

```bash
xcrun notarytool history --keychain-profile "ProfilePilotNotary"
```

**`spctl: rejected`** on the final app — you probably didn't run `notarize.sh` or the staple
step failed. Re-run:

```bash
xcrun stapler staple build/export/ProfilePilot.app
spctl -a -vvv --type execute build/export/ProfilePilot.app
```

**Sparkle framework not signed** — `sign.sh` handles nested frameworks; make sure
you didn't skip it. Confirm with:

```bash
codesign --verify --deep --strict --verbose=2 build/export/ProfilePilot.app
```

**Cannot generate the DMG** — check `create-dmg` is installed (`brew install create-dmg`).
If it's still failing, the script falls back to `hdiutil` (plain DMG, no fancy layout).
