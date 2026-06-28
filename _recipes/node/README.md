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
