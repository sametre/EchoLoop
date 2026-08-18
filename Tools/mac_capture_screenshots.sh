#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
Tools/check_xcode26.sh
python3 Tools/validate_project.py
mkdir -p build AppStore/screenshots/iphone69 AppStore/screenshots/ipad13

select_device() {
  local family="$1"
  xcrun simctl list devices available -j | FAMILY="$family" python3 -c '
import json,os,sys
p=json.load(sys.stdin); family=os.environ["FAMILY"]
all=[d for ds in p.get("devices",{}).values() for d in ds if d.get("isAvailable")]
if family=="iphone":
    preferred=("iPhone 17 Pro Max","iPhone 16 Pro Max","iPhone 16 Plus","iPhone 15 Pro Max")
    candidates=[d for d in all if "iPhone" in d.get("name","")]
else:
    preferred=("iPad Pro 13-inch (M5)","iPad Pro 13-inch (M4)","iPad Pro (13-inch) (M4)")
    candidates=[d for d in all if "iPad" in d.get("name","") and ("13" in d.get("name","") or "12.9" in d.get("name",""))]
for n in preferred:
    for d in candidates:
        if d.get("name")==n: print(d["udid"]); raise SystemExit
if candidates: print(candidates[0]["udid"]); raise SystemExit
raise SystemExit(1)
'
}

capture_family() {
  local family="$1" outdir="$2"
  local udid; udid="$(select_device "$family")" || { echo "No compatible $family Simulator found. Install the current iOS Simulator runtime in Xcode Settings > Platforms." >&2; exit 1; }
  local result="$ROOT/build/AppStoreScreenshots-${family}.xcresult"
  local raw="$ROOT/AppStore/screenshots/${outdir}/raw"
  rm -rf "$result" "$raw"; mkdir -p "$raw"
  xcodebuild -project EchoLoop.xcodeproj -scheme EchoLoop -configuration Debug \
    -destination "platform=iOS Simulator,id=${udid}" \
    -only-testing:EchoLoopUITests/AppStoreScreenshotTests \
    -resultBundlePath "$result" CODE_SIGNING_ALLOWED=NO test
  if xcrun xcresulttool export attachments --path "$result" --output-path "$raw"; then
    echo "$family screenshots exported to $raw"
  else
    echo "Attachment export failed for $family. Open $result in Xcode and export the kept screenshot attachments manually." >&2
  fi
}

capture_family iphone iphone69
capture_family ipad ipad13

echo 'Review exported images and copy the final PNGs one level up:'
echo '  AppStore/screenshots/iphone69/*.png  (6.9-inch accepted size)'
echo '  AppStore/screenshots/ipad13/*.png    (13-inch accepted size)'
echo 'Do not submit generated/mock UI; use screenshots captured from the actual build.'
