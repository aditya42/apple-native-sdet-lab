#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
RESULT=${1:-$ROOT/reports/ContactLab.xcresult}
mkdir -p reports
python3 Tools/xcresult-parser/parse_xcresult.py "$RESULT" > reports/normalized.json
python3 Tools/failure-classifier/classify.py reports/normalized.json > reports/classified.json
python3 Tools/report-generator/generate_report.py reports/classified.json reports/index.html
RUN_KEY="${GITHUB_RUN_ID:-local}:${GITHUB_RUN_ATTEMPT:-1}:${SHARD:-full}:${DEVICE:-local}:${TEST_LOCALE:-en_US}:$(basename "$RESULT")"
python3 Tools/failure-history/history.py --ingest reports/classified.json --run-key "$RUN_KEY" --db reports/history.sqlite --output reports/flaky-scores.json
echo "Report: $ROOT/reports/index.html"
