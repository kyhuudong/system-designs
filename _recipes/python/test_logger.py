"""Tests for logger recipe."""
from __future__ import annotations

import io
import json
import logging

from logger import get_logger


def test_logger_emits_json_lines() -> None:
    buf = io.StringIO()
    log = get_logger("test_emits", stream=buf, level=logging.INFO)
    log.info("hello", extra={"user_id": 42})
    line = buf.getvalue().strip()
    payload = json.loads(line)
    assert payload["level"] == "INFO"
    assert payload["logger"] == "test_emits"
    assert payload["message"] == "hello"
    assert payload["user_id"] == 42
    assert "timestamp" in payload


def test_logger_respects_level() -> None:
    buf = io.StringIO()
    log = get_logger("test_level", stream=buf, level=logging.WARNING)
    log.info("ignored")
    log.warning("kept")
    lines = [ln for ln in buf.getvalue().splitlines() if ln]
    assert len(lines) == 1
    assert json.loads(lines[0])["message"] == "kept"


def test_logger_serializes_exception() -> None:
    buf = io.StringIO()
    log = get_logger("test_exc", stream=buf, level=logging.ERROR)
    try:
        raise ValueError("boom")
    except ValueError:
        log.exception("oops")
    payload = json.loads(buf.getvalue().strip())
    assert payload["message"] == "oops"
    assert "ValueError" in payload["exception"]
    assert "boom" in payload["exception"]


def test_logger_returns_same_instance_for_same_name() -> None:
    buf1 = io.StringIO()
    a = get_logger("test_dup", stream=buf1)
    b = get_logger("test_dup", stream=buf1)
    assert a is b
