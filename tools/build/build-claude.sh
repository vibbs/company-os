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
# The build records every file it wrote in .claude/.generated-by-company-os.
# A later build removes only listed files whose os/ source is gone. Any other
# skill or agent under .claude/ (one you made by hand), and any file of yours
# inside a generated skill folder, is left in place with a notice. With no
# list yet, nothing is removed. install.sh writes the same list (same header
# and order) when it installs or updates this adapter, so the first build
# after an install leaves it unchanged; keep the two in step.
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
NEW_LIST="$(mktemp)"
trap 'rm -f "$NEW_LIST"' EXIT

was_generated() {  # was_generated <skills/name/file | agents/name.md>
  [ -f "$GENERATED_LIST" ] && grep -qxF "$1" "$GENERATED_LIST"
}
listed_under() {  # listed_under <prefix>: list entries starting with <prefix>
  [ -f "$GENERATED_LIST" ] || return 0
  awk -v p="$1" 'index($0, p) == 1' "$GENERATED_LIST"
}
# remove_listed_stale <name>: delete files the build generated for skill
# <name> earlier that os/skills/<name> no longer has. Files the build did not
# generate are left alone and reported.
remove_listed_stale() {
  local name="$1" entry rel f
  while IFS= read -r entry; do
    rel="${entry#skills/$name/}"
    if [ ! -f "os/skills/$name/$rel" ] && [ -f ".claude/skills/$name/$rel" ]; then
      rm -f ".claude/skills/$name/$rel"
    fi
  done < <(listed_under "skills/$name/")
  find ".claude/skills/$name" -mindepth 1 -type d -empty -delete 2>/dev/null || true
  while IFS= read -r f; do
    rel="${f#.claude/skills/$name/}"
    if [ ! -f "os/skills/$name/$rel" ]; then
      echo "  kept $f (your file; the build does not manage it)"
    fi
  done < <(find ".claude/skills/$name" -type f 2>/dev/null | sort)
}

# --- Skills ---
# A skill whose os/skills source is gone: remove the files this build
# generated for it; keep (and warn about) skills it never generated.
for existing in .claude/skills/*/; do
  [ -d "$existing" ] || continue
  name="$(basename "$existing")"
  [ -d "os/skills/$name" ] && continue
  if [ -n "$(listed_under "skills/$name/")" ]; then
    remove_listed_stale "$name"
    if rmdir ".claude/skills/$name" 2>/dev/null; then
      echo "  removed stale generated skill .claude/skills/$name (no longer in os/skills/)"
    fi
  else
    echo "⚠ custom skill .claude/skills/$name is not in os/ — move it to os/skills/$name/ to keep it across runtimes" >&2
  fi
done

# Copy every file of each skill (SKILL.md and any sidecars). Only files the
# build writes are overwritten or removed; your own files in the folder stay.
for src in os/skills/*/; do
  [ -d "$src" ] || continue
  name="$(basename "$src")"
  dst=".claude/skills/$name"
  mkdir -p "$dst"
  while IFS= read -r f; do
    rel="${f#os/skills/$name/}"
    mkdir -p "$(dirname "$dst/$rel")"
    cp "$f" "$dst/$rel"
    echo "skills/$name/$rel" >> "$NEW_LIST"
  done < <(find "os/skills/$name" -type f | sort)
  lift_claude_fields "$dst/SKILL.md"
  remove_listed_stale "$name"
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
  echo "agents/$name" >> "$NEW_LIST"
done

# --- Record what this build generated ---
{
  echo "# Written by tools/build/build-claude.sh: the files it generated from os/."
  echo "# The next build removes or overwrites only files listed here."
  cat "$NEW_LIST"
} > "$GENERATED_LIST"

SKILL_COUNT=$(find os/skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
AGENT_COUNT=$(find os/agents -mindepth 1 -maxdepth 1 -type f -name "*.md" | wc -l | tr -d ' ')
echo "✓ Wrote .claude/skills/  (${SKILL_COUNT} skills)"
echo "✓ Wrote .claude/agents/  (${AGENT_COUNT} agents)"
