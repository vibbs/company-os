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
  lift_claude_fields "$dst/SKILL.md"
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
