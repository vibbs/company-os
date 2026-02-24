#!/usr/bin/env bash
# Tool: Skill Search
# Description: Searches skills by keyword, category, or output type
# Usage: ./tools/registry/search-skill.sh <query>
# Inputs: search query (keyword, skill name, category)
# Outputs: matching skill files with name and description
set -euo pipefail

QUERY="${1:-}"
SKILLS_DIR="$(dirname "$0")/../../.claude/skills"

if [[ -z "$QUERY" ]]; then
  echo "ERROR: No search query provided"
  echo "Usage: ./tools/registry/search-skill.sh <query>"
  echo ""
  echo "Examples:"
  echo "  ./tools/registry/search-skill.sh prd"
  echo "  ./tools/registry/search-skill.sh 'api contract'"
  echo "  ./tools/registry/search-skill.sh engineering"
  exit 1
fi

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo "ERROR: Skills directory not found at $SKILLS_DIR"
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
    NAME=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | grep "^name:" | sed 's/name: *//' | tr -d '"')
    DESC=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | grep "^description:" | sed 's/description: *//' | tr -d '"')

    # Try to extract category from Reference section in body
    CATEGORY=$(grep -A1 "Category" "$SKILL_FILE" | grep -v "Category" | sed 's/.*\*\*: *//' | head -1)

    echo ""
    echo "  $NAME"
    echo "  Directory: $DIR_NAME"
    [[ -n "$CATEGORY" ]] && echo "  Category: $CATEGORY"
    echo "  Description: $DESC"
    echo "  Path: $SKILL_FILE"

    # List supporting files
    SUPPORT_FILES=$(find "$skill_dir" -name "*.md" ! -name "SKILL.md" -printf "%f " 2>/dev/null || true)
    [[ -n "$SUPPORT_FILES" ]] && echo "  Supporting files: $SUPPORT_FILES"

    FOUND=$((FOUND + 1))
  fi
done

echo ""
echo "================================"
echo "Found $FOUND skill(s) matching '$QUERY'"
