#!/usr/bin/env bash
# Minimal test runner. Sources every test_*.sh in this directory and runs every
# function named test_* it finds. Each test runs in a subshell with `set -e`.

set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0
FAILED_NAMES=()

# Discover test files
shopt -s nullglob
for file in "$HERE"/test_*.sh; do
  # shellcheck disable=SC1090
  source "$file"
done

# Discover test functions defined in the sourced files
TESTS=$(declare -F | awk '{print $3}' | grep '^test_' || true)

for t in $TESTS; do
  printf '  %-60s' "$t"
  if ( set -e; "$t" ) >/tmp/test_out.$$ 2>&1; then
    echo "PASS"
    PASS=$((PASS + 1))
  else
    echo "FAIL"
    echo "    --- output ---"
    sed 's/^/    /' /tmp/test_out.$$
    echo "    --------------"
    FAIL=$((FAIL + 1))
    FAILED_NAMES+=("$t")
  fi
  rm -f /tmp/test_out.$$
done

echo
echo "Results: $PASS passed, $FAIL failed"
if [ $FAIL -gt 0 ]; then
  echo "Failed: ${FAILED_NAMES[*]}"
  exit 1
fi
