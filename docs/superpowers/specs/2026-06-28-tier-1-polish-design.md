# Tier 1 Polish — Architecture Design

**Date:** 2026-06-28
**Status:** Approved (pending user review of this spec)
**Bundles:** Items 2–5 from the post-Plan-A audit (the "real-gaps" tier minus the recipes library, which has its own spec).

## Problem Statement

After Plan A landed, four small but meaningful gaps remain in the repo's developer experience:

1. The top-level `README.md` catalog is hand-maintained — projects get added/removed, status changes, and the catalog falls out of date. Users forget to update it.
2. The new-project entry point is `./scripts/new-project.sh`, while every other repo operation is `make <target>`. Two muscle-memory paths for one repo.
3. `scripts/new-project.sh` is `set -euo pipefail`, so a mid-copy or mid-substitution failure leaves a half-created project directory on disk. The user then has to manually `rm -rf` to recover.
4. The repo's bash scripts are not linted. Bash is a footgun-rich language; `shellcheck` would catch real bugs cheaply.

## Goals

- Make the catalog effectively zero-maintenance: write code, run one command (or never run it manually if a pre-commit hook is added later), see the catalog update.
- Provide `make new` so scaffolding fits the same mental model as every other repo command.
- Make scaffolding atomic: success leaves a valid project, any failure leaves no trace.
- Surface bash quality issues automatically via `shellcheck` in the existing test harness.

## Non-Goals

- Auto-running the catalog update on every commit (pre-commit hook). Manual `make catalog` is enough for v1; hooks can come later if forgetting is a real problem.
- Replacing the existing `scripts/new-project.sh` with a Make-only implementation. The script stays as the source of truth; Make is a thin convenience wrapper.
- Aggressive shellcheck severities (warnings vs errors). Use the tool's defaults; fix issues it surfaces; document any deliberate exceptions inline.
- Implementing the recipes library (Plan B) or any Tier 2/3 items from the audit. Out of scope.

## Architecture

### Item 2 — Auto-generated catalog

**Source of truth:** Each project directory may contain a `.status` file with one line whose value is one of:
- `planned` → 📝 planned
- `in-progress` → 🚧 in progress  *(default if `.status` missing)*
- `done` → ✅ done
- `paused` → 🧊 paused
- `archived` → 🗑️ archived

**Script:** `scripts/update-catalog.sh`
- Walks `<category>/<project>/` directories at depth 2 from the repo root, skipping any directory starting with `_` or `.`.
- For each project:
  - Reads `.status` (one line; trim whitespace). Validates value. Defaults to `in-progress` if missing.
  - Reads the project's `README.md` first `# Title` line for the display title.
  - Detects stack: `Node` if `package.json` exists, `Python` if `pyproject.toml` exists, otherwise `?`.
- Generates a markdown block grouped by category (sorted alphabetically; projects within a category sorted alphabetically by name).
- Replaces the content between `<!-- CATALOG:START -->` and `<!-- CATALOG:END -->` markers in top-level `README.md`. If markers are missing, exits non-zero with a clear error.
- Idempotent: running twice with no project changes yields identical output.

**Top-level `README.md`** is updated to replace the existing per-category placeholder sections with a single managed block:

```markdown
## Catalog

<!-- CATALOG:START -->
_Run `make catalog` to regenerate this section._
<!-- CATALOG:END -->
```

**Makefile:** `make catalog` runs `scripts/update-catalog.sh` and prints a diff summary.

**Tests:** A `scripts/tests/test_update_catalog.sh` creates fake projects with `.status` files in a sandbox copy of the repo, runs the script, asserts:
- Markers respected (block content replaced, surrounding text untouched)
- Categories grouped and sorted
- Projects within categories sorted
- Default status applied when `.status` is missing
- Invalid status values cause non-zero exit
- Missing markers cause non-zero exit
- Idempotent (running twice → same output)

### Item 3 — `make new` at repo root

Add a `new` target to the top-level `Makefile`:

```bash
make new CATEGORY=apps NAME=url-shortener LANG=python
```

**Behavior:**
- Validates `CATEGORY`, `NAME`, `LANG` are all set before invoking the script. Missing any → print usage and exit 1.
- Invokes `./scripts/new-project.sh "$(CATEGORY)" "$(NAME)" "$(LANG)"`.
- Script does its own kebab-case validation and propagates exit codes.

**Help text:** the `## comment` for `new` includes a usage example.

**Tests:** Adds two cases to `scripts/tests/test_top_makefile.sh`:
- Missing vars → non-zero exit
- All vars set → exit 0 (sandbox to avoid touching repo state)

