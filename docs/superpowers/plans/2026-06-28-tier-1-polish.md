# Tier 1 Polish (Plan C) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Polish four small but meaningful gaps in the repo's DX: atomic scaffolding (rollback on failure), `make new` entry point, auto-generated catalog, and `shellcheck` linting in the existing test harness.

**Architecture:** Each item is a small, targeted change. No new subsystems. Mostly Bash + a new Make target. Tests integrate into the existing `scripts/tests/run-tests.sh` harness.

**Tech Stack:** Bash 3.2-compatible, GNU Make, shellcheck.

**Spec:** [`docs/superpowers/specs/2026-06-28-tier-1-polish-design.md`](../specs/2026-06-28-tier-1-polish-design.md)

**Order:** Item 4 first (smallest, isolated), then Item 3, then Item 2 (largest), then Item 5 (last so it lints any scripts added in earlier tasks).

---

## File Map

**Create:**
- `scripts/update-catalog.sh` — catalog regenerator
- `scripts/tests/test_update_catalog.sh` — catalog smoke tests
- `scripts/tests/test_shellcheck.sh` — shellcheck on every `*.sh`

**Modify:**
- `scripts/new-project.sh` — add ERR trap (atomic rollback)
- `scripts/tests/test_new_project.sh` — add rollback test
- `Makefile` — add `new` and `catalog` targets, update `.PHONY`
- `scripts/tests/test_top_makefile.sh` — extend with `new` and `catalog` target tests
- `README.md` — replace per-category placeholder sections with managed `<!-- CATALOG -->` block
- Any `*.sh` files that shellcheck flags (Task 4 may touch existing scripts)

---

## Task 1: Item 4 — Atomic scaffold rollback

**Files:**
- Modify: `scripts/new-project.sh`
- Modify: `scripts/tests/test_new_project.sh`

- [ ] **Step 1: Write the failing rollback test**

Append to the bottom of `/Users/dong.kyh/works/system-designs/scripts/tests/test_new_project.sh`:

```bash

# ---------- regression: scaffold must roll back on mid-run failure ----------

test_scaffold_rolls_back_on_mid_run_failure() {
  local box; box=$(setup_sandbox)
  # Sabotage the node template after the existence check but before sed walks files:
  # replace a regular file in the template with a broken symlink, so `cp -R` fails.
  ln -sf /tmp/__does_not_exist__ "$box/_templates/node/CORRUPT_LINK"

  set +e
  ( cd "$box" && ./scripts/new-project.sh caching rollback-check node >/dev/null 2>&1 )
  local rc=$?
  set -e

  # Script should have exited non-zero.
  if [ $rc -eq 0 ]; then
    echo "expected non-zero exit, got 0"
    teardown_sandbox "$box"
    return 1
  fi

  # Target directory must NOT exist (rollback worked).
  if [ -e "$box/caching/rollback-check" ]; then
    echo "expected $box/caching/rollback-check to NOT exist after failure"
    ls -la "$box/caching" 2>&1
    teardown_sandbox "$box"
    return 1
  fi
  teardown_sandbox "$box"
}
```

- [ ] **Step 2: Run the test — expect FAIL (no rollback yet)**

```bash
/Users/dong.kyh/works/system-designs/scripts/tests/run-tests.sh 2>&1 | grep -E "^Results:|test_scaffold_rolls_back"
```
Expected: `test_scaffold_rolls_back_on_mid_run_failure FAIL`. The target directory survives because the script has no cleanup.

(If `cp -R` happens to succeed despite the broken symlink on some platforms, the test would FAIL for a different reason — sed then fails on the broken link. Either way, the target dir exists after, which is what the test asserts against.)

- [ ] **Step 3: Add the ERR trap to `scripts/new-project.sh`**

Edit `/Users/dong.kyh/works/system-designs/scripts/new-project.sh`. Locate this block (around line 60):

```bash
if [ -e "$TARGET_DIR" ]; then
  die "target already exists: $TARGET_DIR"
fi

# Build a Title Case version of the kebab-case name: "url-shortener" -> "Url Shortener".
```

Replace it with:

