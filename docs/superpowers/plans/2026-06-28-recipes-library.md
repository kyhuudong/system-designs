# Recipes Library (Plan B) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish the `_recipes/` library and `make recipes-test` runner with a focused starter set of utility recipes (Python + Node) and a couple of compose snippets. Provides the foundation for adding more recipes ad-hoc later.

**Architecture:** Flat library under `_recipes/{compose,python,node}/`. Each code recipe is fully self-contained, stdlib-only (no external deps for the starter set), with a co-located test file. A `scripts/recipes-test.sh` runner copies each recipe + its test into a tmp dir and runs vitest / pytest in an ephemeral environment, then aggregates results.

**Tech Stack:** Python (stdlib only for starter recipes; uv for ephemeral test envs), TypeScript (Node stdlib; pnpm dlx vitest for tests), bash, GNU Make.

**Spec:** [`docs/superpowers/specs/2026-06-28-shared-services-and-recipes-design.md`](../specs/2026-06-28-shared-services-and-recipes-design.md)

**Scope decision (different from full spec):** Implement a focused starter set first. Cloud-client recipes (localstack, pubsub) are deferred to a follow-up plan because they introduce external dependency management to the test runner, which is a larger design problem. Starter set is enough to validate the architecture and immediately useful.

**In scope (this plan):**
- 4 Python utility recipes + tests: `retry`, `logger`, `env`, `healthcheck`
- 4 Node utility recipes + tests: `retry`, `logger`, `env`, `healthcheck`
- 2 compose snippets: `postgres-with-adminer.yml`, `kafka-kraft.yml`
- `_recipes/README.md` (top-level index) + per-subdir READMEs
- `scripts/recipes-test.sh` runner + `make recipes-test` target + smoke test for the runner

**Deferred (a follow-up plan):**
- Python cloud clients: `localstack_clients.py`, `pubsub_emulator.py`
- Node cloud clients: `localstack-clients.ts`, `pubsub-emulator.ts`
- Additional compose snippets (`postgres-replication`, `redis-cluster`, `kafka-3-broker`, `nginx-load-balancer`)
- Additional utilities (`timing`)

---

## File Map

**Create:**
- `_recipes/README.md` — top-level index
- `_recipes/compose/README.md`
- `_recipes/compose/postgres-with-adminer.yml`
- `_recipes/compose/kafka-kraft.yml`
- `_recipes/python/README.md`
- `_recipes/python/retry.py` + `test_retry.py`
- `_recipes/python/logger.py` + `test_logger.py`
- `_recipes/python/env.py` + `test_env.py`
- `_recipes/python/healthcheck.py` + `test_healthcheck.py`
- `_recipes/node/README.md`
- `_recipes/node/retry.ts` + `retry.test.ts`
- `_recipes/node/logger.ts` + `logger.test.ts`
- `_recipes/node/env.ts` + `env.test.ts`
- `_recipes/node/healthcheck.ts` + `healthcheck.test.ts`
- `scripts/recipes-test.sh` — the runner
- `scripts/tests/test_recipes_runner.sh` — smoke test for the runner

**Modify:**
- `Makefile` — add `recipes-test` target

---

## Task 1: `_recipes/` skeleton

Create the directory structure and index READMEs. No code yet.

**Files:**
- Create: `_recipes/README.md`
- Create: `_recipes/compose/README.md`
- Create: `_recipes/python/README.md`
- Create: `_recipes/node/README.md`

- [ ] **Step 1: Create directories**

```bash
mkdir -p /Users/dong.kyh/works/system-designs/_recipes/{compose,python,node}
```

- [ ] **Step 2: Create `_recipes/README.md`**

```markdown
# Recipes

A library of copy-paste snippets for repeating patterns across projects.

**Recipes are documentation, not dependencies.** Projects copy what they need
into their own `src/` or `docker-compose.yml`. Nothing in a project `imports`
from `_recipes/`. Bug fixes don't propagate automatically — that's intentional.
The point is to *see* the code, not call into magic.

## Structure

- [`compose/`](./compose/README.md) — docker-compose snippets to merge into a
  project's compose file (Postgres with Adminer, Kafka in KRaft mode, …)
- [`python/`](./python/README.md) — Python code snippets (retry, logger,
  env loader, healthcheck handlers, …)
- [`node/`](./node/README.md) — TypeScript code snippets (same set, Node flavor)

## Running tests

Every code recipe ships with a co-located test. Run them all:

```bash
make recipes-test
```

The runner copies each recipe + its test into a tmp dir and runs vitest /
pytest in an ephemeral environment, so the test result reflects only the recipe
itself with no leaking from your global setup.

## Index (by topic)

### App utilities
- `python/retry.py`, `node/retry.ts` — exponential backoff retry helper
- `python/logger.py`, `node/logger.ts` — JSON-line structured logger
- `python/env.py`, `node/env.ts` — typed env-var loader with `required` / `default`
- `python/healthcheck.py`, `node/healthcheck.ts` — `/health` + `/ready` HTTP handlers

### Storage
- `compose/postgres-with-adminer.yml` — Postgres + Adminer web UI

### Messaging
- `compose/kafka-kraft.yml` — single-broker Kafka in KRaft mode (no Zookeeper)

## Adding a new recipe

1. Drop the file under `_recipes/<kind>/`.
2. Add a co-located test (if it's a code recipe).
3. Add a top-of-file comment block:
   ```
   # Recipe: <one-line description>
   # Stdlib-only.  (or:  Requires: <pkg> ≥ <version>)
   # Usage:
   #   <minimal 1–3 line example>
   ```
4. Add an entry to the topic-grouped index above and to the per-subdir README.
5. Run `make recipes-test`.
```

- [ ] **Step 3: Create `_recipes/compose/README.md`**

```markdown
# Compose recipes

Drop-in `docker-compose` snippets you copy into a project's `docker-compose.yml`.

Each file starts with a comment header explaining what it provides and how to
merge it (the snippet uses YAML anchors and a `services:` block — you append
the services to your file, do not include the whole file as-is unless the
project's compose is empty).

## Available

- `postgres-with-adminer.yml` — Postgres 16 + Adminer web UI on :8080
- `kafka-kraft.yml` — single-broker Kafka 3.7 in KRaft mode (no Zookeeper)
```

- [ ] **Step 4: Create `_recipes/python/README.md`**

```markdown
# Python recipes

Copy any of these files into your project's `src/` (rename if you want) and
import as a normal local module.

All starter recipes are **stdlib-only** — no extra dependencies to install.

## Available

- `retry.py` — exponential backoff retry decorator
- `logger.py` — JSON-line structured logger built on stdlib `logging`
- `env.py` — typed env-var loader (`get_str`, `get_int`, `get_bool`, `require`)
- `healthcheck.py` — minimal `/health` and `/ready` HTTP handlers (stdlib `HTTPServer`)

## Convention

Each recipe is one file with its own co-located `test_<name>.py`. Read the
top-of-file comment for usage; read the test for behavior.
```

