#!/usr/bin/env python3
"""Persist normalized XCTest outcomes and calculate evidence-based flaky scores."""
from __future__ import annotations

import argparse
import json
import math
import os
import sqlite3
from datetime import datetime, timezone
from pathlib import Path

SCHEMA = """
CREATE TABLE IF NOT EXISTS runs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    run_key TEXT NOT NULL UNIQUE,
    recorded_at TEXT NOT NULL,
    source_bundle TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS outcomes (
    run_id INTEGER NOT NULL REFERENCES runs(id),
    test_name TEXT NOT NULL,
    status TEXT NOT NULL CHECK(status IN ('passed', 'failed', 'skipped')),
    duration_seconds REAL NOT NULL DEFAULT 0,
    category TEXT NOT NULL DEFAULT '',
    PRIMARY KEY (run_id, test_name)
);
CREATE INDEX IF NOT EXISTS outcomes_test_idx ON outcomes(test_name, run_id);
"""


def connect(path: Path) -> sqlite3.Connection:
    path.parent.mkdir(parents=True, exist_ok=True)
    connection = sqlite3.connect(path)
    connection.executescript(SCHEMA)
    return connection


def ingest(connection: sqlite3.Connection, data: dict, key: str) -> bool:
    rows = data.get("tests", [])
    normalized = []
    for row in rows:
        status = str(row.get("status", "")).lower()
        if status in {"success", "passed", "pass"}:
            status = "passed"
        elif status in {"failure", "failed", "fail"}:
            status = "failed"
        elif status in {"skipped", "skip"}:
            status = "skipped"
        else:
            continue
        name = row.get("test") or row.get("testName") or row.get("nodeIdentifier")
        if not name:
            continue
        normalized.append((str(name), status, float(row.get("duration") or 0),
                           str(row.get("failureCategory") or "")))
    if not normalized:
        return False
    with connection:
        cursor = connection.execute(
            "INSERT OR IGNORE INTO runs(run_key, recorded_at, source_bundle) VALUES(?,?,?)",
            (key, datetime.now(timezone.utc).isoformat(), str(data.get("bundle", ""))),
        )
        if cursor.rowcount == 0:
            return False
        run_id = cursor.lastrowid
        connection.executemany(
            "INSERT OR REPLACE INTO outcomes(run_id, test_name, status, duration_seconds, category)"
            " VALUES(?,?,?,?,?)",
            ((run_id, *row) for row in normalized),
        )
    return True


def score(connection: sqlite3.Connection, minimum_runs: int = 5) -> list[dict]:
    names = [row[0] for row in connection.execute("SELECT DISTINCT test_name FROM outcomes ORDER BY test_name")]
    output = []
    for name in names:
        statuses = [
            row[0] for row in connection.execute(
                "SELECT status FROM outcomes WHERE test_name=? AND status!='skipped' ORDER BY run_id",
                (name,),
            )
        ]
        count = len(statuses)
        if not count:
            continue
        fails = sum(s == "failed" for s in statuses)
        transitions = sum(a != b for a, b in zip(statuses, statuses[1:]))
        fail_rate = fails / count
        transition_rate = transitions / max(1, count - 1)
        # Wilson upper bound avoids overconfidence with small samples.
        z = 1.96
        upper = (fail_rate + z*z/(2*count) + z*math.sqrt(
            (fail_rate*(1-fail_rate) + z*z/(4*count))/count
        )) / (1+z*z/count)
        flaky = count >= minimum_runs and fails > 0 and fails < count and transitions > 0
        output.append({
            "test": name, "samples": count, "failures": fails,
            "failureRate": round(fail_rate, 4),
            "transitionRate": round(transition_rate, 4),
            "wilsonFailureUpper95": round(upper, 4),
            "flakyScore": round(100*(0.65*transition_rate + 0.35*fail_rate), 2),
            "classification": "FLAKY" if flaky else (
                "INSUFFICIENT_HISTORY" if count < minimum_runs else
                "CONSISTENT_FAILURE" if fails == count else "STABLE"
            ),
        })
    return output


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", default="reports/history.sqlite")
    parser.add_argument("--ingest", help="Path to classified normalized JSON")
    parser.add_argument("--run-key", help="Unique CI run key, protects against repeated imports")
    parser.add_argument("--output", default="reports/flaky-scores.json")
    parser.add_argument("--minimum-runs", type=int, default=5)
    args = parser.parse_args()
    with connect(Path(args.db)) as connection:
        if args.ingest:
            data = json.loads(Path(args.ingest).read_text())
            key = args.run_key or os.environ.get("GITHUB_RUN_ID", "") + ":" + os.environ.get("GITHUB_RUN_ATTEMPT", "")
            if not key.strip(":"):
                key = str(Path(args.ingest).resolve()) + ":" + str(Path(args.ingest).stat().st_mtime_ns)
            ingest(connection, data, key)
        rows = score(connection, args.minimum_runs)
    target = Path(args.output)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps({"tests": rows}, indent=2))
    print(f"History: {args.db}; scored {len(rows)} tests -> {target}")


if __name__ == "__main__":
    main()
