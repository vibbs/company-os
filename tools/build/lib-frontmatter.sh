#!/usr/bin/env bash
# ============================================================================
# lib-frontmatter.sh — Shared YAML frontmatter reading for build adapters
# ============================================================================
# Source this file; do not execute directly.
#
# Provides:
#   fm_extract <file>            -> echoes frontmatter block (between --- markers)
#   fm_field <file> <key>        -> echoes value of a top-level scalar field
#   fm_list <file> <key>         -> echoes lines under a YAML list field (one per line)
#   fm_body <file>               -> echoes the Markdown body (everything after the second ---)
# ============================================================================

# Extracts everything between the first two `---` lines.
fm_extract() {
  awk '
    BEGIN { in_fm = 0; count = 0 }
    /^---$/ { count++; if (count == 1) { in_fm = 1; next } else if (count == 2) { exit } }
    in_fm { print }
  ' "$1"
}

# Reads a scalar key from the frontmatter. Strips surrounding quotes.
fm_field() {
  local file="$1" key="$2"
  fm_extract "$file" \
    | awk -v k="$key" '
        $0 ~ "^"k":" {
          sub("^"k": *", "")
          gsub(/^"|"$/, "")
          gsub(/^'\''|'\''$/, "")
          print
          exit
        }
      '
}

# Reads a YAML list field (lines beginning "  - "), echoes each value on its own line.
fm_list() {
  local file="$1" key="$2"
  fm_extract "$file" \
    | awk -v k="$key" '
        $0 ~ "^"k":" { capture = 1; next }
        capture && /^[a-zA-Z_]/ { capture = 0 }
        capture && /^  - / {
          sub(/^  - */, "")
          gsub(/^"|"$/, "")
          print
        }
      '
}

# Echoes the Markdown body (everything after the closing `---`).
fm_body() {
  awk '
    BEGIN { count = 0; print_now = 0 }
    /^---$/ { count++; if (count == 2) { print_now = 1; next } }
    print_now { print }
  ' "$1"
}
