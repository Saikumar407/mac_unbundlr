#!/usr/bin/env bash
# ============================================================================
# bootstrap.sh — install every tool ProfilePilot needs to build a release.
#
# Idempotent. Safe to re-run.
# ============================================================================
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_env.sh
source "${DIR}/_env.sh"

require_macos

section "Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  warn "Homebrew not found. Install it from https://brew.sh — this is a one-time step."
  fail "Bootstrap requires Homebrew."
fi
ok "Homebrew present: $(brew --version | head -n1)"

section "Toolchain (xcodegen, create-dmg, xcbeautify, swiftlint, librsvg)"
BREW_PACKAGES=( xcodegen create-dmg xcbeautify librsvg )
for pkg in "${BREW_PACKAGES[@]}"; do
  if brew list --formula --versions "$pkg" >/dev/null 2>&1; then
    ok "$pkg already installed"
  else
    log "brew install $pkg"
    brew install "$pkg"
  fi
done
# swiftlint is optional (linter) — soft-install
brew list --formula --versions swiftlint >/dev/null 2>&1 || brew install swiftlint || warn "swiftlint install failed (optional)."

section "Xcode Command Line Tools"
if xcode-select -p >/dev/null 2>&1; then
  ok "$(xcode-select -p)"
else
  log "Installing Xcode CLT (may pop a GUI dialog)…"
  xcode-select --install || warn "Command Line Tools install may need manual GUI confirmation."
fi

section "Python (for icon generation)"
require_cmd python3
python3 -m pip install --quiet --upgrade pip cairosvg Pillow >/dev/null
ok "Icon-gen deps present"

section "scripts/.env.local"
"${DIR}/ensure-env-local.sh"
ok "scripts/.env.local ready — fill in your Apple values before releasing."

section "Sparkle keys"
KEYCHAIN_ITEM_LABEL="ProfilePilot Sparkle EdDSA Private Key"
if security find-generic-password -l "${KEYCHAIN_ITEM_LABEL}" >/dev/null 2>&1; then
  ok "Sparkle keypair already in login keychain."
else
  # Generate key pair using Sparkle's helper if available; else fall back to
  # a warning — the user's first `swift build` / xcodebuild will fetch Sparkle
  # and we can re-run this.
  SP_BIN="$(find "${HOME}/Library/Developer/Xcode/DerivedData" -type f -name generate_keys 2>/dev/null | head -n1 || true)"
  if [[ -z "${SP_BIN}" ]]; then
    log "Sparkle not yet resolved. Running 'xcodebuild -resolvePackageDependencies'…"
    ( cd "${REPO_ROOT}" && xcodegen generate 2>/dev/null || true )
    ( cd "${REPO_ROOT}" && xcodebuild -project ProfilePilot.xcodeproj -scheme ProfilePilot \
        -resolvePackageDependencies >/dev/null ) || true
    SP_BIN="$(find "${HOME}/Library/Developer/Xcode/DerivedData" -type f -name generate_keys 2>/dev/null | head -n1 || true)"
  fi
  if [[ -n "${SP_BIN}" ]]; then
    mkdir -p "${REPO_ROOT}/Sparkle/bin"
    cp "${SP_BIN}" "${REPO_ROOT}/Sparkle/bin/"
    cp "$(dirname "${SP_BIN}")/sign_update"        "${REPO_ROOT}/Sparkle/bin/" 2>/dev/null || true
    cp "$(dirname "${SP_BIN}")/generate_appcast"   "${REPO_ROOT}/Sparkle/bin/" 2>/dev/null || true

    log "Generating Sparkle keypair (stored in the login keychain)…"
    "${REPO_ROOT}/Sparkle/bin/generate_keys" | tee "${REPO_ROOT}/Sparkle/public_ed_key.txt"
    PUB_KEY="$(grep -oE '[A-Za-z0-9+/=]{40,}' "${REPO_ROOT}/Sparkle/public_ed_key.txt" | head -n1 || true)"
    if [[ -n "${PUB_KEY}" ]]; then
      log "Patching Info.plist with SUPublicEDKey=${PUB_KEY}"
      /usr/libexec/PlistBuddy -c "Set :SUPublicEDKey ${PUB_KEY}" \
        "${REPO_ROOT}/Sources/ProfilePilot/Resources/Info.plist"
      ok "Public key stored in Info.plist and Sparkle/public_ed_key.txt."
      warn "The PRIVATE key stays in your login keychain. For CI, export once with:"
      warn "  ${REPO_ROOT}/Sparkle/bin/generate_keys -x /tmp/priv.key"
      warn "…then paste the file contents into the SPARKLE_ED_PRIVATE_KEY GitHub secret and delete /tmp/priv.key."
    fi
  else
    warn "Could not locate Sparkle's generate_keys — re-run bootstrap.sh after your first Xcode build."
  fi
fi

section "Icon generation"
python3 "${DIR}/generate_icons.py"

section "Done"
ok "Environment ready. Next: ./scripts/release.sh --skip-notary"
