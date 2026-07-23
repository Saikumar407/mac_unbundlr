#!/usr/bin/env bash
# ============================================================================
# release.sh — one-command production release orchestrator.
#
#   scripts/release.sh                # full pipeline
#   scripts/release.sh --skip-notary  # skip notarisation (dev builds)
#   scripts/release.sh --skip-dmg     # skip DMG creation
# ============================================================================
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_env.sh
source "${DIR}/_env.sh"

require_macos

SKIP_NOTARY=0
SKIP_DMG=0
for arg in "$@"; do
  case "$arg" in
    --skip-notary) SKIP_NOTARY=1 ;;
    --skip-dmg)    SKIP_DMG=1 ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//' | head -n 15
      exit 0
      ;;
  esac
done

section "ProfilePilot release · ${MARKETING_VERSION} (build ${CURRENT_PROJECT_VERSION})"
echo "  Team:    ${DEVELOPMENT_TEAM:-<unset>}"
echo "  Signer:  ${DEVELOPER_ID_APPLICATION:-<unset>}"
echo "  Notary:  ${NOTARY_KEYCHAIN_PROFILE}"
echo "  Skip DMG: ${SKIP_DMG}    Skip notary: ${SKIP_NOTARY}"
echo

"${DIR}/build.sh" clean

if [[ -n "${DEVELOPER_ID_APPLICATION}" ]]; then
  "${DIR}/sign.sh"
else
  warn "Skipping sign.sh — no DEVELOPER_ID_APPLICATION."
fi

if [[ "$SKIP_NOTARY" -eq 0 && -n "${DEVELOPER_ID_APPLICATION}" ]]; then
  "${DIR}/notarize.sh"
else
  warn "Skipping notarize.sh."
fi

if [[ "$SKIP_DMG" -eq 0 ]]; then
  "${DIR}/create-dmg.sh"
fi

"${DIR}/package.sh"

section "Automated production audit"
"${DIR}/audit.sh" || warn "Some audit checks failed — see ${BUILD_DIR}/audit-report.txt"

section "Done"
ls -lh "${BUILD_DIR}"/*.dmg "${BUILD_DIR}"/*.zip 2>/dev/null | sed 's/^/  /' || true
ok "Release artifacts in ${BUILD_DIR}"
echo
echo "Next steps:"
echo "  1. git tag v${MARKETING_VERSION} && git push --tags"
echo "  2. Attach ${APP_NAME}-${MARKETING_VERSION}.dmg and .zip to the GitHub Release."
echo "  3. Paste build/appcast-entry.xml into appcast.xml and push it to your website."
