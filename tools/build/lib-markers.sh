#!/usr/bin/env bash
# ============================================================================
# lib-markers.sh — Status markers for validator output
# ============================================================================
# Source this file; do not execute directly.
#
# Sets MARK_OK, MARK_WARN, MARK_FAIL and MARK_ARROW. They are Unicode symbols
# on an interactive terminal, and plain ASCII ([ok], [warn], [fail], ->) when
# stdout is not a terminal (pipes, CI logs, files) or NO_COLOR is set.
# ============================================================================

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  MARK_OK="✓"; MARK_WARN="⚠"; MARK_FAIL="✗"; MARK_ARROW="→"
else
  MARK_OK="[ok]"; MARK_WARN="[warn]"; MARK_FAIL="[fail]"; MARK_ARROW="->"
fi
