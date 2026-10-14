#!/usr/bin/env bash
# Every runnable tool, build script and validator (plus install.sh and
# .company-os/setup.sh) answers -h and --help with exit 0 and a Usage line, and changes
# nothing in the working tree.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/assert.sh"
cd "$REPO_ROOT"

git_state() {
  git status --porcelain --untracked-files=all 2>/dev/null
}

BEFORE="$(git_state)"

SCRIPTS="$(find tools -name '*.sh' -type f -not -path 'tools/lib/*' -not -name 'lib-*.sh' | sort)"
COUNT=0
for script in $SCRIPTS install.sh .company-os/setup.sh; do
  COUNT=$((COUNT + 1))
  for flag in --help -h; do
    assert_exit 0 bash "$script" "$flag"
    if ! printf '%s\n' "$OUT" | grep -Eq '^ *Usage:?'; then
      assert_eq "a Usage line" "$(printf '%s' "$OUT" | head -3)" "$script $flag prints a Usage line"
    fi
  done
done

# 33 runnable tools + 6 build scripts + 2 validators, plus install.sh and .company-os/setup.sh.
RUNNABLE="$(find tools -name '*.sh' -type f -not -path 'tools/lib/*' -not -path 'tools/build/*' | wc -l | tr -d ' ')"
assert_eq "33" "$RUNNABLE" "runnable tool script count (excluding tools/build, tools/lib)"
assert_eq "43" "$COUNT" "scripts checked for --help"

# -h / --help count anywhere in the arguments, but only as a whole argument.
assert_exit 0 bash tools/ops/status-check.sh https://example.invalid --help
assert_contains "$OUT" "Usage:" "status-check.sh <url> --help prints usage"
assert_exit 0 bash tools/registry/list-runtimes.sh --json -h
assert_contains "$OUT" "Usage:" "list-runtimes.sh --json -h prints usage"
assert_exit 1 bash tools/registry/list-runtimes.sh "--json -h"
assert_not_contains "$OUT" "list-runtimes.sh — Show" "one argument containing -h is not a help request"

# Unknown flags are errors, not ignored.
assert_exit 1 bash tools/registry/list-runtimes.sh --bogus
assert_contains "$OUT" "Unknown argument: --bogus" "list-runtimes.sh rejects an unknown flag"
assert_exit 1 bash tools/registry/list-runtimes.sh --json --bogus
assert_exit 0 bash tools/registry/list-runtimes.sh --detected

# dashboard --period accepts only monthly or all.
assert_exit 1 bash tools/ops/dashboard.sh --period weekly
assert_contains "$OUT" "--period must be monthly or all" "dashboard.sh rejects --period weekly"

# status-check: usage errors use exit 64, apart from 1 (degraded) and 2 (down).
assert_exit 64 bash tools/ops/status-check.sh
assert_exit 64 bash tools/ops/status-check.sh --bogus https://example.invalid
assert_exit 64 bash tools/ops/status-check.sh --timeout

# resilience-test --help shows what the checks are and examples.
assert_exit 0 bash tools/qa/resilience-test.sh --help
assert_contains "$OUT" "Health endpoint reachability" "resilience-test.sh --help lists the checks"
assert_contains "$OUT" "Examples:" "resilience-test.sh --help shows examples"

assert_eq "$BEFORE" "$(git_state)" "help output must not change the working tree"

finish
