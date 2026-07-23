# Sparkle integration

ProfilePilot uses [Sparkle 2](https://sparkle-project.org/) for automatic updates.

## 1. Add Sparkle to the Xcode project

Sparkle is best added via **Swift Package Manager**. If you're using `project.yml`
(XcodeGen), add the dependency to the manifest:

```yaml
packages:
  Sparkle:
    url: https://github.com/sparkle-project/Sparkle
    from: "2.6.0"

targets:
  ProfilePilot:
    dependencies:
      - package: Sparkle
```

After running `xcodegen generate`, open the project in Xcode once so it resolves
the package, then check `Contents/Frameworks/Sparkle.framework` appears in the
built `.app`. The `scripts/sign.sh` script signs every framework and XPC helper
inside `Contents/Frameworks/` automatically — this is required by Sparkle 2.

## 2. Info.plist keys

The generated `Info.plist` already includes:

```xml
<key>SUFeedURL</key>
<string>https://profilepilot.app/appcast.xml</string>
<key>SUEnableAutomaticChecks</key>
<true/>
<key>SUPublicEDKey</key>
<string>REPLACE_WITH_YOUR_BASE64_ED_PUBLIC_KEY</string>
```

If you self-host the appcast on a different URL, override `SUFeedURL` accordingly
and set `APPCAST_URL` in `scripts/.env.local`.

## 3. Generate an EdDSA key-pair (one time)

```bash
# Sparkle ships a helper CLI. On first checkout, resolve packages then find it:
xcodebuild -resolvePackageDependencies -project ProfilePilot.xcodeproj -scheme ProfilePilot

SP_ARTIFACTS="$(find ~/Library/Developer/Xcode/DerivedData -type d -name Sparkle 2>/dev/null | head -n1)/bin"
mkdir -p Sparkle/bin
cp "$SP_ARTIFACTS/sign_update"     Sparkle/bin/
cp "$SP_ARTIFACTS/generate_keys"   Sparkle/bin/
cp "$SP_ARTIFACTS/generate_appcast" Sparkle/bin/ 2>/dev/null || true

# Now generate keys — this stores the private key in your keychain automatically.
Sparkle/bin/generate_keys
```

`generate_keys` prints your **public key**. Paste it into `Info.plist`'s
`SUPublicEDKey` and into `scripts/.env.local` (`SPARKLE_ED_PUBLIC_KEY`).

The private key stays in your Keychain — never commit it. For CI, export it once
with `Sparkle/bin/generate_keys -x /tmp/priv.key` and add its contents as the
GitHub secret `SPARKLE_ED_PRIVATE_KEY`.

## 4. Publishing an update

`scripts/package.sh` runs `sign_update` automatically and writes an appcast
`<item>` stub to `build/appcast-entry.xml`. Paste it into your live `appcast.xml`
and re-deploy the file to whatever host serves `SUFeedURL`.

Alternatively, use `Sparkle/bin/generate_appcast build/` to regenerate the whole
file from a directory of ZIP releases.
