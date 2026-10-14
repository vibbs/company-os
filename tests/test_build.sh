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

# --- The build removes only what it generated ---
# A skill or agent made by hand under .claude/ (no os/ source) survives with a
# warning; a generated one whose os/ source is gone is removed. With no
# generated list yet (first build after an upgrade), nothing is removed.
G="$(make_tmp)"
cp -R "$B/." "$G/"
assert_file_exists "$G/.claude/.generated-by-company-os" "build writes the generated list"
mkdir -p "$G/.claude/skills/my-custom" "$G/os/skills/old-generated"
printf -- '---\nname: my-custom\ndescription: Hand-made.\n---\n' > "$G/.claude/skills/my-custom/SKILL.md"
printf -- '---\nname: my-agent\ndescription: Hand-made.\n---\n' > "$G/.claude/agents/my-agent.md"
cp "$G/os/skills/ship/SKILL.md" "$G/os/skills/old-generated/SKILL.md"
assert_exit 0 bash "$G/tools/build/build-claude.sh"
assert_file_exists "$G/.claude/skills/old-generated/SKILL.md"
rm -rf "$G/os/skills/old-generated"
assert_exit 0 bash "$G/tools/build/build-claude.sh"
assert_file_missing "$G/.claude/skills/old-generated" "stale generated skill is pruned"
assert_contains "$OUT" "removed stale generated skill .claude/skills/old-generated"
assert_file_exists "$G/.claude/skills/my-custom/SKILL.md" "custom .claude skill survives the build"
assert_file_exists "$G/.claude/agents/my-agent.md" "custom .claude agent survives the build"
assert_contains "$OUT" "custom skill .claude/skills/my-custom is not in os/ — move it to os/skills/my-custom/"
assert_contains "$OUT" "custom agent .claude/agents/my-agent.md is not in os/ — move it to os/agents/my-agent.md"
# Your files inside a generated skill folder survive; a sidecar the build
# generated is removed once its os/ source is gone.
printf 'my notes\n' > "$G/.claude/skills/ship/my-notes.md"
printf 'generated sidecar\n' > "$G/os/skills/ship/extra.md"
assert_exit 0 bash "$G/tools/build/build-claude.sh"
assert_file_exists "$G/.claude/skills/ship/extra.md"
rm -f "$G/os/skills/ship/extra.md"
assert_exit 0 bash "$G/tools/build/build-claude.sh"
assert_file_exists "$G/.claude/skills/ship/my-notes.md" "user file inside a generated skill folder survives"
assert_contains "$OUT" "kept .claude/skills/ship/my-notes.md (your file; the build does not manage it)"
assert_file_missing "$G/.claude/skills/ship/extra.md" "stale generated sidecar is removed"
# The Company OS repo (no install manifest) still builds every adapter.
assert_exit 0 bash "$G/tools/build/build.sh"
assert_not_contains "$OUT" "Building the adapters this project has"

# No list yet: a stale skill is kept (it may be the user's).
rm -f "$G/.claude/.generated-by-company-os"
mkdir -p "$G/.claude/skills/unlisted"
cp "$G/os/skills/ship/SKILL.md" "$G/.claude/skills/unlisted/SKILL.md"
assert_exit 0 bash "$G/tools/build/build-claude.sh"
assert_file_exists "$G/.claude/skills/unlisted/SKILL.md" "first build without a list prunes nothing"

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
