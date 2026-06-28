"""Tests for healthcheck recipe."""
from __future__ import annotations

import json
import threading
from http.client import HTTPConnection
from http.server import HTTPServer

from healthcheck import HealthHandler, set_ready


def _start_server() -> tuple[HTTPServer, threading.Thread]:
    server = HTTPServer(("127.0.0.1", 0), HealthHandler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    return server, thread


def _get(server: HTTPServer, path: str) -> tuple[int, dict[str, object]]:
    conn = HTTPConnection(*server.server_address)
    conn.request("GET", path)
    resp = conn.getresponse()
    body = resp.read()
    conn.close()
    return resp.status, json.loads(body)


def test_health_endpoint_is_always_ok() -> None:
    server, _ = _start_server()
    try:
        status, body = _get(server, "/health")
        assert status == 200
        assert body == {"status": "ok"}
    finally:
        server.shutdown()


def test_ready_is_503_until_set_ready_true() -> None:
    set_ready(False)
    server, _ = _start_server()
    try:
        status, body = _get(server, "/ready")
        assert status == 503
        assert body == {"status": "not_ready"}

        set_ready(True)
        status, body = _get(server, "/ready")
        assert status == 200
        assert body == {"status": "ready"}
    finally:
        server.shutdown()
        set_ready(False)


def test_unknown_path_returns_404() -> None:
    server, _ = _start_server()
    try:
        status, _ = _get(server, "/nope")
        assert status == 404
    finally:
        server.shutdown()
