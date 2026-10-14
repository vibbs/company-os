#!/usr/bin/env bash
# Every runnable tool, build script and validator (plus install.sh and
# setup.sh) answers -h and --help with exit 0 and a Usage line, and changes
# nothing in the working tree.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/assert.sh"
cd "$REPO_ROOT"

git_state() {
  git status --porcelain --untracked-files=all 2>/dev/null
}

BEFORE="$(git_state)"

SCRIPTS="$(find tools -name '*.sh' -type f -not -path 'tools/lib/*' -not -name 'lib-*.sh' | sort)"
COUNT=0
for script in $SCRIPTS install.sh setup.sh; do
  COUNT=$((COUNT + 1))
  for flag in --help -h; do
    assert_exit 0 bash "$script" "$flag"
    if ! printf '%s\n' "$OUT" | grep -Eq '^ *Usage:?'; then
      assert_eq "a Usage line" "$(printf '%s' "$OUT" | head -3)" "$script $flag prints a Usage line"
    fi
  done
done

# 33 runnable tools + 6 build scripts + 2 validators, plus install.sh and setup.sh.
RUNNABLE="$(find tools -name '*.sh' -type f -not -path 'tools/lib/*' -not -path 'tools/build/*' | wc -l | tr -d ' ')"
assert_eq "33" "$RUNNABLE" "runnable tool script count (excluding tools/build, tools/lib)"
assert_eq "43" "$COUNT" "scripts checked for --help"

assert_eq "$BEFORE" "$(git_state)" "help output must not change the working tree"

finish
