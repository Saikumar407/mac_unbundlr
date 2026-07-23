#!/usr/bin/env bash
# ============================================================================
# build.sh — clean Debug/Release build of ProfilePilot (universal binary).
#
# Usage:
#   scripts/build.sh                # Release
#   scripts/build.sh debug          # Debug
#   scripts/build.sh clean          # Wipe build/ then Release
# ============================================================================
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_env.sh
source "${DIR}/_env.sh"

MODE="${1:-release}"
require_macos
require_cmd xcodebuild

if [[ "$MODE" == "clean" ]]; then
  section "Cleaning build/"
  rm -rf "${BUILD_DIR}"
  MODE="release"
fi

CONFIG="Release"
[[ "$MODE" == "debug" ]] && CONFIG="Debug"

section "Regenerating Xcode project via XcodeGen"
if command -v xcodegen >/dev/null 2>&1; then
  ( cd "${REPO_ROOT}" && xcodegen generate )
  ok "xcodegen generate"
else
  warn "xcodegen not installed — assuming ${XCODE_PROJECT} already exists."
  [[ -d "${XCODE_PROJECT}" ]] || fail "No Xcode project found. Install with: brew install xcodegen"
fi

section "Archiving ${APP_NAME} (${CONFIG}, Universal Binary)"
mkdir -p "${BUILD_DIR}"

XCB=(
  xcodebuild
  -project "${XCODE_PROJECT}"
  -scheme "${SCHEME}"
  -configuration "${CONFIG}"
  -archivePath "${ARCHIVE_PATH}"
  -destination "generic/platform=macOS"
  ONLY_ACTIVE_ARCH=NO
  ARCHS="x86_64 arm64"
  MARKETING_VERSION="${MARKETING_VERSION}"
  CURRENT_PROJECT_VERSION="${CURRENT_PROJECT_VERSION}"
  archive
)

if command -v xcbeautify >/dev/null 2>&1; then
  "${XCB[@]}" | xcbeautify
else
  "${XCB[@]}"
fi

ok "Archive at ${ARCHIVE_PATH}"

section "Exporting .app"
mkdir -p "${EXPORT_DIR}"
EXPORT_PLIST="${BUILD_DIR}/ExportOptions.plist"
cat > "${EXPORT_PLIST}" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>developer-id</string>
  <key>signingStyle</key><string>manual</string>
  <key>teamID</key><string>${DEVELOPMENT_TEAM:-XXXXXXXXXX}</string>
  <key>destination</key><string>export</string>
</dict></plist>
PLIST

if ! xcodebuild -exportArchive \
     -archivePath "${ARCHIVE_PATH}" \
     -exportPath "${EXPORT_DIR}" \
     -exportOptionsPlist "${EXPORT_PLIST}"; then
  warn "exportArchive failed (probably missing Developer ID). Copying unsigned .app."
fi

if [[ ! -d "${APP_PATH}" ]]; then
  UNSIGNED="${ARCHIVE_PATH}/Products/Applications/${APP_NAME}.app"
  [[ -d "${UNSIGNED}" ]] || fail "No .app produced. Check the xcodebuild logs above."
  cp -R "${UNSIGNED}" "${APP_PATH}"
  warn "Copied UNSIGNED .app to ${APP_PATH} — run scripts/sign.sh before distribution."
fi

ok "App at ${APP_PATH}"
