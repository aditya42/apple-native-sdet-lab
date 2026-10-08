#!/usr/bin/env bash
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
RUNS=${RUNS:-25}
TEST=${TEST:-ContactLabUITests/ContactCRUDUITests/testCreateContact}
UDID=${SIMULATOR_UDID:-$(scripts/resolve-simulator.sh)}
mkdir -p reports/reliability
CSV=reports/reliability/summary.csv
echo "run,status,duration_seconds,result_bundle" > "$CSV"

for i in $(seq 1 "$RUNS"); do
  result="reports/reliability/run-$i.xcresult"
  rm -rf "$result"
  start=$(date +%s)
  if xcodebuild test -project ContactLab.xcodeproj -scheme ContactLab \
      -destination "platform=iOS Simulator,id=$UDID" \
      -only-testing:"$TEST" -resultBundlePath "$result" CODE_SIGNING_ALLOWED=NO >/tmp/contactlab-run.log 2>&1; then
    status=PASS
  else
    status=FAIL
  fi
  end=$(date +%s)
  echo "$i,$status,$((end-start)),$result" >> "$CSV"
  echo "[$i/$RUNS] $status"
done

python3 - "$CSV" <<'PY'
import csv,sys
rows=list(csv.DictReader(open(sys.argv[1])))
passed=sum(r['status']=='PASS' for r in rows)
total=len(rows)
print(f"Reliability: {passed}/{total} = {(passed/total*100 if total else 0):.2f}%")
PY