```bash
if [ -e "$TARGET_DIR" ]; then
  die "target already exists: $TARGET_DIR"
fi

# Atomic: if anything below fails, remove the half-created target.
# $TARGET_DIR was verified to NOT exist above, so removing it is safe.
trap 'rc=$?; if [ -n "${TARGET_DIR:-}" ] && [ -e "$TARGET_DIR" ]; then rm -rf "$TARGET_DIR"; echo "scaffold failed; cleaned up $TARGET_DIR" >&2; fi; exit $rc' ERR

# Build a Title Case version of the kebab-case name: "url-shortener" -> "Url Shortener".
```

Then locate the LAST line of the file (after `cat <<EOF ... EOF`) and append:

```bash

# Clear the rollback trap — we made it to the end successfully.
trap - ERR
```

- [ ] **Step 4: Run the test — expect PASS**

```bash
/Users/dong.kyh/works/system-designs/scripts/tests/run-tests.sh 2>&1 | grep -E "^Results:|test_scaffold_rolls_back"
```
Expected: `test_scaffold_rolls_back_on_mid_run_failure PASS`. Existing tests still pass (regression check via full count).

If the test fails because the trap fires but the directory isn't removed: check whether `set -euo pipefail` is causing the script to exit before the trap runs — the trap is on ERR which fires on any non-zero exit from any command outside an `if`/`while`/`||`. With `set -e` this is the correct setup.

- [ ] **Step 5: Commit**

```bash
cd /Users/dong.kyh/works/system-designs
git add scripts/new-project.sh scripts/tests/test_new_project.sh
git commit -m "fix(scripts): atomic scaffold — rollback target dir on any mid-run failure

Before: a failure mid-copy or mid-substitution left a half-created project
directory on disk, requiring manual rm -rf. After: an ERR trap removes the
target directory on any non-zero exit, then re-raises the exit code. The
trap is cleared on success.

Adds a regression test that sabotages the template with a broken symlink
and asserts the target dir does NOT exist after the failed scaffold.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 2: Item 3 — `make new` at repo root

**Files:**
- Modify: `Makefile`
- Modify: `scripts/tests/test_top_makefile.sh`

- [ ] **Step 1: Add failing tests for the `new` target**

Append to `/Users/dong.kyh/works/system-designs/scripts/tests/test_top_makefile.sh` (before the `# ---------- regression ...` comment if you want them grouped logically, or just at the bottom):

```bash

# ---------- `make new` target ----------

test_make_new_target_exists() {
  grep -qE "^new[[:space:]]*:" "$MAKEFILE"
}

test_make_new_help_shows_usage_example() {
  local out
  out=$(cd "$REPO_ROOT" && make help 2>&1)
  echo "$out" | grep -qE "^[[:space:]]*new\b"
}

test_make_new_without_vars_fails() {
  set +e
  ( cd "$REPO_ROOT" && make new >/dev/null 2>&1 )
  local rc=$?
  set -e
  [ $rc -ne 0 ]
}

test_make_new_with_vars_succeeds_in_sandbox() {
  # Sandbox the repo so we don't pollute the working tree.
  local box; box=$(mktemp -d)
  mkdir -p "$box/scripts"
  cp -R "$REPO_ROOT/_templates" "$box/_templates"
  cp "$REPO_ROOT/scripts/new-project.sh" "$box/scripts/new-project.sh"
  chmod +x "$box/scripts/new-project.sh"
  cp "$REPO_ROOT/Makefile" "$box/Makefile"

  ( cd "$box" && make new CATEGORY=apps NAME=make-new-test LANG=node >/dev/null 2>&1 )
  local rc=$?
  if [ $rc -ne 0 ]; then
    echo "make new exited $rc"
    rm -rf "$box"
    return 1
  fi
  [ -d "$box/apps/make-new-test" ] || { echo "project dir not created"; rm -rf "$box"; return 1; }
  rm -rf "$box"
}
```

- [ ] **Step 2: Run the tests — expect 4 FAILs**

```bash
/Users/dong.kyh/works/system-designs/scripts/tests/run-tests.sh 2>&1 | grep -E "^Results:|test_make_new"
```
Expected: 4 FAILs for the new tests.

- [ ] **Step 3: Add `new` target to `/Users/dong.kyh/works/system-designs/Makefile`**

Update `.PHONY` to include `new`:

Change:
```makefile
.PHONY: help services-up services-down services-logs services-status services-reset services-reset-force
```
to:
```makefile
.PHONY: help services-up services-down services-logs services-status services-reset services-reset-force new
```

Append at the bottom of the Makefile (after `services-reset-force`):

