# Agent Enablement, Diagram-First Design, and Learning Aids — Architecture Design

**Date:** 2026-06-28
**Status:** Approved (pending user review of this spec)
**Bundles three related improvement areas:** Agent enablement (D), diagram-first design (E), learning aids (F). Each gets its own implementation plan.

## Problem Statement

The repo has reached a usable v1 (scaffolding, side services, recipes, atomic catalog). Two unmet needs remain:

1. **You delegate most work to AI agents.** The repo's conventions live in scattered specs/READMEs — agents have to read a lot to figure out "how do I do X here." Without a clear contract, agents drift: they re-derive conventions, miss the design-first rule, or stop before the project actually works.

2. **You build to learn.** The current design doc template asks for a mermaid diagram, but nothing renders it as a committed image, nothing enforces it's actually drawn, and nothing nudges you to think about *failure modes*, *back-of-envelope sizing*, or *trade-offs explicitly*. Practice without those steps reinforces "make it work" thinking, not "design a system" thinking.

These are addressed by three loosely-coupled bundles, sequenced D → E → F.

## Goals

- Agents can complete a project task with minimal hand-holding because the repo tells them what to do, when they're done, and where to write down lessons learned.
- Every project starts with a diagram before any code, and the diagram survives as a committed SVG anyone can view.
- Learning artifacts (ADRs, capacity estimation, failure-mode analysis) are part of the standard project, not optional homework.

## Non-Goals

- A custom AI agent runtime, multi-agent orchestration, or evaluator pipelines.
- A full curriculum / textbook of system design.
- Per-tool config files for every AI tool that exists. `AGENTS.md` is the source of truth; tool-specific symlinks (e.g., `.cursorrules`) are out of scope for v1.
- Auto-execution of `make finalize` in git hooks. Manual invocation only.
- A renderer for non-Mermaid diagram formats (D2, PlantUML, etc.).
- Cloud-rendered diagrams or hosted diagram-as-code tools.

---

## Bundle D — Agent enablement

### Approach

A four-layer agent contract: repo-level instructions, project-level instructions, a stopping condition, and a self-improvement log.

### Files added / modified

