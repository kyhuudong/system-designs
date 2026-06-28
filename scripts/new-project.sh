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

# Atomic: if anything below fails, remove the half-created target.
# $TARGET_DIR was verified to NOT exist above, so removing it is safe.
trap 'rc=$?; if [ -n "${TARGET_DIR:-}" ] && [ -e "$TARGET_DIR" ]; then rm -rf "$TARGET_DIR"; echo "scaffold failed; cleaned up $TARGET_DIR" >&2; fi; exit $rc' ERR

# Build a Title Case version of the kebab-case name: "url-shortener" -> "Url Shortener".
# Written for bash 3.2 compatibility (macOS default) — avoids ${var^} which needs bash 4+.
to_title() {
  local s="$1"
  local out=""
  local first rest
  local IFS='-'
  for w in $s; do
    first=$(printf '%s' "${w:0:1}" | tr '[:lower:]' '[:upper:]')
    rest="${w:1}"
    out="${out}${first}${rest} "
  done
  # Strip trailing space.
  printf '%s' "${out% }"
}

PROJECT_TITLE="$(to_title "$NAME")"

# Copy the template (preserving hidden files).
mkdir -p "$(dirname "$TARGET_DIR")"
cp -R "$TEMPLATE_DIR" "$TARGET_DIR"

# Substitute placeholders in every regular file in the target.
# Use `cat > "$f"` (instead of `mv tmp f`) to preserve the original file's
# permission bits — `mv` would adopt mktemp's default 0600, silently downgrading
# the template's permissions on every scaffolded file.
sub_in_file() {
  local f="$1"
  local tmp
  tmp="$(mktemp)"
  sed \
    -e "s|__PROJECT_NAME__|${NAME}|g" \
    -e "s|__CATEGORY__|${CATEGORY}|g" \
    -e "s|__PROJECT_TITLE__|${PROJECT_TITLE}|g" \
    "$f" > "$tmp"
  cat "$tmp" > "$f"
  rm -f "$tmp"
}

# Walk all regular files; skip binaries by checking with `file` would be more robust,
# but for these templates everything is text. Still avoid following symlinks.
while IFS= read -r -d '' f; do
  sub_in_file "$f"
done < <(find "$TARGET_DIR" -type f -print0)

# Bootstrap a .env from .env.example so `make up` / `docker compose up` works
# immediately — docker compose treats a missing env_file as a fatal error.
# The .env is gitignored; users edit it freely without leaking to git.
if [ -f "$TARGET_DIR/.env.example" ] && [ ! -f "$TARGET_DIR/.env" ]; then
  cp "$TARGET_DIR/.env.example" "$TARGET_DIR/.env"
fi

cat <<EOF
✓ Scaffolded $CATEGORY/$NAME ($LANG)

Next steps:
  cd $CATEGORY/$NAME
  \$EDITOR README.md     # write your design
  make install           # install deps (and create lockfile)
  make up                # start app + dependencies in Docker
  make test              # run tests

Remember to add an entry under "### $CATEGORY" in the top-level README catalog
when you start or finish the project.
EOF

# Clear the rollback trap — we made it to the end successfully.
trap - ERR
