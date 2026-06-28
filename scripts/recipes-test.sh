#!/usr/bin/env bash
# Runs each recipe's co-located test in an isolated tmp dir.
# Python recipes: pattern test_<name>.py runs via `uv run --no-project --with pytest`.
# Node recipes:   pattern <name>.test.ts runs via `npx vitest` after `npm install`
#                 (npm rather than pnpm to avoid pnpm 11's build-script policy on esbuild).
# Exits non-zero if any recipe test fails. SKIPs cleanly if a toolchain is missing.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PY_DIR="$REPO_ROOT/_recipes/python"
NODE_DIR="$REPO_ROOT/_recipes/node"

pass=0
fail=0
skip=0
failed_recipes=()

have_uv() { command -v uv >/dev/null 2>&1; }
have_npm() { command -v npm >/dev/null 2>&1; }

run_python_recipe() {
  local recipe="$1"
  local name; name="$(basename "$recipe" .py)"
  local test_file="$PY_DIR/test_$name.py"
  if [ ! -f "$test_file" ]; then
    printf "  %-30s %s\n" "python/$name" "NO_TEST"
    return 0
  fi
  if ! have_uv; then
    printf "  %-30s %s\n" "python/$name" "SKIP (uv not installed)"
    skip=$((skip + 1))
    return 0
  fi
  local box; box=$(mktemp -d)
  cp "$recipe" "$test_file" "$box/"
  if ( cd "$box" && uv run --no-project --with pytest pytest -q "test_${name}.py" ) >/tmp/recipes_out.$$ 2>&1; then
    printf "  %-30s %s\n" "python/$name" "PASS"
    pass=$((pass + 1))
  else
    printf "  %-30s %s\n" "python/$name" "FAIL"
    sed 's/^/      /' /tmp/recipes_out.$$
    fail=$((fail + 1))
    failed_recipes+=("python/$name")
  fi
  rm -f /tmp/recipes_out.$$
  rm -rf "$box"
}

run_node_recipe() {
  local recipe="$1"
  local name; name="$(basename "$recipe" .ts)"
  local test_file="$NODE_DIR/${name}.test.ts"
  if [ ! -f "$test_file" ]; then
    printf "  %-30s %s\n" "node/$name" "NO_TEST"
    return 0
  fi
  if ! have_npm; then
    printf "  %-30s %s\n" "node/$name" "SKIP (npm not installed)"
    skip=$((skip + 1))
    return 0
  fi
  local box; box=$(mktemp -d)
  cp "$recipe" "$test_file" "$box/"
  cat > "$box/package.json" <<'JSON'
{"name":"recipe-test","type":"module","devDependencies":{"vitest":"^1.6.0"}}
JSON
  if ( cd "$box" && npm install --silent >/dev/null 2>&1 && npx vitest run --reporter=basic ) >/tmp/recipes_out.$$ 2>&1; then
    printf "  %-30s %s\n" "node/$name" "PASS"
    pass=$((pass + 1))
  else
    printf "  %-30s %s\n" "node/$name" "FAIL"
    sed 's/^/      /' /tmp/recipes_out.$$
    fail=$((fail + 1))
    failed_recipes+=("node/$name")
  fi
  rm -f /tmp/recipes_out.$$
  rm -rf "$box"
}

echo "Recipe tests:"

if [ -d "$PY_DIR" ]; then
  for recipe in "$PY_DIR"/*.py; do
    [ -e "$recipe" ] || continue
    case "$(basename "$recipe")" in
      test_*) continue ;;
    esac
    run_python_recipe "$recipe"
  done
fi

if [ -d "$NODE_DIR" ]; then
  for recipe in "$NODE_DIR"/*.ts; do
    [ -e "$recipe" ] || continue
    case "$(basename "$recipe")" in
      *.test.ts) continue ;;
    esac
    run_node_recipe "$recipe"
  done
fi

echo
echo "Summary: $pass passed, $fail failed, $skip skipped"
if [ $fail -gt 0 ]; then
  echo "Failed: ${failed_recipes[*]}"
  exit 1
fi
