#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path

RULES = [
    ("NETWORK_FAILURE", re.compile(r"network|connection|offline|NSURLError", re.I)),
    ("TIMEOUT", re.compile(r"timed out|timeout|waitForExistence", re.I)),
    ("PERFORMANCE_REGRESSION", re.compile(r"performance|baseline|standard deviation", re.I)),
    ("INFRASTRUCTURE_FAILURE", re.compile(r"simulator|xcodebuild|destination|boot", re.I)),
    ("ASSERTION_FAILURE", re.compile(r"XCTAssert|failed -|assertion", re.I)),
]


def classify(message: str) -> str:
    for category, pattern in RULES:
        if pattern.search(message or ""):
            return category
    return "UNKNOWN"


def main() -> None:
    path = Path(sys.argv[1])
    data = json.loads(path.read_text())
    for test in data.get("tests", []):
        test["failureCategory"] = classify(test.get("failureMessage", ""))
    print(json.dumps(data, indent=2))


if __name__ == "__main__":
    main()
