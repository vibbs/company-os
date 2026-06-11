#!/usr/bin/env bash
# ============================================================================
# build.sh — Run all adapter builders
# ============================================================================
# Regenerates every runtime adapter from the current source-of-truth.
#
# Phase A: reads from .claude/ and CLAUDE.md
# Phase C: reads from os/ (once promoted)
#
# Usage:
#   bash tools/build/build.sh                     # build all adapters
#   bash tools/build/build.sh --runtime=cursor    # build only the cursor adapter
#   bash tools/build/build.sh --runtime=agents    # build only AGENTS.md
#   bash tools/build/build.sh --runtime=gemini    # build only GEMINI.md
#   bash tools/build/build.sh --runtime=codex     # build only Codex adapter
#   bash tools/build/build.sh --check             # validate without writing
# ============================================================================

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

RUNTIME="all"
CHECK=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --runtime=*) RUNTIME="${1#*=}"; shift ;;
    --runtime)   RUNTIME="$2"; shift 2 ;;
    --check)     CHECK=true; shift ;;
    --help)
      grep -E '^#' "$0" | sed 's/^# *//'
      exit 0
      ;;
    *) echo "Unknown flag: $1"; exit 1 ;;
  esac
done

if [ "$CHECK" = true ]; then
  echo "→ Validating source..."
  source tools/build/lib-skill-index.sh
  source tools/build/lib-agent-index.sh
  SRC="$(skill_source_dir || true)"
  if [ -z "$SRC" ]; then
    echo "✗ No skill source directory found (.claude/skills/ or os/skills/)"
    exit 1
  fi
  echo "  Source dir: $SRC"
  echo "  Skills: $(skill_list | wc -l | tr -d ' ')"
  echo "  Agents: $(agent_list | wc -l | tr -d ' ')"
  exit 0
fi

run() {
  local script="$1"
  echo "→ $(basename "$script")"
  bash "$script"
}

case "$RUNTIME" in
  all)
    run tools/build/build-agents-md.sh
    run tools/build/build-gemini.sh
    run tools/build/build-cursor.sh
    run tools/build/build-codex.sh
    ;;
  agents)  run tools/build/build-agents-md.sh ;;
  gemini)  run tools/build/build-gemini.sh ;;
  cursor)  run tools/build/build-cursor.sh ;;
  codex)   run tools/build/build-codex.sh ;;
  *)
    echo "Unknown runtime: $RUNTIME"
    echo "Valid: all | agents | gemini | cursor | codex"
    exit 1
    ;;
esac

echo ""
echo "✓ Build complete."
