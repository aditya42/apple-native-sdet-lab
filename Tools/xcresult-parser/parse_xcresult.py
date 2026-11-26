#!/usr/bin/env python3
"""Normalize xcresult test summaries and detailed test trees into per-test JSON."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


def run(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, text=True, capture_output=True, check=False)


def children(node: dict):
    for item in node.get("testNodes", []):
        if isinstance(item, dict):
            yield item
            yield from children(item)


def normalized_tests(tree: dict, failures: list[dict]) -> list[dict]:
    failures_by_name = {}
    for failure in failures:
        name = str(failure.get("testName", ""))
        failures_by_name[name] = failure.get("failureText", "")
    tests = []
    seen = set()
    for node in children(tree):
        identifier = str(node.get("nodeIdentifier") or node.get("name") or "")
        node_type = str(node.get("nodeType") or "").lower()
        result = str(node.get("result") or "").lower()
        if not identifier or not (node_type in {"test case", "testcase", "test"} or
                                  (result and "test" in node_type)):
            continue
        status = {"passed": "passed", "success": "passed", "failed": "failed",
                  "failure": "failed", "skipped": "skipped"}.get(result)
        if not status or identifier in seen:
            continue
        seen.add(identifier)
        message = next((value for name, value in failures_by_name.items()
                        if name in identifier or identifier.endswith(name)), "")
        tests.append({
            "test": identifier, "status": status,
            "duration": node.get("duration"),
            "failureMessage": message,
        })
    for name, message in failures_by_name.items():
        if not any(name in t["test"] for t in tests):
            tests.append({"test": name or "unknown", "status": "failed",
                          "duration": None, "failureMessage": message})
    return tests


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: parse_xcresult.py path/to/Test.xcresult")
    bundle = Path(sys.argv[1])
    if not bundle.exists():
        raise SystemExit(f"xcresult not found: {bundle}")
    cmd = ("xcrun", "xcresulttool", "get", "test-results")
    summary = run(*cmd, "summary", "--path", str(bundle), "--format", "json")
    if summary.returncode != 0:
        raise SystemExit(f"Cannot parse xcresult summary: {summary.stderr.strip()}")
    raw = json.loads(summary.stdout)
    tree_result = run(*cmd, "tests", "--path", str(bundle), "--format", "json")
    if tree_result.returncode != 0:
        raise SystemExit(f"Cannot parse xcresult tests: {tree_result.stderr.strip()}")
    tree = json.loads(tree_result.stdout)
    print(json.dumps({
        "bundle": str(bundle),
        "summary": raw.get("result", raw.get("statistics", {})),
        "tests": normalized_tests(tree, raw.get("testFailures", [])),
    }, indent=2))


if __name__ == "__main__":
    main()
