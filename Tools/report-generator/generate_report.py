#!/usr/bin/env python3
import csv
import html
import json
import sys
from pathlib import Path


def main() -> None:
    if len(sys.argv) < 3:
        raise SystemExit("usage: generate_report.py input.json output.html")
    data = json.loads(Path(sys.argv[1]).read_text())
    rows = data.get("tests", [])
    table = "".join(
        f"<tr><td>{html.escape(str(r.get('test','')))}</td><td>{html.escape(str(r.get('status','')))}</td>"
        f"<td>{html.escape(str(r.get('duration','')))}</td><td>{html.escape(str(r.get('failureCategory','')))}</td>"
        f"<td><pre>{html.escape(str(r.get('failureMessage','')))}</pre></td></tr>" for r in rows
    )
    page = f"""<!doctype html><html><head><meta charset='utf-8'><title>ContactLab Test Report</title>
<style>body{{font-family:-apple-system,BlinkMacSystemFont,sans-serif;max-width:1200px;margin:40px auto;padding:0 20px}}table{{border-collapse:collapse;width:100%}}th,td{{border:1px solid #ddd;padding:8px;text-align:left}}pre{{white-space:pre-wrap}}</style></head>
<body><h1>ContactLab Test Report</h1><p>XCResult: {html.escape(str(data.get('bundle','')))}</p>
<table><thead><tr><th>Test</th><th>Status</th><th>Duration</th><th>Category</th><th>Failure</th></tr></thead><tbody>{table}</tbody></table></body></html>"""
    Path(sys.argv[2]).write_text(page)


if __name__ == "__main__":
    main()
