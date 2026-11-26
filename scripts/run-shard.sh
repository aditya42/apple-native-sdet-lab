#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
mkdir -p reports
UDID=${SIMULATOR_UDID:-$(scripts/resolve-simulator.sh)}
SHARD=${SHARD:-unit}
TEST_LOCALE=${TEST_LOCALE:-en_US}
RESULT_BUNDLE="reports/shard-$SHARD.xcresult"
rm -rf "$RESULT_BUNDLE"
case "$SHARD" in
  unit) suite=ContactLabTests ;;
  ui) suite=ContactLabUITests ;;
  *) echo "Unknown SHARD: $SHARD" >&2; exit 2 ;;
esac
language=${TEST_LOCALE%%_*}
region=${TEST_LOCALE#*_}
xcodebuild test -project ContactLab.xcodeproj -scheme ContactLab \
  -destination "platform=iOS Simulator,id=$UDID" \
  -only-testing:"$suite" \
  -testLanguage "$language" -testRegion "$region" \
  -resultBundlePath "$RESULT_BUNDLE" CODE_SIGNING_ALLOWED=NO
