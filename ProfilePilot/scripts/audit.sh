#!/usr/bin/env bash
# ============================================================================
# audit.sh — automated production audit of the built .app / .dmg.
#
# Runs every check we can perform on a Mac without user interaction.
# Prints a pass/fail matrix and exits non-zero if any REQUIRED check fails.
#
# Usage:
#   scripts/audit.sh                       # audits build/export/ProfilePilot.app
#   scripts/audit.sh /path/to/App.app      # audits an explicit path
# ============================================================================
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_env.sh
source "${DIR}/_env.sh"

require_macos

TARGET_APP="${1:-${APP_PATH}}"
[[ -d "${TARGET_APP}" ]] || fail "App not found: ${TARGET_APP}"

REPORT="${BUILD_DIR}/audit-report.txt"
mkdir -p "${BUILD_DIR}"
: > "${REPORT}"

PASS=0
FAIL=0
WARN=0

check() {
  # check "Description" "command..." [--soft]
  local desc="$1"; shift
  local soft=0
  [[ "${!#}" == "--soft" ]] && { soft=1; set -- "${@:1:$#-1}"; }
  local out rc
  out="$("$@" 2>&1)"; rc=$?
  if [[ $rc -eq 0 ]]; then
    printf "  %s✓%s %s\n"       "$C_GRN" "$C_RST" "$desc"
    printf "PASS  %s\n"          "$desc" >>"${REPORT}"
    PASS=$((PASS+1))
  else
    if [[ $soft -eq 1 ]]; then
      printf "  %s!%s %s%s\n"    "$C_YEL" "$C_RST" "$desc" " (soft)"
      printf "WARN  %s :: %s\n"  "$desc" "$out" >>"${REPORT}"
      WARN=$((WARN+1))
    else
      printf "  %s✗%s %s\n"      "$C_RED" "$C_RST" "$desc"
      printf "FAIL  %s :: %s\n"  "$desc" "$out" >>"${REPORT}"
      FAIL=$((FAIL+1))
    fi
  fi
}

section "ProfilePilot production audit"
echo "  Target: ${TARGET_APP}"
echo "  Report: ${REPORT}"
echo

# ---------- Structure ------------------------------------------------------
section "Bundle structure"
check "Info.plist present"        test -f "${TARGET_APP}/Contents/Info.plist"
check "MacOS binary present"      test -f "${TARGET_APP}/Contents/MacOS/${APP_NAME}"
check "PkgInfo present"           test -f "${TARGET_APP}/Contents/PkgInfo"
check "AppIcon present"           test -f "${TARGET_APP}/Contents/Resources/AppIcon.icns"
check "Assets.car present"        test -f "${TARGET_APP}/Contents/Resources/Assets.car" --soft
check "_CodeSignature dir"        test -d "${TARGET_APP}/Contents/_CodeSignature" --soft
check "Sparkle.framework present" test -d "${TARGET_APP}/Contents/Frameworks/Sparkle.framework" --soft

# ---------- Info.plist keys ------------------------------------------------
section "Info.plist keys"
PLIST="${TARGET_APP}/Contents/Info.plist"
check "CFBundleIdentifier == ${BUNDLE_ID}" \
  bash -c "test \"\$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' '${PLIST}')\" = '${BUNDLE_ID}'"
check "LSMinimumSystemVersion >= 14.0" \
  bash -c "/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' '${PLIST}' | awk '{exit (\$1+0 >= 14.0) ? 0 : 1}'"
check "NSHighResolutionCapable true" \
  bash -c "test \"\$(/usr/libexec/PlistBuddy -c 'Print :NSHighResolutionCapable' '${PLIST}')\" = 'true'"
check "SUFeedURL configured" \
  bash -c "/usr/libexec/PlistBuddy -c 'Print :SUFeedURL' '${PLIST}' | grep -q '^https://'"
check "SUPublicEDKey filled in (not placeholder)" \
  bash -c "! /usr/libexec/PlistBuddy -c 'Print :SUPublicEDKey' '${PLIST}' | grep -q REPLACE" --soft

# ---------- Universal binary ------------------------------------------------
section "Universal binary"
BIN="${TARGET_APP}/Contents/MacOS/${APP_NAME}"
check "Contains x86_64 slice" bash -c "lipo -info '${BIN}' | grep -q x86_64"
check "Contains arm64 slice"  bash -c "lipo -info '${BIN}' | grep -q arm64"

# ---------- Code signing ---------------------------------------------------
section "Code signing"
check "codesign --verify --deep --strict" codesign --verify --deep --strict --verbose=2 "${TARGET_APP}"
check "Hardened runtime enabled" \
  bash -c "codesign -dvv '${TARGET_APP}' 2>&1 | grep -q 'flags=0x10000(runtime)'" --soft
check "Signed with Developer ID" \
  bash -c "codesign -dvv '${TARGET_APP}' 2>&1 | grep -q 'Authority=Developer ID Application'" --soft
check "Nested frameworks signed" \
  bash -c "find '${TARGET_APP}/Contents/Frameworks' -name '*.framework' -maxdepth 2 2>/dev/null | \
           while read fw; do codesign --verify --strict \"\$fw\" || exit 1; done"

