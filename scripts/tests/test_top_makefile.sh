#!/usr/bin/env bash
# Tests for the top-level Makefile.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MAKEFILE="$REPO_ROOT/Makefile"

# Every target the spec promises.
EXPECTED_TARGETS=(
  services-up
  services-down
  services-logs
  services-status
  services-reset
  services-reset-force
  help
)

test_top_makefile_exists() {
  [ -f "$MAKEFILE" ]
}

test_top_makefile_defines_every_target() {
  local missing=0
  for t in "${EXPECTED_TARGETS[@]}"; do
    if ! grep -qE "^${t}[[:space:]]*:" "$MAKEFILE"; then
      echo "missing target: $t"
      missing=$((missing + 1))
    fi
  done
  [ $missing -eq 0 ]
}

test_top_makefile_help_lists_every_target() {
  local out
  out=$(cd "$REPO_ROOT" && make help 2>&1)
  for t in "${EXPECTED_TARGETS[@]}"; do
    if ! echo "$out" | grep -qE "^[[:space:]]*${t}\b"; then
      echo "make help did not list: $t"
      echo "--- make help output ---"
      echo "$out"
      return 1
    fi
  done
}

test_top_makefile_default_target_is_help() {
  local out
  out=$(cd "$REPO_ROOT" && make 2>&1)
  echo "$out" | grep -qE "^Usage:|^Targets:|services-up"
}

test_top_makefile_reset_requires_confirmation() {
  set +e
  ( cd "$REPO_ROOT" && printf '\n' | make services-reset >/dev/null 2>&1 )
  local rc=$?
  set -e
  [ $rc -ne 0 ]
}
