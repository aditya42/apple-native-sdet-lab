#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FIXTURES = ROOT / "fixtures"
STATE = {"scenario": "normal"}


class Handler(BaseHTTPRequestHandler):
    server_version = "ContactLabMock/1.0"

    def _json(self, status: int, payload) -> None:
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):  # noqa: N802
        if self.path == "/health":
            return self._json(200, {"status": "ok", "scenario": STATE["scenario"]})
        if self.path != "/contacts":
            return self._json(404, {"error": "not_found"})

        scenario = STATE["scenario"]
        if scenario == "server_error":
            return self._json(500, {"error": "internal_server_error"})
        if scenario == "service_unavailable":
            return self._json(503, {"error": "service_unavailable"})
        if scenario == "slow_3s":
            time.sleep(3)
        if scenario == "timeout":
            time.sleep(30)
        if scenario == "malformed_json":
            body = b'{"contacts": [invalid]'
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            return self.wfile.write(body)
        if scenario == "empty":
            return self._json(200, [])

        contacts = json.loads((FIXTURES / "contacts.json").read_text())
        return self._json(200, contacts)

    def do_POST(self):  # noqa: N802
        if self.path != "/test/scenario":
            return self._json(404, {"error": "not_found"})
        length = int(self.headers.get("Content-Length", "0"))
        payload = json.loads(self.rfile.read(length) or b"{}")
        scenario = payload.get("scenario", "normal")
        allowed = {"normal", "empty", "server_error", "service_unavailable", "slow_3s", "timeout", "malformed_json"}
        if scenario not in allowed:
            return self._json(400, {"error": "unsupported_scenario", "allowed": sorted(allowed)})
        STATE["scenario"] = scenario
        return self._json(200, {"scenario": scenario})

    def log_message(self, fmt, *args):
        print("[mock]", fmt % args)


def main() -> None:
    host = os.getenv("MOCK_HOST", "127.0.0.1")
    port = int(os.getenv("MOCK_PORT", "8080"))
    print(f"ContactLab mock server listening on http://{host}:{port}")
    ThreadingHTTPServer((host, port), Handler).serve_forever()


if __name__ == "__main__":
    main()
