# Agent Enablement (Plan D) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the repo legible to AI agents so they can complete project tasks with minimal hand-holding — by adding repo-level conventions (`AGENTS.md`), per-project agent contracts (`AGENTS.md`, `DONE.md`, `AGENT-PROMPT.md`), and a per-project self-improvement log (`notes/gotchas.md`).

**Architecture:** Pure documentation + template additions. No new scripts. Existing `scripts/new-project.sh` already substitutes placeholders in every file it copies, so adding files to `_templates/{node,python}/` automatically wires them up.

**Tech Stack:** Markdown. Bash for tests.

**Spec:** [`docs/superpowers/specs/2026-06-28-agent-enablement-diagrams-learning-design.md`](../specs/2026-06-28-agent-enablement-diagrams-learning-design.md) (Bundle D)

---

## File Map

**Create (repo-level):**
- `AGENTS.md` — single source of truth for repo-wide agent instructions

**Modify (repo-level):**
- `README.md` — small "AI agents: read AGENTS.md first" pointer near the top

**Create (per-project templates, applied to BOTH `_templates/node/` and `_templates/python/`):**
- `AGENTS.md` — per-project agent contract (with substitution placeholders)
- `DONE.md` — checklist that defines "project is done"
- `AGENT-PROMPT.md` — pre-written prompt to paste into a fresh agent session
- `notes/gotchas.md` — self-improvement log starter

**Modify:**
- `scripts/tests/test_new_project.sh` — extend the existing expected-files lists in `test_scaffold_node_creates_expected_files` and `test_scaffold_python_creates_expected_files`; add substitution assertion test for the new files

---

## Task 1: Repo-level `AGENTS.md` + README pointer

**Files:**
- Create: `/Users/dong.kyh/works/system-designs/AGENTS.md`
- Modify: `/Users/dong.kyh/works/system-designs/README.md`

- [ ] **Step 1: Create `/Users/dong.kyh/works/system-designs/AGENTS.md`**

```markdown
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
```

- [ ] **Step 2: Add agent pointer near the top of `/Users/dong.kyh/works/system-designs/README.md`**

Insert this block IMMEDIATELY AFTER the existing `**Architecture:**` line (around line 8) and BEFORE the `## Quick start` heading:

```markdown

> **Working with an AI coding agent?** Point it at [`AGENTS.md`](./AGENTS.md) first.
> Repo-wide conventions, command index, and lifecycle all live there.
```

(The block contains a leading blank line so the markdown renders cleanly.)

- [ ] **Step 3: Verify the file tree and content**

```bash
cd /Users/dong.kyh/works/system-designs
ls AGENTS.md
head -20 README.md
```
Expected: `AGENTS.md` exists at root; the README shows the new pointer immediately after the Architecture line.

- [ ] **Step 4: Commit**

```bash
cd /Users/dong.kyh/works/system-designs
git add AGENTS.md README.md
git commit -m "feat: add repo-level AGENTS.md with conventions and command index

Single source of truth for AI coding agents. Documents the design-first
rule, project lifecycle, repo layout, command index, self-improvement
log usage, and what-not-to-do. Top-level README gets a one-line pointer
so agents discover AGENTS.md immediately.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 2: Per-project template additions — Node side

**Files:**
- Create: `_templates/node/AGENTS.md`
- Create: `_templates/node/DONE.md`
- Create: `_templates/node/AGENT-PROMPT.md`
- Create: `_templates/node/notes/gotchas.md`

- [ ] **Step 1: Create `_templates/node/AGENTS.md`**

```markdown
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
```

- [ ] **Step 2: Create `_templates/node/DONE.md`**

```markdown
# DONE.md — __PROJECT_TITLE__

Tick every box before declaring this project finished and setting
`.status` to `done`. This is the agent's stopping condition.

## Design
- [ ] `README.md` §1 (Problem statement) — filled, not placeholder
- [ ] `README.md` §2 (Requirements) — functional + non-functional with numeric NFRs
- [ ] `README.md` §3 (API / interface) — concrete endpoints / schemas
- [ ] `README.md` §4 (Architecture) — references the diagrams below
- [ ] `README.md` §5 (Data model) — schemas, indexes, partitioning
- [ ] `README.md` §6 (Trade-offs & alternatives) — at least one row in the table

## Diagrams
- [ ] `docs/diagrams/00-context.svg` — rendered from `.mmd` source via `make diagram`
- [ ] `docs/diagrams/01-sequence-happy-path.svg` — rendered

## Design artifacts
- [ ] `docs/requirements.md` — filled
- [ ] `docs/capacity-estimation.md` — back-of-envelope numbers present
- [ ] `docs/failure-modes.md` — at least 3 rows
- [ ] `docs/adr/` — at least one ADR for a real decision (not the template itself)

