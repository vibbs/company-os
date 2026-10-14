#!/usr/bin/env bash
# Tool: Skill Search
# Description: Searches skills by keyword, category, or output type
# Usage: ./tools/registry/search-skill.sh <query>
# Inputs: search query (keyword, skill name, category)
# Outputs: matching skill files with name and description
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/usage.sh"
usage_help_if_requested "${BASH_SOURCE[0]}" "${1:-}"

QUERY="${1:-}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
if [ -d "$ROOT/os/skills" ]; then
  SKILLS_DIR="$ROOT/os/skills"
else
  SKILLS_DIR="$ROOT/.claude/skills"
fi

if [[ -z "$QUERY" ]]; then
  echo "ERROR: No search query provided" >&2
  echo "Usage: ./tools/registry/search-skill.sh <query>" >&2
  echo "" >&2
  echo "Examples:" >&2
  echo "  ./tools/registry/search-skill.sh prd" >&2
  echo "  ./tools/registry/search-skill.sh 'api contract'" >&2
  echo "  ./tools/registry/search-skill.sh engineering" >&2
  exit 1
fi

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo "ERROR: Skills directory not found at $SKILLS_DIR" >&2
  exit 1
fi

echo "Searching skills for: '$QUERY'"
echo "================================"

FOUND=0

for skill_dir in "$SKILLS_DIR"/*/; do
  SKILL_FILE="$skill_dir/SKILL.md"
  [[ -f "$SKILL_FILE" ]] || continue

  # Search in directory name and file content (case-insensitive)
  DIR_NAME=$(basename "$skill_dir")
  if grep -il "$QUERY" "$SKILL_FILE" > /dev/null 2>&1 || echo "$DIR_NAME" | grep -iq "$QUERY"; then
    # Extract metadata from frontmatter
    NAME=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | { grep "^name:" || true; } | sed 's/name: *//' | tr -d '"')
    DESC=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | { grep "^description:" || true; } | sed 's/description: *//' | tr -d '"')

    # Category comes from the "- **Category**: X" line in the Reference section
    CATEGORY=$({ grep -m1 '^- \*\*Category\*\*:' "$SKILL_FILE" || true; } | sed 's/.*\*\*Category\*\*: *//')

    echo ""
    echo "  $NAME"
    echo "  Directory: $DIR_NAME"
    [[ -n "$CATEGORY" ]] && echo "  Category: $CATEGORY"
    echo "  Description: $DESC"
    echo "  Path: $SKILL_FILE"

    # List supporting files
    SUPPORT_FILES=$(find "$skill_dir" -name "*.md" ! -name "SKILL.md" -exec basename {} \; 2>/dev/null | tr '\n' ' ' || true)
    [[ -n "$SUPPORT_FILES" ]] && echo "  Supporting files: $SUPPORT_FILES"

    FOUND=$((FOUND + 1))
  fi
done

echo ""
echo "================================"
echo "Found $FOUND skill(s) matching '$QUERY'"
