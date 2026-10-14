#!/usr/bin/env bash
# ============================================================================
# install-runtime.sh — Add a runtime adapter to a project post-install.
# ============================================================================
# When you set up the project with --runtime=claude and later want to also
# work in Cursor, run:
#
#   ./tools/registry/install-runtime.sh cursor
#
# This script rebuilds the requested adapter from os/ into the project.
# It does NOT touch any other runtime adapters that are already installed.
#
# Usage:
#   ./tools/registry/install-runtime.sh <runtime>
#   ./tools/registry/install-runtime.sh --list      # list valid runtimes
#
# Valid runtimes: claude, cursor, codex, gemini, all
# ============================================================================

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/usage.sh"
usage_help_if_requested "${BASH_SOURCE[0]}" "${1:-}"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

if [ "${1:-}" = "--list" ] || [ "${1:-}" = "" ]; then
  echo "Usage: ./tools/registry/install-runtime.sh <runtime>"
  echo "Valid runtimes: claude cursor codex gemini all"
  exit 0
fi

RUNTIME="$1"

if [ ! -d "os/skills" ] || [ ! -d "os/agents" ]; then
  echo "✗ os/skills/ or os/agents/ not found." >&2
  echo "  Run install.sh first, or check that you're in a Company OS project root." >&2
  exit 1
fi

case "$RUNTIME" in
  claude|cursor|codex|gemini|all)
    bash tools/build/build.sh --runtime="$RUNTIME"
    ;;
  agents)
    bash tools/build/build.sh --runtime=agents
    ;;
  *)
    echo "✗ Unknown runtime: $RUNTIME" >&2
    echo "  Valid: claude cursor codex gemini all" >&2
    exit 1
    ;;
esac

# Some runtimes need AGENTS.md too — make sure it's present.
if [ ! -f AGENTS.md ]; then
  bash tools/build/build-agents-md.sh
fi

echo ""
echo "✓ Runtime adapter '$RUNTIME' installed."
echo ""
echo "Detected runtimes on this system:"
bash tools/registry/list-runtimes.sh