## Code & tests
- [ ] `make install` succeeds on a fresh clone
- [ ] `make test` passes
- [ ] `make lint` passes
- [ ] `make up` brings the project up; basic happy-path request works
- [ ] `make down` cleans up

## Reflection
- [ ] `README.md` §8 ("What I learned") — at least 3 substantive sentences,
      not boilerplate

## Catalog
- [ ] `.status` set to `done`
- [ ] Top-level catalog regenerated: `make catalog` from repo root
```

- [ ] **Step 3: Create `_templates/node/AGENT-PROMPT.md`**

```markdown
# AGENT-PROMPT.md — __PROJECT_TITLE__

Copy-paste this into a fresh agent session to bootstrap the agent fast.
Edit the bracketed parts.

---

```
I'm working on __CATEGORY__/__PROJECT_NAME__ in the system-designs
repo. Read these first, in order:

1. /Users/dong.kyh/works/system-designs/AGENTS.md
2. ./AGENTS.md (this project's contract)
3. ./README.md (design doc)
4. ./DONE.md (stopping condition)
5. ./notes/gotchas.md (lessons from prior sessions)

My request: [WHAT YOU WANT THE AGENT TO DO]

Constraints:
- Follow the design-first rule. If the design doc is incomplete, fix it
  before writing code.
- Use the existing recipes in /Users/dong.kyh/works/system-designs/_recipes/
  before adding new dependencies.
- Update ./notes/gotchas.md when you encounter anything non-obvious.
- Update ./docs/adr/ for any non-obvious decision.
- When you think you're done, walk through ./DONE.md and confirm every
  checkbox.
```
```

(Note: the inner triple-backticks above are the prompt body; the outer ones are the markdown code fence. When this file is rendered, the inner block displays as a code block — exactly what users want to copy.)

- [ ] **Step 4: Create `_templates/node/notes/gotchas.md`**

```bash
mkdir -p /Users/dong.kyh/works/system-designs/_templates/node/notes
```

Then create the file:

```markdown
# notes/gotchas.md — __PROJECT_TITLE__

Append a short entry whenever you hit something non-obvious. Future
agents (and you) will thank past you.

Format:

```
## YYYY-MM-DD — <short title>
Problem: <one sentence>
Fix:     <one sentence>
Future:  <what next time's agent should do differently>
```

---

## Examples (delete these once you've added real entries)

## 2026-06-28 — pnpm dlx couldn't import vitest from CWD
Problem: `pnpm dlx vitest run` fails with ERR_MODULE_NOT_FOUND because
         pnpm's dlx store isn't in node_modules of the calling project.
Fix:     Use `npm install vitest && npx vitest run` for ephemeral test
         environments where node_modules has to be local.
Future:  Prefer npm over pnpm for "install vitest into a scratch dir
         and run it" patterns; pnpm 11's build-script policy makes this
         worse.
```

- [ ] **Step 5: Commit**

```bash
cd /Users/dong.kyh/works/system-designs
git add _templates/node/AGENTS.md _templates/node/DONE.md _templates/node/AGENT-PROMPT.md _templates/node/notes/
git commit -m "feat(templates/node): add per-project agent contract files

AGENTS.md (per-project conventions and read-these-first list),
DONE.md (stopping-condition checklist), AGENT-PROMPT.md (paste-into-
new-session bootstrap prompt), notes/gotchas.md (self-improvement log
starter with one worked example).

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 3: Per-project template additions — Python side

Same content as Task 2 except minor stack-specific wording in `AGENTS.md`.

**Files:**
- Create: `_templates/python/AGENTS.md`
- Create: `_templates/python/DONE.md`
- Create: `_templates/python/AGENT-PROMPT.md`
- Create: `_templates/python/notes/gotchas.md`

- [ ] **Step 1: Create `_templates/python/AGENTS.md`**

