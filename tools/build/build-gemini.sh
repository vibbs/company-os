#!/usr/bin/env bash
# ============================================================================
# build-gemini.sh — Generate GEMINI.md for Gemini CLI
# ============================================================================
# Gemini CLI reads GEMINI.md (its own convention) — same payload as AGENTS.md
# but with a Gemini-specific header pointing at its activate_skill flow.
#
# Usage:
#   bash tools/build/build-gemini.sh
# ============================================================================

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

# Ensure AGENTS.md is fresh
if [ ! -f AGENTS.md ] || [ AGENTS.md -ot CLAUDE.md ]; then
  bash tools/build/build-agents-md.sh >/dev/null
fi

OUT="GEMINI.md"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

cat > "$TMP" <<'EOF'
# GEMINI.md

<!-- GENERATED FILE — do not edit by hand. Source: AGENTS.md -->
<!-- Regenerate with: bash tools/build/build-gemini.sh -->

You are operating inside a **Company OS** project. Read `AGENTS.md` for the
full system overview, agent catalog, skill catalog, and tool catalog — this
file is identical in content but lives at the path Gemini CLI loads
automatically.

## Skill Activation in Gemini CLI

Gemini CLI exposes skills through the `activate_skill` tool. When the user's
intent matches a skill from the catalog below, activate it before responding.

## Tool Equivalents

Where Claude Code skills mention the `Skill`, `Task`, or `TodoWrite` tool, use
the Gemini CLI equivalents:

| Claude Code | Gemini CLI |
|-------------|-----------|
| `Skill` (load a skill) | `activate_skill` |
| `Task` (sub-agent) | direct continuation |
| `TodoWrite` | inline progress tracking |
| `Read`, `Edit`, `Write`, `Grep`, `Glob`, `Bash` | same names, same semantics |

---

EOF

# Append the body of AGENTS.md (skip its own header)
awk '/^## What Is Company OS/{found=1} found' AGENTS.md >> "$TMP"

mv "$TMP" "$OUT"
trap - EXIT

echo "✓ Wrote $OUT"
