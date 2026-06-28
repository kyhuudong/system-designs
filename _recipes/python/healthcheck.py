# Recipe: /health and /ready HTTP handlers, stdlib only
# Stdlib-only.
# Usage:
#   from http.server import HTTPServer
#   from healthcheck import HealthHandler, set_ready
#
#   server = HTTPServer(("0.0.0.0", 8080), HealthHandler)
#   set_ready(True)
#   server.serve_forever()
#
# /health  -> 200 {"status":"ok"} always
# /ready   -> 200 {"status":"ready"} or 503 {"status":"not_ready"} based on set_ready()
from __future__ import annotations

import json
import threading
from http.server import BaseHTTPRequestHandler

_ready_lock = threading.Lock()
_ready = False


def set_ready(value: bool) -> None:
    """Mark the service as ready (or not). Thread-safe."""
    global _ready
    with _ready_lock:
        _ready = bool(value)


def _is_ready() -> bool:
    with _ready_lock:
        return _ready


class HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        if self.path == "/health":
            self._json(200, {"status": "ok"})
        elif self.path == "/ready":
            if _is_ready():
                self._json(200, {"status": "ready"})
            else:
                self._json(503, {"status": "not_ready"})
        else:
            self._json(404, {"status": "not_found", "path": self.path})

    def _json(self, status: int, payload: dict[str, object]) -> None:
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format: str, *args: object) -> None:  # noqa: A002
        return
