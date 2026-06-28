# AGENTS.md — __PROJECT_TITLE__

> **Read repo-root `AGENTS.md` FIRST** for repo-wide conventions. This
> file covers only what's specific to **__PROJECT_NAME__**.

## What this project is

- **Category:** `__CATEGORY__`
- **Stack:** Node.js (TypeScript)
- **Status:** see `.status` (one of `planned`, `in-progress`, `done`, `paused`, `archived`)

## Done means

See [`DONE.md`](./DONE.md). Do not declare this project finished until
every checkbox is ticked.

## Recipes copied into this project

_List recipes you've copied from `_recipes/` here so future agents
know what's vendored and what's not (e.g., "Copied
`_recipes/python/retry.py` to `src/retry.ts` and adapted to TS")._

## Side services this project uses

_List which `_services/*` you connect to and how
(`make services-up` brings them all up; the env vars in `.env.example`
point at them)._

## Project-specific conventions

_Things to know that differ from repo defaults, e.g.:
"All errors flow through the structured logger in `src/logger.ts`.
Don't add `console.log`."_

## Read these before you change code

- [`README.md`](./README.md) — design doc (problem, requirements, API,
  architecture, data model, trade-offs, how to run, what I learned)
- [`docs/diagrams/`](./docs/diagrams/) — context and sequence diagrams
- [`docs/adr/`](./docs/adr/) — Architecture Decision Records
- [`notes/gotchas.md`](./notes/gotchas.md) — lessons from prior sessions

## Update these as you work

- `notes/gotchas.md` — every non-obvious thing
- `docs/adr/NNNN-<topic>.md` — every non-obvious decision
- `README.md` §8 ("What I learned") — at finalize time