- [ ] **Step 5: Create `_recipes/node/README.md`**

```markdown
# Node recipes (TypeScript)

Copy any of these files into your project's `src/` (rename if you want) and
import as a normal local module.

All starter recipes use **only Node stdlib** (`node:http`, `process`, etc.) — no
extra dependencies to install. Tests use vitest, which is already in the Node
template's devDependencies.

## Available

- `retry.ts` — exponential backoff retry helper
- `logger.ts` — JSON-line structured logger
- `env.ts` — typed env-var loader with TypeScript generics
- `healthcheck.ts` — minimal `/health` and `/ready` HTTP handlers (`node:http`)

## Convention

Each recipe is one file with its own co-located `<name>.test.ts`. Read the
top-of-file comment for usage; read the test for behavior.
```

- [ ] **Step 6: Commit**

```bash
cd /Users/dong.kyh/works/system-designs
git add _recipes/
git commit -m "feat(_recipes): add recipes library skeleton with index READMEs

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 2: Python utility recipes (4 files + 4 tests)

Each recipe is small, stdlib-only, with a co-located test. We do this TDD-style per recipe — write the test, see it fail, write the recipe, see it pass.

Note: at this point the `make recipes-test` target doesn't exist yet, so we exercise tests by running pytest directly in a tmp dir.

**Files:**
- Create: `_recipes/python/retry.py` + `test_retry.py`
- Create: `_recipes/python/logger.py` + `test_logger.py`
- Create: `_recipes/python/env.py` + `test_env.py`
- Create: `_recipes/python/healthcheck.py` + `test_healthcheck.py`

### 2A. `retry.py`

- [ ] **Step 1: Create `_recipes/python/test_retry.py`**

```python
"""Tests for retry recipe."""
from __future__ import annotations

import time

import pytest

from retry import RetryError, retry


def test_retry_passes_through_on_first_success() -> None:
    calls = {"n": 0}

    @retry(max_attempts=3, base_delay=0.0)
    def f() -> int:
        calls["n"] += 1
        return 42

    assert f() == 42
    assert calls["n"] == 1


def test_retry_succeeds_after_transient_failures() -> None:
    calls = {"n": 0}

    @retry(max_attempts=5, base_delay=0.0)
    def f() -> str:
        calls["n"] += 1
        if calls["n"] < 3:
            raise RuntimeError("nope")
        return "ok"

    assert f() == "ok"
    assert calls["n"] == 3


def test_retry_gives_up_after_max_attempts() -> None:
    calls = {"n": 0}

    @retry(max_attempts=3, base_delay=0.0)
    def f() -> None:
        calls["n"] += 1
        raise RuntimeError("always")

    with pytest.raises(RetryError) as exc:
        f()
    assert calls["n"] == 3
    assert isinstance(exc.value.__cause__, RuntimeError)


def test_retry_respects_only_clause() -> None:
    """retry should not catch exceptions outside `only=`."""
    calls = {"n": 0}

    @retry(max_attempts=5, base_delay=0.0, only=(ValueError,))
    def f() -> None:
        calls["n"] += 1
        raise KeyError("not retried")

    with pytest.raises(KeyError):
        f()
    assert calls["n"] == 1


def test_retry_backoff_uses_base_delay() -> None:
    """Smoke test: with base_delay=0.05 and 3 attempts, total >= ~0.05 + ~0.10."""
    calls = {"n": 0}

    @retry(max_attempts=3, base_delay=0.05, jitter=0.0)
    def f() -> None:
        calls["n"] += 1
        raise RuntimeError

    start = time.monotonic()
    with pytest.raises(RetryError):
        f()
    elapsed = time.monotonic() - start
    # 2 sleeps: 0.05 and 0.10. Allow for scheduling slack.
    assert elapsed >= 0.10
```

- [ ] **Step 2: Run the test in a tmp dir — expect FAIL (no retry module)**

```bash
TMP=$(mktemp -d)
cp /Users/dong.kyh/works/system-designs/_recipes/python/test_retry.py "$TMP/"
( cd "$TMP" && uv run --no-project --with pytest pytest -q test_retry.py 2>&1 | tail -10 )
rm -rf "$TMP"
```
Expected: pytest reports collection errors (no `retry` module to import). FAIL.

- [ ] **Step 3: Create `_recipes/python/retry.py`**

```python
# Recipe: exponential-backoff retry decorator
# Stdlib-only.
# Usage:
#   from retry import retry, RetryError
#
#   @retry(max_attempts=5, base_delay=0.1)
#   def fetch_or_die() -> bytes:
#       ...
#
# Exceptions outside `only=` propagate immediately. After max_attempts
# failures the last caught exception is re-raised wrapped in RetryError.
from __future__ import annotations

import random
import time
from functools import wraps
from typing import Any, Callable, Tuple, Type, TypeVar

F = TypeVar("F", bound=Callable[..., Any])


class RetryError(RuntimeError):
    """Raised when all retry attempts have been exhausted."""


def retry(
    *,
    max_attempts: int = 3,
    base_delay: float = 0.1,
    max_delay: float = 30.0,
    jitter: float = 0.1,
    only: Tuple[Type[BaseException], ...] = (Exception,),
) -> Callable[[F], F]:
    """Return a decorator that retries the wrapped function with exponential backoff.

    Args:
        max_attempts: total tries including the first. Must be >= 1.
        base_delay: seconds to wait before the second attempt. Each subsequent
            attempt doubles the delay, capped at max_delay.
        max_delay: cap on per-attempt sleep in seconds.
        jitter: max random jitter added per sleep, as a fraction of the delay
            (0.0 disables jitter).
        only: exception types to catch. Anything not matching propagates.
    """
    if max_attempts < 1:
        raise ValueError("max_attempts must be >= 1")

    def decorator(fn: F) -> F:
        @wraps(fn)
        def wrapper(*args: Any, **kwargs: Any) -> Any:
            last_exc: BaseException | None = None
            for attempt in range(max_attempts):
                try:
                    return fn(*args, **kwargs)
                except only as exc:  # noqa: B030 - intentional dynamic exception spec
                    last_exc = exc
                    if attempt == max_attempts - 1:
                        break
                    delay = min(base_delay * (2 ** attempt), max_delay)
                    if jitter > 0:
                        delay += random.random() * delay * jitter
                    time.sleep(delay)
            raise RetryError(f"{fn.__name__} failed after {max_attempts} attempts") from last_exc

        return wrapper  # type: ignore[return-value]

    return decorator
```

- [ ] **Step 4: Run the test — expect PASS**

```bash
TMP=$(mktemp -d)
cp /Users/dong.kyh/works/system-designs/_recipes/python/retry.py /Users/dong.kyh/works/system-designs/_recipes/python/test_retry.py "$TMP/"
( cd "$TMP" && uv run --no-project --with pytest pytest -q test_retry.py 2>&1 | tail -10 )
rm -rf "$TMP"
```
Expected: 5 passed in ~0.1s.

### 2B. `logger.py`

- [ ] **Step 5: Create `_recipes/python/test_logger.py`**

```python
"""Tests for logger recipe."""
from __future__ import annotations

