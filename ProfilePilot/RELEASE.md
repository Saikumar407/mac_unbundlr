# Releasing ProfilePilot

Everything needed to cut a real, signed, notarised release that Homebrew, Sparkle,
and GitHub Releases can all consume.

---

## Prerequisites (one-time)

1. **Apple Developer Program** membership (required for Developer ID signing).
2. Create a **Developer ID Application** certificate in
   [Apple Developer → Certificates](https://developer.apple.com/account/resources/certificates/list).
   Download it, double-click to import into your login keychain.
3. Generate an **app-specific password** for your Apple ID at
   [appleid.apple.com](https://appleid.apple.com) → Sign-In and Security → App-Specific Passwords.
4. Store it in the keychain for notarytool:
   ```bash
   xcrun notarytool store-credentials "ProfilePilotNotary" \
     --apple-id "you@icloud.com" \
     --team-id  "TEAMID1234" \
     --password "abcd-efgh-ijkl-mnop"
   ```
5. Generate a **Sparkle EdDSA key-pair** (see `Sparkle/README.md`). Paste the public
   key into `Info.plist`'s `SUPublicEDKey` (and `project.yml` if you regenerate).
6. Fill in `scripts/.env.local` (`cp scripts/.env.local.example scripts/.env.local`).

---

## Cutting a release

```bash
# 1. Bump versions
sed -i '' 's/MARKETING_VERSION: "0.1.0"/MARKETING_VERSION: "0.2.0"/' project.yml

# 2. Update CHANGELOG.md — describe user-visible changes.

# 3. Commit + tag
git add -A
git commit -m "Release 0.2.0"
git tag  v0.2.0
git push origin main --tags     # triggers .github/workflows/release.yml on GH
```

The GitHub Actions workflow will:

1. Import your Developer ID certificate from the `MAC_CERTIFICATES_P12_BASE64` secret.
2. Run `scripts/release.sh` (build → sign → notarise → DMG → ZIP → appcast entry).
3. Sign the ZIP with Sparkle's `sign_update` using `SPARKLE_ED_PRIVATE_KEY`.
4. Publish a GitHub Release with the DMG, ZIP, and appcast stub attached.

## Manual release (no CI)

```bash
export MARKETING_VERSION=0.2.0
./scripts/release.sh
```

Then attach `build/*.dmg` and `build/*.zip` to a GitHub Release manually.

---

## Required GitHub secrets

Set these under **Repo → Settings → Secrets and variables → Actions**:

| Secret | How to obtain |
|---|---|
| `DEVELOPER_ID_APPLICATION` | Full name from `security find-identity -p codesigning -v` |
| `DEVELOPMENT_TEAM` | 10-char team ID (top-right of developer.apple.com) |
| `APPLE_ID` | Your Apple ID email |
| `APPLE_APP_SPECIFIC_PASSWORD` | From appleid.apple.com |
| `MAC_CERTIFICATES_P12_BASE64` | `security export -k login.keychain -t identities -f pkcs12 -o dev-id.p12 "$DEVELOPER_ID_APPLICATION"` then `base64 -i dev-id.p12` |
| `MAC_CERTIFICATES_P12_PASSWORD` | Password you set when exporting the .p12 |
| `SPARKLE_ED_PRIVATE_KEY` | Contents of `Sparkle/bin/generate_keys -x /tmp/priv.key` |

---

## After the release

- **Sparkle appcast**: paste `build/appcast-entry.xml` into your live `appcast.xml`
  and push it to whatever host serves `SUFeedURL` (github.io, Cloudflare Pages, etc.).
- **Homebrew Cask**: bump the `version` and `sha256` in `homebrew/profilepilot.rb`
  (`shasum -a 256 build/ProfilePilot-<ver>.dmg`), then submit a PR to your tap.
- **Announce**: docs site, changelog, social. Users on the previous version will
  auto-update via Sparkle within `SUScheduledCheckInterval` seconds (default 24h).

---

## Rollback

If a release is broken:

1. Delete the offending GitHub Release + tag.
2. Revert the appcast `<item>` addition.
3. Users on the previous version stay on the previous version — Sparkle only
   pulls what's currently in the appcast.
