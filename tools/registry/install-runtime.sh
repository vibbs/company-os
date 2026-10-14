#!/usr/bin/env bash
# ============================================================================
# install-runtime.sh — Add a runtime adapter to a project post-install.
# ============================================================================
# When you set up the project with --runtime=claude and later want to also
# work in Cursor, run:
#
#   ./tools/registry/install-runtime.sh cursor
#
# This script builds the requested adapter from os/ into the project, and
# AGENTS.md when it is missing. A runtime name (or a comma-separated list of
# names) leaves the other adapters alone; `all` rebuilds every adapter and
# adds the ones the project does not have yet.
#
# Usage:
#   ./tools/registry/install-runtime.sh <runtime>
#   ./tools/registry/install-runtime.sh claude,cursor
#   ./tools/registry/install-runtime.sh --list      # list valid runtimes
#
# Valid runtimes: claude, cursor, codex, gemini, aider (comma-separated list
# allowed), or all on its own. aider needs only AGENTS.md.
# ============================================================================

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/usage.sh"
usage_help_if_requested "${BASH_SOURCE[0]}" "${1:-}"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

VALID_HINT="Valid runtimes: claude, cursor, codex, gemini, aider (combine with commas, e.g. claude,cursor), or all on its own"

if [ "${1:-}" = "--list" ] || [ "${1:-}" = "" ]; then
  echo "Usage: ./tools/registry/install-runtime.sh <runtime>"
  echo "$VALID_HINT"
  exit 0
fi

SPEC="$1"

runtime_error() {
  echo "✗ $1" >&2
  echo "  $VALID_HINT" >&2
  exit 1
}

# Validate every name before building anything.
RUNTIMES=""
if [ "$SPEC" = "all" ]; then
  RUNTIMES="all"
else
  rest="$SPEC,"
  while [ -n "$rest" ]; do
    name="${rest%%,*}"
    rest="${rest#*,}"
    case "$name" in
      claude|cursor|codex|gemini|aider) RUNTIMES="$RUNTIMES $name" ;;
      "")  runtime_error "Empty runtime name in: $SPEC" ;;
      all) runtime_error "'all' cannot be combined with other names; use it on its own" ;;
      *)   runtime_error "Unknown runtime: $name" ;;
    esac
  done
fi

if [ ! -d "os/skills" ] || [ ! -d "os/agents" ]; then
  echo "✗ os/skills/ or os/agents/ not found." >&2
  echo "  Run install.sh first, or check that you're in a Company OS project root." >&2
  exit 1
fi

for runtime in $RUNTIMES; do
  case "$runtime" in
    aider) bash tools/build/build.sh --runtime=agents ;;   # aider reads AGENTS.md
    *)     bash tools/build/build.sh --runtime="$runtime" ;;
  esac
done

# Every runtime other than Claude Code reads AGENTS.md — make sure it's present.
if [ ! -f AGENTS.md ]; then
  bash tools/build/build-agents-md.sh
fi

echo ""
echo "✓ Runtime adapter(s) installed:$RUNTIMES"
echo ""
echo "Detected runtimes on this system:"
bash tools/registry/list-runtimes.sh