import io
import json
import logging

from logger import get_logger


def test_logger_emits_json_lines() -> None:
    buf = io.StringIO()
    log = get_logger("app", stream=buf, level=logging.INFO)
    log.info("hello", extra={"user_id": 42})
    line = buf.getvalue().strip()
    payload = json.loads(line)
    assert payload["level"] == "INFO"
    assert payload["logger"] == "app"
    assert payload["message"] == "hello"
    assert payload["user_id"] == 42
    assert "timestamp" in payload


def test_logger_respects_level() -> None:
    buf = io.StringIO()
    log = get_logger("app", stream=buf, level=logging.WARNING)
    log.info("ignored")
    log.warning("kept")
    lines = [ln for ln in buf.getvalue().splitlines() if ln]
    assert len(lines) == 1
    assert json.loads(lines[0])["message"] == "kept"


def test_logger_serializes_exception() -> None:
    buf = io.StringIO()
    log = get_logger("app", stream=buf, level=logging.ERROR)
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
    a = get_logger("dup", stream=buf1)
    b = get_logger("dup", stream=buf1)
    assert a is b
```

- [ ] **Step 6: Create `_recipes/python/logger.py`**

```python
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
        # Merge custom fields from `extra=...`.
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
        # Update level on existing handler too.
        for h in log.handlers:
            h.setLevel(level)
    return log
```

- [ ] **Step 7: Run the test — expect PASS**

```bash
TMP=$(mktemp -d)
cp /Users/dong.kyh/works/system-designs/_recipes/python/logger.py /Users/dong.kyh/works/system-designs/_recipes/python/test_logger.py "$TMP/"
( cd "$TMP" && uv run --no-project --with pytest pytest -q test_logger.py 2>&1 | tail -10 )
rm -rf "$TMP"
```
Expected: 4 passed.

### 2C. `env.py`

- [ ] **Step 8: Create `_recipes/python/test_env.py`**

```python
"""Tests for env recipe."""
from __future__ import annotations

import os

import pytest

from env import MissingEnvError, get_bool, get_int, get_str, require


def setup_function() -> None:
    for k in list(os.environ):
        if k.startswith("TEST_RECIPE_"):
            del os.environ[k]


def test_get_str_returns_value_when_set() -> None:
    os.environ["TEST_RECIPE_FOO"] = "bar"
    assert get_str("TEST_RECIPE_FOO") == "bar"


def test_get_str_returns_default_when_missing() -> None:
    assert get_str("TEST_RECIPE_MISSING", default="fallback") == "fallback"


def test_get_str_returns_none_when_missing_no_default() -> None:
    assert get_str("TEST_RECIPE_MISSING") is None


def test_get_int_parses() -> None:
    os.environ["TEST_RECIPE_PORT"] = "8080"
    assert get_int("TEST_RECIPE_PORT") == 8080


def test_get_int_rejects_non_numeric() -> None:
    os.environ["TEST_RECIPE_PORT"] = "abc"
    with pytest.raises(ValueError):
        get_int("TEST_RECIPE_PORT")


def test_get_bool_truthy_values() -> None:
    for truthy in ("1", "true", "TRUE", "yes", "on"):
        os.environ["TEST_RECIPE_FLAG"] = truthy
        assert get_bool("TEST_RECIPE_FLAG") is True


def test_get_bool_falsy_values() -> None:
    for falsy in ("0", "false", "FALSE", "no", "off", ""):
        os.environ["TEST_RECIPE_FLAG"] = falsy
        assert get_bool("TEST_RECIPE_FLAG") is False


def test_get_bool_unknown_raises() -> None:
    os.environ["TEST_RECIPE_FLAG"] = "maybe"
    with pytest.raises(ValueError):
        get_bool("TEST_RECIPE_FLAG")


def test_require_raises_when_missing() -> None:
    with pytest.raises(MissingEnvError):
        require("TEST_RECIPE_MUST_HAVE")


def test_require_returns_value() -> None:
    os.environ["TEST_RECIPE_MUST_HAVE"] = "ok"
    assert require("TEST_RECIPE_MUST_HAVE") == "ok"
```

- [ ] **Step 9: Create `_recipes/python/env.py`**

```python
# Recipe: typed env-var loader
# Stdlib-only.
# Usage:
#   from env import get_str, get_int, get_bool, require, MissingEnvError
#
#   port = get_int("PORT", default=8080)
#   debug = get_bool("DEBUG", default=False)
#   db_url = require("DATABASE_URL")  # raises MissingEnvError if absent
from __future__ import annotations

import os
from typing import overload


class MissingEnvError(RuntimeError):
    """Raised by `require` when a required env var is not set."""


_TRUE = {"1", "true", "yes", "on"}
_FALSE = {"0", "false", "no", "off", ""}


@overload
def get_str(name: str) -> str | None: ...
@overload
def get_str(name: str, *, default: str) -> str: ...
def get_str(name: str, *, default: str | None = None) -> str | None:
    """Return the env var as a string, or `default` if unset."""
    value = os.environ.get(name)
    if value is None:
        return default
    return value


@overload
def get_int(name: str) -> int | None: ...
@overload
def get_int(name: str, *, default: int) -> int: ...
def get_int(name: str, *, default: int | None = None) -> int | None:
    """Return the env var parsed as int, or `default` if unset.

    Raises ValueError if the value is set but not parseable.
    """
    raw = os.environ.get(name)
    if raw is None:
        return default
    try:
        return int(raw)
    except ValueError as exc:
        raise ValueError(f"env {name}={raw!r} is not a valid integer") from exc


@overload
def get_bool(name: str) -> bool | None: ...
@overload
def get_bool(name: str, *, default: bool) -> bool: ...
def get_bool(name: str, *, default: bool | None = None) -> bool | None:
    """Return the env var parsed as bool, or `default` if unset.

    Accepts (case-insensitive): 1/0, true/false, yes/no, on/off, "".
    Raises ValueError on anything else.
    """
    raw = os.environ.get(name)
    if raw is None:
        return default
    low = raw.lower()
    if low in _TRUE:
        return True
    if low in _FALSE:
        return False
    raise ValueError(f"env {name}={raw!r} is not a valid boolean")


def require(name: str) -> str:
    """Return the env var, or raise MissingEnvError if not set or empty."""
    value = os.environ.get(name)
    if value is None or value == "":
        raise MissingEnvError(f"required env var {name} is not set")
    return value
