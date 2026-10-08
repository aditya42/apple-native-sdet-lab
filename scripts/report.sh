#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
RESULT=${1:-$ROOT/reports/ContactLab.xcresult}
mkdir -p "$ROOT/reports"
python3 "$ROOT/Tools/xcresult-parser/parse_xcresult.py" "$RESULT" > "$ROOT/reports/normalized.json"
python3 "$ROOT/Tools/failure-classifier/classify.py" "$ROOT/reports/normalized.json" > "$ROOT/reports/classified.json"
python3 "$ROOT/Tools/report-generator/generate_report.py" "$ROOT/reports/classified.json" "$ROOT/reports/index.html"
echo "Report: $ROOT/reports/index.html"