```makefile

new: ## Scaffold a project: make new CATEGORY=<cat> NAME=<name> LANG=<node|python>
	@if [ -z "$(CATEGORY)" ] || [ -z "$(NAME)" ] || [ -z "$(LANG)" ]; then \
	  echo "error: missing required vars" >&2; \
	  echo "usage: make new CATEGORY=<category> NAME=<project-name> LANG=<node|python>" >&2; \
	  echo "example: make new CATEGORY=apps NAME=url-shortener LANG=python" >&2; \
	  exit 1; \
	fi
	./scripts/new-project.sh "$(CATEGORY)" "$(NAME)" "$(LANG)"
```

- [ ] **Step 4: Update `EXPECTED_TARGETS` in `test_top_makefile.sh`**

Find the array near the top of `scripts/tests/test_top_makefile.sh`:

```bash
EXPECTED_TARGETS=(
  services-up
  services-down
  services-logs
  services-status
  services-reset
  services-reset-force
  help
)
```

Add `new`:

```bash
EXPECTED_TARGETS=(
  services-up
  services-down
  services-logs
  services-status
  services-reset
  services-reset-force
  new
  help
)
```

(This makes `test_top_makefile_defines_every_target` and `test_top_makefile_help_lists_every_target` exercise the new target.)

- [ ] **Step 5: Run the tests — expect all to PASS**

```bash
/Users/dong.kyh/works/system-designs/scripts/tests/run-tests.sh 2>&1 | grep -E "^Results:|test_make_new|test_top_makefile"
```
Expected: all the `test_make_new_*` and `test_top_makefile_*` tests PASS.

- [ ] **Step 6: Verify `make help` looks right**

```bash
cd /Users/dong.kyh/works/system-designs
make
```
Expected: `new` listed with usage hint, between `services-reset-force` and the tip block (or wherever your order resolved).

- [ ] **Step 7: Commit**

```bash
cd /Users/dong.kyh/works/system-designs
git add Makefile scripts/tests/test_top_makefile.sh
git commit -m "feat(Makefile): add 'make new' target for one-line scaffolding

  make new CATEGORY=apps NAME=url-shortener LANG=python

Validates required vars before invoking scripts/new-project.sh. Extends
test_top_makefile.sh's EXPECTED_TARGETS so existence and help-listing
tests cover the new target, plus 4 new tests for var validation and
sandbox-end-to-end behavior.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 3: Item 2 — Auto-generated catalog

This is the biggest item. The script walks `<category>/<project>/` directories, reads each project's `.status` and `README.md`, and regenerates a managed block in the top-level `README.md`.

**Files:**
- Create: `scripts/update-catalog.sh`
- Create: `scripts/tests/test_update_catalog.sh`
- Modify: `Makefile` — add `catalog` target
- Modify: `README.md` — replace per-category sections with managed block
- Modify: `scripts/tests/test_top_makefile.sh` — add `catalog` to `EXPECTED_TARGETS`

### 3A. Replace the catalog section in `README.md`

- [ ] **Step 1: Replace the catalog placeholder sections**

In `/Users/dong.kyh/works/system-designs/README.md`, find the existing block starting at `## Catalog` and ending after the last `_No projects yet._` line. Replace it entirely with:

```markdown
## Catalog

<!-- CATALOG:START -->
_Run `make catalog` to regenerate this section._
<!-- CATALOG:END -->
```

Keep everything before `## Catalog` (Quick start, Status legend, Side services) and everything after `<!-- CATALOG:END -->` untouched.

- [ ] **Step 2: Verify the markers are exactly placed**

```bash
grep -n "CATALOG:START\|CATALOG:END" /Users/dong.kyh/works/system-designs/README.md
```
Expected: 2 lines, one for START, one for END, with reasonable line numbers.

### 3B. Write the failing catalog tests

- [ ] **Step 3: Create `scripts/tests/test_update_catalog.sh`**

