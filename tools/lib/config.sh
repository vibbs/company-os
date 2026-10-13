#!/usr/bin/env bash
# Shared helper (sourced, not run): read values from company.config.yaml.
#
# Usage:
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/config.sh"
#   LINTER="$(cfg_get conventions.linter)"
#
# cfg_get <dotted.key> [config-file]
#   Walks nested keys by indentation (a.b.c matches a: / b: / c:).
#   Strips trailing "# comments", surrounding quotes and whitespace.
#   Prints an empty string when the key or file is missing. Never aborts
#   the calling script, even under `set -euo pipefail`.
#   Only scalar values on the same line as the key are supported.

COS_CONFIG_FILE_DEFAULT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/company.config.yaml"

cfg_get() {
  local key="${1:-}" file="${2:-${CONFIG_FILE:-$COS_CONFIG_FILE_DEFAULT}}"
  [[ -n "$key" && -f "$file" ]] || { echo ""; return 0; }
  awk -v key="$key" '
    BEGIN { n = split(key, parts, "."); depth = 1; found = 0 }
    /^[ \t]*#/ || /^[ \t]*$/ { next }
    {
      match($0, /^[ ]*/); indent = RLENGTH
      line = substr($0, indent + 1)
      # Pop levels we have left (indent not deeper than the matched parent).
      while (depth > 1 && indent <= ind[depth - 1]) depth--
      k = line; sub(/:.*/, "", k)
      if (k != parts[depth] || line !~ /^[A-Za-z0-9_.-]+:/) next
      if (depth == n) {
        v = line; sub(/^[^:]*:[ \t]*/, "", v)
        if (v ~ /^"/) { sub(/^"/, "", v); sub(/".*$/, "", v) }
        else if (v ~ /^'"'"'/) { sub(/^'"'"'/, "", v); sub(/'"'"'.*$/, "", v) }
        else { sub(/[ \t]+#.*$/, "", v); sub(/^#.*$/, "", v); sub(/[ \t]+$/, "", v) }
        print v; found = 1; exit
      }
      ind[depth] = indent; depth++
    }
    END { if (!found) print "" }
  ' "$file" 2>/dev/null || true
}
