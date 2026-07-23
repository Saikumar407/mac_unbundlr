# Contributing to ProfilePilot

Thanks for wanting to help! ProfilePilot is a small native macOS app with a
narrow scope — before opening a large PR, please open an issue first to
discuss the direction.

## Ground rules

- **Native only.** No Electron, no cross-platform runtimes, no web-view UI.
  If a feature can't be done in Swift + AppKit + SwiftUI, we don't ship it.
- **Respect macOS.** We never bypass code-signing, System Integrity Protection,
  or user consent prompts. If an API needs the Accessibility permission, we ask
  for it politely and degrade gracefully when the user declines.
- **Zero telemetry.** No analytics SDKs, no crash-reporting cloud, no vendored
  trackers. Ever.
- **No new dependencies without discussion.** We currently depend only on Sparkle.
  Every additional dependency is a supply-chain risk.

## Development loop

```bash
git clone https://github.com/YOURUSER/ProfilePilot.git
cd ProfilePilot
brew install xcodegen create-dmg xcbeautify swiftlint
xcodegen generate
open ProfilePilot.xcodeproj
```

Press ⌘U to run the unit tests, ⌘R to launch the app.

## Code style

- Swift 5.9, 4-space indent, no trailing whitespace.
- Prefer `struct` over `class` unless reference semantics are required.
- All services live in `Sources/ProfilePilot/Services` and take their
  dependencies via init, not singletons — except for `AppState.shared`, which
  is the one intentional singleton (the app root).
- New public APIs need a doc comment (`///`).
- Run `swiftlint` before pushing.

## Tests

New services must ship with `XCTest` tests under `Tests/ProfilePilotTests/`.
Aim for pure-logic tests — UI tests are welcome but not mandatory.

## PR checklist

- [ ] `swift build -c release` succeeds.
- [ ] `xcodebuild test` is green.
- [ ] `swiftlint` reports no new warnings.
- [ ] `CHANGELOG.md` updated under **Unreleased**.
- [ ] If the change affects UX, added screenshots or a short screen-recording.

## Licensing

By contributing, you agree that your contributions are licensed under the MIT
license (see `LICENSE`).
