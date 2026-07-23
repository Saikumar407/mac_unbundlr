#!/usr/bin/env bash
# ============================================================================
# sign.sh — Developer ID codesign + hardened runtime on the exported .app.
#
# Requirements:
#   - macOS
#   - A valid Developer ID Application certificate in the login keychain
#   - $DEVELOPER_ID_APPLICATION and $DEVELOPMENT_TEAM exported (see scripts/_env.sh)
#
# Usage:
#   scripts/sign.sh
# ============================================================================
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_env.sh
source "${DIR}/_env.sh"

require_macos
require_cmd codesign
require_cmd security

[[ -d "${APP_PATH}" ]] || fail "No .app to sign at ${APP_PATH}. Run scripts/build.sh first."

if [[ -z "${DEVELOPER_ID_APPLICATION}" ]]; then
  warn "DEVELOPER_ID_APPLICATION not set."
  warn "Available signing identities:"
  security find-identity -p codesigning -v || true
  fail "Export DEVELOPER_ID_APPLICATION=\"Developer ID Application: Your Name (TEAMID)\" and retry."
fi

section "Signing ${APP_PATH} with '${DEVELOPER_ID_APPLICATION}'"

ENTITLEMENTS="${REPO_ROOT}/Sources/ProfilePilot/Resources/ProfilePilot.entitlements"

# Sign nested frameworks first (Sparkle, XPC services, etc.)
if [[ -d "${APP_PATH}/Contents/Frameworks" ]]; then
  find "${APP_PATH}/Contents/Frameworks" -type d -name "*.framework" | while read -r fw; do
    log "  signing framework $(basename "$fw")"
    codesign --force --timestamp --options runtime \
      --sign "${DEVELOPER_ID_APPLICATION}" \
      "$fw"
  done
  # Sign Sparkle XPC helpers & Autoupdate binary explicitly (required by Sparkle 2)
  find "${APP_PATH}/Contents/Frameworks" -type f \( -name "*.xpc" -o -name "Autoupdate" -o -name "Updater" \) | while read -r bin; do
    log "  signing helper $(basename "$bin")"
    codesign --force --timestamp --options runtime \
      --sign "${DEVELOPER_ID_APPLICATION}" \
      "$bin"
  done
fi

# Sign the main app last with hardened runtime and our entitlements.
codesign --force --deep --timestamp --options runtime \
  --entitlements "${ENTITLEMENTS}" \
  --sign "${DEVELOPER_ID_APPLICATION}" \
  "${APP_PATH}"

section "Verifying signature"
codesign --verify --deep --strict --verbose=2 "${APP_PATH}"
spctl -a -vvv --type execute "${APP_PATH}" || warn "spctl says not-yet-notarised (expected before notarize.sh)."

ok "Signed ${APP_PATH}"
