#!/usr/bin/env bash
# Lints every *.sh under scripts/ (and _recipes/ if any) with shellcheck.
# Skips with a notice if shellcheck isn't installed.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

test_shellcheck_passes_on_all_scripts() {
  if ! command -v shellcheck >/dev/null 2>&1; then
    echo "SKIP: shellcheck not installed (brew install shellcheck or apt install shellcheck)"
    return 0
  fi

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