```bash
#!/usr/bin/env bash
# Tests for scripts/update-catalog.sh.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/update-catalog.sh"

setup_catalog_sandbox() {
  SANDBOX=$(mktemp -d)
  mkdir -p "$SANDBOX/scripts"
  cp "$SCRIPT" "$SANDBOX/scripts/update-catalog.sh" 2>/dev/null || true
  [ -f "$SANDBOX/scripts/update-catalog.sh" ] && chmod +x "$SANDBOX/scripts/update-catalog.sh"

  cat > "$SANDBOX/README.md" <<'README'
# fake repo

## Quick start

Some preamble.

## Catalog

<!-- CATALOG:START -->
_placeholder_
<!-- CATALOG:END -->

## After

Some postamble.
README

  echo "$SANDBOX"
}

teardown_catalog_sandbox() {
  rm -rf "$1"
}

make_project() {
  # $1 = sandbox, $2 = category, $3 = name, $4 = status (or empty), $5 = stack (node|python)
  local box="$1" cat="$2" name="$3" status="${4:-}" stack="$5"
  mkdir -p "$box/$cat/$name"
  echo "# $(echo "$name" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)$i=toupper(substr($i,1,1)) substr($i,2)} 1')" > "$box/$cat/$name/README.md"
  if [ -n "$status" ]; then
    echo "$status" > "$box/$cat/$name/.status"
  fi
  if [ "$stack" = "node" ]; then
    echo '{"name":"x"}' > "$box/$cat/$name/package.json"
  elif [ "$stack" = "python" ]; then
    echo '[project]' > "$box/$cat/$name/pyproject.toml"
  fi
}

read_catalog_block() {
  # Print just the lines between (exclusive) CATALOG:START and CATALOG:END.
  awk '/<!-- CATALOG:START -->/{flag=1; next} /<!-- CATALOG:END -->/{flag=0} flag' "$1/README.md"
}

# ---------- tests ----------

test_update_catalog_script_exists() {
  [ -x "$SCRIPT" ]
}

test_update_catalog_replaces_managed_block() {
  local box; box=$(setup_catalog_sandbox)
  make_project "$box" caching foo done node
  ( cd "$box" && ./scripts/update-catalog.sh )
  local block; block=$(read_catalog_block "$box")
  # Original placeholder line must be gone.
  echo "$block" | grep -q '_placeholder_' && { echo "placeholder still present"; teardown_catalog_sandbox "$box"; return 1; }
  # New project must appear.
  echo "$block" | grep -qF 'foo' || { echo "project foo missing from catalog"; teardown_catalog_sandbox "$box"; return 1; }
  teardown_catalog_sandbox "$box"
}

test_update_catalog_preserves_surrounding_text() {
  local box; box=$(setup_catalog_sandbox)
  make_project "$box" caching foo done node
  ( cd "$box" && ./scripts/update-catalog.sh )
  grep -q '^# fake repo$' "$box/README.md" || { echo "title missing"; teardown_catalog_sandbox "$box"; return 1; }
  grep -q '^## Quick start$' "$box/README.md" || { echo "preamble removed"; teardown_catalog_sandbox "$box"; return 1; }
  grep -q '^## After$' "$box/README.md" || { echo "postamble removed"; teardown_catalog_sandbox "$box"; return 1; }
  teardown_catalog_sandbox "$box"
}

test_update_catalog_groups_by_category_sorted() {
  local box; box=$(setup_catalog_sandbox)
  make_project "$box" caching bbb done node
  make_project "$box" caching aaa done node
  make_project "$box" apps zzz done python
  ( cd "$box" && ./scripts/update-catalog.sh )
  local block; block=$(read_catalog_block "$box")
  # apps must come before caching alphabetically.
  echo "$block" | grep -nE '^### apps|^### caching' | head -2 | awk '{print $0}' > /tmp/cat_order.$$
  local first second
  first=$(sed -n '1p' /tmp/cat_order.$$ | grep -oE 'apps|caching')
  second=$(sed -n '2p' /tmp/cat_order.$$ | grep -oE 'apps|caching')
  rm -f /tmp/cat_order.$$
  [ "$first" = "apps" ] && [ "$second" = "caching" ] || {
    echo "categories not in alpha order: $first then $second"
    teardown_catalog_sandbox "$box"
    return 1
  }
  # Within caching, aaa must appear before bbb.
  local aaa_line bbb_line
  aaa_line=$(echo "$block" | grep -nF '| aaa ' | head -1 | cut -d: -f1)
  bbb_line=$(echo "$block" | grep -nF '| bbb ' | head -1 | cut -d: -f1)
  [ -n "$aaa_line" ] && [ -n "$bbb_line" ] && [ "$aaa_line" -lt "$bbb_line" ] || {
    echo "projects within category not sorted: aaa at $aaa_line, bbb at $bbb_line"
    teardown_catalog_sandbox "$box"
    return 1
  }
  teardown_catalog_sandbox "$box"
}

test_update_catalog_default_status_in_progress() {
  local box; box=$(setup_catalog_sandbox)
  # No .status file.
  make_project "$box" apps nostatus "" node
  ( cd "$box" && ./scripts/update-catalog.sh )
  local block; block=$(read_catalog_block "$box")
  echo "$block" | grep -F 'nostatus' | grep -qE 'in.progress|🚧' || {
    echo "default status not applied"
    echo "block was:"
    echo "$block"
    teardown_catalog_sandbox "$box"
    return 1
  }
  teardown_catalog_sandbox "$box"
}

test_update_catalog_invalid_status_errors() {
  local box; box=$(setup_catalog_sandbox)
  make_project "$box" apps weird "totally-bogus" node
  set +e
  ( cd "$box" && ./scripts/update-catalog.sh >/dev/null 2>&1 )
  local rc=$?
  set -e
  teardown_catalog_sandbox "$box"
  [ $rc -ne 0 ]
}

test_update_catalog_missing_markers_errors() {
  local box; box=$(setup_catalog_sandbox)
  # Remove the markers.
  printf '# no markers here\n' > "$box/README.md"
  set +e
  ( cd "$box" && ./scripts/update-catalog.sh >/dev/null 2>&1 )
  local rc=$?
  set -e
  teardown_catalog_sandbox "$box"
  [ $rc -ne 0 ]
}

test_update_catalog_is_idempotent() {
  local box; box=$(setup_catalog_sandbox)
  make_project "$box" caching foo done node
  ( cd "$box" && ./scripts/update-catalog.sh ) >/dev/null
  cp "$box/README.md" "$box/README.first.md"
  ( cd "$box" && ./scripts/update-catalog.sh ) >/dev/null
  diff -q "$box/README.first.md" "$box/README.md" >/dev/null || {
    echo "second run produced different output"
    diff -u "$box/README.first.md" "$box/README.md"
    teardown_catalog_sandbox "$box"
    return 1
  }
  teardown_catalog_sandbox "$box"
}

test_update_catalog_skips_underscore_and_dot_dirs() {
  local box; box=$(setup_catalog_sandbox)
  make_project "$box" apps real done node
  mkdir -p "$box/_templates/junk" "$box/.hidden/junk" "$box/_services/foo"
  ( cd "$box" && ./scripts/update-catalog.sh ) >/dev/null
  local block; block=$(read_catalog_block "$box")
  echo "$block" | grep -F 'junk' && { echo "junk leaked into catalog"; teardown_catalog_sandbox "$box"; return 1; }
  echo "$block" | grep -F 'real' >/dev/null || { echo "real project missing"; teardown_catalog_sandbox "$box"; return 1; }
  teardown_catalog_sandbox "$box"
}
```

