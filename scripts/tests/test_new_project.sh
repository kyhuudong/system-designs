#!/usr/bin/env bash
# Tests for scripts/new-project.sh

# Resolve repo root and script path
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/new-project.sh"

# Run the script in a sandboxed copy of the repo so we don't pollute the working
# tree. The sandbox contains only what the script needs: _templates/ and the
# script itself.
setup_sandbox() {
  SANDBOX=$(mktemp -d)
  mkdir -p "$SANDBOX/scripts"
  cp -R "$REPO_ROOT/_templates" "$SANDBOX/_templates"
  cp "$SCRIPT" "$SANDBOX/scripts/new-project.sh"
  chmod +x "$SANDBOX/scripts/new-project.sh"
  echo "$SANDBOX"
}

teardown_sandbox() {
  rm -rf "$1"
}

# ---------- validation tests ----------

test_help_flag_exits_zero() {
  local box; box=$(setup_sandbox)
  ( cd "$box" && ./scripts/new-project.sh --help >/dev/null )
  local rc=$?
  teardown_sandbox "$box"
  [ $rc -eq 0 ]
}

test_no_args_exits_nonzero() {
  local box; box=$(setup_sandbox)
  set +e
  ( cd "$box" && ./scripts/new-project.sh >/dev/null 2>&1 )
  local rc=$?
  set -e
  teardown_sandbox "$box"
  [ $rc -ne 0 ]
}

test_two_args_exits_nonzero() {
  local box; box=$(setup_sandbox)
  set +e
  ( cd "$box" && ./scripts/new-project.sh caching url-shortener >/dev/null 2>&1 )
  local rc=$?
  set -e
  teardown_sandbox "$box"
  [ $rc -ne 0 ]
}

test_invalid_lang_exits_nonzero() {
  local box; box=$(setup_sandbox)
  set +e
  ( cd "$box" && ./scripts/new-project.sh caching url-shortener rust >/dev/null 2>&1 )
  local rc=$?
  set -e
  teardown_sandbox "$box"
  [ $rc -ne 0 ]
}

test_invalid_name_uppercase_exits_nonzero() {
  local box; box=$(setup_sandbox)
  set +e
  ( cd "$box" && ./scripts/new-project.sh caching URLShortener node >/dev/null 2>&1 )
  local rc=$?
  set -e
  teardown_sandbox "$box"
  [ $rc -ne 0 ]
}

test_invalid_name_underscore_exits_nonzero() {
  local box; box=$(setup_sandbox)
  set +e
  ( cd "$box" && ./scripts/new-project.sh caching url_shortener node >/dev/null 2>&1 )
  local rc=$?
  set -e
  teardown_sandbox "$box"
  [ $rc -ne 0 ]
}

test_invalid_category_uppercase_exits_nonzero() {
  local box; box=$(setup_sandbox)
  set +e
  ( cd "$box" && ./scripts/new-project.sh Caching url-shortener node >/dev/null 2>&1 )
  local rc=$?
  set -e
  teardown_sandbox "$box"
  [ $rc -ne 0 ]
}

test_existing_target_exits_nonzero() {
  local box; box=$(setup_sandbox)
  mkdir -p "$box/caching/url-shortener"
  set +e
  ( cd "$box" && ./scripts/new-project.sh caching url-shortener node >/dev/null 2>&1 )
  local rc=$?
  set -e
  teardown_sandbox "$box"
  [ $rc -ne 0 ]
}

test_valid_inputs_exit_zero_node() {
  local box; box=$(setup_sandbox)
  ( cd "$box" && ./scripts/new-project.sh caching url-shortener node >/dev/null )
  local rc=$?
  teardown_sandbox "$box"
  [ $rc -eq 0 ]
}

test_valid_inputs_exit_zero_python() {
  local box; box=$(setup_sandbox)
  ( cd "$box" && ./scripts/new-project.sh apps news-feed python >/dev/null )
  local rc=$?
  teardown_sandbox "$box"
  [ $rc -eq 0 ]
}
