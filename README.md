# ProfilePilot — monorepo

This repository contains two related projects.

| Path              | What it is                                    | Language     |
|-------------------|-----------------------------------------------|--------------|
| **`ProfilePilot/`** | **The primary product: a native macOS app.** | Swift / SwiftUI / AppKit |
| `frontend/`       | Companion marketing & docs website            | React        |
| `backend/`        | Companion API used by the website's live AI Workspace demo | Python / FastAPI |

**If you only care about the Mac app, everything you need is inside `ProfilePilot/`.**
That folder is self-contained: source, tests, Xcode/SPM manifests, build/sign/notarise
scripts, GitHub Actions workflows (`.github/workflows/*` at repo root run from that
subdirectory), Homebrew Cask, DMG assets, and docs.

The companion web app is optional — feel free to delete `frontend/` and `backend/`
if you don't want a companion website. Nothing in the Mac app depends on it.

---

## Quick start (Mac app)

```bash
cd ProfilePilot
./scripts/bootstrap.sh            # installs xcodegen, create-dmg, xcbeautify, generates Sparkle keys, icons
./scripts/release.sh --skip-notary   # first dry run
# ...fill in scripts/.env.local with your Developer ID, store notarytool creds, then:
./scripts/release.sh              # signed + notarised + DMG + ZIP + audit report
```

Full docs: [`ProfilePilot/README.md`](./ProfilePilot/README.md).

---

## Quick start (web companion)

Frontend + backend follow the standard Emergent full-stack layout (React on port 3000,
FastAPI on port 8001, MongoDB local). See `frontend/README.md` and `backend/` for
details. Everything is optional and unrelated to the Mac release pipeline.

---

## License

MIT. See `ProfilePilot/LICENSE`.
