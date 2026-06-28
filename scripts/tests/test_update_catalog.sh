#!/usr/bin/env bash
# Tests for scripts/update-catalog.sh.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CATALOG_SCRIPT="$REPO_ROOT/scripts/update-catalog.sh"

setup_catalog_sandbox() {
  SANDBOX=$(mktemp -d)
  mkdir -p "$SANDBOX/scripts"
  if [ -f "$CATALOG_SCRIPT" ]; then
    cp "$CATALOG_SCRIPT" "$SANDBOX/scripts/update-catalog.sh"
    chmod +x "$SANDBOX/scripts/update-catalog.sh"
  fi

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
  awk '/<!-- CATALOG:START -->/{flag=1; next} /<!-- CATALOG:END -->/{flag=0} flag' "$1/README.md"
}

# ---------- tests ----------

test_update_catalog_script_exists() {
  [ -x "$CATALOG_SCRIPT" ]
}

test_update_catalog_replaces_managed_block() {
  local box; box=$(setup_catalog_sandbox)
  make_project "$box" caching foo "done" node
  ( cd "$box" && ./scripts/update-catalog.sh ) >/dev/null
  local block; block=$(read_catalog_block "$box")
  echo "$block" | grep -q '_placeholder_' && { echo "placeholder still present"; teardown_catalog_sandbox "$box"; return 1; }
  echo "$block" | grep -qF 'foo' || { echo "project foo missing from catalog"; teardown_catalog_sandbox "$box"; return 1; }
  teardown_catalog_sandbox "$box"
}

test_update_catalog_preserves_surrounding_text() {
  local box; box=$(setup_catalog_sandbox)
  make_project "$box" caching foo "done" node
  ( cd "$box" && ./scripts/update-catalog.sh ) >/dev/null
  grep -q '^# fake repo$' "$box/README.md" || { echo "title missing"; teardown_catalog_sandbox "$box"; return 1; }
  grep -q '^## Quick start$' "$box/README.md" || { echo "preamble removed"; teardown_catalog_sandbox "$box"; return 1; }
  grep -q '^## After$' "$box/README.md" || { echo "postamble removed"; teardown_catalog_sandbox "$box"; return 1; }
  teardown_catalog_sandbox "$box"
}

test_update_catalog_groups_by_category_sorted() {
  local box; box=$(setup_catalog_sandbox)
  make_project "$box" caching bbb "done" node
  make_project "$box" caching aaa "done" node
  make_project "$box" apps zzz "done" python
  ( cd "$box" && ./scripts/update-catalog.sh ) >/dev/null
  local block; block=$(read_catalog_block "$box")
  local apps_line caching_line
  apps_line=$(echo "$block" | grep -n '^### apps' | head -1 | cut -d: -f1)
  caching_line=$(echo "$block" | grep -n '^### caching' | head -1 | cut -d: -f1)
  [ -n "$apps_line" ] && [ -n "$caching_line" ] && [ "$apps_line" -lt "$caching_line" ] || {
    echo "categories not in alpha order: apps at $apps_line, caching at $caching_line"
    teardown_catalog_sandbox "$box"
    return 1
  }
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
  make_project "$box" apps nostatus "" node
  ( cd "$box" && ./scripts/update-catalog.sh ) >/dev/null
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
  make_project "$box" caching foo "done" node
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
  make_project "$box" apps real "done" node
  mkdir -p "$box/_templates/junk" "$box/.hidden/junk" "$box/_services/foo"
  ( cd "$box" && ./scripts/update-catalog.sh ) >/dev/null
  local block; block=$(read_catalog_block "$box")
  echo "$block" | grep -F 'junk' && { echo "junk leaked into catalog"; teardown_catalog_sandbox "$box"; return 1; }
  echo "$block" | grep -F 'real' >/dev/null || { echo "real project missing"; teardown_catalog_sandbox "$box"; return 1; }
  teardown_catalog_sandbox "$box"
}

# ---------- regression: README without # Title shouldn't abort the script ----------

test_update_catalog_tolerates_titleless_readme() {
  local box; box=$(setup_catalog_sandbox)
  mkdir -p "$box/apps/notitle"
  # README intentionally has no top-level heading in first 5 lines.
  cat > "$box/apps/notitle/README.md" <<'README'
<!-- nothing but comments and prose here -->

This project's design doc was started but a heading hasn't been chosen yet.

## Subsection only

Body text.
README
  echo "done" > "$box/apps/notitle/.status"
  echo '{"name":"x"}' > "$box/apps/notitle/package.json"

  ( cd "$box" && ./scripts/update-catalog.sh ) >/dev/null
  local rc=$?
  if [ $rc -ne 0 ]; then
    echo "script exited $rc on titleless README"
    teardown_catalog_sandbox "$box"
    return 1
  fi

  local block; block=$(read_catalog_block "$box")
  # Title should fall back to the project basename when no '# Title' line exists.
  echo "$block" | grep -F 'notitle' >/dev/null || {
    echo "project missing from catalog"
    echo "block was:"; echo "$block"
    teardown_catalog_sandbox "$box"
    return 1
  }
  teardown_catalog_sandbox "$box"
}
