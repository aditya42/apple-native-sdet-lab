#!/usr/bin/env python3
"""Enforce absolute XCTest performance budgets from normalized xcresult data."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def evaluate(data: dict, budgets: dict) -> tuple[list[str], int]:
    problems = []
    checked = 0
    for test_name, rule in budgets.items():
        matches = [t for t in data.get("tests", []) if test_name in str(t.get("test", ""))]
        if not matches:
            problems.append(f"MISSING: {test_name} (cannot assert performance budget)")
            continue
        for result in matches:
            if result.get("status") != "passed":
                problems.append(f"FAILED: {test_name} ({result.get('status')})")
                continue
            duration = result.get("duration")
            if duration is None:
                problems.append(f"MISSING_DURATION: {test_name}")
                continue
            checked += 1
            if float(duration) > float(rule["maxDurationSeconds"]):
                problems.append(
                    f"SLOW: {test_name} {duration}s > {rule['maxDurationSeconds']}s"
                )
    return problems, checked


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("results")
    parser.add_argument("--budgets", default="config/performance-budgets.json")
    args = parser.parse_args()
    data = json.loads(Path(args.results).read_text())
    budgets = json.loads(Path(args.budgets).read_text())
    issues, checked = evaluate(data, budgets)
    for issue in issues:
        print(issue)
    print(f"Performance gate: {checked} assertions checked, {len(issues)} violations")
    if issues:
        sys.exit(1)


if __name__ == "__main__":
    main()
