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
