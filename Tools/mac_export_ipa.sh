#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
Tools/check_xcode26.sh
python3 Tools/validate_project.py
python3 Tools/release_preflight.py
ARCHIVE="$ROOT/build/EchoLoop.xcarchive"; EXPORT="$ROOT/build/AppStoreExport"
if [[ ! -d "$ARCHIVE" ]]; then Tools/mac_archive_release.sh; fi
rm -rf "$EXPORT"; mkdir -p "$EXPORT"
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath "$EXPORT" -exportOptionsPlist AppStore/ExportOptions.plist
IPA="$(find "$EXPORT" -maxdepth 1 -name '*.ipa' -print -quit)"
[[ -n "$IPA" ]] || { echo 'No IPA produced.' >&2; exit 1; }
echo "IPA created: $IPA"
