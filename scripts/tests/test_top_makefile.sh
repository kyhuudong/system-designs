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
  recipes-test
  new
  catalog
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

# ---------- regression: services-reset must actually wipe bind-mount data ----------

test_wipe_command_removes_subdirs_preserves_gitkeep() {
  local box; box=$(mktemp -d)
  mkdir -p "$box/_services/data/localstack" "$box/_services/data/azurite"
  : > "$box/_services/data/.gitkeep"
  : > "$box/_services/data/localstack/state.dat"
  : > "$box/_services/data/azurite/keys.bin"

  ( cd "$box" && find _services/data -mindepth 1 -maxdepth 1 ! -name .gitkeep -exec rm -rf {} + )

  [ -f "$box/_services/data/.gitkeep" ] || { echo ".gitkeep removed"; rm -rf "$box"; return 1; }
  [ ! -e "$box/_services/data/localstack" ] || { echo "localstack survived"; rm -rf "$box"; return 1; }
  [ ! -e "$box/_services/data/azurite" ] || { echo "azurite survived"; rm -rf "$box"; return 1; }
  rm -rf "$box"
}

test_services_reset_force_wipes_data() {
  # Sandbox: copy Makefile + compose file + a sentinel into _services/data/
  local box; box=$(mktemp -d)
  mkdir -p "$box/_services/data/sentinel"
  : > "$box/_services/data/.gitkeep"
  : > "$box/_services/data/sentinel/marker.txt"
  cp "$REPO_ROOT/Makefile" "$box/Makefile"
  mkdir -p "$box/_services"
  cp "$REPO_ROOT/_services/docker-compose.yml" "$box/_services/docker-compose.yml"

  # Run the target. docker compose down -v on a non-running stack should succeed.
  # If docker isn't available, the whole test SKIPs cleanly.
  if ! command -v docker >/dev/null 2>&1 || ! docker compose version >/dev/null 2>&1; then
    echo "SKIP: docker not available"
    rm -rf "$box"
    return 0
  fi

  ( cd "$box" && make services-reset-force >/dev/null 2>&1 )
  local rc=$?
  if [ $rc -ne 0 ]; then
    echo "make services-reset-force exited $rc"
    rm -rf "$box"
    return 1
  fi

  [ -f "$box/_services/data/.gitkeep" ] || { echo ".gitkeep removed"; rm -rf "$box"; return 1; }
  [ ! -e "$box/_services/data/sentinel" ] || { echo "sentinel survived"; rm -rf "$box"; return 1; }
  rm -rf "$box"
}

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
