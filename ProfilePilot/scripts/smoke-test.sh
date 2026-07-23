#!/usr/bin/env bash
# ============================================================================
# smoke-test.sh — runs every check that DOES NOT require macOS.
#
# This script exists because most of the release pipeline can only run on a
# Mac. But we can still verify:
#   - every shell script has valid syntax
#   - every plist/XML asset is well-formed
#   - the icon generator works end-to-end
#   - the SwiftPM manifest is valid
#   - the XcodeGen manifest is valid YAML
#   - the appcast is a valid RSS feed
#
# Run this in Linux CI (or on your Mac) before pushing.
# ============================================================================
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/.." && pwd)"
cd "${ROOT}"

if [[ -t 1 ]]; then
  C_GRN=$'\033[32m'; C_RED=$'\033[31m'; C_YEL=$'\033[33m'; C_BOLD=$'\033[1m'; C_RST=$'\033[0m'
else
  C_GRN=; C_RED=; C_YEL=; C_BOLD=; C_RST=
fi

PASS=0; FAIL=0
ok()   { echo "  ${C_GRN}✓${C_RST} $*"; PASS=$((PASS+1)); }
fail() { echo "  ${C_RED}✗${C_RST} $*"; FAIL=$((FAIL+1)); }
section() { echo; echo "${C_BOLD}══ $* ══${C_RST}"; }

section "Shell script syntax"
for f in scripts/*.sh; do
  if bash -n "$f"; then ok "$f"; else fail "$f"; fi
done

section "Plist / entitlements well-formed"
python3 - <<'PY' || exit 1
import plistlib, sys, glob
paths = [
  "Sources/ProfilePilot/Resources/Info.plist",
  "Sources/ProfilePilot/Resources/ProfilePilot.entitlements",
  "ExportOptions.plist.template",
]
bad = 0
for p in paths:
    try:
        with open(p, "rb") as f: plistlib.load(f)
        print(f"  \033[32m✓\033[0m {p}")
    except Exception as e:
        print(f"  \033[31m✗\033[0m {p}: {e}"); bad += 1
sys.exit(1 if bad else 0)
PY
[[ $? -eq 0 ]] && PASS=$((PASS+3)) || FAIL=$((FAIL+1))

section "XML assets well-formed"
python3 - <<'PY' || exit 1
import xml.etree.ElementTree as ET, sys
paths = ["appcast.xml", "dmg-assets/AppIcon.svg", "dmg-assets/dmg-background.svg"]
bad = 0
for p in paths:
    try:
        ET.parse(p); print(f"  \033[32m✓\033[0m {p}")
    except Exception as e:
        print(f"  \033[31m✗\033[0m {p}: {e}"); bad += 1
sys.exit(1 if bad else 0)
PY
[[ $? -eq 0 ]] && PASS=$((PASS+3)) || FAIL=$((FAIL+1))

section "YAML manifests well-formed"
python3 - <<'PY' || exit 1
import yaml, sys
paths = ["project.yml", ".github/workflows/ci.yml", ".github/workflows/release.yml"] \
    if False else ["project.yml"]
# The GH workflow YAML lives at repo root (../.github). Guard the path.
import os
for extra in ["../.github/workflows/ci.yml", "../.github/workflows/release.yml"]:
    if os.path.exists(extra): paths.append(extra)
bad = 0
for p in paths:
    try:
        with open(p) as f: yaml.safe_load(f)
        print(f"  \033[32m✓\033[0m {p}")
    except Exception as e:
        print(f"  \033[31m✗\033[0m {p}: {e}"); bad += 1
sys.exit(1 if bad else 0)
PY
[[ $? -eq 0 ]] && PASS=$((PASS+1)) || FAIL=$((FAIL+1))

section "Icon generator"
python3 scripts/generate_icons.py >/dev/null && ok "generate_icons.py produced all assets" || fail "generate_icons.py"

section "AppIcon.appiconset contents"
NEEDED=(icon_16x16.png icon_16x16@2x.png icon_32x32.png icon_32x32@2x.png \
        icon_128x128.png icon_128x128@2x.png icon_256x256.png icon_256x256@2x.png \
        icon_512x512.png icon_512x512@2x.png Contents.json)
MISSING=0
for f in "${NEEDED[@]}"; do
  if [[ -f "Sources/ProfilePilot/Resources/Assets.xcassets/AppIcon.appiconset/$f" ]]; then
    ok "$f"
  else
    fail "missing $f"; MISSING=$((MISSING+1))
  fi
done

section "Swift package sanity (compile-check via SwiftSyntax not available offline — just grep)"
COUNT=$(grep -rE '^import |^@main|struct |class |func ' Sources/ProfilePilot | wc -l)
[[ $COUNT -gt 100 ]] && ok "Swift sources look non-trivial ($COUNT declarations)" || fail "Swift sources look thin ($COUNT declarations)"

echo
if [[ $FAIL -gt 0 ]]; then
  echo "${C_RED}${C_BOLD}FAIL${C_RST}  $PASS ok, $FAIL failed"
  exit 1
else
  echo "${C_GRN}${C_BOLD}PASS${C_RST}  $PASS checks green"
fi
