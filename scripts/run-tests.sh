#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
mkdir -p reports
RESULT_BUNDLE="reports/ContactLab.xcresult"
rm -rf "$RESULT_BUNDLE"
UDID=${SIMULATOR_UDID:-$(scripts/resolve-simulator.sh)}
locale=${TEST_LOCALE:-en_US}
language=${locale%%_*}
xcodebuild test \
  -project ContactLab.xcodeproj \
  -scheme ContactLab \
  -destination "platform=iOS Simulator,id=$UDID" \
  -resultBundlePath "$RESULT_BUNDLE" \
  -testLanguage "$language" \
  -testRegion "${locale#*_}" \
  CODE_SIGNING_ALLOWED=NO