**Repo-level (new):**
- `AGENTS.md` — Single source of truth for repo-wide agent instructions. ~150 lines. Includes:
  - The design-first rule ("write design before code, period")
  - Project lifecycle (scaffold → design → implement → finalize → catalog)
  - Command index (`make` targets, scaffolding command, recipe location)
  - Where things live (categories, templates, recipes, services, docs)
  - "What not to do" (don't restructure layout without asking, don't add deps without checking, don't skip tests)
  - How to use the self-improvement log
  - A pointer to project-level `AGENTS.md` for project-specific context

**Repo-level (modified):**
- Top-level `README.md` — small section near the top: "AI agents: read `AGENTS.md` first."

**Per-project template additions** (in both `_templates/node/` and `_templates/python/`):
- `AGENTS.md` — Per-project agent contract. Skeleton fields the scaffolder substitutes:
  - Project name, category, stack
  - "Done means" link to `DONE.md`
  - "Side services this project uses" (placeholder for human to fill)
  - "Recipes copied into this project" (placeholder)
  - Pointer to `notes/gotchas.md` and `AGENT-PROMPT.md`
- `DONE.md` — A checklist template. Required items at scaffold time:
  - `- [ ] Design doc (`README.md`) sections 1–6 filled`
  - `- [ ] Context diagram (`docs/diagrams/00-context.svg`) present`
  - `- [ ] `make test` passes`
  - `- [ ] `make lint` passes`
  - `- [ ] Section 8 ("What I learned") of `README.md` non-trivial`
  - Plus project-specific rows the user adds
- `notes/gotchas.md` — Self-improvement log starter. Format:
  ```
  ## YYYY-MM-DD — <short title>
  Problem: ...
  Fix: ...
  Future: ...
  ```
  Agents are instructed (via the repo `AGENTS.md`) to append here whenever they hit something non-obvious.
- `AGENT-PROMPT.md` — Pre-written prompt template the user can paste into a fresh agent session. Includes pointers to design doc, DONE checklist, notes, conventions.

**Scaffolding behavior:** existing `scripts/new-project.sh` already substitutes placeholders in every file — no script changes needed. Tests assert the new files exist and have substitutions applied.

### Self-improvement loop

The pattern: agents read repo `AGENTS.md` + project `AGENTS.md` + project `notes/gotchas.md` at task start. When they encounter something non-obvious (a tool quirk, an unexpected dep clash, a recipe that needed adjustment), they append a 3-line entry to `notes/gotchas.md`. Subsequent agents pick up the wisdom for free. No automation required for v1.

### `make doctor` (deferred — captured here for reference)

A `make doctor` target that prints env diagnostics (Docker running? uv installed? npm version? side services up?) is *out of scope* for Plan D — small but separable.

### Testing (Plan D)

- New scaffold-output assertions for the 4 new per-project files
- `AGENTS.md` content tests are minimal (just existence + substitution, not content quality)

---

## Bundle E — Diagram-first design

### Approach

Mermaid diagrams already live inline in design docs (placeholders in template). Plan E:
- Promote diagrams to a `docs/diagrams/<name>.mmd` source-of-truth (one file per diagram, plain text, git-friendly)
- Render to `docs/diagrams/<name>.svg` committed alongside via a `make diagram` target
- Two starter diagrams per project: **context** (C4 level 1) and **sequence happy-path**
- A `make design-check` target asserts both `.svg` files exist before declaring a project ready

### Files added / modified

**Per-project template additions** (both languages):
- `docs/diagrams/00-context.mmd` — C4 Context placeholder, edits required by user
- `docs/diagrams/01-sequence-happy-path.mmd` — sequence diagram placeholder
- `docs/diagrams/.gitignore` — keep `.svg` rendered files tracked but allow scratch `*.tmp.svg`

**Per-project Makefile additions:**
- `make diagram` — renders every `docs/diagrams/*.mmd` → `.svg`. Uses Mermaid CLI via Docker so users don't need a local Node install:
  ```
  docker run --rm -u $(id -u):$(id -g) -v "$$PWD":/data minlag/mermaid-cli -i <in> -o <out>
  ```
  Skips cleanly with a clear message if Docker isn't available.
- `make design-check` — asserts:
  - Both `docs/diagrams/00-context.svg` and `docs/diagrams/01-sequence-happy-path.svg` exist
  - `README.md` sections 1, 2, 4 (problem, requirements, architecture) are non-empty (not still placeholder text)

**Per-project README template change:**
- §4 (Architecture) gets explicit "see `docs/diagrams/00-context.svg`" and "see `docs/diagrams/01-sequence-happy-path.svg`" inserts, plus a one-line `make diagram` reminder.

**Repo-level (deferred):**
- A `make diagrams-all` target that walks every project and renders. *Out of scope for Plan E* — small follow-up.

### Testing (Plan E)

- Scaffold-output assertions: both `.mmd` files exist, Makefile has `diagram` and `design-check` targets
- A scaffold-then-diagram sandbox test: scaffold a project, run `make diagram`, assert both `.svg` files appear. Skips cleanly if Docker isn't available.
- A `design-check` test:
  - Fresh scaffold → `make design-check` fails (placeholders still in README, no `.svg` rendered)
  - After rendering + filling sections → `make design-check` passes

### Why Mermaid CLI via Docker

- No Node install needed in the project
- Always pinned version (one image tag, repeatable rendering)
- Same toolchain on macOS and Linux
- The `minlag/mermaid-cli` image is the official one; pin major tag for predictability

---

## Bundle F — Learning aids

This bundle is the largest. To keep Plan F focused, implement a **starter subset** now and defer the rest to a follow-up plan (same pattern as Plan B).

### Plan F starter scope

**Per-project additions** (in both templates):
- `docs/adr/0000-template.md` — ADR template (Context / Decision / Consequences / Alternatives Considered)
- `docs/adr/README.md` — short note: "Add `0001-<topic>.md` for each non-obvious decision. Number sequentially."
- `docs/requirements.md` — functional + non-functional requirements template, with numeric NFR rows (QPS, p50/p95/p99 latency, durability, availability)
- `docs/capacity-estimation.md` — back-of-envelope worksheet (users, RPS, payload size, storage growth, bandwidth, single-node limit, when does it need sharding)
- `docs/failure-modes.md` — table template: failure → blast radius → detection → mitigation
- README §7 (How to run) gets a one-liner: "Open `docs/adr/`, `docs/requirements.md`, `docs/capacity-estimation.md`, `docs/failure-modes.md`."
- `DONE.md` checklist (from Plan D) gets four new rows: each of these docs has been filled (not still placeholder)

**Repo-level additions:**
- `docs/learning/README.md` — index
- `docs/learning/latency-numbers.md` — Jeff Dean's latency numbers + practical implications
- `docs/learning/consistency-models.md` — strong / eventual / read-your-writes / causal — when each matters
- `docs/learning/back-of-envelope.md` — methodology + worked examples

### Plan F deferred to follow-up (F2)

- `docs/learning/cap-pacelc.md`
- `docs/learning/system-design-pattern-glossary.md` (saga, CQRS, event sourcing, sharding, leader election, etc.)
- `docs/problems/` — curated index of classic system-design problems with hints
- `_recipes/compose/k6-runner.yml` and per-project `tests/load.js` (load testing infrastructure)
- `make finalize` and `make postmortem` automation
- A "compare to reference" `docs/postmortem.md` template

### Testing (Plan F)

- Scaffold-output assertions for the new `docs/` files
- `design-check` (from Plan E) extended to also assert ADR/requirements/etc. are present (existence only, not content quality)
- The `docs/learning/*.md` files are pure docs — no tests beyond a markdown-link-sanity smoke test

---

## Cross-bundle interactions

- Plan E adds `make design-check`. Plan F extends it (one extra asserted file per worksheet). Plan D's `DONE.md` lists what `design-check` enforces.
- Plan D's `AGENTS.md` references Plan E's `docs/diagrams/` and Plan F's `docs/adr/`. Implementation order matters: D's content references E and F artifacts.
- **Mitigation:** write Plan D's `AGENTS.md` *last* in Plan D's implementation, after E and F are merged. Or write Plan D's `AGENTS.md` with placeholder references that Plans E/F fill in. Either works; recommended approach: write all three plans, then **implement in order D → E → F**, and at the start of E and F revisit `AGENTS.md` to add the new sections.

## Trade-offs & Alternatives Considered

| Decision | Chosen | Alternative | Why |
|---|---|---|---|
| Agent contract location | Dedicated `AGENTS.md` (repo + per-project) | Embed in `README.md` | Separation of concerns: README is for humans, AGENTS.md is for the AI |
| Per-tool config | Single `AGENTS.md` only | Generate `.cursorrules`, `.copilot-instructions.md`, etc. | YAGNI — symlink later if needed |
| Diagram format | Mermaid only | Mermaid + D2 + PlantUML | One format keeps tooling simple; mermaid covers C4 + sequence + flow |
| Diagram tooling | `minlag/mermaid-cli` via Docker | Local `@mermaid-js/mermaid-cli` install | Zero local install, pinned version, repeatable |
| Diagram rendering trigger | Manual `make diagram` | Pre-commit hook | Manual is enough for v1; can automate later |
| Worksheets location | Per-project `docs/` | Single shared template | Each project needs its own values; sharing the *template* (via scaffold) preserves independence |
| ADR template | Lightweight 4-section | Full MADR / Y-statements / Nygard | Smaller is more likely to be filled |
| Learning notes location | `docs/learning/` at repo root | Per-project | Cross-cutting; one place to reference from many projects |
| `make finalize` automation | Deferred to F2 | Implement now | Avoid creeping scope on a polish task; `design-check` is enough for v1 |
| Self-improvement log | `notes/gotchas.md` per project | Shared `docs/lessons-learned.md` | Per-project keeps signal high; gets read when working on that project |

## Open Questions

None at design time. Specific worksheet wording, ADR template phrasing, and learning-notes content depth are implementation choices made in the plans.

## Out of Scope (Future)

- Plan F2: rest of learning library (pattern glossary, CAP/PACELC, problems index, load testing, finalize automation)
- `make doctor` env-diagnostic target
- `make diagrams-all` repo-wide renderer
- `make all-tests` repo-wide test runner
- Git hooks (pre-commit auto-rendering, pre-push design-check)
- Per-AI-tool config files (`.cursorrules` etc.)
- Auto-derived `AGENTS.md` per project (currently a static template)
- A curated patterns library beyond glossary entries
- Devcontainer / `bootstrap.sh` for one-command environment setup
