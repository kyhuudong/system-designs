#!/usr/bin/env bash
# Tests for scripts/recipes-test.sh.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNNER="$REPO_ROOT/scripts/recipes-test.sh"

test_recipes_runner_exists_and_executable() {
  [ -x "$RUNNER" ]
}

test_recipes_runner_against_real_recipes_succeeds() {
  if ! command -v uv >/dev/null 2>&1 && ! command -v npm >/dev/null 2>&1; then
    echo "SKIP: neither uv nor npm installed"
    return 0
  fi
  ( cd "$REPO_ROOT" && "$RUNNER" >/tmp/runner_out.$$ 2>&1 )
  local rc=$?
  if [ $rc -ne 0 ]; then
    echo "runner exited $rc:"
    sed 's/^/    /' /tmp/runner_out.$$
    rm -f /tmp/runner_out.$$
    return 1
  fi
  grep -qE '  (python|node)/[a-z_-]+ +PASS' /tmp/runner_out.$$ || {
    echo "no PASS lines in runner output:"
    sed 's/^/    /' /tmp/runner_out.$$
    rm -f /tmp/runner_out.$$
    return 1
  }
  rm -f /tmp/runner_out.$$
}

test_recipes_runner_fails_when_recipe_test_fails() {
  if ! command -v uv >/dev/null 2>&1; then
    echo "SKIP: uv not installed"
    return 0
  fi
  local box; box=$(mktemp -d)
  mkdir -p "$box/_recipes/python" "$box/scripts"
  cp "$RUNNER" "$box/scripts/recipes-test.sh"
  chmod +x "$box/scripts/recipes-test.sh"
  cat > "$box/_recipes/python/broken.py" <<'PY'
def add(a, b):
    return a + b + 1
PY
  cat > "$box/_recipes/python/test_broken.py" <<'PY'
from broken import add

def test_add():
    assert add(1, 2) == 3
PY

  set +e
  ( cd "$box" && ./scripts/recipes-test.sh >/dev/null 2>&1 )
  local rc=$?
  set -e
  rm -rf "$box"
  [ $rc -ne 0 ]
}