- [ ] **Step 4: Run the tests — expect all to FAIL (script missing)**

```bash
/Users/dong.kyh/works/system-designs/scripts/tests/run-tests.sh 2>&1 | grep -E "^Results:|test_update_catalog"
```
Expected: 8 `test_update_catalog_*` FAILs.

### 3C. Implement the script

- [ ] **Step 5: Create `/Users/dong.kyh/works/system-designs/scripts/update-catalog.sh`**

```bash
#!/usr/bin/env bash
# Regenerate the project catalog in the top-level README.md.
# Walks <category>/<project>/ directories at depth 2 (excluding any starting
# with _ or .), reads each project's .status and README.md title, and emits
# a topic-grouped markdown table between <!-- CATALOG:START --> and
# <!-- CATALOG:END --> markers.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
README="$REPO_ROOT/README.md"
START_MARK="<!-- CATALOG:START -->"
END_MARK="<!-- CATALOG:END -->"

if [ ! -f "$README" ]; then
  echo "error: $README not found" >&2
  exit 1
fi
if ! grep -qF "$START_MARK" "$README" || ! grep -qF "$END_MARK" "$README"; then
  echo "error: $README is missing CATALOG markers" >&2
  echo "expected lines containing:" >&2
  echo "  $START_MARK" >&2
  echo "  $END_MARK" >&2
  exit 1
fi

status_for() {
  local dir="$1"
  local raw="in-progress"
  if [ -f "$dir/.status" ]; then
    raw=$(head -n1 "$dir/.status" | tr -d '[:space:]')
  fi
  case "$raw" in
    planned)     echo "📝 planned" ;;
    in-progress) echo "🚧 in-progress" ;;
    done)        echo "✅ done" ;;
    paused)      echo "🧊 paused" ;;
    archived)    echo "🗑️ archived" ;;
    *) echo "error: invalid status '$raw' in $dir/.status (expected planned|in-progress|done|paused|archived)" >&2; exit 1 ;;
  esac
}

title_for() {
  local dir="$1"
  if [ -f "$dir/README.md" ]; then
    head -n5 "$dir/README.md" | grep -m1 -E '^#[[:space:]]' | sed -E 's/^#[[:space:]]+//'
  else
    basename "$dir"
  fi
}

stack_for() {
  local dir="$1"
  if [ -f "$dir/package.json" ]; then
    echo "Node"
  elif [ -f "$dir/pyproject.toml" ]; then
    echo "Python"
  else
    echo "?"
  fi
}

# Collect project entries grouped by category. Sort categories, then projects within.
TMPDIR_OUT=$(mktemp -d)
trap 'rm -rf "$TMPDIR_OUT"' EXIT

# Find category directories (depth 1, exclude _* and .*).
CATEGORIES=$(find "$REPO_ROOT" -mindepth 1 -maxdepth 1 -type d \
  ! -name '_*' ! -name '.*' \
  -exec basename {} \; 2>/dev/null | sort)

# Also exclude well-known top-level dirs that aren't categories.
EXCLUDE='^(docs|scripts)$'

for cat in $CATEGORIES; do
  if echo "$cat" | grep -qE "$EXCLUDE"; then
    continue
  fi
  cat_dir="$REPO_ROOT/$cat"
  # Find project subdirs (depth 1 within the category).
  projects=$(find "$cat_dir" -mindepth 1 -maxdepth 1 -type d \
    ! -name '_*' ! -name '.*' \
    -exec basename {} \; 2>/dev/null | sort)
  [ -z "$projects" ] && continue

  {
    echo ""
    echo "### $cat"
    echo ""
    echo "| Project | Stack | Status | Doc |"
    echo "|---|---|---|---|"
    for proj in $projects; do
      proj_dir="$cat_dir/$proj"
      stack=$(stack_for "$proj_dir")
      status=$(status_for "$proj_dir")
      title=$(title_for "$proj_dir")
      [ -z "$title" ] && title="$proj"
      doc="./$cat/$proj/README.md"
      echo "| $proj | $stack | $status | [$title]($doc) |"
    done
  } >> "$TMPDIR_OUT/block"
done

# If no projects found anywhere, emit the "none" line.
if [ ! -s "$TMPDIR_OUT/block" ]; then
  printf '\n_No projects yet. Run `make new CATEGORY=<cat> NAME=<name> LANG=<node|python>`._\n\n' > "$TMPDIR_OUT/block"
fi

# Rewrite README.md: keep everything outside the markers, replace inside.
TMP_README=$(mktemp)
awk -v block_file="$TMPDIR_OUT/block" \
    -v start="$START_MARK" \
    -v end="$END_MARK" '
  $0 ~ start {
    print
    while ((getline line < block_file) > 0) print line
    close(block_file)
    in_block = 1
    next
  }
  $0 ~ end {
    in_block = 0
    print
    next
  }
  !in_block { print }
' "$README" > "$TMP_README"

cat "$TMP_README" > "$README"
rm -f "$TMP_README"

echo "Updated catalog in $README"
```