```markdown
# AGENTS.md — __PROJECT_TITLE__

> **Read repo-root `AGENTS.md` FIRST** for repo-wide conventions. This
> file covers only what's specific to **__PROJECT_NAME__**.

## What this project is

- **Category:** `__CATEGORY__`
- **Stack:** Python 3.12
- **Status:** see `.status` (one of `planned`, `in-progress`, `done`, `paused`, `archived`)

## Done means

See [`DONE.md`](./DONE.md). Do not declare this project finished until
every checkbox is ticked.

## Recipes copied into this project

_List recipes you've copied from `_recipes/` here so future agents
know what's vendored and what's not (e.g., "Copied
`_recipes/python/retry.py` to `src/retry.py` unchanged")._

## Side services this project uses

_List which `_services/*` you connect to and how
(`make services-up` brings them all up; the env vars in `.env.example`
point at them)._

## Project-specific conventions

_Things to know that differ from repo defaults, e.g.:
"All errors flow through the structured logger in `src/logger.py`.
Don't add `print()` statements."_

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
```

- [ ] **Step 2: Create `_templates/python/DONE.md`**

Same content as `_templates/node/DONE.md` from Task 2 Step 2 — no stack-specific text in it. Copy the body verbatim into this file.

- [ ] **Step 3: Create `_templates/python/AGENT-PROMPT.md`**

Same content as `_templates/node/AGENT-PROMPT.md` from Task 2 Step 3 — no stack-specific text in it. Copy the body verbatim into this file.

- [ ] **Step 4: Create `_templates/python/notes/gotchas.md`**

```bash
mkdir -p /Users/dong.kyh/works/system-designs/_templates/python/notes
```

Same content as `_templates/node/notes/gotchas.md` from Task 2 Step 4 — copy verbatim.

- [ ] **Step 5: Commit**

```bash
cd /Users/dong.kyh/works/system-designs
git add _templates/python/AGENTS.md _templates/python/DONE.md _templates/python/AGENT-PROMPT.md _templates/python/notes/
git commit -m "feat(templates/python): add per-project agent contract files

Same set as the Node template (AGENTS.md, DONE.md, AGENT-PROMPT.md,
notes/gotchas.md), with the per-project AGENTS.md adjusted to mention
the Python stack.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 4: Extend scaffold tests

**Files:**
- Modify: `scripts/tests/test_new_project.sh`

- [ ] **Step 1: Extend the expected-files list in the Node scaffold test**

Open `/Users/dong.kyh/works/system-designs/scripts/tests/test_new_project.sh`. Locate the function `test_scaffold_node_creates_expected_files` and find its `for f in ...; do` loop. The current list ends with `src/index.ts tests/smoke.test.ts`.

Add the four new files to the list. The updated loop body should be:

```bash
  for f in README.md Dockerfile docker-compose.yml Makefile package.json tsconfig.json \
           .eslintrc.json .prettierrc .env.example .gitignore .dockerignore \
           src/index.ts tests/smoke.test.ts \
           AGENTS.md DONE.md AGENT-PROMPT.md notes/gotchas.md; do
```

- [ ] **Step 2: Extend the expected-files list in the Python scaffold test**

Same file. Locate `test_scaffold_python_creates_expected_files`. The current list ends with `src/__init__.py src/main.py tests/__init__.py tests/test_smoke.py`.

Add the four new files:

```bash
  for f in README.md Dockerfile docker-compose.yml Makefile pyproject.toml \
           .env.example .gitignore .dockerignore \
           src/__init__.py src/main.py tests/__init__.py tests/test_smoke.py \
           AGENTS.md DONE.md AGENT-PROMPT.md notes/gotchas.md; do
```

- [ ] **Step 3: Add a new test that asserts substitution happens in the agent files**

Append to the bottom of `/Users/dong.kyh/works/system-designs/scripts/tests/test_new_project.sh`:

```bash

# ---------- agent contract files: substitution coverage ----------

test_scaffold_substitutes_in_agents_md() {
  local box; box=$(setup_sandbox)
  ( cd "$box" && ./scripts/new-project.sh caching agents-check node >/dev/null )
  local f="$box/caching/agents-check/AGENTS.md"
  [ -f "$f" ] || { echo "missing AGENTS.md"; teardown_sandbox "$box"; return 1; }
  if grep -q '__PROJECT_NAME__\|__CATEGORY__\|__PROJECT_TITLE__' "$f"; then
    echo "unsubstituted placeholders in AGENTS.md"
    grep -n '__' "$f" | head
    teardown_sandbox "$box"
    return 1
  fi
  grep -q 'agents-check' "$f" || { echo "agents-check not in AGENTS.md"; teardown_sandbox "$box"; return 1; }
  grep -qF '`caching`' "$f" || { echo "category not in AGENTS.md"; teardown_sandbox "$box"; return 1; }
  teardown_sandbox "$box"
}

test_scaffold_substitutes_in_done_and_prompt() {
  local box; box=$(setup_sandbox)
  ( cd "$box" && ./scripts/new-project.sh apps done-check python >/dev/null )
  for f in "$box/apps/done-check/DONE.md" "$box/apps/done-check/AGENT-PROMPT.md" "$box/apps/done-check/notes/gotchas.md"; do
    [ -f "$f" ] || { echo "missing $f"; teardown_sandbox "$box"; return 1; }
    if grep -q '__PROJECT_NAME__\|__CATEGORY__\|__PROJECT_TITLE__' "$f"; then
      echo "unsubstituted placeholders in $f"
      teardown_sandbox "$box"
      return 1
    fi
  done
  # AGENT-PROMPT.md should mention the specific category and project name.
  grep -qF 'apps/done-check' "$box/apps/done-check/AGENT-PROMPT.md" || {
    echo "AGENT-PROMPT.md missing project ref"
    teardown_sandbox "$box"
    return 1
  }
  teardown_sandbox "$box"
}
```

- [ ] **Step 4: Run the full suite — expect all to PASS**

```bash
/Users/dong.kyh/works/system-designs/scripts/tests/run-tests.sh 2>&1 | tail -10
```
Expected: all tests pass. Count goes from 50 to 52 (two new tests).

If `test_scaffold_node_creates_expected_files` or `test_scaffold_python_creates_expected_files` fail because the new files aren't present, that means Task 2 or Task 3 wasn't completed. Go back and finish them first.

If the substitution tests fail because the existing `notes/` subdir was never created by the scaffolder: verify the scaffolder's `cp -R` copies subdirectories (it does — `cp -R` is recursive). If a specific file is missing, double-check the file actually exists in `_templates/{node,python}/`.

- [ ] **Step 5: Commit**

```bash
cd /Users/dong.kyh/works/system-designs
git add scripts/tests/test_new_project.sh
git commit -m "test(scripts): assert agent contract files are scaffolded with substitutions

Extends the existing per-language file-existence tests to cover the new
AGENTS.md, DONE.md, AGENT-PROMPT.md, and notes/gotchas.md. Adds two
substitution-coverage tests asserting __PROJECT_NAME__, __CATEGORY__,
and __PROJECT_TITLE__ are replaced in AGENTS.md, DONE.md,
AGENT-PROMPT.md, and notes/gotchas.md.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 5: End-to-end verification

**Files:** none (verification only)

- [ ] **Step 1: Full test suite**

```bash
/Users/dong.kyh/works/system-designs/scripts/tests/run-tests.sh 2>&1 | tail -10
```
Expected: all PASS (52 total).

- [ ] **Step 2: Scaffold a throwaway project and inspect**

```bash
SANDBOX=$(mktemp -d)
mkdir -p "$SANDBOX/scripts"
cp -R /Users/dong.kyh/works/system-designs/_templates "$SANDBOX/_templates"
cp /Users/dong.kyh/works/system-designs/scripts/new-project.sh "$SANDBOX/scripts/new-project.sh"
chmod +x "$SANDBOX/scripts/new-project.sh"

cd "$SANDBOX"
./scripts/new-project.sh apps demo-e2e python
echo "--- tree ---"
ls -la apps/demo-e2e
echo "--- AGENTS.md head ---"
head -15 apps/demo-e2e/AGENTS.md
echo "--- DONE.md head ---"
head -10 apps/demo-e2e/DONE.md
echo "--- AGENT-PROMPT.md head ---"
head -15 apps/demo-e2e/AGENT-PROMPT.md
echo "--- notes/gotchas.md head ---"
head -5 apps/demo-e2e/notes/gotchas.md
echo "--- check no leftover placeholders ---"
grep -r '__PROJECT_NAME__\|__CATEGORY__\|__PROJECT_TITLE__' apps/demo-e2e && echo FAIL || echo OK
cd /
rm -rf "$SANDBOX"
```
Expected:
- `apps/demo-e2e/` contains `AGENTS.md`, `DONE.md`, `AGENT-PROMPT.md`, `notes/gotchas.md`
- Each new file's head shows real values (`demo-e2e`, `apps`, `Demo E2e`) — no `__PLACEHOLDER__` text
- `grep` reports `OK` at the end (no unsubstituted placeholders)

- [ ] **Step 3: Sanity check the repo `AGENTS.md`**

```bash
cd /Users/dong.kyh/works/system-designs
head -20 AGENTS.md
grep -c "## " AGENTS.md   # should be >= 5 section headers
```

- [ ] **Step 4: Repo state clean**

```bash
cd /Users/dong.kyh/works/system-designs
git status
ls
```
Expected: working tree clean, top-level shows `AGENTS.md` alongside the existing files.

- [ ] **Step 5: Tag the milestone**

```bash
cd /Users/dong.kyh/works/system-designs
git tag -a agent-enablement-v1 -m "Agent enablement: repo AGENTS.md + per-project agent contract"
```

---

## Done

After Task 5, a fresh agent dropped into a scaffolded project has:
- Repo-wide instructions (`AGENTS.md` at root)
- Project-specific contract (`AGENTS.md` in the project)
- A precise stopping condition (`DONE.md`)
- A ready-to-paste session prompt (`AGENT-PROMPT.md`)
- A place to record and read prior lessons (`notes/gotchas.md`)

Plan E will add the diagram rendering pipeline and `make design-check`, which the DONE.md and AGENTS.md already reference (those references will become live once E lands).
