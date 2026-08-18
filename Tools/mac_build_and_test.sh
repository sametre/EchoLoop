#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

Tools/check_xcode26.sh

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild not found. Run this script on macOS with Xcode installed." >&2
  exit 1
fi
if ! command -v xcrun >/dev/null 2>&1; then
  echo "xcrun not found. Install/select Xcode command line tools." >&2
  exit 1
fi

Tools/linux_core_smoke.sh
python3 Tools/validate_project.py

echo "[1/3] Resolving Swift packages..."
xcodebuild -resolvePackageDependencies -project EchoLoop.xcodeproj -scheme EchoLoop

echo "[2/3] Building Debug for a generic iOS Simulator..."
xcodebuild \
  -project EchoLoop.xcodeproj \
  -scheme EchoLoop \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build

echo "[3/3] Selecting an available iPhone Simulator for XCTest..."
SIMULATOR_UDID="$(xcrun simctl list devices available -j | python3 -c '
import json, sys
payload=json.load(sys.stdin)
for runtime, devices in payload.get("devices", {}).items():
    for d in devices:
        if d.get("isAvailable") and "iPhone" in d.get("name", ""):
            print(d["udid"])
            raise SystemExit(0)
raise SystemExit(1)
')" || {
  echo "No available iPhone Simulator was found. Install an iOS Simulator runtime in Xcode Settings > Platforms." >&2
  exit 1
}

xcodebuild \
  -project EchoLoop.xcodeproj \
  -scheme EchoLoop \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=${SIMULATOR_UDID}" \
  CODE_SIGNING_ALLOWED=NO \
  test

echo "ECHO LOOP Debug build + XCTest + XCUITest completed successfully."
