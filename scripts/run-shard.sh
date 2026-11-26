#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
mkdir -p reports
UDID=${SIMULATOR_UDID:-$(scripts/resolve-simulator.sh)}
SHARD=${SHARD:-unit}
RESULT_BUNDLE="reports/shard-$SHARD.xcresult"
rm -rf "$RESULT_BUNDLE"
case "$SHARD" in
  unit) suites=(ContactLabTests) ;;
  ui) suites=(ContactLabUITests) ;;
  *) echo "Unknown SHARD: $SHARD" >&2; exit 2 ;;
esac
xcodebuild test -project ContactLab.xcodeproj -scheme ContactLab \
  -destination "platform=iOS Simulator,id=$UDID" \
  -only-testing:"${suites[0]}" \
  -resultBundlePath "$RESULT_BUNDLE" CODE_SIGNING_ALLOWED=NO
