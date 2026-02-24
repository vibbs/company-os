#!/usr/bin/env bash
# Tool: Skill Health Check
# Description: Checks all skills for valid structure, frontmatter, and required fields
# Usage: ./tools/registry/health-check.sh
# Inputs: none
# Outputs: health report for all skills
set -euo pipefail

SKILLS_DIR="$(dirname "$0")/../../.claude/skills"
AGENTS_DIR="$(dirname "$0")/../../.claude/agents"

echo "Skill Registry Health Check"
echo "==========================="

TOTAL=0
WARNINGS=0
ERRORS=0

for skill_dir in "$SKILLS_DIR"/*/; do
  DIR_NAME=$(basename "$skill_dir")
  SKILL_FILE="$skill_dir/SKILL.md"

  TOTAL=$((TOTAL + 1))

  # Check SKILL.md exists
  if [[ ! -f "$SKILL_FILE" ]]; then
    echo "❌ $DIR_NAME: Missing SKILL.md entrypoint"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # Check frontmatter exists
  FIRST_LINE=$(head -1 "$SKILL_FILE")
  if [[ "$FIRST_LINE" != "---" ]]; then
    echo "❌ $DIR_NAME: Missing YAML frontmatter in SKILL.md"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # Extract frontmatter
  FRONTMATTER=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | sed '1d;$d')

  # Check required official frontmatter fields
  for field in "name" "description"; do
    if ! echo "$FRONTMATTER" | grep -q "^${field}:"; then
      echo "❌ $DIR_NAME: Missing required field '$field'"
      ERRORS=$((ERRORS + 1))
    fi
  done

  # Check name matches directory name
  SKILL_NAME=$(echo "$FRONTMATTER" | grep "^name:" | sed 's/name: *//' | tr -d '"')
  if [[ "$SKILL_NAME" != "$DIR_NAME" ]]; then
    echo "⚠️  $DIR_NAME: Frontmatter name '$SKILL_NAME' doesn't match directory name"
    WARNINGS=$((WARNINGS + 1))
  fi

  # Check for skeleton markers (unfleshed skills)
  if grep -q "<!-- TODO" "$SKILL_FILE" 2>/dev/null; then
    echo "📝 $DIR_NAME: Skeleton (needs authoring) — $SKILL_NAME"
  fi

  # Check for invalid frontmatter fields (non-official)
  for field in "id" "category" "inputs" "outputs" "output_schema" "recommended_tools" "used_by"; do
    if echo "$FRONTMATTER" | grep -q "^${field}:"; then
      echo "⚠️  $DIR_NAME: Non-official frontmatter field '$field' (move to markdown body)"
      WARNINGS=$((WARNINGS + 1))
    fi
  done

done

echo ""
echo "==========================="
echo "Total skills: $TOTAL"
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"
echo ""

if [[ $ERRORS -gt 0 ]]; then
  echo "❌ Health check FAILED"
  exit 1
else
  echo "✅ Health check PASSED (with $WARNINGS warnings)"
  exit 0
fi
