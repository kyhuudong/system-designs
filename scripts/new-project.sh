#!/usr/bin/env bash
set -euo pipefail

USAGE="Usage: $0 <category> <project-name> <node|python>

Scaffolds a new project from _templates/<lang>/ into <category>/<project-name>/.

Arguments:
  <category>      kebab-case category folder name (e.g. caching, apps)
  <project-name>  kebab-case project name (e.g. url-shortener)
  <lang>          node or python

Examples:
  $0 caching distributed-lru-cache node
  $0 apps news-feed python
"

KEBAB_RE='^[a-z][a-z0-9-]*[a-z0-9]$'

die() {
  echo "error: $*" >&2
  echo "" >&2
  echo "$USAGE" >&2
  exit 1
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "$USAGE"
  exit 0
fi

if [ "$#" -ne 3 ]; then
  die "expected 3 arguments, got $#"
fi

CATEGORY="$1"
NAME="$2"
LANG="$3"

if [[ "$LANG" != "node" && "$LANG" != "python" ]]; then
  die "<lang> must be 'node' or 'python' (got '$LANG')"
fi

if ! [[ "$CATEGORY" =~ $KEBAB_RE ]]; then
  die "<category> must be kebab-case (got '$CATEGORY')"
fi

if ! [[ "$NAME" =~ $KEBAB_RE ]]; then
  die "<project-name> must be kebab-case (got '$NAME')"
fi

# Resolve repo root (one level up from this script).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_DIR="$REPO_ROOT/_templates/$LANG"
TARGET_DIR="$REPO_ROOT/$CATEGORY/$NAME"

if [ ! -d "$TEMPLATE_DIR" ]; then
  die "template not found: $TEMPLATE_DIR"
fi

if [ -e "$TARGET_DIR" ]; then
  die "target already exists: $TARGET_DIR"
fi

# Copy + substitute logic added in Task 8.
# For now, just create the target dir so the valid-input tests pass.
mkdir -p "$TARGET_DIR"
echo "scaffolded $TARGET_DIR (placeholder — copy logic pending)"