- [ ] **Step 6: Make executable**

```bash
chmod +x /Users/dong.kyh/works/system-designs/scripts/update-catalog.sh
```

- [ ] **Step 7: Run the tests — expect all to PASS**

```bash
/Users/dong.kyh/works/system-designs/scripts/tests/run-tests.sh 2>&1 | grep -E "^Results:|test_update_catalog"
```
Expected: all 8 `test_update_catalog_*` PASS.

If any fail, read the captured output and adjust. Common issues:
- macOS `find ... -exec basename {} \;` returns full path on some versions; consider `find ... -print | sed "s|.*/||"` as a fallback
- awk's `getline` behavior differs between BSD and GNU awk; the pattern above should work on both but if not, fall back to sed-based marker replacement

### 3D. Wire up `make catalog`

- [ ] **Step 8: Add `catalog` to `EXPECTED_TARGETS` in `scripts/tests/test_top_makefile.sh`**

Add `catalog` to the array:

```bash
EXPECTED_TARGETS=(
  services-up
  services-down
  services-logs
  services-status
  services-reset
  services-reset-force
  new
  catalog
  help
)
```

- [ ] **Step 9: Add `catalog` target to `/Users/dong.kyh/works/system-designs/Makefile`**

Update `.PHONY` to include `catalog`:

