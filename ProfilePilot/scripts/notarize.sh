#!/usr/bin/env bash
# ============================================================================
# notarize.sh — submit the signed .app (zipped) to Apple's notary service,
#               wait for the ticket, then staple it onto the .app.
#
# One-time setup on your Mac (stores credentials in the keychain):
#   xcrun notarytool store-credentials "ProfilePilotNotary" \
#     --apple-id  "$APPLE_ID" \
#     --team-id   "$DEVELOPMENT_TEAM" \
#     --password  "$APPLE_APP_SPECIFIC_PASSWORD"
#
# Usage:
#   scripts/notarize.sh
# ============================================================================
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_env.sh
source "${DIR}/_env.sh"

require_macos
require_cmd xcrun
require_cmd ditto

[[ -d "${APP_PATH}" ]] || fail "No .app at ${APP_PATH}. Run build.sh + sign.sh first."

NOTARY_ZIP="${BUILD_DIR}/${APP_NAME}-notary.zip"

section "Packaging .app for notarisation"
rm -f "${NOTARY_ZIP}"
ditto -c -k --sequesterRsrc --keepParent "${APP_PATH}" "${NOTARY_ZIP}"
ok "Wrote ${NOTARY_ZIP}"

section "Submitting to Apple notary service (this can take 5–20 minutes)"
if xcrun notarytool submit "${NOTARY_ZIP}" \
     --keychain-profile "${NOTARY_KEYCHAIN_PROFILE}" \
     --wait; then
  ok "Notarisation accepted"
else
  fail "Notarisation failed. Fetch the log with:
    xcrun notarytool log <submission-id> --keychain-profile ${NOTARY_KEYCHAIN_PROFILE}"
fi

section "Stapling ticket"
xcrun stapler staple "${APP_PATH}"
xcrun stapler validate "${APP_PATH}"

ok "${APP_PATH} is signed, notarised and stapled."
rm -f "${NOTARY_ZIP}"
