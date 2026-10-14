#!/usr/bin/env bash
# Build and validation: build.sh --check is clean, the committed adapters
# match a fresh build, and lift_claude_fields handles the edge-case fixtures.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/assert.sh"
cd "$REPO_ROOT"

# --- build.sh --check on the repository (writes nothing) ---
assert_exit 0 bash tools/build/build.sh --check
assert_contains "$OUT" "Failed: 0"
assert_not_contains "$OUT" "[fail]"
assert_exit 0 bash tools/build/build.sh --check --strict
assert_not_contains "$OUT" "[warn]"
assert_exit 1 bash tools/build/build.sh --strict
assert_contains "$OUT" "--strict only applies to --check"

# --- Fresh build into a temporary copy matches the committed adapters ---
B="$(make_tmp)"
mkdir -p "$B/.claude"
for p in os tools CLAUDE.md AGENTS.md GEMINI.md .cursorrules .cursor .codex .company-os; do
  [ -e "$p" ] && cp -R "$p" "$B/$p"
done
cp -R .claude/skills .claude/agents "$B/.claude/"
assert_exit 0 bash "$B/tools/build/build.sh"
for p in .claude/skills .claude/agents .cursor AGENTS.md GEMINI.md .cursorrules .codex; do
  [ -e "$p" ] || continue
  assert_exit 0 diff -r "$p" "$B/$p"
done
# Stale generated skills are removed by the build, then rebuilt from os/.
SKILLS_OK=true
for f in os/skills/*/SKILL.md; do
  name="$(basename "$(dirname "$f")")"
  if ! cmp -s ".claude/skills/$name/SKILL.md" "$B/.claude/skills/$name/SKILL.md"; then
    SKILLS_OK=false
    echo "  stale: .claude/skills/$name/SKILL.md (run bash tools/build/build.sh)"
  fi
done
assert_eq "true" "$SKILLS_OK" "every generated .claude/skills/*/SKILL.md matches a fresh build"

# --- Lift edge cases (fixtures) ---
cp -R tests/fixtures/skills/crlf-comments tests/fixtures/skills/spaced-comments "$B/os/skills/"
mkdir -p "$B/os/skills/legacy-top"
cat > "$B/os/skills/legacy-top/SKILL.md" <<'EOF'
---
name: legacy-top
description: Fixture skill with the legacy top-level spelling.
user-invokable: false
---

Body.
EOF
assert_exit 0 bash "$B/tools/build/build-claude.sh"

CRLF="$(cat "$B/.claude/skills/crlf-comments/SKILL.md")"
assert_eq "0" "$(grep -c "$(printf '\r')" "$B/.claude/skills/crlf-comments/SKILL.md")" "CRLF: output has LF line endings"
assert_contains "$CRLF" "$(printf -- '---\nname: crlf-comments')"
assert_contains "$CRLF" "$(printf 'user-invocable: true\nargument-hint: "[x]"\nruntimes:\n  cursor:\n    alwaysApply: false\n---')" "CRLF: claude keys lifted, cursor kept"
assert_not_contains "$CRLF" "  claude:"

SPACED="$(cat "$B/.claude/skills/spaced-comments/SKILL.md")"
assert_contains "$SPACED" "$(printf 'user-invocable: true\ndisable-model-invocation: false\nruntimes:\n  cursor:')" "commented keys: lifted and trimmed"
assert_not_contains "$SPACED" "user-invokable" "legacy nested alias written as user-invocable"
assert_not_contains "$SPACED" "  claude:"

assert_contains "$(cat "$B/.claude/skills/legacy-top/SKILL.md")" "$(printf '\nuser-invocable: false\n')" "legacy top-level alias renamed"

# --- Validators on the fixtures ---
assert_exit 0 bash tools/build/validate-skill.sh --strict tests/fixtures/skills/crlf-comments/SKILL.md
assert_contains "$OUT" "[ok]"
assert_exit 0 bash tools/build/validate-skill.sh tests/fixtures/skills/spaced-comments/SKILL.md
assert_contains "$OUT" "valid with 1 warning(s)" "spaced-comments: exactly one warning"
assert_contains "$OUT" "[warn] tests/fixtures/skills/spaced-comments/SKILL.md: 'user-invokable' is a deprecated spelling"
assert_exit 1 bash tools/build/validate-skill.sh --strict tests/fixtures/skills/spaced-comments/SKILL.md
assert_exit 2 bash tools/build/validate-skill.sh tests/fixtures/skills/missing/SKILL.md

finish