```

- [ ] **Step 10: Run the test — expect PASS**

```bash
TMP=$(mktemp -d)
cp /Users/dong.kyh/works/system-designs/_recipes/python/env.py /Users/dong.kyh/works/system-designs/_recipes/python/test_env.py "$TMP/"
( cd "$TMP" && uv run --no-project --with pytest pytest -q test_env.py 2>&1 | tail -10 )
rm -rf "$TMP"
```
Expected: 10 passed.

### 2D. `healthcheck.py`

- [ ] **Step 11: Create `_recipes/python/test_healthcheck.py`**

```python
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
```

- [ ] **Step 12: Create `_recipes/python/healthcheck.py`**

```python
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
```

- [ ] **Step 13: Run the test — expect PASS**

```bash
TMP=$(mktemp -d)
cp /Users/dong.kyh/works/system-designs/_recipes/python/healthcheck.py /Users/dong.kyh/works/system-designs/_recipes/python/test_healthcheck.py "$TMP/"
( cd "$TMP" && uv run --no-project --with pytest pytest -q test_healthcheck.py 2>&1 | tail -10 )
rm -rf "$TMP"
```
Expected: 3 passed.

- [ ] **Step 14: Commit all 4 Python recipes together**

```bash
cd /Users/dong.kyh/works/system-designs
git add _recipes/python/
git commit -m "feat(_recipes/python): add stdlib-only utility recipes (retry, logger, env, healthcheck)

Each recipe + its co-located test, all stdlib-only and verified by
running pytest in an isolated tmp dir.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 3: Node utility recipes (4 files + 4 tests)

Same shape as the Python recipes but TypeScript. Tests use vitest. For verification before `make recipes-test` exists, we use `pnpm dlx vitest@1 run` in a tmp dir.

**Files:**
- Create: `_recipes/node/retry.ts` + `retry.test.ts`
- Create: `_recipes/node/logger.ts` + `logger.test.ts`
- Create: `_recipes/node/env.ts` + `env.test.ts`
- Create: `_recipes/node/healthcheck.ts` + `healthcheck.test.ts`

### 3A. `retry.ts`

- [ ] **Step 1: Create `_recipes/node/retry.test.ts`**

```typescript
import { describe, it, expect, vi } from 'vitest';
import { retry, RetryError } from './retry.js';

describe('retry', () => {
  it('returns the first successful result without sleeping', async () => {
    const fn = vi.fn(async () => 42);
    const result = await retry(fn, { maxAttempts: 3, baseDelayMs: 0 });
    expect(result).toBe(42);
    expect(fn).toHaveBeenCalledTimes(1);
  });

  it('retries on failure and succeeds within max attempts', async () => {
    let n = 0;
    const fn = vi.fn(async () => {
      n += 1;
      if (n < 3) throw new Error('nope');
      return 'ok';
    });
    const result = await retry(fn, { maxAttempts: 5, baseDelayMs: 0 });
    expect(result).toBe('ok');
    expect(fn).toHaveBeenCalledTimes(3);
  });

  it('throws RetryError after exhausting attempts', async () => {
    const fn = vi.fn(async () => {
      throw new Error('always');
    });
    await expect(retry(fn, { maxAttempts: 3, baseDelayMs: 0 })).rejects.toBeInstanceOf(RetryError);
    expect(fn).toHaveBeenCalledTimes(3);
  });

  it('does not retry errors outside `only`', async () => {
    class TransientError extends Error {}
    class FatalError extends Error {}
    const fn = vi.fn(async () => {
      throw new FatalError('boom');
    });
    await expect(
      retry(fn, { maxAttempts: 5, baseDelayMs: 0, only: [TransientError] }),
    ).rejects.toBeInstanceOf(FatalError);
    expect(fn).toHaveBeenCalledTimes(1);
  });

  it('uses exponential backoff base delay', async () => {
    let n = 0;
    const fn = vi.fn(async () => {
      n += 1;
      throw new Error('nope');
    });
    const start = Date.now();
    await retry(fn, { maxAttempts: 3, baseDelayMs: 50, jitter: 0 }).catch(() => undefined);
    const elapsed = Date.now() - start;
    // 2 sleeps: 50ms and 100ms, allow scheduling slack.
    expect(elapsed).toBeGreaterThanOrEqual(100);
  });
});
```

- [ ] **Step 2: Create `_recipes/node/retry.ts`**

```typescript
// Recipe: exponential-backoff retry helper
// Stdlib-only.
// Usage:
//   import { retry, RetryError } from './retry.js';
//
//   const data = await retry(() => fetch(url), { maxAttempts: 5, baseDelayMs: 100 });
//
// Errors that aren't instances of any class in `only` propagate immediately.
// After maxAttempts failures the last caught error is re-thrown wrapped in RetryError.

export class RetryError extends Error {
  constructor(message: string, readonly cause: unknown) {
    super(message);
    this.name = 'RetryError';
  }
}

export interface RetryOptions {
  maxAttempts?: number;
  baseDelayMs?: number;
  maxDelayMs?: number;
  jitter?: number;
  /** Error classes to catch and retry. Anything else propagates. */
  only?: Array<abstract new (...args: never[]) => Error>;
}

const sleep = (ms: number): Promise<void> =>
  new Promise((resolve) => setTimeout(resolve, ms));

export async function retry<T>(
  fn: () => Promise<T>,
  options: RetryOptions = {},
): Promise<T> {
  const {
    maxAttempts = 3,
    baseDelayMs = 100,
    maxDelayMs = 30_000,
    jitter = 0.1,
    only = [Error],
  } = options;

  if (maxAttempts < 1) {
    throw new Error('maxAttempts must be >= 1');
  }

  let lastErr: unknown;
  for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
    try {
      return await fn();
    } catch (err) {
      const matches = only.some((Klass) => err instanceof Klass);
      if (!matches) throw err;
      lastErr = err;
      if (attempt === maxAttempts - 1) break;
      let delay = Math.min(baseDelayMs * 2 ** attempt, maxDelayMs);
      if (jitter > 0) delay += Math.random() * delay * jitter;
      await sleep(delay);
    }
  }
  throw new RetryError(`retried ${maxAttempts} times`, lastErr);
}
```

- [ ] **Step 3: Run test in tmp dir — expect PASS**

```bash
TMP=$(mktemp -d)
cp /Users/dong.kyh/works/system-designs/_recipes/node/retry.ts /Users/dong.kyh/works/system-designs/_recipes/node/retry.test.ts "$TMP/"
( cd "$TMP" && pnpm dlx vitest@1 run --reporter=basic 2>&1 | tail -15 )
rm -rf "$TMP"
```
Expected: 5 passed.

### 3B. `logger.ts`

- [ ] **Step 4: Create `_recipes/node/logger.test.ts`**

