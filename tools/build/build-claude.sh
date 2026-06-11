#!/usr/bin/env bash
# ============================================================================
# build-claude.sh — Generate the .claude/ adapter from os/ source
# ============================================================================
# Claude Code is now treated as one runtime adapter among several. This script
# rebuilds .claude/skills/ and .claude/agents/ from os/skills/ and os/agents/
# so authoring happens once in the neutral location.
#
# Currently the file format is identical between os/ and .claude/, so this is
# a straight copy. When the neutral schema is fully adopted (legacy fields
# moved under runtimes.claude), a transform step will live here.
#
# Hooks (.claude/hooks/) and settings (.claude/settings.json) are
# Claude-specific and are NOT generated — they live directly under .claude/.
#
# Usage:
#   bash tools/build/build-claude.sh
# ============================================================================

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

if [ ! -d "os/skills" ] || [ ! -d "os/agents" ]; then
  echo "✗ os/skills/ or os/agents/ not found — nothing to build from" >&2
  exit 1
fi

# Wipe + regenerate skills and agents only; preserve hooks/settings/agent-memory.
mkdir -p .claude/skills .claude/agents

# --- Skills ---
# Delete .claude/skills entries that no longer exist in os/skills, then mirror.
if [ -d .claude/skills ]; then
  for existing in .claude/skills/*/; do
    [ -d "$existing" ] || continue
    name="$(basename "$existing")"
    if [ ! -d "os/skills/$name" ]; then
      rm -rf "$existing"
    fi
  done
fi

# Copy each skill directory wholesale (preserves SKILL.md + any sidecars)
for src in os/skills/*/; do
  [ -d "$src" ] || continue
  name="$(basename "$src")"
  dst=".claude/skills/$name"
  mkdir -p "$dst"
  # Sync contents without preserving owner/timestamps to keep diffs minimal
  rsync -a --delete "$src" "$dst/" 2>/dev/null || {
    # Fallback for systems without rsync
    rm -rf "$dst"
    cp -R "$src" "$dst"
  }
done

# --- Agents ---
if [ -d .claude/agents ]; then
  for existing in .claude/agents/*.md; do
    [ -f "$existing" ] || continue
    name="$(basename "$existing" .md)"
    if [ ! -f "os/agents/$name.md" ]; then
      rm -f "$existing"
    fi
  done
fi

for src in os/agents/*.md; do
  [ -f "$src" ] || continue
  name="$(basename "$src")"
  cp "$src" ".claude/agents/$name"
done

SKILL_COUNT=$(find os/skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
AGENT_COUNT=$(find os/agents -mindepth 1 -maxdepth 1 -type f -name "*.md" | wc -l | tr -d ' ')
echo "✓ Wrote .claude/skills/  (${SKILL_COUNT} skills)"
echo "✓ Wrote .claude/agents/  (${AGENT_COUNT} agents)"
