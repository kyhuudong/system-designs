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
# Using a tmp file pattern because BSD sed (macOS) and GNU sed differ on `-i`.
sub_in_file() {
  local f="$1"
  local tmp
  tmp="$(mktemp)"
  sed \
    -e "s|__PROJECT_NAME__|${NAME}|g" \
    -e "s|__CATEGORY__|${CATEGORY}|g" \
    -e "s|__PROJECT_TITLE__|${PROJECT_TITLE}|g" \
    "$f" > "$tmp"
  mv "$tmp" "$f"
}

# Walk all regular files; skip binaries by checking with `file` would be more robust,
# but for these templates everything is text. Still avoid following symlinks.
while IFS= read -r -d '' f; do
  sub_in_file "$f"
done < <(find "$TARGET_DIR" -type f -print0)

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
