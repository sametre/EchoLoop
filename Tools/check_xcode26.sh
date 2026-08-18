#!/bin/bash
set -euo pipefail
if ! command -v xcodebuild >/dev/null 2>&1; then echo 'xcodebuild not found. Run on macOS with Xcode 26+.' >&2; exit 1; fi
VERSION="$(xcodebuild -version | awk '/Xcode/{print $2; exit}')"
MAJOR="${VERSION%%.*}"
if [[ ! "$MAJOR" =~ ^[0-9]+$ ]] || (( MAJOR < 26 )); then
  echo "Xcode 26+ is required for the current App Store upload requirements. Found: ${VERSION:-unknown}" >&2; exit 2
fi
echo "Xcode requirement PASS: $VERSION"
