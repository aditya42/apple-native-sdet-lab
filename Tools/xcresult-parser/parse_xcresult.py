#!/usr/bin/env python3
"""Normalize an .xcresult bundle into compact JSON.

Uses the modern xcresulttool test-results summary command when available.
Falls back to a minimal metadata record instead of failing the CI report stage.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


def run(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, text=True, capture_output=True, check=False)


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: parse_xcresult.py path/to/Test.xcresult")
    bundle = Path(sys.argv[1])
    if not bundle.exists():
        raise SystemExit(f"xcresult not found: {bundle}")

    proc = run("xcrun", "xcresulttool", "get", "test-results", "summary", "--path", str(bundle), "--format", "json")
    if proc.returncode != 0:
        print(json.dumps({"bundle": str(bundle), "tests": [], "parserWarning": proc.stderr.strip()}, indent=2))
        return

    raw = json.loads(proc.stdout)
    tests = []
    for item in raw.get("testFailures", []):
        tests.append({
            "test": item.get("testName", "unknown"),
            "status": "failed",
            "duration": item.get("duration", 0),
            "failureMessage": item.get("failureText", ""),
        })

    output = {
        "bundle": str(bundle),
        "summary": raw.get("result", raw.get("statistics", {})),
        "tests": tests,
    }
    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
