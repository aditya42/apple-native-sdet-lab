#!/usr/bin/env bash
set -euo pipefail
UDID=$(xcrun simctl list devices available -j | python3 -c 'import json,sys; d=json.load(sys.stdin)["devices"]; xs=[x for runtime in d.values() for x in runtime if x.get("isAvailable") and x.get("name","").startswith("iPhone")]; print(xs[0]["udid"] if xs else "")')
if [[ -z "$UDID" ]]; then
  echo "No available iPhone simulator found" >&2
  exit 1
fi
echo "$UDID"
