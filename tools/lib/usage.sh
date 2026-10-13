#!/usr/bin/env bash
# Shared helper (sourced, not run): print a script's header comment as --help text.
#
# Usage inside a tool script, right after `set -euo pipefail`:
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/usage.sh"
#   usage_help_if_requested "${BASH_SOURCE[0]}" "${1:-}"
#
# If the first argument is -h or --help, prints the script's leading comment
# block (Tool / Usage / Inputs / Outputs) without the shebang or rule lines,
# then exits 0. Otherwise it returns and does nothing.

usage_print_header() {
  local file="$1"
  awk '
    NR == 1 && /^#!/ { next }
    !started && /^#/ { started = 1 }
    !started { next }
    !/^#/ { exit }
    {
      line = $0
      sub(/^# ?/, "", line)
      had = (line ~ /─/)
      gsub(/─/, "", line)
      if (had) { sub(/^ +/, "", line); sub(/ +$/, "", line) }
      if (line ~ /^[ =-]*$/ && $0 ~ /[=─-]/) next
      print line
    }
  ' "$file" | sed -e 's/[[:space:]]*$//'
}

usage_help_if_requested() {
  case "${2:-}" in
    -h|--help) usage_print_header "$1"; exit 0 ;;
  esac
  return 0
}