### Item 4 — Atomic scaffold rollback

Add an ERR trap to `scripts/new-project.sh` immediately after `TARGET_DIR` is computed AND validated as not pre-existing:

```bash
trap 'rm -rf "$TARGET_DIR"' ERR
# ... do work ...
trap - ERR
```

This ensures any failure (sed error, find error, cp permission issue) leaves no partial directory.

**Tests:** A new test in `scripts/tests/test_new_project.sh` injects a controlled failure (e.g., make the template directory unreadable mid-copy, or sabotage the template after the existence check) and asserts `$TARGET_DIR` does NOT exist afterward. If a portable way to inject failure is hard, fall back to a unit-style test that calls the script with a template that contains a syntactically broken file the script processes.

Simplest injection: temporarily replace `_templates/node/Dockerfile` (in the sandbox) with a symlink to a non-existent path before running the scaffold — `cp -R` will fail at that file, and the trap should clean up.

### Item 5 — ShellCheck test

New test `scripts/tests/test_shellcheck.sh`:
- Skips with PASS if `shellcheck` is not on PATH.
- Lists every `*.sh` file under the repo (excluding `_services/data/` and any `node_modules`/`.venv`).
- Runs `shellcheck` on each. Reports per-file pass/fail. Fails the test if any file has shellcheck errors.

**Fix any existing issues:** before the test passes, audit the existing scripts (`scripts/new-project.sh`, `scripts/tests/*.sh`) for issues shellcheck flags. Document any deliberate suppressions inline using `# shellcheck disable=SCXXXX` with a comment explaining why.

## Data Flow

- **Catalog script:** reads project metadata → emits markdown → in-place updates `README.md` between markers. No persistent state of its own.
- **`make new`:** Make → bash script → filesystem. No new flow vs the existing direct-script path.
- **ERR trap:** in-process. No external state.
- **ShellCheck test:** reads `*.sh` files → invokes external tool → reports.

## Error Handling

- **`update-catalog.sh`:** clear errors for missing markers, invalid `.status` values, missing README title. Non-zero exit per error.
- **`make new`:** missing required vars → usage message + non-zero exit. Script-level errors propagate.
- **`new-project.sh`** with ERR trap: prior behavior preserved (clear messages); now also auto-cleans the target dir on any error.
- **ShellCheck test:** if shellcheck isn't installed, skip cleanly with a SKIP notice (PASS). If it is, fail loud on any file with errors.

## Testing

- `scripts/tests/test_update_catalog.sh` — new
- `scripts/tests/test_shellcheck.sh` — new
- `scripts/tests/test_top_makefile.sh` — extend with `make new` tests
- `scripts/tests/test_new_project.sh` — extend with atomic-rollback test
- All run via the existing `scripts/tests/run-tests.sh` harness. Expect ~6 new tests, all passing on macOS bash 3.2 and Linux bash 4+/5+.

## Trade-offs & Alternatives Considered

| Decision | Chosen | Alternative | Why |
|---|---|---|---|
| Status source | `.status` file | YAML front-matter in README, or status badge regex | User-selected. Simplest to read/write; greppable; survives README edits without escaping concerns |
| Catalog trigger | Explicit `make catalog` | Pre-commit hook auto-regen | YAGNI for v1; can be added later if forgetting becomes a real problem |
| `make new` interface | `CATEGORY=… NAME=… LANG=…` | Short vars (`C=`, `N=`, `L=`) or positional | Long form is clear and self-documenting; positional args don't read naturally in Make |
| Rollback mechanism | `trap ... ERR` | Manual `if/else` after each step | Trap is the standard bash idiom for cleanup-on-failure; less code, fewer escape paths missed |
| ShellCheck install | Skip-if-missing | Hard requirement | Some environments don't have it; skipping cleanly matches the docker-compose test pattern |
| Existing per-category README sections | Replace with managed `<!-- CATALOG -->` block | Keep manual sections, add a separate auto-section below | Two sources of truth is worse than one; managed block is the single source going forward |

## Open Questions

None at design time.

## Out of Scope (Future)

- Pre-commit hook auto-running `make catalog`
- Per-project status badges (e.g., "tests passing" derived from running `make test`)
- A `make new` short form like `make new apps/url-shortener.py`
- Promoting ERR-trap pattern to all scripts (the existing scripts are short enough that it's a YAGNI)
- ShellCheck severity tuning, SARIF output, custom rule disabling beyond the inline `# shellcheck disable=` mechanism
