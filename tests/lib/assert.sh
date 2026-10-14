#!/usr/bin/env bash
# Shared test helpers (sourced by tests/test_*.sh, not run).
#
# Usage, at the top of a test file:
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/assert.sh"
#   ...assertions...
#   finish
#
# Assertions record a failure and keep going; `finish` exits 1 when any
# failed, so one run shows every broken expectation. `skip "<reason>"` ends
# the test with exit code 77, which tests/run.sh reports as SKIP.
#
#   assert_eq <expected> <actual> [message]
#   assert_contains <haystack> <needle> [message]
#   assert_not_contains <haystack> <needle> [message]
#   assert_file_exists <path> [message]
#   assert_file_missing <path> [message]
#   assert_exit <expected-code> <command> [args...]
#       runs the command, stores its combined stdout+stderr in $OUT and its
#       exit code in $RC, and fails when the code differs
#   make_tmp      prints a new temporary directory, removed when the test exits
#                 (all of them live under $TEST_TMP)
#
# Bash 3.2 compatible. Sets REPO_ROOT to the repository root.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export NO_COLOR=1
ASSERT_FAILS=0
ASSERT_COUNT=0
OUT=""
RC=0

_assert_fail() {
  ASSERT_FAILS=$((ASSERT_FAILS + 1))
  echo "  not ok: $1"
  shift
  local line
  for line in "$@"; do
    printf '    %s\n' "$line"
  done
}

assert_eq() {
  ASSERT_COUNT=$((ASSERT_COUNT + 1))
  if [ "$1" != "$2" ]; then
    _assert_fail "${3:-values differ}" "expected: $1" "actual:   $2"
  fi
}

assert_contains() {
  ASSERT_COUNT=$((ASSERT_COUNT + 1))
  case "$1" in
    *"$2"*) ;;
    *) _assert_fail "${3:-output does not contain '$2'}" "output: $(printf '%s' "$1" | head -c 2000)" ;;
  esac
}

assert_not_contains() {
  ASSERT_COUNT=$((ASSERT_COUNT + 1))
  case "$1" in
    *"$2"*) _assert_fail "${3:-output contains '$2'}" "output: $(printf '%s' "$1" | head -c 2000)" ;;
    *) ;;
  esac
}

assert_file_exists() {
  ASSERT_COUNT=$((ASSERT_COUNT + 1))
  [ -e "$1" ] || _assert_fail "${2:-missing file: $1}"
}

assert_file_missing() {
  ASSERT_COUNT=$((ASSERT_COUNT + 1))
  [ ! -e "$1" ] || _assert_fail "${2:-file should not exist: $1}"
}

assert_exit() {
  local expected="$1"
  shift
  ASSERT_COUNT=$((ASSERT_COUNT + 1))
  RC=0
  OUT="$("$@" 2>&1)" || RC=$?
  if [ "$RC" != "$expected" ]; then
    _assert_fail "exit $RC, expected $expected: $*" "output: $(printf '%s' "$OUT" | tail -n 15)"
  fi
}

# One temporary root per test file; make_tmp hands out folders inside it.
TEST_TMP="$(mktemp -d "${TMPDIR:-/tmp}/cos-test.XXXXXX")"
TEST_TMP="$(cd "$TEST_TMP" && pwd -P)"
trap 'rm -rf "$TEST_TMP"' EXIT

make_tmp() {
  mktemp -d "$TEST_TMP/t.XXXXXX"
}

skip() {
  echo "SKIP: $*"
  exit 77
}

finish() {
  if [ "$ASSERT_FAILS" -gt 0 ]; then
    echo "$ASSERT_FAILS of $ASSERT_COUNT assertion(s) failed"
    exit 1
  fi
  echo "$ASSERT_COUNT assertion(s) passed"
  exit 0
}
