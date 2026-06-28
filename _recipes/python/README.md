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
