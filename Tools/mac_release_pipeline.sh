#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
Tools/check_xcode26.sh
Tools/linux_core_smoke.sh
Tools/mac_build_and_test.sh
python3 Tools/release_preflight.py
Tools/mac_archive_release.sh
Tools/mac_export_ipa.sh
if [[ "${UPLOAD:-0}" == "1" ]]; then Tools/mac_upload_appstore.sh; else echo 'Release IPA ready. Set UPLOAD=1 to upload after credentials are configured.'; fi