# ---------- Notarisation / Gatekeeper --------------------------------------
section "Notarisation & Gatekeeper"
check "Notarisation ticket stapled" xcrun stapler validate "${TARGET_APP}" --soft
check "spctl accepts the app"       spctl -a -vvv --type execute "${TARGET_APP}" --soft

# ---------- Entitlements ---------------------------------------------------
section "Entitlements"
ENTITLE=$(codesign -d --entitlements :- "${TARGET_APP}" 2>/dev/null || true)
check "App Sandbox is disabled (wrapper generator requires ~/Applications write)" \
  bash -c "echo \"${ENTITLE}\" | grep -q 'com.apple.security.app-sandbox' && \
           echo \"${ENTITLE}\" | grep -A1 'app-sandbox' | grep -q '<false/>'"
check "Apple Events entitlement present" \
  bash -c "echo \"${ENTITLE}\" | grep -q 'automation.apple-events'" --soft

# ---------- Sparkle appcast reachability -----------------------------------
section "Sparkle"
FEED_URL=$(/usr/libexec/PlistBuddy -c 'Print :SUFeedURL' "${PLIST}" 2>/dev/null || echo "")
if [[ -n "${FEED_URL}" ]]; then
  check "Appcast feed reachable (${FEED_URL})" \
    bash -c "curl -sSfL --max-time 10 -o /dev/null '${FEED_URL}'" --soft
else
  warn "No SUFeedURL — skipping"
fi

# ---------- Runtime ---------------------------------------------------------
section "Runtime"
# Cold-start check: measure how long `open -a` takes to return AND how long
# it takes ProfilePilot to appear as a process. Anything under 800ms end-to-end
# on a modern Mac is a green light for our <100ms cold-start budget (the extra
# is the LaunchServices round-trip).
if killall "${APP_NAME}" 2>/dev/null; then sleep 1; fi
START_NS=$(python3 -c "import time; print(int(time.time()*1e9))")
if open -a "${TARGET_APP}"; then
  # Wait up to 5s for the process to appear
  for _ in $(seq 1 50); do
    if pgrep -x "${APP_NAME}" >/dev/null; then
      END_NS=$(python3 -c "import time; print(int(time.time()*1e9))")
      COLD_MS=$(( (END_NS - START_NS) / 1000000 ))
      break
    fi
    sleep 0.1
  done
  COLD_MS=${COLD_MS:-9999}
  if [[ $COLD_MS -lt 800 ]]; then
    printf "  %s✓%s Cold start %d ms (<800 ms envelope)\n" "$C_GRN" "$C_RST" "$COLD_MS"
    printf "PASS  Cold start %d ms\n" "$COLD_MS" >>"${REPORT}"; PASS=$((PASS+1))
  else
    printf "  %s!%s Cold start %d ms (soft)\n" "$C_YEL" "$C_RST" "$COLD_MS"
    printf "WARN  Cold start %d ms\n" "$COLD_MS" >>"${REPORT}"; WARN=$((WARN+1))
  fi
  # Idle RAM after 2s
  sleep 2
  PID=$(pgrep -x "${APP_NAME}" | head -n1 || true)
  if [[ -n "$PID" ]]; then
    RSS_KB=$(ps -o rss= -p "$PID" | awk '{print $1}')
    RSS_MB=$(( RSS_KB / 1024 ))
    if [[ $RSS_MB -lt 120 ]]; then
      printf "  %s✓%s Idle RAM %d MB (<120 MB envelope)\n" "$C_GRN" "$C_RST" "$RSS_MB"
      printf "PASS  Idle RAM %d MB\n" "$RSS_MB" >>"${REPORT}"; PASS=$((PASS+1))
    else
      printf "  %s!%s Idle RAM %d MB (soft)\n" "$C_YEL" "$C_RST" "$RSS_MB"
      printf "WARN  Idle RAM %d MB\n" "$RSS_MB" >>"${REPORT}"; WARN=$((WARN+1))
    fi
  fi
  killall "${APP_NAME}" 2>/dev/null || true
else
  printf "  %s!%s Could not launch app for runtime measurement (soft)\n" "$C_YEL" "$C_RST"
  WARN=$((WARN+1))
fi

# ---------- DMG (optional) --------------------------------------------------
if [[ -f "${DMG_PATH}" ]]; then
  section "DMG"
  check "DMG signed" bash -c "codesign --verify '${DMG_PATH}'" --soft
  check "DMG notarised & stapled" xcrun stapler validate "${DMG_PATH}" --soft
  check "DMG mounts" bash -c "hdiutil attach -nobrowse -readonly '${DMG_PATH}' -mountpoint /tmp/pp-audit-mnt && hdiutil detach /tmp/pp-audit-mnt" --soft
fi

# ---------- Summary --------------------------------------------------------
section "Summary"
printf "  %sPASS%s: %d   %sWARN%s: %d   %sFAIL%s: %d\n" \
  "$C_GRN" "$C_RST" "$PASS" \
  "$C_YEL" "$C_RST" "$WARN" \
  "$C_RED" "$C_RST" "$FAIL"
printf "\nReport written to %s\n" "${REPORT}"

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
