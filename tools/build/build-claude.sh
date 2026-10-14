#!/usr/bin/env bash
# ============================================================================
# build-claude.sh — Generate the .claude/ adapter from os/ source
# ============================================================================
# Claude Code is now treated as one runtime adapter among several. This script
# rebuilds .claude/skills/ and .claude/agents/ from os/skills/ and os/agents/
# so authoring happens once in the neutral location.
#
# Skills are copied as-is except for one transform: Claude Code reads
# `user-invocable`, `disable-model-invocation` and `argument-hint` at the top
# level of SKILL.md, but the neutral schema keeps them under `runtimes.claude`.
# lift_claude_fields() moves them up in the generated copy. Other runtimes'
# keys under `runtimes:` (e.g. cursor) are left in place. The legacy spelling
# `user-invokable` (nested or top level) is written out as `user-invocable`,
# so older skills keep working; validate-skill.sh warns about it.
#
# Hooks (.claude/hooks/) and settings (.claude/settings.json) are
# Claude-specific and are NOT generated — they live directly under .claude/.
#
# The build records what it wrote in .claude/.generated-by-company-os. A later
# build removes only entries on that list whose os/ source is gone. Any other
# skill or agent under .claude/ (one you made by hand) is left in place with
# a warning to move it to os/. With no list yet (first build after an
# upgrade), nothing is removed.
#
# Usage:
#   bash tools/build/build-claude.sh
# ============================================================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/usage.sh"
usage_help_if_requested "${BASH_SOURCE[0]}" "${1:-}"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

if [ ! -d "os/skills" ] || [ ! -d "os/agents" ]; then
  echo "✗ os/skills/ or os/agents/ not found — nothing to build from" >&2
  exit 1
fi

# Rewrites the frontmatter of $1 in place: keys nested under
# `runtimes: > claude:` become top-level keys. No-op when there is no such block.
# Tolerates CRLF line endings (the file is rewritten with LF) and a trailing
# comment or extra spaces after `runtimes:` and `claude:`.
lift_claude_fields() {
  local file="$1" tmp
  tmp="$(mktemp)"
  awk '
    function flush_runtimes(   i) {
      for (i = 1; i <= nl; i++) print lifted[i]
      if (nr > 0) { print "runtimes:"; for (i = 1; i <= nr; i++) print rest[i] }
      nl = 0; nr = 0; inrt = 0; inclaude = 0
    }
    { sub(/\r$/, "") }
    /^---[ \t]*$/ { $0 = "---" }
    /^---$/ { c++; if (c == 2 && inrt) flush_runtimes(); print; next }
    c != 1 { print; next }
    inrt {
      if ($0 ~ /^[^ \t]/) { flush_runtimes() }
      else {
        if ($0 ~ /^  claude[ \t]*:[ \t]*(#.*)?$/) { inclaude = 1; next }
        if (inclaude && $0 ~ /^    /) { line = $0; sub(/^    /, "", line); sub(/^user-invokable[ \t]*:/, "user-invocable:", line); sub(/[ \t]+$/, "", line); lifted[++nl] = line; next }
        if ($0 ~ /^  [^ ]/) inclaude = 0
        rest[++nr] = $0; next
      }
    }
    /^runtimes[ \t]*:[ \t]*(#.*)?$/ { inrt = 1; next }
    /^user-invokable:/ { sub(/^user-invokable:/, "user-invocable:") }
    { print }
  ' "$file" > "$tmp"
  cat "$tmp" > "$file"
  rm -f "$tmp"
}

# Regenerate skills and agents only; preserve hooks/settings/agent-memory.
mkdir -p .claude/skills .claude/agents

GENERATED_LIST=".claude/.generated-by-company-os"
was_generated() {  # was_generated <skills/name | agents/name.md>
  [ -f "$GENERATED_LIST" ] && grep -qxF "$1" "$GENERATED_LIST"
}

# --- Skills ---
# Remove skills this build generated before whose os/skills source is gone;
# keep (and warn about) skills it did not generate.
for existing in .claude/skills/*/; do
  [ -d "$existing" ] || continue
  name="$(basename "$existing")"
  [ -d "os/skills/$name" ] && continue
  if was_generated "skills/$name"; then
    rm -rf "$existing"
    echo "  removed stale generated skill .claude/skills/$name (no longer in os/skills/)"
  else
    echo "⚠ custom skill .claude/skills/$name is not in os/ — move it to os/skills/$name/ to keep it across runtimes" >&2
  fi
done

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
  lift_claude_fields "$dst/SKILL.md"
done

# --- Agents ---
for existing in .claude/agents/*.md; do
  [ -f "$existing" ] || continue
  name="$(basename "$existing" .md)"
  [ -f "os/agents/$name.md" ] && continue
  if was_generated "agents/$name.md"; then
    rm -f "$existing"
    echo "  removed stale generated agent .claude/agents/$name.md (no longer in os/agents/)"
  else
    echo "⚠ custom agent .claude/agents/$name.md is not in os/ — move it to os/agents/$name.md to keep it across runtimes" >&2
  fi
done

for src in os/agents/*.md; do
  [ -f "$src" ] || continue
  name="$(basename "$src")"
  cp "$src" ".claude/agents/$name"
done

# --- Record what this build generated ---
{
  echo "# Written by tools/build/build-claude.sh: the skills and agents it generated"
  echo "# from os/. The next build removes only entries here whose os/ source is gone."
  for src in os/skills/*/; do
    if [ -d "$src" ]; then echo "skills/$(basename "$src")"; fi
  done
  for src in os/agents/*.md; do
    if [ -f "$src" ]; then echo "agents/$(basename "$src")"; fi
  done
} > "$GENERATED_LIST"

SKILL_COUNT=$(find os/skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
AGENT_COUNT=$(find os/agents -mindepth 1 -maxdepth 1 -type f -name "*.md" | wc -l | tr -d ' ')
echo "✓ Wrote .claude/skills/  (${SKILL_COUNT} skills)"
echo "✓ Wrote .claude/agents/  (${AGENT_COUNT} agents)"
