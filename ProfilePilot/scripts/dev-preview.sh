#!/usr/bin/env bash
# ============================================================================
# dev-preview.sh — build an UNSIGNED developer preview .app + .dmg on any Mac
#                  (no Apple Developer account required).
#
# Produces:
#   build/dev/ProfilePilot.app      — ad-hoc signed .app you can run today
#   build/dev/ProfilePilot-dev.dmg  — simple UDZO DMG for handing to a friend
#
# The output IS NOT distributable — macOS Gatekeeper will warn the first user
# because it's not signed with a Developer ID and not notarised. Use
# scripts/release.sh once you have your Developer ID cert.
#
# First-run tip for your users:
#   Right-click the .app → Open → confirm the dialog. (Only needed once.)
#
# Usage:
#   scripts/dev-preview.sh              # build both .app and .dmg
#   scripts/dev-preview.sh --app-only   # skip DMG creation
#   scripts/dev-preview.sh --run        # after build, open the .app
# ============================================================================

set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_env.sh
source "${DIR}/_env.sh"

require_macos
require_cmd xcodebuild

MAKE_DMG=1
RUN_AFTER=0
for arg in "$@"; do
  case "$arg" in
    --app-only) MAKE_DMG=0 ;;
    --run)      RUN_AFTER=1 ;;
    -h|--help)  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  esac
done

DEV_DIR="${BUILD_DIR}/dev"
DEV_APP="${DEV_DIR}/${APP_NAME}.app"
DEV_DMG="${BUILD_DIR}/${APP_NAME}-dev.dmg"

section "ProfilePilot developer preview build"
echo "  Output: ${DEV_APP}"
echo "  Signed: ad-hoc only (Gatekeeper will warn on first launch)"
echo

# 1. Icons + Xcode project
section "Regenerating icons + Xcode project"
python3 -m pip install --quiet cairosvg Pillow >/dev/null 2>&1 || true
python3 "${DIR}/generate_icons.py" || warn "Icon generation skipped."
if command -v xcodegen >/dev/null 2>&1; then
  ( cd "${REPO_ROOT}" && xcodegen generate )
else
  warn "xcodegen missing — install with: brew install xcodegen"
  [[ -d "${XCODE_PROJECT}" ]] || fail "No Xcode project found."
fi

# 2. Build Debug (fast) or Release (small) — we default to Release Universal
CONFIG="Release"
section "Archiving (${CONFIG}, Universal Binary, ad-hoc signed)"
mkdir -p "${DEV_DIR}"

DEV_ARCHIVE="${DEV_DIR}/${APP_NAME}.xcarchive"
rm -rf "${DEV_ARCHIVE}"

XCB=(
  xcodebuild
  -project "${XCODE_PROJECT}"
  -scheme "${SCHEME}"
  -configuration "${CONFIG}"
  -archivePath "${DEV_ARCHIVE}"
  -destination "generic/platform=macOS"
  ONLY_ACTIVE_ARCH=NO
  ARCHS="x86_64 arm64"
  MARKETING_VERSION="${MARKETING_VERSION}-dev"
  CURRENT_PROJECT_VERSION="${CURRENT_PROJECT_VERSION}"
  CODE_SIGN_IDENTITY="-"                # ad-hoc signature
  CODE_SIGN_STYLE="Manual"
  DEVELOPMENT_TEAM=""
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO
  archive
)

if command -v xcbeautify >/dev/null 2>&1; then
  "${XCB[@]}" | xcbeautify
else
  "${XCB[@]}"
fi

# 3. Copy the .app out (no exportArchive — that requires a distribution profile)
UNSIGNED="${DEV_ARCHIVE}/Products/Applications/${APP_NAME}.app"
[[ -d "${UNSIGNED}" ]] || fail "Archive produced no .app."
rm -rf "${DEV_APP}"
cp -R "${UNSIGNED}" "${DEV_APP}"
ok ".app copied to ${DEV_APP}"

# 4. Ad-hoc re-sign so nested frameworks are consistent
section "Ad-hoc re-signing"
if [[ -d "${DEV_APP}/Contents/Frameworks" ]]; then
  find "${DEV_APP}/Contents/Frameworks" -type d -name "*.framework" \
    -exec codesign --force --sign - {} \;
fi
codesign --force --deep --sign - "${DEV_APP}"
codesign --verify --deep --strict "${DEV_APP}" \
  && ok "Ad-hoc signature valid"

# 5. Remove the quarantine xattr for local runs
xattr -dr com.apple.quarantine "${DEV_APP}" 2>/dev/null || true

# 6. Optional plain DMG for sharing
if [[ "$MAKE_DMG" -eq 1 ]]; then
  section "Building plain developer DMG (no fancy layout)"
  rm -f "${DEV_DMG}"
  hdiutil create -volname "${APP_NAME} dev" \
    -srcfolder "${DEV_APP}" \
    -ov -format UDZO \
    "${DEV_DMG}" >/dev/null
  ok "DMG at ${DEV_DMG} ($(du -h "${DEV_DMG}" | awk '{print $1}'))"
fi

# 7. Summary
section "Done"
echo "  App: ${DEV_APP}"
[[ -f "${DEV_DMG}" ]] && echo "  DMG: ${DEV_DMG}"
echo
cat <<EOF
${C_YEL}Distribute to yourself only.${C_RST} Because this build is not signed with a
Developer ID or notarised, macOS Gatekeeper will warn recipients that
"${APP_NAME}" cannot be opened. First-run workaround:

    1. Right-click ${APP_NAME}.app → Open
    2. Confirm the dialog once.
    3. From then on it launches normally.

For a real public release, run:  ./scripts/release.sh
EOF

if [[ "$RUN_AFTER" -eq 1 ]]; then
  section "Launching"
  open "${DEV_APP}"
fi