Change:
```makefile
.PHONY: help services-up services-down services-logs services-status services-reset services-reset-force new
```
to:
```makefile
.PHONY: help services-up services-down services-logs services-status services-reset services-reset-force new catalog
```

Append at the bottom of the Makefile:
```makefile

catalog: ## Regenerate the project catalog in README.md
	@scripts/update-catalog.sh
```

- [ ] **Step 10: Run tests — expect all to PASS**

```bash
/Users/dong.kyh/works/system-designs/scripts/tests/run-tests.sh 2>&1 | tail -10
```
Expected: every test PASS.

- [ ] **Step 11: Run `make catalog` against the real repo and verify it updates cleanly**

```bash
cd /Users/dong.kyh/works/system-designs
make catalog
git diff README.md | head -30
```
Expected: `README.md` shows the catalog block now contains either the `_No projects yet…_` line (if no real projects yet) or any real projects found. The CATALOG markers are unchanged.

- [ ] **Step 12: Commit**

```bash
cd /Users/dong.kyh/works/system-designs
git add scripts/update-catalog.sh scripts/tests/test_update_catalog.sh Makefile README.md scripts/tests/test_top_makefile.sh
git commit -m "feat: add make catalog for auto-generated project index

scripts/update-catalog.sh walks <category>/<project>/ dirs (depth 2),
reads each project's .status (default 'in-progress') and README.md
title, detects stack from package.json/pyproject.toml, and replaces the
managed block between CATALOG:START and CATALOG:END in README.md.

Categories and projects within categories are sorted. Surrounding
README text is preserved. Idempotent. Errors loud on invalid status or
missing markers.

8 smoke tests covering markers, sorting, default status, validation,
idempotency, and underscore/dot-dir exclusion.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 4: Item 5 — ShellCheck test

**Files:**
- Create: `scripts/tests/test_shellcheck.sh`
- Modify: any existing `*.sh` flagged by shellcheck (only fixes; no behavior changes)

- [ ] **Step 1: Verify shellcheck is available (or install)**

```bash
which shellcheck && shellcheck --version
```
If not installed on macOS:
```bash
brew install shellcheck
```
If you don't want to install it, the test will SKIP cleanly when run on this machine, but it's worth having locally for the audit step.

- [ ] **Step 2: Run shellcheck on the existing scripts to surface issues**

```bash
cd /Users/dong.kyh/works/system-designs
find scripts -type f -name "*.sh" -print0 | xargs -0 shellcheck -e SC1091 || true
```
The `-e SC1091` suppresses "Can't follow non-constant source" — harmless for our `source "$file"` pattern in the test runner.

Note the output. Fix any genuine issues (typically: unquoted vars, command substitutions, missing `--` separators, `[ ]` instead of `[[ ]]` for regex). Document deliberate suppressions inline with `# shellcheck disable=SCXXXX # reason`.

- [ ] **Step 3: Apply fixes**

For each issue surfaced in Step 2, apply the smallest fix that satisfies shellcheck without changing behavior. Common ones:
- Quote `$VAR` → `"$VAR"`
- Replace `$(cmd)` with explicit interpretation if shellcheck can't infer it
- Add `# shellcheck disable=SCXXXX # <reason>` for deliberate idioms
- Do NOT restructure logic to please shellcheck; if a rule is wrong, suppress with comment

Re-run Step 2 until clean (other than allowed suppressions).

- [ ] **Step 4: Create `scripts/tests/test_shellcheck.sh`**

```bash
#!/usr/bin/env bash
# Lints every *.sh under scripts/ (and _recipes/ if any) with shellcheck.
# Skips with a notice if shellcheck isn't installed.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

test_shellcheck_passes_on_all_scripts() {
  if ! command -v shellcheck >/dev/null 2>&1; then
    echo "SKIP: shellcheck not installed (brew install shellcheck or apt install shellcheck)"
    return 0
  fi

  # Find scripts. Exclude _services/data and any node_modules/.venv that may exist.
  local files
  files=$(find "$REPO_ROOT" \
    \( -path "$REPO_ROOT/_services/data" -o -path '*/node_modules' -o -path '*/.venv' \) -prune -o \
    -type f -name '*.sh' -print)

  if [ -z "$files" ]; then
    echo "no .sh files found"
    return 1
  fi

  local fail=0
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if ! shellcheck -e SC1091 "$f" >/tmp/shellcheck_out.$$ 2>&1; then
      echo "shellcheck failed: $f"
      sed 's/^/    /' /tmp/shellcheck_out.$$
      fail=$((fail + 1))
    fi
    rm -f /tmp/shellcheck_out.$$
  done <<< "$files"

  [ $fail -eq 0 ]
}
```