```typescript
import { describe, it, expect } from 'vitest';
import { Writable } from 'node:stream';
import { createLogger } from './logger.js';

function collect(): { stream: Writable; lines: () => string[] } {
  const chunks: string[] = [];
  const stream = new Writable({
    write(chunk, _enc, cb) {
      chunks.push(chunk.toString());
      cb();
    },
  });
  return { stream, lines: () => chunks.join('').split('\n').filter(Boolean) };
}

describe('logger', () => {
  it('emits a JSON line per log call', () => {
    const { stream, lines } = collect();
    const log = createLogger({ name: 'app', stream, level: 'info' });
    log.info('hello', { userId: 42 });
    const out = lines();
    expect(out).toHaveLength(1);
    const payload = JSON.parse(out[0]);
    expect(payload.level).toBe('info');
    expect(payload.logger).toBe('app');
    expect(payload.message).toBe('hello');
    expect(payload.userId).toBe(42);
    expect(payload.timestamp).toEqual(expect.any(String));
  });

  it('respects the level threshold', () => {
    const { stream, lines } = collect();
    const log = createLogger({ name: 'app', stream, level: 'warn' });
    log.info('ignored');
    log.warn('kept');
    const out = lines();
    expect(out).toHaveLength(1);
    expect(JSON.parse(out[0]).message).toBe('kept');
  });

  it('serializes Error instances', () => {
    const { stream, lines } = collect();
    const log = createLogger({ name: 'app', stream, level: 'error' });
    log.error('oops', { err: new Error('boom') });
    const payload = JSON.parse(lines()[0]);
    expect(payload.err.name).toBe('Error');
    expect(payload.err.message).toBe('boom');
    expect(payload.err.stack).toEqual(expect.any(String));
  });
});
```

- [ ] **Step 5: Create `_recipes/node/logger.ts`**

```typescript
// Recipe: JSON-line structured logger
// Stdlib-only (node:stream, node:process).
// Usage:
//   import { createLogger } from './logger.js';
//   const log = createLogger({ name: 'my-service' });
//   log.info('started', { port: 8080 });
//
// Every call emits one JSON object per line. Custom fields are merged at the
// top level. Error values are serialized as { name, message, stack }.

import { Writable } from 'node:stream';

export type LogLevel = 'debug' | 'info' | 'warn' | 'error';

const LEVELS: Record<LogLevel, number> = { debug: 10, info: 20, warn: 30, error: 40 };

export interface LoggerOptions {
  name: string;
  level?: LogLevel;
  stream?: Writable;
}

export interface Logger {
  debug: (message: string, fields?: Record<string, unknown>) => void;
  info: (message: string, fields?: Record<string, unknown>) => void;
  warn: (message: string, fields?: Record<string, unknown>) => void;
  error: (message: string, fields?: Record<string, unknown>) => void;
}

function serializeValue(v: unknown): unknown {
  if (v instanceof Error) {
    return { name: v.name, message: v.message, stack: v.stack };
  }
  return v;
}

export function createLogger({
  name,
  level = 'info',
  stream = process.stderr,
}: LoggerOptions): Logger {
  const threshold = LEVELS[level];

  const emit = (lvl: LogLevel, message: string, fields?: Record<string, unknown>): void => {
    if (LEVELS[lvl] < threshold) return;
    const payload: Record<string, unknown> = {
      timestamp: new Date().toISOString(),
      level: lvl,
      logger: name,
      message,
    };
    if (fields) {
      for (const [k, v] of Object.entries(fields)) {
        payload[k] = serializeValue(v);
      }
    }
    stream.write(`${JSON.stringify(payload)}\n`);
  };

  return {
    debug: (m, f) => emit('debug', m, f),
    info: (m, f) => emit('info', m, f),
    warn: (m, f) => emit('warn', m, f),
    error: (m, f) => emit('error', m, f),
  };
}
```

- [ ] **Step 6: Run test in tmp dir — expect PASS**

```bash
TMP=$(mktemp -d)
cp /Users/dong.kyh/works/system-designs/_recipes/node/logger.ts /Users/dong.kyh/works/system-designs/_recipes/node/logger.test.ts "$TMP/"
( cd "$TMP" && pnpm dlx vitest@1 run --reporter=basic 2>&1 | tail -15 )
rm -rf "$TMP"
```
Expected: 3 passed.

### 3C. `env.ts`

- [ ] **Step 7: Create `_recipes/node/env.test.ts`**

```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { MissingEnvError, getBool, getInt, getStr, require_ } from './env.js';

describe('env', () => {
  beforeEach(() => {
    for (const k of Object.keys(process.env)) {
      if (k.startsWith('TEST_RECIPE_')) delete process.env[k];
    }
  });

  it('getStr returns value when set, default when missing', () => {
    process.env.TEST_RECIPE_FOO = 'bar';
    expect(getStr('TEST_RECIPE_FOO')).toBe('bar');
    expect(getStr('TEST_RECIPE_MISSING', 'fallback')).toBe('fallback');
    expect(getStr('TEST_RECIPE_MISSING')).toBeUndefined();
  });

  it('getInt parses numbers, throws on non-numeric', () => {
    process.env.TEST_RECIPE_PORT = '8080';
    expect(getInt('TEST_RECIPE_PORT')).toBe(8080);
    process.env.TEST_RECIPE_PORT = 'abc';
    expect(() => getInt('TEST_RECIPE_PORT')).toThrow();
  });

  it('getBool handles truthy and falsy values', () => {
    for (const truthy of ['1', 'true', 'TRUE', 'yes', 'on']) {
      process.env.TEST_RECIPE_FLAG = truthy;
      expect(getBool('TEST_RECIPE_FLAG')).toBe(true);
    }
    for (const falsy of ['0', 'false', 'FALSE', 'no', 'off', '']) {
      process.env.TEST_RECIPE_FLAG = falsy;
      expect(getBool('TEST_RECIPE_FLAG')).toBe(false);
    }
    process.env.TEST_RECIPE_FLAG = 'maybe';
    expect(() => getBool('TEST_RECIPE_FLAG')).toThrow();
  });

  it('require_ throws MissingEnvError when not set', () => {
    expect(() => require_('TEST_RECIPE_MUST')).toThrow(MissingEnvError);
    process.env.TEST_RECIPE_MUST = 'ok';
    expect(require_('TEST_RECIPE_MUST')).toBe('ok');
  });
});
```

- [ ] **Step 8: Create `_recipes/node/env.ts`**

