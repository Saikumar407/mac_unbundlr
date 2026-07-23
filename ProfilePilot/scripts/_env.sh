#!/usr/bin/env bash
# ============================================================================
# ProfilePilot — shared build environment
# ----------------------------------------------------------------------------
# Sourced by every other script under scripts/. Do NOT execute directly.
# ============================================================================

set -euo pipefail

# Repo root (one dir above scripts/)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# --- Project identity -------------------------------------------------------
APP_NAME="ProfilePilot"
BUNDLE_ID="com.profilepilot.app"
SCHEME="ProfilePilot"
XCODE_PROJECT="${REPO_ROOT}/${APP_NAME}.xcodeproj"

# --- Version -----------------------------------------------------------------
# MARKETING_VERSION drives semver + Sparkle appcast. CURRENT_PROJECT_VERSION
# is the monotonically increasing build number Sparkle uses to compare.
MARKETING_VERSION="${MARKETING_VERSION:-$(grep -m1 'MARKETING_VERSION' "${REPO_ROOT}/project.yml" | awk -F'"' '{print $2}')}"
CURRENT_PROJECT_VERSION="${CURRENT_PROJECT_VERSION:-$(date +%Y%m%d%H%M)}"

# --- Directories -------------------------------------------------------------
BUILD_DIR="${REPO_ROOT}/build"
ARCHIVE_PATH="${BUILD_DIR}/${APP_NAME}.xcarchive"
EXPORT_DIR="${BUILD_DIR}/export"
APP_PATH="${EXPORT_DIR}/${APP_NAME}.app"
DMG_DIR="${BUILD_DIR}/dmg"
DMG_PATH="${BUILD_DIR}/${APP_NAME}-${MARKETING_VERSION}.dmg"
ZIP_PATH="${BUILD_DIR}/${APP_NAME}-${MARKETING_VERSION}.zip"

# --- Signing (fill in via env or a local .env file) --------------------------
# Do NOT commit real values. Set in ~/.zshrc, CI secrets, or scripts/.env.local
: "${DEVELOPER_ID_APPLICATION:=${DEVELOPER_ID_APPLICATION-}}"    # "Developer ID Application: Your Name (TEAMID)"
: "${DEVELOPMENT_TEAM:=${DEVELOPMENT_TEAM-}}"                    # 10-char team ID
: "${APPLE_ID:=${APPLE_ID-}}"                                    # apple id email
: "${APPLE_APP_SPECIFIC_PASSWORD:=${APPLE_APP_SPECIFIC_PASSWORD-}}"  # app-specific pwd
: "${NOTARY_KEYCHAIN_PROFILE:=${NOTARY_KEYCHAIN_PROFILE:-ProfilePilotNotary}}"

# Optional overrides file for local dev — keep untracked.
if [[ -f "${REPO_ROOT}/scripts/.env.local" ]]; then
  # shellcheck disable=SC1091
  source "${REPO_ROOT}/scripts/.env.local"
fi

# --- Sparkle -----------------------------------------------------------------
SPARKLE_ED_PUBLIC_KEY="${SPARKLE_ED_PUBLIC_KEY:-}"      # base64 EdDSA public key
APPCAST_URL="${APPCAST_URL:-https://profilepilot.app/appcast.xml}"

# --- Logging -----------------------------------------------------------------
if [[ -t 1 ]]; then
  C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'; C_RED=$'\033[31m'; C_GRN=$'\033[32m'
  C_YEL=$'\033[33m'; C_BLU=$'\033[34m'; C_RST=$'\033[0m'
else
  C_BOLD=; C_DIM=; C_RED=; C_GRN=; C_YEL=; C_BLU=; C_RST=
fi

log()  { printf "%s▸%s %s\n" "$C_BLU" "$C_RST" "$*"; }
ok()   { printf "%s✓%s %s\n" "$C_GRN" "$C_RST" "$*"; }
warn() { printf "%s!%s %s\n" "$C_YEL" "$C_RST" "$*" >&2; }
fail() { printf "%s✗%s %s\n" "$C_RED" "$C_RST" "$*" >&2; exit 1; }
section() { printf "\n%s══ %s ══%s\n" "$C_BOLD" "$*" "$C_RST"; }

require_macos() {
  [[ "$(uname -s)" == "Darwin" ]] || fail "This script must run on macOS (current: $(uname -s))."
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

export APP_NAME BUNDLE_ID SCHEME REPO_ROOT XCODE_PROJECT \
       MARKETING_VERSION CURRENT_PROJECT_VERSION \
       BUILD_DIR ARCHIVE_PATH EXPORT_DIR APP_PATH DMG_DIR DMG_PATH ZIP_PATH \
       DEVELOPER_ID_APPLICATION DEVELOPMENT_TEAM APPLE_ID \
       APPLE_APP_SPECIFIC_PASSWORD NOTARY_KEYCHAIN_PROFILE \
       SPARKLE_ED_PUBLIC_KEY APPCAST_URL
