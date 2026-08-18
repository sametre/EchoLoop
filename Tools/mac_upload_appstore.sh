#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
Tools/check_xcode26.sh
python3 Tools/release_preflight.py
IPA="${1:-$(find "$ROOT/build/AppStoreExport" -maxdepth 1 -name '*.ipa' -print -quit 2>/dev/null || true)}"
[[ -n "$IPA" && -f "$IPA" ]] || { echo 'IPA not found. Run Tools/mac_export_ipa.sh first.' >&2; exit 1; }
# Prefer App Store Connect API keys. Put AuthKey_<KEYID>.p8 in ~/private_keys, ~/.private_keys,
# ~/.appstoreconnect/private_keys, or pass an Apple-supported private key path for Transporter.
if [[ -n "${ASC_API_KEY:-}" && -n "${ASC_API_ISSUER:-}" ]]; then
  echo 'Uploading with App Store Connect API key via iTMSTransporter...'
  xcrun iTMSTransporter -m upload -apiIssuer "$ASC_API_ISSUER" -apiKey "$ASC_API_KEY" -assetFile "$IPA"
elif [[ -n "${APP_STORE_USERNAME:-}" && -n "${APP_STORE_APP_SPECIFIC_PASSWORD:-}" ]]; then
  echo 'Validating IPA with altool...'
  xcrun altool --validate-app -f "$IPA" -t ios -u "$APP_STORE_USERNAME" -p "$APP_STORE_APP_SPECIFIC_PASSWORD"
  echo 'Uploading IPA with altool...'
  xcrun altool --upload-app -f "$IPA" -t ios -u "$APP_STORE_USERNAME" -p "$APP_STORE_APP_SPECIFIC_PASSWORD"
else
  echo 'No App Store upload credential environment is configured.' >&2
  echo 'Preferred: ASC_API_KEY + ASC_API_ISSUER and the matching AuthKey_<KEYID>.p8 in an Apple-supported Transporter key location.' >&2
  echo 'Alternative: APP_STORE_USERNAME + APP_STORE_APP_SPECIFIC_PASSWORD.' >&2
  exit 2
fi
