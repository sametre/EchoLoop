#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

Tools/check_xcode26.sh

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild not found. Run this script on macOS with Xcode installed." >&2
  exit 1
fi

python3 Tools/validate_project.py
python3 Tools/release_preflight.py

mkdir -p build
xcodebuild \
  -project EchoLoop.xcodeproj \
  -scheme EchoLoop \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ROOT/build/EchoLoop.xcarchive" \
  archive

echo "Archive created at build/EchoLoop.xcarchive"
