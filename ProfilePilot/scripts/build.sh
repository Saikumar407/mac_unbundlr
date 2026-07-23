#!/usr/bin/env bash
# Convenience script: generate an Xcode project from project.yml, then build.
# Requires: xcodegen (`brew install xcodegen`) and Xcode 15+.

set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen not found. Install with: brew install xcodegen" >&2
  exit 1
fi

xcodegen generate
xcodebuild -project ProfilePilot.xcodeproj \
           -scheme ProfilePilot \
           -configuration Release \
           -destination 'platform=macOS' \
           build
echo
echo "Build succeeded. Binary at build/Release/ProfilePilot.app"
