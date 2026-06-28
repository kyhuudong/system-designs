# AGENTS.md — Repo-wide instructions for AI coding agents

You are operating inside the `system-designs` repo: a hands-on practice
collection of backend system-design projects. Read this file first, then
the per-project `AGENTS.md` (if a project is in scope).

## The non-negotiable rule

**Design before code.** Every project starts with:
1. A design doc (`README.md` sections 1–6) describing the problem,
   requirements, API, architecture, data model, and trade-offs.
2. At least one architecture diagram (rendered as SVG under
   `docs/diagrams/`). Sequence and context diagrams strongly preferred.
3. ADRs (`docs/adr/`) for any non-obvious decision.

If the user asks you to "build X" without a design doc, your first step
is to write or update the design — not to write code.

## Project lifecycle

```
scaffold      →  make new CATEGORY=<cat> NAME=<name> LANG=<node|python>
design        →  edit <cat>/<name>/README.md sections 1-6; fill docs/
diagram       →  edit docs/diagrams/*.mmd; run `make diagram` to render SVG
implement     →  src/, tests/, then `make test` and `make lint`
gate          →  `make design-check` must pass before marking done
finalize      →  fill README §8 retrospective; update DONE.md checkboxes
catalog       →  set .status to 'done'; run `make catalog` at repo root
```

## Repo layout you need to know

- `_templates/{node,python}/` — language-specific project skeletons.
  Files contain `__PROJECT_NAME__`, `__CATEGORY__`, `__PROJECT_TITLE__`
  placeholders that the scaffolder substitutes.
- `_recipes/{compose,python,node}/` — copy-paste snippets. Read
  `_recipes/README.md`. Recipes are NOT a dependency; they're
  documentation. Copy what you need into the project.
- `_services/` — shared sandbox infrastructure (LocalStack, GCloud
  emulators, Azurite, MinIO, Mailhog, Jaeger). See `_services/README.md`
  for endpoints, env vars, client examples.
- `docs/learning/` — cross-cutting cheat sheets (latency numbers,
  consistency models, back-of-envelope methodology). Read once,
  reference often.
- `docs/superpowers/specs/`, `docs/superpowers/plans/` — design specs
  and implementation plans (this is one of them).
- `scripts/` — repo utilities (`new-project.sh`, `update-catalog.sh`,
  `recipes-test.sh`) and their tests (`tests/`).
- `<category>/<project>/` — individual projects (e.g., `apps/url-shortener/`,
  `caching/distributed-lru-cache/`). Each is fully self-contained.

## Command index

| Want to... | Run from... | Command |
|---|---|---|
| Scaffold a project | repo root | `make new CATEGORY=<cat> NAME=<name> LANG=<node\|python>` |
| Regenerate top-level catalog | repo root | `make catalog` |
| Start shared sandbox services | repo root | `make services-up` |
| Stop shared sandbox services | repo root | `make services-down` |
| Reset sandbox state | repo root | `make services-reset-force` |
| Run all recipe tests | repo root | `make recipes-test` |
| Run repo bash test harness | repo root | `scripts/tests/run-tests.sh` |
| Install project deps | project dir | `make install` |
| Run project tests | project dir | `make test` |
| Run project locally | project dir | `make dev` |
| Run project in Docker | project dir | `make up` |
| Lint project | project dir | `make lint` |
| Render project diagrams | project dir | `make diagram` |
| Validate design completeness | project dir | `make design-check` |

## How to use the self-improvement log

Every project has `notes/gotchas.md`. When you hit something non-obvious
— a tool quirk, an unexpected dep clash, a recipe that needed
adjustment, a missing convention — append a 3-line entry:

```
## YYYY-MM-DD — <short title>
Problem: <one sentence>
Fix:     <one sentence>
Future:  <what next time's agent should do differently>
```

Read `notes/gotchas.md` at the start of every task in that project.

## What NOT to do

- Don't restructure the top-level layout (don't move `_templates/`,
  `_services/`, `scripts/`, etc.) without an explicit user request and
  a design doc for the change.
- Don't add new top-level dependencies in projects without checking
  whether a recipe already covers the use case.
- Don't skip tests. Don't disable tests. If a test is genuinely wrong,
  fix it; if you can't, escalate.
- Don't commit secrets. `.env` files are gitignored; `.env.example`
  documents the schema without real values.
- Don't introduce shared code between projects. Projects are deliberately
  independent. If you need to share, copy a recipe.
- Don't run `make services-reset-force` while someone else might be
  using a service. State is wiped permanently.

## When unclear, ask

If a task requires architectural decisions with multiple valid
approaches, stop and ask the user. Bad design that "works" is worse
than no design at all — the whole point of this repo is to think
clearly about trade-offs.
