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

# ---------- scaffold behavior tests ----------

test_scaffold_node_creates_expected_files() {
  local box; box=$(setup_sandbox)
  ( cd "$box" && ./scripts/new-project.sh caching url-shortener node >/dev/null )
  local rc=$?
  if [ $rc -ne 0 ]; then teardown_sandbox "$box"; return 1; fi

  local target="$box/caching/url-shortener"
  for f in README.md Dockerfile docker-compose.yml Makefile package.json tsconfig.json \
           .eslintrc.json .prettierrc .env.example .gitignore .dockerignore \
           src/index.ts tests/smoke.test.ts; do
    if [ ! -f "$target/$f" ]; then
      echo "missing file: $f"
      teardown_sandbox "$box"
      return 1
    fi
  done
  teardown_sandbox "$box"
}

test_scaffold_python_creates_expected_files() {
  local box; box=$(setup_sandbox)
  ( cd "$box" && ./scripts/new-project.sh apps news-feed python >/dev/null )
  local rc=$?
  if [ $rc -ne 0 ]; then teardown_sandbox "$box"; return 1; fi

  local target="$box/apps/news-feed"
  for f in README.md Dockerfile docker-compose.yml Makefile pyproject.toml \
           .env.example .gitignore .dockerignore \
           src/__init__.py src/main.py tests/__init__.py tests/test_smoke.py; do
    if [ ! -f "$target/$f" ]; then
      echo "missing file: $f"
      teardown_sandbox "$box"
      return 1
    fi
  done
  teardown_sandbox "$box"
}

test_scaffold_substitutes_project_name() {
  local box; box=$(setup_sandbox)
  ( cd "$box" && ./scripts/new-project.sh caching url-shortener node >/dev/null )
  local target="$box/caching/url-shortener"
  if grep -r '__PROJECT_NAME__' "$target" >/dev/null 2>&1; then
    echo "found unsubstituted __PROJECT_NAME__"
    teardown_sandbox "$box"
    return 1
  fi
  grep -q '"name": "url-shortener"' "$target/package.json" || { teardown_sandbox "$box"; return 1; }
  teardown_sandbox "$box"
}

test_scaffold_substitutes_category() {
  local box; box=$(setup_sandbox)
  ( cd "$box" && ./scripts/new-project.sh caching url-shortener node >/dev/null )
  local target="$box/caching/url-shortener"
  if grep -r '__CATEGORY__' "$target" >/dev/null 2>&1; then
    echo "found unsubstituted __CATEGORY__"
    teardown_sandbox "$box"
    return 1
  fi
  # shellcheck disable=SC2016  # backticks in single quotes are literal markdown
  grep -q '`caching`' "$target/README.md" || { teardown_sandbox "$box"; return 1; }
  teardown_sandbox "$box"
}

test_scaffold_substitutes_project_title() {
  local box; box=$(setup_sandbox)
  ( cd "$box" && ./scripts/new-project.sh caching url-shortener node >/dev/null )
  local target="$box/caching/url-shortener"
  if grep -r '__PROJECT_TITLE__' "$target" >/dev/null 2>&1; then
    echo "found unsubstituted __PROJECT_TITLE__"
    teardown_sandbox "$box"
    return 1
  fi
  grep -q '^# Url Shortener' "$target/README.md" || { teardown_sandbox "$box"; return 1; }
  teardown_sandbox "$box"
}

test_scaffold_creates_category_when_missing() {
  local box; box=$(setup_sandbox)
  ( cd "$box" && ./scripts/new-project.sh networking dns-resolver python >/dev/null )
  [ -d "$box/networking/dns-resolver" ] || { teardown_sandbox "$box"; return 1; }
  teardown_sandbox "$box"
}

test_scaffold_does_not_modify_templates() {
  local box; box=$(setup_sandbox)
  ( cd "$box" && ./scripts/new-project.sh caching url-shortener node >/dev/null )
  # Templates should still contain unsubstituted placeholders.
  grep -q '__PROJECT_NAME__' "$box/_templates/node/package.json" || { teardown_sandbox "$box"; return 1; }
  teardown_sandbox "$box"
}

# ---------- regression tests for review findings ----------

test_scaffold_bootstraps_env_from_example() {
  local box; box=$(setup_sandbox)
  ( cd "$box" && ./scripts/new-project.sh caching env-check node >/dev/null )
  local target="$box/caching/env-check"
  if [ ! -f "$target/.env" ]; then
    echo "missing .env (should be bootstrapped from .env.example)"
    teardown_sandbox "$box"
    return 1
  fi
  # .env should match .env.example content (post-substitution)
  diff -q "$target/.env" "$target/.env.example" >/dev/null || {
    echo ".env content differs from .env.example"
    teardown_sandbox "$box"
    return 1
  }
  teardown_sandbox "$box"
}

test_scaffold_preserves_file_permissions() {
  local box; box=$(setup_sandbox)
  ( cd "$box" && ./scripts/new-project.sh caching perm-check node >/dev/null )
  local target="$box/caching/perm-check"
  # On macOS use `stat -f %A`, on Linux use `stat -c %a`. Pick whichever works.
  local mode
  if mode=$(stat -f '%A' "$target/src/index.ts" 2>/dev/null); then
    :
  elif mode=$(stat -c '%a' "$target/src/index.ts" 2>/dev/null); then
    :
  else
    echo "could not stat file mode"
    teardown_sandbox "$box"
    return 1
  fi
  # Mode should grant group+other read (i.e. not 600 / 400 / etc.). Accept 644 or 664.
  case "$mode" in
    644|664|666) ;;
    *)
      echo "unexpected file mode $mode for src/index.ts (expected 644/664/666)"
      teardown_sandbox "$box"
      return 1
      ;;
  esac
  teardown_sandbox "$box"
}

# ---------- regression: scaffold must roll back on mid-run failure ----------

test_scaffold_rolls_back_on_mid_run_failure() {
  local box; box=$(setup_sandbox)
  # Sabotage: make a template file unreadable so 'cp -R' fails partway through.
  chmod 000 "$box/_templates/node/package.json"

  set +e
  ( cd "$box" && ./scripts/new-project.sh caching rollback-check node >/dev/null 2>&1 )
  local rc=$?
  set -e

  # Restore perms before any teardown action would care.
  chmod 644 "$box/_templates/node/package.json" 2>/dev/null

  if [ $rc -eq 0 ]; then
    echo "expected non-zero exit, got 0"
    teardown_sandbox "$box"
    return 1
  fi

  if [ -e "$box/caching/rollback-check" ]; then
    echo "expected $box/caching/rollback-check to NOT exist after failure"
    ls -la "$box/caching" 2>&1
    teardown_sandbox "$box"
    return 1
  fi
  teardown_sandbox "$box"
}
