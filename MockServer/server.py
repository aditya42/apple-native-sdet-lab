#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FIXTURES = ROOT / "fixtures"
STATE = {"scenario": "normal", "requests": 0}
LOCK = threading.Lock()
ALLOWED = {
    "normal", "empty", "server_error", "service_unavailable", "slow_3s",
    "timeout", "malformed_json", "retry_then_success",
}


class Handler(BaseHTTPRequestHandler):
    server_version = "ContactLabMock/2.0"

    def _json(self, status: int, payload) -> None:
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        try:
            self.wfile.write(body)
        except (BrokenPipeError, ConnectionResetError):
            pass

    def do_GET(self):  # noqa: N802
        if self.path == "/health":
            with LOCK:
                state = dict(STATE)
            return self._json(200, {"status": "ok", **state})
        if self.path != "/contacts":
            return self._json(404, {"error": "not_found"})

        with LOCK:
            scenario = STATE["scenario"]
            STATE["requests"] += 1
            request_number = STATE["requests"]

        if scenario == "retry_then_success" and request_number <= 2:
            return self._json(503, {"error": "transient_error", "attempt": request_number})
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
        try:
            payload = json.loads(self.rfile.read(length) or b"{}")
        except (ValueError, UnicodeDecodeError):
            return self._json(400, {"error": "invalid_json"})
        scenario = payload.get("scenario", "normal")
        if scenario not in ALLOWED:
            return self._json(400, {"error": "unsupported_scenario", "allowed": sorted(ALLOWED)})
        with LOCK:
            STATE["scenario"] = scenario
            STATE["requests"] = 0
        return self._json(200, {"scenario": scenario, "requests": 0})

    def log_message(self, fmt, *args):
        print("[mock]", fmt % args)


def main() -> None:
    host = os.getenv("MOCK_HOST", "127.0.0.1")
    port = int(os.getenv("MOCK_PORT", "8080"))
    print(f"ContactLab mock server listening on http://{host}:{port}")
    ThreadingHTTPServer((host, port), Handler).serve_forever()


if __name__ == "__main__":
    main()
