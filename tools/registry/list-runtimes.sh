#!/usr/bin/env bash
# ============================================================================
# list-runtimes.sh — Show which agent runtimes are detected and which Company
# OS adapters are installed for them.
# ============================================================================
# Usage:
#   ./tools/registry/list-runtimes.sh             # human-readable table
#   ./tools/registry/list-runtimes.sh --json      # machine-readable JSON
#   ./tools/registry/list-runtimes.sh --detected  # only print detected runtime names (one per line)
# ============================================================================

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/usage.sh"
usage_help_if_requested "${BASH_SOURCE[0]}" "${1:-}"

FORMAT="table"
case "${1:-}" in
  "")         ;;
  --json)     FORMAT="json" ;;
  --detected) FORMAT="detected" ;;
  *)
    echo "ERROR: Unknown argument: $1" >&2
    echo "Usage: ./tools/registry/list-runtimes.sh [--json|--detected]" >&2
    exit 1
    ;;
esac
if [ $# -gt 1 ]; then
  echo "ERROR: Unexpected argument: $2" >&2
  echo "Usage: ./tools/registry/list-runtimes.sh [--json|--detected]" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

# ----------------------------------------------------------------------------
# Detection: is the agent runtime installed on this system?
# ----------------------------------------------------------------------------
detect_claude() {
  if command -v claude >/dev/null 2>&1; then return 0; fi
  [ -d "$HOME/.claude" ] && return 0
  return 1
}
detect_cursor() {
  if command -v cursor >/dev/null 2>&1; then return 0; fi
  [ -d "$HOME/.cursor" ] && return 0
  [ -d "$HOME/Library/Application Support/Cursor" ] && return 0
  return 1
}
detect_codex() {
  if command -v codex >/dev/null 2>&1; then return 0; fi
  [ -d "$HOME/.codex" ] && return 0
  return 1
}
detect_gemini() {
  if command -v gemini >/dev/null 2>&1; then return 0; fi
  [ -d "$HOME/.gemini" ] && return 0
  return 1
}
detect_aider() {
  if command -v aider >/dev/null 2>&1; then return 0; fi
  return 1
}

# ----------------------------------------------------------------------------
# Project-side: is the adapter present in THIS project?
# ----------------------------------------------------------------------------
adapter_claude()  { [ -d ".claude/skills" ] && [ -d ".claude/agents" ]; }
adapter_cursor()  { [ -f ".cursorrules" ] || [ -d ".cursor/rules" ]; }
adapter_codex()   { [ -f ".codex/config.md" ] || [ -f "AGENTS.md" ]; }
adapter_gemini()  { [ -f "GEMINI.md" ]; }
adapter_aider()   { [ -f "AGENTS.md" ]; }

runtime_status() {
  local name="$1"
  local installed_fn="detect_$name"
  local adapter_fn="adapter_$name"
  local installed adapter
  if "$installed_fn"; then installed="yes"; else installed="no"; fi
  if "$adapter_fn"; then adapter="yes"; else adapter="no"; fi
  echo "$name $installed $adapter"
}

RUNTIMES="claude cursor codex gemini aider"

case "$FORMAT" in
  detected)
    for r in $RUNTIMES; do
      if "detect_$r"; then echo "$r"; fi
    done
    ;;

  json)
    echo "["
    first=1
    for r in $RUNTIMES; do
      [ "$first" = 1 ] || echo ","
      first=0
      if "detect_$r"; then det="true"; else det="false"; fi
      if "adapter_$r"; then ada="true"; else ada="false"; fi
      printf '  {"runtime":"%s","detected":%s,"adapter_present":%s}' "$r" "$det" "$ada"
    done
    echo ""
    echo "]"
    ;;

  table|*)
    printf "%-10s %-12s %-18s\n" "Runtime" "Detected" "Adapter in repo"
    printf "%-10s %-12s %-18s\n" "-------" "--------" "---------------"
    for r in $RUNTIMES; do
      if "detect_$r"; then det="yes"; else det="no"; fi
      if "adapter_$r"; then ada="yes"; else ada="no"; fi
      printf "%-10s %-12s %-18s\n" "$r" "$det" "$ada"
    done
    ;;
esac
