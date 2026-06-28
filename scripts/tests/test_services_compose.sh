#!/usr/bin/env bash
# Tests for _services/docker-compose.yml.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/_services/docker-compose.yml"

test_services_compose_exists() {
  [ -f "$COMPOSE_FILE" ]
}

test_services_compose_validates() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "SKIP: docker not installed"
    return 0
  fi
  if ! docker compose version >/dev/null 2>&1; then
    echo "SKIP: 'docker compose' subcommand not available"
    return 0
  fi
  docker compose -f "$COMPOSE_FILE" config --quiet
}

test_services_compose_defines_all_seven_services() {
  local expected=(localstack gcloud-pubsub gcloud-firestore azurite minio mailhog jaeger)
  local missing=0
  for s in "${expected[@]}"; do
    if ! grep -qE "^  ${s}:[[:space:]]*$" "$COMPOSE_FILE"; then
      echo "missing service: $s"
      missing=$((missing + 1))
    fi
  done
  [ $missing -eq 0 ]
}

test_services_compose_uses_named_network() {
  grep -qE "^[[:space:]]*system-designs-sandbox:[[:space:]]*$" "$COMPOSE_FILE"
}

test_services_compose_persists_state() {
  local expected_paths=(
    "./data/localstack"
    "./data/azurite"
    "./data/minio"
    "./data/gcloud-firestore"
  )
  local missing=0
  for p in "${expected_paths[@]}"; do
    if ! grep -q "$p" "$COMPOSE_FILE"; then
      echo "missing volume bind: $p"
      missing=$((missing + 1))
    fi
  done
  [ $missing -eq 0 ]
}
