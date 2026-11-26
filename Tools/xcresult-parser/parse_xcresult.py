#!/usr/bin/env python3
"""Normalize modern xcresulttool test-results trees into per-test JSON."""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path


def run(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, text=True, capture_output=True, check=False)


def children(node: dict):
    """The modern xcresulttool tree nests child nodes under 'children'."""
    for child in node.get("children", []) + node.get("testNodes", []):
        if isinstance(child, dict):
            yield child
            yield from children(child)


def parse_duration(value: object) -> float | None:
    """Parse xcresult durations, including '0.021s', '250ms', and '1m 11s'."""
    if value is None or value == "":
        return None
    if isinstance(value, (int, float)):
        return float(value)
    raw = str(value).strip()
    # Older fixtures and some xcresult schemas contain numeric strings in seconds.
    if re.fullmatch(r"[0-9]+(?:\.[0-9]+)?", raw):
        return float(raw)
    # xcresulttool emits compact or composite duration strings.
    parts = list(re.finditer(r"([0-9]+(?:\.[0-9]+)?)\s*(ms|h|m|s)", raw))
    if not parts or re.sub(r"[0-9]+(?:\.[0-9]+)?\s*(?:ms|h|m|s)", "", raw).strip():
        raise ValueError(f"Unsupported xcresult duration: {value!r}")
    factors = {"ms": 0.001, "s": 1.0, "m": 60.0, "h": 3600.0}
    return sum(float(part.group(1)) * factors[part.group(2)] for part in parts)


def normalized_tests(tree: dict, failures: list[dict]) -> list[dict]:
    failure_messages = {
        str(item.get("testName", "")): str(item.get("failureText", ""))
        for item in failures if item.get("testName")
    }
    results = []
    seen = set()
    for node in children(tree):
        if str(node.get("nodeType", "")).lower() not in ("test case", "testcase"):
            continue
        identifier = str(node.get("nodeIdentifier") or node.get("name") or "")
        status = {
            "passed": "passed", "success": "passed",
            "failed": "failed", "failure": "failed",
            "skipped": "skipped", "expected failure": "passed",
        }.get(str(node.get("result", "")).lower())
        if not identifier or not status or identifier in seen:
            continue
        seen.add(identifier)
        duration = node.get("duration")
        message = next((
            value for name, value in failure_messages.items()
            if name in identifier or identifier.endswith(name)
        ), "")
        results.append({
            "test": identifier,
            "status": status,
            "duration": parse_duration(duration),
            "failureMessage": message,
        })
    for name, message in failure_messages.items():
        if not any(name in item["test"] for item in results):
            results.append({
                "test": name, "status": "failed",
                "duration": None, "failureMessage": message,
            })
    return results


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: parse_xcresult.py path/to/Result.xcresult")
    bundle = Path(sys.argv[1])
    if not bundle.exists():
        raise SystemExit(f"xcresult not found: {bundle}")
    cmd = ("xcrun", "xcresulttool", "get", "test-results")
    summary = run(*cmd, "summary", "--path", str(bundle), "--format", "json")
    if summary.returncode != 0:
        raise SystemExit(f"Cannot parse xcresult summary: {summary.stderr.strip()}")
    raw = json.loads(summary.stdout)
    tests = run(*cmd, "tests", "--path", str(bundle), "--format", "json")
    if tests.returncode != 0:
        raise SystemExit(f"Cannot parse xcresult tests: {tests.stderr.strip()}")
    tree = json.loads(tests.stdout)
    normalized = normalized_tests(tree, raw.get("testFailures", []))
    if not normalized:
        raise SystemExit("No per-test results in xcresult; refusing empty report")
    print(json.dumps({
        "bundle": str(bundle),
        "summary": raw.get("result", raw.get("statistics", {})),
        "tests": normalized,
    }, indent=2))


if __name__ == "__main__":
    main()
