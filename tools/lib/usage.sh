#!/usr/bin/env bash
# Shared helper (sourced, not run): print a script's header comment as --help text.
#
# Usage inside a tool script, right after `set -euo pipefail`:
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/usage.sh"
#   usage_help_if_requested "${BASH_SOURCE[0]}" "${1:-}"
#
# If any argument is exactly -h or --help, prints the script's leading comment
# block (Tool / Usage / Inputs / Outputs) without the shebang or rule lines,
# then exits 0. Otherwise it returns and does nothing.
#
# How it sees every argument: sourcing a file without arguments keeps the
# caller's positional parameters, so the scan below runs once, at source time,
# over the script's own "$@". Rules:
#   - Only an argument exactly equal to -h or --help counts. "--helpful" or a
#     value such as "fix -h handling" does not.
#   - A value that directly follows a flag that takes one (for example
#     `--message --help`) is not told apart from the help flag; it prints help.
#     Rare, harmless, and left alone on purpose.
# Source this file at the top level of the script, before any `shift`.

_USAGE_HELP_ASKED=0
for _usage_arg in "$@"; do
  case "$_usage_arg" in
    -h|--help) _USAGE_HELP_ASKED=1 ;;
  esac
done
unset _usage_arg

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
    -h|--help) _USAGE_HELP_ASKED=1 ;;
  esac
  if [ "$_USAGE_HELP_ASKED" = 1 ]; then usage_print_header "$1"; exit 0; fi
  return 0
}
