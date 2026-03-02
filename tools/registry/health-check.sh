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
  for field in "id" "category" "inputs" "outputs" "output_schema" "recommended_tools" "used_by" "allowed-tools"; do
    if echo "$FRONTMATTER" | grep -q "^${field}:"; then
      echo "⚠️  $DIR_NAME: Non-official frontmatter field '$field' (move to markdown body)"
      WARNINGS=$((WARNINGS + 1))
    fi
  done

  # Check for common misspelling of user-invokable
  if echo "$FRONTMATTER" | grep -q "^user-invocable:"; then
    echo "⚠️  $DIR_NAME: Misspelled field 'user-invocable' — should be 'user-invokable'"
    WARNINGS=$((WARNINGS + 1))
  fi

done

echo ""
echo "==========================="

# --- Agent Health Check ---
echo ""
echo "Agent Registry Health Check"
echo "==========================="

AGENT_TOTAL=0
AGENT_WARNINGS=0
AGENT_ERRORS=0

for agent_file in "$AGENTS_DIR"/*.md; do
  [[ ! -f "$agent_file" ]] && continue
  AGENT_NAME=$(basename "$agent_file" .md)
  AGENT_TOTAL=$((AGENT_TOTAL + 1))

  # Check frontmatter exists
  FIRST_LINE=$(head -1 "$agent_file")
  if [[ "$FIRST_LINE" != "---" ]]; then
    echo "❌ $AGENT_NAME: Missing YAML frontmatter"
    AGENT_ERRORS=$((AGENT_ERRORS + 1))
    continue
  fi

  # Extract frontmatter
  AGENT_FM=$(sed -n '/^---$/,/^---$/p' "$agent_file" | sed '1d;$d')

  # Check required fields
  for field in "name" "description" "tools"; do
    if ! echo "$AGENT_FM" | grep -q "^${field}:"; then
      echo "❌ $AGENT_NAME: Missing required field '$field'"
      AGENT_ERRORS=$((AGENT_ERRORS + 1))
    fi
  done

  # Check skills references resolve to actual skill directories
  AGENT_SKILLS=$(echo "$AGENT_FM" | grep "^  - " | sed 's/^  - //' || true)
  if [[ -n "$AGENT_SKILLS" ]]; then
    while IFS= read -r skill; do
      if [[ ! -d "$SKILLS_DIR/$skill" ]]; then
        echo "❌ $AGENT_NAME: References non-existent skill '$skill'"
        AGENT_ERRORS=$((AGENT_ERRORS + 1))
      fi
    done <<< "$AGENT_SKILLS"
  fi

  # Check memory: project agents have MEMORY.md
  if echo "$AGENT_FM" | grep -q "^memory: project"; then
    MEMORY_DIR="$(dirname "$0")/../../.claude/agent-memory/$AGENT_NAME"
    if [[ ! -f "$MEMORY_DIR/MEMORY.md" ]]; then
      echo "⚠️  $AGENT_NAME: Has memory: project but no MEMORY.md at .claude/agent-memory/$AGENT_NAME/"
      AGENT_WARNINGS=$((AGENT_WARNINGS + 1))
    fi
  fi
done

echo ""
echo "==========================="
echo "Skills:  $TOTAL total, $ERRORS errors, $WARNINGS warnings"
echo "Agents:  $AGENT_TOTAL total, $AGENT_ERRORS errors, $AGENT_WARNINGS warnings"
echo ""

TOTAL_ERRORS=$((ERRORS + AGENT_ERRORS))
if [[ $TOTAL_ERRORS -gt 0 ]]; then
  echo "❌ Health check FAILED"
  exit 1
else
  echo "✅ Health check PASSED (with $((WARNINGS + AGENT_WARNINGS)) warnings)"
  exit 0
fi
