#!/usr/bin/env bash
# Tool: T-QA-08 Experiment Report Generator
# Description: Summarizes experiment artifacts and their current state
# Usage: ./tools/qa/experiment-report.sh [experiment-id]
# Inputs: experiment ID (optional -- if omitted, lists all)
# Outputs: experiment status summary to stdout
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
EXPERIMENTS_DIR="$PROJECT_ROOT/artifacts/experiments"

# Create experiments dir if it doesn't exist
mkdir -p "$EXPERIMENTS_DIR"

EXPERIMENT_ID="${1:-}"

# Helper: extract field from frontmatter
extract_field() {
  local FILE="$1"
  local FIELD="$2"
  sed -n '/^---$/,/^---$/p' "$FILE" | grep "^${FIELD}:" | sed "s/${FIELD}: *//" | tr -d '"' | tr -d "'" || true
}

if [[ -n "$EXPERIMENT_ID" ]]; then
  # Show specific experiment
  FOUND=$(grep -rl "^id: *${EXPERIMENT_ID} *$" "$EXPERIMENTS_DIR" --include="*.md" 2>/dev/null | head -1 || true)
  if [[ -z "$FOUND" ]]; then
    echo "ERROR: Experiment '$EXPERIMENT_ID' not found in $EXPERIMENTS_DIR"
    exit 1
  fi
  echo "=== Experiment: $EXPERIMENT_ID ==="
  echo "  File: $FOUND"
  echo "  Status: $(extract_field "$FOUND" "status")"
  echo "  Parent: $(extract_field "$FOUND" "parent")"
  echo "  Depends on: $(extract_field "$FOUND" "depends_on")"
  echo ""
  # Print the body (after frontmatter)
  sed -n '/^---$/,/^---$/!p' "$FOUND" | head -30
else
  # List all experiments
  echo "=== Experiment Registry ==="
  echo ""
  FOUND_ANY=false
  while IFS= read -r -d '' file; do
    FILE_TYPE=$(extract_field "$file" "type")
    if [[ "$FILE_TYPE" == "experiment" ]]; then
      FOUND_ANY=true
      EXP_ID=$(extract_field "$file" "id")
      EXP_STATUS=$(extract_field "$file" "status")
      EXP_PARENT=$(extract_field "$file" "parent")
      printf "  %-15s  %-12s  parent: %s  (%s)\n" "$EXP_ID" "[$EXP_STATUS]" "$EXP_PARENT" "$(basename "$file")"
    fi
  done < <(find "$EXPERIMENTS_DIR" -name "*.md" -print0 2>/dev/null)

  if [[ "$FOUND_ANY" == "false" ]]; then
    echo "  No experiments found in $EXPERIMENTS_DIR"
    echo "  Run the experiment-framework skill to create experiment specs."
  fi
fi

echo ""
echo "Done."
