#!/usr/bin/env bash
# ============================================================================
# build-codex.sh — Generate Codex CLI adapter
# ============================================================================
# Codex CLI reads AGENTS.md natively. This script ensures AGENTS.md is fresh
# and writes a minimal `.codex/config.md` pointer for Codex users who want a
# dedicated config namespace.
#
# Usage:
#   bash tools/build/build-codex.sh
# ============================================================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/usage.sh"
usage_help_if_requested "${BASH_SOURCE[0]}" "${1:-}"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

# Ensure AGENTS.md is fresh
if [ ! -f AGENTS.md ] || [ AGENTS.md -ot CLAUDE.md ]; then
  bash tools/build/build-agents-md.sh >/dev/null
fi

mkdir -p .codex

cat > .codex/config.md <<'EOF'
# Codex Configuration — Company OS

<!-- GENERATED FILE — regenerate with: bash tools/build/build-codex.sh -->

Codex CLI reads `AGENTS.md` at the repo root. This file is a placeholder for
Codex-specific overrides; the source of truth for instructions is `AGENTS.md`.

## Tool equivalents

| Concept | Codex equivalent |
|---------|-----------------|
| Claude `Skill` tool | Read the skill file directly and follow its procedure |
| Claude `Task` sub-agent | Continue inline |
| Claude `TodoWrite` | Inline progress narration |
| Claude slash commands | Ask the agent to "run the X skill" |

See `AGENTS.md` for the full system overview, skill catalog, and agent personas.
EOF

echo "✓ Wrote .codex/config.md"
