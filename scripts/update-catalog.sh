#!/usr/bin/env bash
# Regenerate the project catalog in the top-level README.md.
# Walks <category>/<project>/ directories at depth 2 (excluding any starting
# with _ or .), reads each project's .status and README.md title, and emits
# a topic-grouped markdown table between <!-- CATALOG:START --> and
# <!-- CATALOG:END --> markers.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
README="$REPO_ROOT/README.md"
START_MARK="<!-- CATALOG:START -->"
END_MARK="<!-- CATALOG:END -->"

if [ ! -f "$README" ]; then
  echo "error: $README not found" >&2
  exit 1
fi
if ! grep -qF "$START_MARK" "$README" || ! grep -qF "$END_MARK" "$README"; then
  echo "error: $README is missing CATALOG markers" >&2
  echo "expected lines containing:" >&2
  echo "  $START_MARK" >&2
  echo "  $END_MARK" >&2
  exit 1
fi

status_for() {
  local dir="$1"
  local raw="in-progress"
  if [ -f "$dir/.status" ]; then
    raw=$(head -n1 "$dir/.status" | tr -d '[:space:]')
  fi
  case "$raw" in
    planned)     echo "📝 planned" ;;
    in-progress) echo "🚧 in-progress" ;;
    done)        echo "✅ done" ;;
    paused)      echo "🧊 paused" ;;
    archived)    echo "🗑️ archived" ;;
    *) echo "error: invalid status '$raw' in $dir/.status (expected planned|in-progress|done|paused|archived)" >&2; exit 1 ;;
  esac
}

title_for() {
  local dir="$1"
  if [ -f "$dir/README.md" ]; then
    head -n5 "$dir/README.md" | grep -m1 -E '^#[[:space:]]' | sed -E 's/^#[[:space:]]+//'
  else
    basename "$dir"
  fi
}

stack_for() {
  local dir="$1"
  if [ -f "$dir/package.json" ]; then
    echo "Node"
  elif [ -f "$dir/pyproject.toml" ]; then
    echo "Python"
  else
    echo "?"
  fi
}

TMPDIR_OUT=$(mktemp -d)
trap 'rm -rf "$TMPDIR_OUT"' EXIT

CATEGORIES=$(find "$REPO_ROOT" -mindepth 1 -maxdepth 1 -type d \
  ! -name '_*' ! -name '.*' \
  -exec basename {} \; 2>/dev/null | sort)

EXCLUDE='^(docs|scripts)$'

for cat in $CATEGORIES; do
  if echo "$cat" | grep -qE "$EXCLUDE"; then
    continue
  fi
  cat_dir="$REPO_ROOT/$cat"
  projects=$(find "$cat_dir" -mindepth 1 -maxdepth 1 -type d \
    ! -name '_*' ! -name '.*' \
    -exec basename {} \; 2>/dev/null | sort)
  [ -z "$projects" ] && continue

  {
    echo ""
    echo "### $cat"
    echo ""
    echo "| Project | Stack | Status | Doc |"
    echo "|---|---|---|---|"
    for proj in $projects; do
      proj_dir="$cat_dir/$proj"
      stack=$(stack_for "$proj_dir")
      status=$(status_for "$proj_dir")
      title=$(title_for "$proj_dir")
      [ -z "$title" ] && title="$proj"
      doc="./$cat/$proj/README.md"
      echo "| $proj | $stack | $status | [$title]($doc) |"
    done
  } >> "$TMPDIR_OUT/block"
done

if [ ! -s "$TMPDIR_OUT/block" ]; then
  # shellcheck disable=SC2016  # backticks in single quotes are literal markdown
  printf '\n_No projects yet. Run `make new CATEGORY=<cat> NAME=<name> LANG=<node|python>`._\n\n' > "$TMPDIR_OUT/block"
fi

TMP_README=$(mktemp)
awk -v block_file="$TMPDIR_OUT/block" \
    -v start="$START_MARK" \
    -v end="$END_MARK" '
  $0 ~ start {
    print
    while ((getline line < block_file) > 0) print line
    close(block_file)
    in_block = 1
    next
  }
  $0 ~ end {
    in_block = 0
    print
    next
  }
  !in_block { print }
' "$README" > "$TMP_README"

cat "$TMP_README" > "$README"
rm -f "$TMP_README"

echo "Updated catalog in $README"
