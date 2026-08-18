#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
python3 Tools/validate_project.py

if command -v xcodebuild >/dev/null 2>&1; then
  echo "[INFO] xcodebuild detected; checking project/scheme discovery"
  xcodebuild -project EchoLoop.xcodeproj -list >/dev/null
  echo "[PASS] xcodebuild can read the project"
else
  echo "[INFO] xcodebuild is unavailable in this environment; run the following on macOS:"
  echo "       xcodebuild -project EchoLoop.xcodeproj -scheme EchoLoop -sdk iphonesimulator -configuration Debug build test"
fi