```typescript
// Recipe: typed env-var loader
// Stdlib-only.
// Usage:
//   import { getInt, getBool, require_ } from './env.js';
//
//   const port = getInt('PORT', 8080);
//   const debug = getBool('DEBUG', false);
//   const dbUrl = require_('DATABASE_URL');  // throws if absent
//
// `require_` is named with an underscore to avoid clashing with CommonJS `require`.

export class MissingEnvError extends Error {
  constructor(name: string) {
    super(`required env var ${name} is not set`);
    this.name = 'MissingEnvError';
  }
}

const TRUE = new Set(['1', 'true', 'yes', 'on']);
const FALSE = new Set(['0', 'false', 'no', 'off', '']);

export function getStr(name: string): string | undefined;
export function getStr(name: string, defaultValue: string): string;
export function getStr(name: string, defaultValue?: string): string | undefined {
  const v = process.env[name];
  return v === undefined ? defaultValue : v;
}

export function getInt(name: string): number | undefined;
export function getInt(name: string, defaultValue: number): number;
export function getInt(name: string, defaultValue?: number): number | undefined {
  const raw = process.env[name];
  if (raw === undefined) return defaultValue;
  if (!/^-?\d+$/.test(raw)) {
    throw new Error(`env ${name}=${JSON.stringify(raw)} is not a valid integer`);
  }
  return Number.parseInt(raw, 10);
}

export function getBool(name: string): boolean | undefined;
export function getBool(name: string, defaultValue: boolean): boolean;
export function getBool(name: string, defaultValue?: boolean): boolean | undefined {
  const raw = process.env[name];
  if (raw === undefined) return defaultValue;
  const low = raw.toLowerCase();
  if (TRUE.has(low)) return true;
  if (FALSE.has(low)) return false;
  throw new Error(`env ${name}=${JSON.stringify(raw)} is not a valid boolean`);
}

export function require_(name: string): string {
  const v = process.env[name];
  if (v === undefined || v === '') throw new MissingEnvError(name);
  return v;
}
```

- [ ] **Step 9: Run test in tmp dir — expect PASS**

```bash
TMP=$(mktemp -d)
cp /Users/dong.kyh/works/system-designs/_recipes/node/env.ts /Users/dong.kyh/works/system-designs/_recipes/node/env.test.ts "$TMP/"
( cd "$TMP" && pnpm dlx vitest@1 run --reporter=basic 2>&1 | tail -15 )
rm -rf "$TMP"
```
Expected: 4 passed.

### 3D. `healthcheck.ts`

- [ ] **Step 10: Create `_recipes/node/healthcheck.test.ts`**

```typescript
import { describe, it, expect, afterAll } from 'vitest';
import type { AddressInfo } from 'node:net';
import { createHealthServer, setReady } from './healthcheck.js';

async function get(port: number, path: string): Promise<{ status: number; body: unknown }> {
  const res = await fetch(`http://127.0.0.1:${port}${path}`);
  const body = await res.json();
  return { status: res.status, body };
}

describe('healthcheck', () => {
  const server = createHealthServer();
  server.listen(0, '127.0.0.1');
  const port = (server.address() as AddressInfo).port;

  afterAll(() => {
    server.close();
  });

  it('/health is always 200', async () => {
    const { status, body } = await get(port, '/health');
    expect(status).toBe(200);
    expect(body).toEqual({ status: 'ok' });
  });

  it('/ready is 503 until setReady(true)', async () => {
    setReady(false);
    let res = await get(port, '/ready');
    expect(res.status).toBe(503);
    expect(res.body).toEqual({ status: 'not_ready' });

    setReady(true);
    res = await get(port, '/ready');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: 'ready' });
  });

  it('unknown path returns 404', async () => {
    const { status } = await get(port, '/nope');
    expect(status).toBe(404);
  });
});
```

- [ ] **Step 11: Create `_recipes/node/healthcheck.ts`**

```typescript
// Recipe: /health and /ready HTTP handlers, stdlib only
// Stdlib-only (node:http).
// Usage:
//   import { createHealthServer, setReady } from './healthcheck.js';
//   const server = createHealthServer();
//   server.listen(8080);
//   setReady(true);
//
// /health  -> 200 {"status":"ok"} always
// /ready   -> 200 {"status":"ready"} or 503 {"status":"not_ready"}

import { createServer, type Server } from 'node:http';

let ready = false;

export function setReady(value: boolean): void {
  ready = Boolean(value);
}

export function createHealthServer(): Server {
  return createServer((req, res) => {
    const send = (status: number, payload: Record<string, unknown>): void => {
      const body = JSON.stringify(payload);
      res.writeHead(status, {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
      });
      res.end(body);
    };

    if (req.url === '/health') {
      send(200, { status: 'ok' });
    } else if (req.url === '/ready') {
      if (ready) send(200, { status: 'ready' });
      else send(503, { status: 'not_ready' });
    } else {
      send(404, { status: 'not_found', path: req.url });
    }
  });
}
```

- [ ] **Step 12: Run test in tmp dir — expect PASS**

```bash
TMP=$(mktemp -d)
cp /Users/dong.kyh/works/system-designs/_recipes/node/healthcheck.ts /Users/dong.kyh/works/system-designs/_recipes/node/healthcheck.test.ts "$TMP/"
( cd "$TMP" && pnpm dlx vitest@1 run --reporter=basic 2>&1 | tail -15 )
rm -rf "$TMP"
```
Expected: 3 passed.

- [ ] **Step 13: Commit all 4 Node recipes together**

```bash
cd /Users/dong.kyh/works/system-designs
git add _recipes/node/
git commit -m "feat(_recipes/node): add stdlib-only utility recipes (retry, logger, env, healthcheck)

Each recipe + co-located test, all using only Node stdlib (node:http,
node:stream, etc.). Verified by running vitest in an isolated tmp dir.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 4: Compose snippets (2 files, no tests)

Pure docs/config files — the unit test is "does it `docker compose config` cleanly when included in a project compose."

**Files:**
- Create: `_recipes/compose/postgres-with-adminer.yml`
- Create: `_recipes/compose/kafka-kraft.yml`

- [ ] **Step 1: Create `_recipes/compose/postgres-with-adminer.yml`**

```yaml
# Recipe: Postgres + Adminer (web UI)
#
# How to use: copy the `services:` entries below into your project's
# docker-compose.yml. Adjust ports if they clash with other projects.
# Default credentials are dev-only.
#
# After `make up`:
#   psql: postgresql://app:app@localhost:5432/app
#   adminer: http://localhost:8080  (server=postgres, user=app, pass=app, db=app)

services:

  postgres:
    image: postgres:16-alpine
    container_name: ${COMPOSE_PROJECT_NAME:-app}-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: app
      POSTGRES_PASSWORD: app
      POSTGRES_DB: app
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d app"]
      interval: 5s
      timeout: 5s
      retries: 10

  adminer:
    image: adminer:latest
    container_name: ${COMPOSE_PROJECT_NAME:-app}-adminer
    restart: unless-stopped
    ports:
      - "8080:8080"
    depends_on:
      postgres:
        condition: service_healthy

volumes:
  pgdata:
```

- [ ] **Step 2: Create `_recipes/compose/kafka-kraft.yml`**

```yaml
# Recipe: single-broker Kafka 3.7 in KRaft mode (no Zookeeper)
#
# How to use: copy the `services:` entry below into your project's
# docker-compose.yml.
#
# Client bootstrap: localhost:9092 from the host;
#                   kafka:9092 from other services on the same docker network.
#
# This is the simplest possible Kafka — single broker, single controller. For
# replication / partitioning practice, use the (deferred) kafka-3-broker recipe.

services:

  kafka:
    image: bitnami/kafka:3.7
    container_name: ${COMPOSE_PROJECT_NAME:-app}-kafka
    restart: unless-stopped
    environment:
      KAFKA_CFG_NODE_ID: 0
      KAFKA_CFG_PROCESS_ROLES: controller,broker
      KAFKA_CFG_CONTROLLER_QUORUM_VOTERS: 0@kafka:9093
      KAFKA_CFG_LISTENERS: PLAINTEXT://:9092,CONTROLLER://:9093
      KAFKA_CFG_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_CFG_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP: CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT
      KAFKA_CFG_AUTO_CREATE_TOPICS_ENABLE: "true"
    ports:
      - "9092:9092"
    volumes:
      - kafka-data:/bitnami/kafka

volumes:
  kafka-data:
```

