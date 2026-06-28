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
