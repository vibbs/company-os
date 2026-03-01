#!/bin/bash
# ============================================================================
# Hook: SessionStart — inject project context at session start
# ============================================================================
# Runs once per session (startup, resume, clear, compact).
# Outputs a compact context block that Claude Code injects automatically.
#
# Cost: ~100-200 tokens per session (fixed ceiling)
# ============================================================================

set -euo pipefail

CONFIG="company.config.yaml"

# Guard: skip if config doesn't exist or company.name is empty
if [ ! -f "$CONFIG" ]; then
  echo "Run /setup to configure Company OS."
  exit 0
fi

COMPANY_NAME=$(grep '^  name:' "$CONFIG" | head -1 | sed 's/^  name: *"\{0,1\}\([^"]*\)"\{0,1\}.*/\1/' || true)
if [ -z "$COMPANY_NAME" ]; then
  echo "Run /setup to configure Company OS."
  exit 0
fi

# Extract key config values
STAGE=$(grep '^  stage:' "$CONFIG" | head -1 | sed 's/^  stage: *"\{0,1\}\([^"]*\)"\{0,1\}.*/\1/' || true)
FRAMEWORK=$(grep '^  framework:' "$CONFIG" | head -1 | sed 's/^  framework: *"\{0,1\}\([^"]*\)"\{0,1\}.*/\1/' || true)
DATABASE=$(grep '^  database:' "$CONFIG" | head -1 | sed 's/^  database: *"\{0,1\}\([^"]*\)"\{0,1\}.*/\1/' || true)

# Build stack string
STACK=""
if [ -n "$FRAMEWORK" ]; then STACK="$FRAMEWORK"; fi
if [ -n "$DATABASE" ]; then
  if [ -n "$STACK" ]; then STACK="$STACK + $DATABASE"; else STACK="$DATABASE"; fi
fi

# Version
VERSION=""
if [ -f "VERSION" ]; then
  VERSION=$(cat VERSION | tr -d '[:space:]')
fi

# Git branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

# Output header
echo "[Company OS] $COMPANY_NAME | Stage: ${STAGE:-unset} | Stack: ${STACK:-unset}"
echo "Branch: $BRANCH${VERSION:+ | Version: $VERSION}"

# Lessons (last 5 non-empty, non-comment lines)
if [ -f "tasks/lessons.md" ]; then
  LESSONS=$(grep -v '^#\|^$\|^<!--\|^-->' "tasks/lessons.md" 2>/dev/null | grep -v '^\s*$' | tail -5 || true)
  if [ -n "$LESSONS" ]; then
    echo "Lessons:"
    echo "$LESSONS" | while IFS= read -r line; do
      echo "  $line"
    done
  fi
fi

exit 0