- [ ] **Step 3: Validate both compose snippets parse**

For each file, wrap it in a temporary parent compose context to verify `docker compose config` accepts it:

```bash
for snippet in postgres-with-adminer kafka-kraft; do
  TMP=$(mktemp -d)
  cp "/Users/dong.kyh/works/system-designs/_recipes/compose/${snippet}.yml" "$TMP/docker-compose.yml"
  if docker compose version >/dev/null 2>&1; then
    (cd "$TMP" && docker compose config --quiet) && echo "$snippet OK" || echo "$snippet FAIL"
  else
    echo "$snippet SKIP (no docker)"
  fi
  rm -rf "$TMP"
done
```
Expected: both report `OK` (or both `SKIP` if docker isn't available).

- [ ] **Step 4: Commit**

```bash
cd /Users/dong.kyh/works/system-designs
git add _recipes/compose/
git commit -m "feat(_recipes/compose): add postgres-with-adminer and kafka-kraft snippets

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 5: Recipes test runner + Makefile target + smoke test

The runner copies each recipe + its test into a tmp dir and runs vitest/pytest in an ephemeral env.

**Files:**
- Create: `scripts/recipes-test.sh`
- Create: `scripts/tests/test_recipes_runner.sh`
- Modify: `Makefile` — add `recipes-test` target

- [ ] **Step 1: Create `scripts/recipes-test.sh`**

```bash
#!/usr/bin/env bash
# Runs each recipe's co-located test in an isolated tmp dir.
# Python recipes: pattern test_<name>.py runs via `uv run --no-project --with pytest`.
# Node recipes:   pattern <name>.test.ts runs via `pnpm dlx vitest`.
# Exits non-zero if any recipe test fails. SKIPs cleanly if a toolchain is missing.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PY_DIR="$REPO_ROOT/_recipes/python"
NODE_DIR="$REPO_ROOT/_recipes/node"

pass=0
fail=0
skip=0
failed_recipes=()

have_uv() { command -v uv >/dev/null 2>&1; }
have_pnpm() { command -v pnpm >/dev/null 2>&1; }

run_python_recipe() {
  local recipe="$1"
  local name; name="$(basename "$recipe" .py)"
  local test_file="$PY_DIR/test_$name.py"
  if [ ! -f "$test_file" ]; then
    echo "  python/$name           NO_TEST"
    return 0
  fi
  if ! have_uv; then
    echo "  python/$name           SKIP (uv not installed)"
    skip=$((skip + 1))
    return 0
  fi
  local box; box=$(mktemp -d)
  cp "$recipe" "$test_file" "$box/"
  if ( cd "$box" && uv run --no-project --with pytest pytest -q test_${name}.py ) >/tmp/recipes_out.$$ 2>&1; then
    echo "  python/$name           PASS"
    pass=$((pass + 1))
  else
    echo "  python/$name           FAIL"
    sed 's/^/      /' /tmp/recipes_out.$$
    fail=$((fail + 1))
    failed_recipes+=("python/$name")
  fi
  rm -f /tmp/recipes_out.$$
  rm -rf "$box"
}

run_node_recipe() {
  local recipe="$1"
  local name; name="$(basename "$recipe" .ts)"
  local test_file="$NODE_DIR/${name}.test.ts"
  if [ ! -f "$test_file" ]; then
    echo "  node/$name             NO_TEST"
    return 0
  fi
  if ! have_pnpm; then
    echo "  node/$name             SKIP (pnpm not installed)"
    skip=$((skip + 1))
    return 0
  fi
  local box; box=$(mktemp -d)
  cp "$recipe" "$test_file" "$box/"
  if ( cd "$box" && pnpm dlx vitest@1 run --reporter=basic ) >/tmp/recipes_out.$$ 2>&1; then
    echo "  node/$name             PASS"
    pass=$((pass + 1))
  else
    echo "  node/$name             FAIL"
    sed 's/^/      /' /tmp/recipes_out.$$
    fail=$((fail + 1))
    failed_recipes+=("node/$name")
  fi
  rm -f /tmp/recipes_out.$$
  rm -rf "$box"
}

echo "Recipe tests:"

# Python recipes: every *.py that isn't test_*.py.
if [ -d "$PY_DIR" ]; then
  for recipe in "$PY_DIR"/*.py; do
    [ -e "$recipe" ] || continue
    case "$(basename "$recipe")" in
      test_*) continue ;;
    esac
    run_python_recipe "$recipe"
  done
fi

# Node recipes: every *.ts that isn't *.test.ts.
if [ -d "$NODE_DIR" ]; then
  for recipe in "$NODE_DIR"/*.ts; do
    [ -e "$recipe" ] || continue
    case "$(basename "$recipe")" in
      *.test.ts) continue ;;
    esac
    run_node_recipe "$recipe"
  done
fi

echo
echo "Summary: $pass passed, $fail failed, $skip skipped"
if [ $fail -gt 0 ]; then
  echo "Failed: ${failed_recipes[*]}"
  exit 1
fi
```

- [ ] **Step 2: Make executable**

```bash
chmod +x /Users/dong.kyh/works/system-designs/scripts/recipes-test.sh
```

- [ ] **Step 3: Add `recipes-test` target to the top-level Makefile**

Insert this target into `/Users/dong.kyh/works/system-designs/Makefile`, immediately after the `services-reset-force` target (keep `.PHONY` updated):

Change the `.PHONY` line from:
```makefile
.PHONY: help services-up services-down services-logs services-status services-reset services-reset-force
```
to:
```makefile
.PHONY: help services-up services-down services-logs services-status services-reset services-reset-force recipes-test
```

And append at the bottom of the file:
```makefile

recipes-test: ## Run every _recipes/* test in an isolated tmp dir
	@scripts/recipes-test.sh
```

- [ ] **Step 4: Create smoke test for the runner**

Create `/Users/dong.kyh/works/system-designs/scripts/tests/test_recipes_runner.sh`:

```bash
#!/usr/bin/env bash
# Tests for scripts/recipes-test.sh.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNNER="$REPO_ROOT/scripts/recipes-test.sh"

test_recipes_runner_exists_and_executable() {
  [ -x "$RUNNER" ]
}

test_recipes_runner_against_real_recipes_succeeds() {
  # Skip if neither toolchain is available — runner would print only SKIPs.
  if ! command -v uv >/dev/null 2>&1 && ! command -v pnpm >/dev/null 2>&1; then
    echo "SKIP: neither uv nor pnpm installed"
    return 0
  fi
  ( cd "$REPO_ROOT" && "$RUNNER" >/tmp/runner_out.$$ 2>&1 )
  local rc=$?
  if [ $rc -ne 0 ]; then
    echo "runner exited $rc:"
    sed 's/^/    /' /tmp/runner_out.$$
    rm -f /tmp/runner_out.$$
    return 1
  fi
  # Expect at least one PASS line.
  grep -qE '  (python|node)/[a-z_-]+[[:space:]]+PASS' /tmp/runner_out.$$ || {
    echo "no PASS lines in runner output:"
    sed 's/^/    /' /tmp/runner_out.$$
    rm -f /tmp/runner_out.$$
    return 1
  }
  rm -f /tmp/runner_out.$$
}

test_recipes_runner_fails_when_recipe_test_fails() {
  if ! command -v uv >/dev/null 2>&1; then
    echo "SKIP: uv not installed"
    return 0
  fi
  # Sandbox the repo so a deliberately-broken recipe doesn't pollute the real
  # _recipes/ directory.
  local box; box=$(mktemp -d)
  mkdir -p "$box/_recipes/python" "$box/scripts"
  cp "$RUNNER" "$box/scripts/recipes-test.sh"
  chmod +x "$box/scripts/recipes-test.sh"
  # Deliberately-broken recipe.
  cat > "$box/_recipes/python/broken.py" <<'PY'
def add(a, b):
    return a + b + 1  # off-by-one
PY
  cat > "$box/_recipes/python/test_broken.py" <<'PY'
from broken import add

def test_add():
    assert add(1, 2) == 3  # would fail because add returns 4
PY

  set +e
  ( cd "$box" && ./scripts/recipes-test.sh >/dev/null 2>&1 )
  local rc=$?
  set -e
  rm -rf "$box"
  [ $rc -ne 0 ]
}
```

- [ ] **Step 5: Run all tests — expect everything to PASS**

```bash
/Users/dong.kyh/works/system-designs/scripts/tests/run-tests.sh 2>&1 | tail -15
```
Expected: all tests PASS (existing 31 + 3 new runner tests = 34 total). The new runner-smoke test triggers the full recipe test cycle internally, which may take 20-30 seconds the first time (pnpm dlx fetches vitest).

- [ ] **Step 6: Verify `make recipes-test` works end-to-end**

```bash
cd /Users/dong.kyh/works/system-designs
make recipes-test
```
Expected: prints per-recipe PASS lines for all 8 recipes (4 Python + 4 Node), Summary line at the end. Exit 0.

Also verify `make help` lists the new target:
```bash
make help | grep recipes-test
```
Expected: shows `recipes-test            Run every _recipes/* test in an isolated tmp dir`.

- [ ] **Step 7: Commit**

```bash
cd /Users/dong.kyh/works/system-designs
git add Makefile scripts/recipes-test.sh scripts/tests/test_recipes_runner.sh
git commit -m "feat: add make recipes-test runner with per-recipe isolation

The runner copies each recipe + its co-located test into a tmp dir and
runs vitest (Node, via pnpm dlx) or pytest (Python, via uv run --with)
in an ephemeral environment, then aggregates per-recipe PASS/FAIL/SKIP
counts. Add 3 smoke tests including a sandbox check that a deliberately
broken recipe causes the runner to exit non-zero.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 6: End-to-end verification + spec amendment

**Files:** none (verification + a small spec update)

- [ ] **Step 1: Verify the full test suite passes**

```bash
/Users/dong.kyh/works/system-designs/scripts/tests/run-tests.sh 2>&1 | tail -10
```
Expected: 34 passed, 0 failed (existing 31 + 3 new).

- [ ] **Step 2: Verify `make recipes-test` is clean**

```bash
cd /Users/dong.kyh/works/system-designs
make recipes-test 2>&1 | tail -20
```
Expected: 8 PASS lines, Summary `8 passed, 0 failed, 0 skipped` (or with skips if a toolchain is missing).

- [ ] **Step 3: Amend the spec to note the staged-rollout decision**

Edit `/Users/dong.kyh/works/system-designs/docs/superpowers/specs/2026-06-28-shared-services-and-recipes-design.md`. Find the section `### Initial Recipe Set` and replace the existing paragraph at the very top of that section with:

```markdown
The full target set below is the design goal. Plan B (`docs/superpowers/plans/2026-06-28-recipes-library.md`) implements a focused starter subset (4 utilities per language + 2 compose snippets + the test runner). Cloud-client recipes and additional compose snippets are deferred to a follow-up plan because they require the test runner to handle external dependencies (boto3, AWS SDK v3, etc.), which is a larger design problem.

**Implemented in Plan B (starter set):**
- `python/{retry,logger,env,healthcheck}.py` + tests
- `node/{retry,logger,env,healthcheck}.ts` + tests
- `compose/{postgres-with-adminer,kafka-kraft}.yml`
- `scripts/recipes-test.sh` + `make recipes-test`

**Deferred to a follow-up plan:**
- Python `timing.py`, `localstack_clients.py`, `pubsub_emulator.py`
- Node `timing.ts`, `localstack-clients.ts`, `pubsub-emulator.ts`
- Compose `postgres-replication.yml`, `redis-cluster.yml`, `kafka-3-broker.yml`, `nginx-load-balancer.yml`
- A recipe-runner extension that parses `# requires: <pkg>` headers and threads them through to uv / pnpm dlx
```

- [ ] **Step 4: Repo sanity check**

```bash
cd /Users/dong.kyh/works/system-designs
git status
ls _recipes
ls _recipes/python _recipes/node _recipes/compose
```
Expected: working tree clean (or just the spec amendment pending). `_recipes/` contains `README.md`, `compose/`, `python/`, `node/`, each populated as designed.

- [ ] **Step 5: Commit the spec amendment + tag the milestone**

```bash
cd /Users/dong.kyh/works/system-designs
git add docs/superpowers/specs/2026-06-28-shared-services-and-recipes-design.md
git commit -m "docs(spec): note staged rollout of recipes library

Plan B implements the starter set; cloud-client recipes and additional
compose snippets are explicitly deferred to a follow-up plan because the
test runner doesn't yet handle external deps.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
git tag -a recipes-library-v1 -m "Recipes library v1: 4 utilities per language + 2 compose snippets + make recipes-test"
```

---

## Done

After Task 6, the recipes library is wired up:

```bash
# Browse what's available
ls _recipes/python _recipes/node _recipes/compose
cat _recipes/README.md           # topic-grouped index

# Use a recipe in a project
cp _recipes/python/retry.py apps/url-shortener/src/
# Edit your project code, import retry, done.

# Verify every recipe still works after editing one
make recipes-test
```

Adding more recipes is one file + one test + one README entry — no design needed, no plan needed. The follow-up plan (cloud clients, more compose snippets) can come whenever you actually want one of them.
