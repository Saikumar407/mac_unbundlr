#!/usr/bin/env bash
# ============================================================================
# package.sh — produce the release ZIP + a Sparkle-ready appcast entry.
# ============================================================================
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_env.sh
source "${DIR}/_env.sh"

require_macos
[[ -d "${APP_PATH}" ]] || fail "No .app at ${APP_PATH}. Run build.sh first."

rm -f "${ZIP_PATH}"

section "Zipping .app for Sparkle distribution"
ditto -c -k --sequesterRsrc --keepParent "${APP_PATH}" "${ZIP_PATH}"
ok "Wrote ${ZIP_PATH}"

# --- Sparkle signature ------------------------------------------------------
SIGN_TOOL=""
for candidate in \
  "${REPO_ROOT}/Sparkle/bin/sign_update" \
  "$(command -v sign_update 2>/dev/null || true)" \
  "$HOME/Library/Developer/Xcode/DerivedData/*/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update"
do
  [[ -x "$candidate" ]] && SIGN_TOOL="$candidate" && break
done

if [[ -n "$SIGN_TOOL" ]]; then
  section "Signing update with Sparkle EdDSA key"
  ED_SIG="$("$SIGN_TOOL" "${ZIP_PATH}")"
  echo "  ${ED_SIG}"
  APPCAST_STUB="${BUILD_DIR}/appcast-entry.xml"
  BYTES=$(stat -f%z "${ZIP_PATH}")
  cat > "${APPCAST_STUB}" <<XML
<item>
  <title>Version ${MARKETING_VERSION}</title>
  <pubDate>$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S +0000')</pubDate>
  <sparkle:version>${CURRENT_PROJECT_VERSION}</sparkle:version>
  <sparkle:shortVersionString>${MARKETING_VERSION}</sparkle:shortVersionString>
  <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
  <description><![CDATA[
    <ul>
      <li>Release notes for ${MARKETING_VERSION}</li>
    </ul>
  ]]></description>
  <enclosure
    url="https://github.com/YOURUSER/ProfilePilot/releases/download/v${MARKETING_VERSION}/${APP_NAME}-${MARKETING_VERSION}.zip"
    length="${BYTES}"
    type="application/octet-stream"
    ${ED_SIG} />
</item>
XML
  ok "Wrote appcast entry stub to ${APPCAST_STUB}. Paste into appcast.xml."
else
  warn "sign_update tool not found — skipping Sparkle signing. Install Sparkle first (see Sparkle/README.md)."
fi

ls -lh "${BUILD_DIR}" | sed 's/^/  /'
ok "Packaging complete."
