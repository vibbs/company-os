#!/usr/bin/env bash
# ============================================================================
# run.sh — Run the Company OS test suite
# ============================================================================
# Runs every tests/test_*.sh in its own process with the same bash that runs
# this script, so `/bin/bash tests/run.sh` tests under macOS bash 3.2.
# Prints PASS, FAIL or SKIP per file and a summary. A failing file's output
# is shown below its FAIL line. No dependencies beyond bash and coreutils.
#
# Usage:
#   bash tests/run.sh                  # run every test file
#   bash tests/run.sh build docs       # run files whose names contain "build" or "docs"
#   bash tests/run.sh -v               # also show the output of passing files
#
# Exit codes:
#   0 - every selected test passed or was skipped
#   1 - a test failed, or no test file matched the filters
# ============================================================================

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
source "$ROOT/tools/lib/usage.sh"

VERBOSE=false
FILTERS=""
for arg in "$@"; do
  case "$arg" in
    -h|--help) usage_print_header "${BASH_SOURCE[0]}"; exit 0 ;;
    -v|--verbose) VERBOSE=true ;;
    -*) echo "ERROR: Unknown option: $arg (see --help)" >&2; exit 1 ;;
    *) FILTERS="$FILTERS $arg" ;;
  esac
done

selected() {
  local name="$1" f
  [ -z "$FILTERS" ] && return 0
  for f in $FILTERS; do
    case "$name" in *"$f"*) return 0 ;; esac
  done
  return 1
}

PASSED=0 FAILED=0 SKIPPED=0
FAILED_NAMES=""
LOG="$(mktemp "${TMPDIR:-/tmp}/cos-run.XXXXXX")"
trap 'rm -f "$LOG"' EXIT
SUITE_START=$(date +%s)

echo "Running tests with $BASH (bash $BASH_VERSION)"
for test_file in tests/test_*.sh; do
  [ -f "$test_file" ] || continue
  name="$(basename "$test_file" .sh)"
  selected "$name" || continue
  start=$(date +%s)
  rc=0
  "$BASH" "$test_file" >"$LOG" 2>&1 </dev/null || rc=$?
  secs=$(( $(date +%s) - start ))
  case "$rc" in
    0)
      PASSED=$((PASSED + 1))
      echo "PASS $name (${secs}s)"
      [ "$VERBOSE" = true ] && sed 's/^/     /' "$LOG"
      ;;
    77)
      SKIPPED=$((SKIPPED + 1))
      reason="$(grep '^SKIP:' "$LOG" | tail -1 | sed 's/^SKIP: *//' || true)"
      echo "SKIP $name — ${reason:-no reason given}"
      ;;
    *)
      FAILED=$((FAILED + 1))
      FAILED_NAMES="$FAILED_NAMES $name"
      echo "FAIL $name (exit $rc, ${secs}s)"
      sed 's/^/     /' "$LOG"
      ;;
  esac
done

TOTAL=$((PASSED + FAILED + SKIPPED))
echo ""
echo "$TOTAL test file(s): $PASSED passed, $FAILED failed, $SKIPPED skipped ($(( $(date +%s) - SUITE_START ))s)"

if [ "$TOTAL" -eq 0 ]; then
  if [ -n "$FILTERS" ]; then echo "No test file matched:$FILTERS" >&2; else echo "No tests/test_*.sh files found" >&2; fi
  exit 1
fi
if [ "$FAILED" -gt 0 ]; then
  echo "Failed:$FAILED_NAMES"
  exit 1
fi
exit 0
