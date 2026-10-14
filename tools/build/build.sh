#!/usr/bin/env bash
# ============================================================================
# build.sh — Run all adapter builders
# ============================================================================
# Regenerates every runtime adapter (Claude Code, Cursor, Codex, Gemini,
# AGENTS.md) from os/ (skills and agents) and CLAUDE.md. Edit os/, then run
# this script; do not edit the generated adapters by hand.
#
# Usage:
#   bash tools/build/build.sh                     # build the adapters this project uses
#   bash tools/build/build.sh --runtime=all       # build every adapter
#   bash tools/build/build.sh --runtime=cursor    # build only the cursor adapter
#   bash tools/build/build.sh --runtime=agents    # build only AGENTS.md
#   bash tools/build/build.sh --runtime=gemini    # build GEMINI.md (rebuilds AGENTS.md first)
#   bash tools/build/build.sh --runtime=codex     # build the Codex adapter (rebuilds AGENTS.md first)
#   bash tools/build/build.sh --check             # validate without writing
#   bash tools/build/build.sh --check --strict    # also fail on warnings
#
# Options:
#   --runtime=<name>   all, claude, cursor, agents, gemini or codex. Default: in a
#                      project installed with install.sh (.company-os/manifest
#                      has hashes), the adapters already present (.claude/,
#                      .cursor/ or .cursorrules, .codex/, GEMINI.md) plus
#                      AGENTS.md; in the Company OS repo itself, all
#   --check            run the skill and agent validators; write nothing
#   --strict           with --check, exit 1 when any validator reports a warning
#   -h, --help         show this help
#
# Exit codes:
#   0 - success (--check: no failures)
#   1 - bad flag, build error, validation failure, or warnings under --strict
# ============================================================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/usage.sh"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

RUNTIME=""
CHECK=false
STRICT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --runtime=*) RUNTIME="${1#*=}"; shift ;;
    --runtime)
      [[ $# -ge 2 ]] || { echo "ERROR: --runtime requires a value (all, claude, cursor, agents, gemini, codex)" >&2; exit 1; }
      RUNTIME="$2"; shift 2 ;;
    --check)     CHECK=true; shift ;;
    --strict)    STRICT=true; shift ;;
    -h|--help)
      usage_print_header "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *) echo "ERROR: Unknown flag: $1" >&2; echo "Run with --help for usage." >&2; exit 1 ;;
  esac
done

if [ "$STRICT" = true ] && [ "$CHECK" != true ]; then
  echo "ERROR: --strict only applies to --check" >&2
  exit 1
fi

if [ "$CHECK" = true ]; then
  source tools/build/lib-markers.sh
  echo "$MARK_ARROW Validating source..."
  source tools/build/lib-skill-index.sh
  source tools/build/lib-agent-index.sh
  SRC="$(skill_source_dir || true)"
  if [ -z "$SRC" ]; then
    echo "$MARK_FAIL No skill source directory found (.claude/skills/ or os/skills/)"
    exit 1
  fi
  echo "  Source dir: $SRC"
  echo "  Skills: $(skill_list | wc -l | tr -d ' ')"
  echo "  Agents: $(agent_list | wc -l | tr -d ' ')"
  STRICT_FLAG=""
  [ "$STRICT" = true ] && STRICT_FLAG="--strict"
  CHECK_RC=0
  for kind in skill agent; do
    echo ""
    echo "$MARK_ARROW Running $kind validator..."
    rc=0
    out="$(bash "tools/build/validate-$kind.sh" ${STRICT_FLAG:+"$STRICT_FLAG"} --all 2>&1)" || rc=$?
    if [ "$rc" -eq 0 ]; then
      printf '%s\n' "$out" | tail -3
    else
      printf '%s\n' "$out"
      CHECK_RC=1
    fi
  done
  exit "$CHECK_RC"
fi

# Default: an installed project builds only the adapters it already has, so
# a rebuild does not add runtimes (the next upgrade keeps what is present).
# The Company OS repo (no install manifest with hashes) builds everything.
if [ -z "$RUNTIME" ]; then
  RUNTIME="all"
  if [ -f .company-os/manifest ] && grep -Eq '^[0-9a-f]{8,}  ' .company-os/manifest 2>/dev/null; then
    RUNTIME="project"
  fi
fi

run() {
  local script="$1"
  echo "→ $(basename "$script")"
  bash "$script"
}

case "$RUNTIME" in
  all)
    run tools/build/build-claude.sh
    run tools/build/build-agents-md.sh
    run tools/build/build-gemini.sh
    run tools/build/build-cursor.sh
    run tools/build/build-codex.sh
    ;;
  project)
    echo "Building the adapters this project has (use --runtime=all for every adapter)"
    if [ -d .claude ]; then run tools/build/build-claude.sh; fi
    run tools/build/build-agents-md.sh
    if [ -f GEMINI.md ]; then run tools/build/build-gemini.sh; fi
    if [ -d .cursor ] || [ -f .cursorrules ]; then run tools/build/build-cursor.sh; fi
    if [ -d .codex ]; then run tools/build/build-codex.sh; fi
    ;;
  claude)  run tools/build/build-claude.sh ;;
  agents)  run tools/build/build-agents-md.sh ;;
  gemini)  run tools/build/build-gemini.sh ;;
  cursor)  run tools/build/build-cursor.sh ;;
  codex)   run tools/build/build-codex.sh ;;
  *)
    echo "Unknown runtime: $RUNTIME"
    echo "Valid: all | claude | agents | gemini | cursor | codex"
    exit 1
    ;;
esac

echo ""
echo "✓ Build complete."
