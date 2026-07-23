#!/usr/bin/env bash
# ============================================================================
# create-dmg.sh — produce a beautiful, drag-to-Applications DMG installer.
#
# Uses create-dmg (brew install create-dmg). Falls back to hdiutil if not
# present, but the fancy layout requires create-dmg.
# ============================================================================
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_env.sh
source "${DIR}/_env.sh"

require_macos
[[ -d "${APP_PATH}" ]] || fail "No .app at ${APP_PATH}. Run build.sh first."

DMG_BG="${REPO_ROOT}/dmg-assets/dmg-background.png"
VOL_ICON="${REPO_ROOT}/dmg-assets/VolumeIcon.icns"

rm -f "${DMG_PATH}"

if command -v create-dmg >/dev/null 2>&1; then
  section "Building fancy DMG with create-dmg"

  ARGS=(
    --volname "${APP_NAME} ${MARKETING_VERSION}"
    --window-pos 200 120
    --window-size 620 400
    --icon-size 128
    --text-size 13
    --icon "${APP_NAME}.app" 160 200
    --hide-extension "${APP_NAME}.app"
    --app-drop-link 460 200
    --hdiutil-quiet
    --no-internet-enable
  )
  [[ -f "${DMG_BG}" ]]   && ARGS+=( --background "${DMG_BG}" )
  [[ -f "${VOL_ICON}" ]] && ARGS+=( --volicon "${VOL_ICON}" )

  create-dmg "${ARGS[@]}" \
    "${DMG_PATH}" \
    "${APP_PATH}" \
    || fail "create-dmg failed"

else
  warn "create-dmg not installed. Falling back to plain hdiutil (no fancy layout)."
  warn "Install with: brew install create-dmg"
  hdiutil create -volname "${APP_NAME} ${MARKETING_VERSION}" \
    -srcfolder "${APP_PATH}" \
    -ov -format UDZO \
    "${DMG_PATH}"
fi

# Sign the DMG itself so Gatekeeper is happy on the container too.
if [[ -n "${DEVELOPER_ID_APPLICATION}" ]]; then
  section "Signing DMG"
  codesign --force --sign "${DEVELOPER_ID_APPLICATION}" --timestamp "${DMG_PATH}"
  ok "Signed ${DMG_PATH}"
fi

section "Notarising DMG (recommended)"
if xcrun notarytool submit "${DMG_PATH}" \
     --keychain-profile "${NOTARY_KEYCHAIN_PROFILE}" \
     --wait 2>/dev/null; then
  xcrun stapler staple "${DMG_PATH}"
  ok "DMG notarised and stapled"
else
  warn "DMG notarisation skipped — configure the '${NOTARY_KEYCHAIN_PROFILE}' credential profile to enable."
fi

ok "DMG at ${DMG_PATH}"
