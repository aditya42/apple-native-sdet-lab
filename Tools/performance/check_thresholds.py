#!/usr/bin/env python3
"""Enforce whole-test runtime guardrails using normalized xcresult results."""
from __future__ import annotations
import argparse
import json
import sys
from pathlib import Path

def evaluate(data: dict, budgets: dict):
    issues = []
    checked = 0
    for name, rule in budgets.items():
        matches = [item for item in data.get("tests", []) if name in item.get("test", "")]
        if not matches:
            issues.append(f"MISSING: {name}")
        for item in matches:
            if item.get("status") != "passed":
                issues.append(f"FAILED: {name}: {item.get('status')}")
            elif item.get("duration") is None:
                issues.append(f"MISSING_DURATION: {name}")
            else:
                checked += 1
                if float(item["duration"]) > float(rule["maxDurationSeconds"]):
                    issues.append(f"SLOW: {name} exceeded {rule['maxDurationSeconds']}s")
    return issues, checked

def main():
    p = argparse.ArgumentParser()
    p.add_argument("results")
    p.add_argument("--budgets", default="config/performance-budgets.json")
    args = p.parse_args()
    data = json.loads(Path(args.results).read_text())
    budgets = json.loads(Path(args.budgets).read_text())
    issues, checked = evaluate(data, budgets)
    for issue in issues:
        print(issue)
    print(f"Performance guardrail: {checked} checks, {len(issues)} violations")
    if issues:
        sys.exit(1)

if __name__ == "__main__":
    main()
