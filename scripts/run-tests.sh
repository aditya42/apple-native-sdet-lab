#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

mkdir -p reports

RESULT_BUNDLE="reports/ContactLab.xcresult"

# xcodebuild refuses to overwrite an existing .xcresult bundle.
# Remove the previous bundle so repeated `make test` runs are idempotent.
rm -rf "$RESULT_BUNDLE"

UDID=${SIMULATOR_UDID:-$(scripts/resolve-simulator.sh)}

xcodebuild test \
  -project ContactLab.xcodeproj \
  -scheme ContactLab \
  -destination "platform=iOS Simulator,id=$UDID" \
  -resultBundlePath "$RESULT_BUNDLE" \
  CODE_SIGNING_ALLOWED=NO
