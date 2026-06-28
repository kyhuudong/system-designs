# Recipe: JSON-line structured logger built on stdlib `logging`
# Stdlib-only.
# Usage:
#   from logger import get_logger
#   log = get_logger("my-service")
#   log.info("started", extra={"port": 8080})
#
# Every log record is emitted as a single JSON object per line containing
# at minimum: timestamp, level, logger, message. Anything you pass via
# `extra={...}` is merged into the JSON object at the top level.
from __future__ import annotations

import json
import logging
import sys
from datetime import datetime, timezone
from typing import IO, Any

_RESERVED = {
    "args", "asctime", "created", "exc_info", "exc_text", "filename",
    "funcName", "levelname", "levelno", "lineno", "message", "module",
    "msecs", "msg", "name", "pathname", "process", "processName",
    "relativeCreated", "stack_info", "thread", "threadName", "taskName",
}


class _JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload: dict[str, Any] = {
            "timestamp": datetime.fromtimestamp(record.created, tz=timezone.utc).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }
        for key, value in record.__dict__.items():
            if key in _RESERVED or key.startswith("_"):
                continue
            payload[key] = value
        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)
        return json.dumps(payload, default=str)


def get_logger(
    name: str,
    *,
    level: int = logging.INFO,
    stream: IO[str] | None = None,
) -> logging.Logger:
    """Return a logger configured with a single JSON-line StreamHandler.

    Idempotent for a given `name` — repeated calls return the same logger and do
    not duplicate handlers. `stream` defaults to sys.stderr.
    """
    log = logging.getLogger(name)
    log.setLevel(level)
    log.propagate = False
    if not log.handlers:
        handler = logging.StreamHandler(stream or sys.stderr)
        handler.setFormatter(_JsonFormatter())
        log.addHandler(handler)
    else:
        for h in log.handlers:
            h.setLevel(level)
    return log
