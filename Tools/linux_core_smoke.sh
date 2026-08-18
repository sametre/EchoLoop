#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
if ! command -v swiftc >/dev/null 2>&1; then
  echo "swiftc not found; install Swift to run this smoke test." >&2
  exit 1
fi
OUT="${TMPDIR:-/tmp}/echoloop-core-smoke"
swiftc \
  EchoLoop/Core/AdaptiveQualityController.swift \
  EchoLoop/Core/SceneComplexityPolicy.swift \
  EchoLoop/Core/SeasonProgression.swift \
  EchoLoop/Core/ArenaEventDirector.swift \
  EchoLoop/Core/TutorialRunCoordinator.swift \
  Tools/LinuxCoreSmokeMain.swift \
  -o "$OUT"
"$OUT"
rm -f "$OUT"