- [ ] **Step 5: Run the tests — expect PASS or SKIP**

```bash
/Users/dong.kyh/works/system-designs/scripts/tests/run-tests.sh 2>&1 | grep -E "^Results:|test_shellcheck"
```
Expected: `test_shellcheck_passes_on_all_scripts PASS` (if shellcheck installed) or PASS-via-SKIP (if not).

If FAIL, re-run Step 3 — surface remaining issues, fix or suppress, re-test.

- [ ] **Step 6: Commit**

```bash
cd /Users/dong.kyh/works/system-designs
git add scripts/tests/test_shellcheck.sh $(git diff --name-only scripts | tr '\n' ' ')
git commit -m "test: add shellcheck linting on every *.sh, fix any issues surfaced

Adds scripts/tests/test_shellcheck.sh which runs shellcheck (with SC1091
suppressed for our source-from-glob pattern) on every *.sh file under
the repo. Skips cleanly with PASS if shellcheck isn't installed.

If any pre-existing scripts were modified, the commit includes the
minimal fixes required to pass shellcheck without changing behavior;
deliberate idioms are suppressed inline with a comment explaining why.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

(If no other scripts needed changes, the second `git add` will be a no-op and the diff will only include the new test file.)

---

## Task 5: End-to-end verification

**Files:** none

- [ ] **Step 1: Verify the full test suite**

```bash
/Users/dong.kyh/works/system-designs/scripts/tests/run-tests.sh 2>&1 | tail -15
```
Expected: every test passes. Total count after Plans A + B + C should be around 45-50 (the exact number depends on Plan B/C ordering).

- [ ] **Step 2: Verify all Make targets**

```bash
cd /Users/dong.kyh/works/system-designs
make
```
Expected: `make help` shows: help, services-up, services-down, services-logs, services-status, services-reset, services-reset-force, new, catalog (and recipes-test if Plan B is also done).

- [ ] **Step 3: Try the new scaffold + catalog flow end-to-end**

```bash
cd /Users/dong.kyh/works/system-designs
make new CATEGORY=apps NAME=catalog-demo LANG=python
echo "done" > apps/catalog-demo/.status
make catalog
git diff README.md | head -20
```
Expected: README catalog now shows the `catalog-demo` project under `### apps` with status `✅ done`.

- [ ] **Step 4: Clean up the demo**

```bash
cd /Users/dong.kyh/works/system-designs
rm -rf apps/catalog-demo
rmdir apps 2>/dev/null || true
make catalog
git status
```
Expected: catalog reverts to "no projects" line; working tree shows README.md modified twice (now back to baseline) — `git status` may show README.md as modified depending on whether the catalog block content went back identically. If it did, no change. If close-but-not-identical, that's the catalog formatting being slightly different from the original `_Run …_` placeholder — that's expected one-time.

If `README.md` shows changes from before-Step-3 baseline, revert it: `git checkout README.md`.

- [ ] **Step 5: Tag the milestone**

```bash
cd /Users/dong.kyh/works/system-designs
git tag -a tier-1-polish-v1 -m "Tier 1 polish: atomic scaffold, make new, make catalog, shellcheck"
```

---

## Done

After Task 5, the repo's developer experience is noticeably tighter:

- `make new CATEGORY=apps NAME=foo LANG=python` — one command, fits the `make` muscle memory
- A failure mid-scaffold leaves no trace (`trap ERR` cleans up the target dir)
- `make catalog` regenerates the project index — set `.status` files, never edit the README by hand
- `make services-up` / `make services-down` / etc. unchanged from Plan A
- `make recipes-test` unchanged from Plan B (if Plan B is done)
- ShellCheck runs on every `*.sh` as part of the standard test harness — bash typos caught for free

Future small polishes (per audit Tier 2/3) remain on the wishlist but no longer block daily use.
