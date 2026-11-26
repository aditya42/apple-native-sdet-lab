#!/usr/bin/env python3
"""Import reliability CSV iterations as independent historical observations."""
import argparse
import csv
import importlib.util
import os
import sys
from pathlib import Path

spec = importlib.util.spec_from_file_location("history", Path(__file__).with_name("history.py"))
history = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = history
spec.loader.exec_module(history)

def main():
    p = argparse.ArgumentParser()
    p.add_argument("csv_file")
    p.add_argument("--db", default="reports/history.sqlite")
    args = p.parse_args()
    test_name = os.environ.get("RELIABILITY_TEST", "ContactLabUITests/ContactCRUDUITests/testCreateContact")
    run_id = os.environ.get("GITHUB_RUN_ID", "local")
    with history.connect(Path(args.db)) as connection:
        with open(args.csv_file, newline="") as handle:
            for row in csv.DictReader(handle):
                history.ingest(connection, {
                    "bundle": row["result_bundle"],
                    "tests": [{"test": test_name,
                               "status": "passed" if row["status"] == "PASS" else "failed",
                               "duration": float(row["duration_seconds"])}]
                }, f"reliability:{run_id}:{row['result_bundle']}:{row['run']}")

if __name__ == "__main__":
    main()
