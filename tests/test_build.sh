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

# --- AGENTS.md names its real source and lists only runnable tools ---
AGENTS_MD="$(cat AGENTS.md)"
assert_contains "$AGENTS_MD" "Source: os/ + CLAUDE.md"
assert_not_contains "$AGENTS_MD" "Source: .claude/"
assert_eq "" "$(grep -E '^- `tools/(lib/|build/lib-)' AGENTS.md || true)" "sourced helpers are not listed as runnable tools"
assert_contains "$AGENTS_MD" "Shared helpers, sourced by the scripts above (do not run them): \`tools/build/lib-agent-index.sh\`"

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

# --- known-hashes.txt: fresh in the repo, stale after a template change, and
# skipped where there is no history to build it from ---
sha() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}'; else sha256sum "$1" | awk '{print $1}'; fi
}
assert_exit 0 bash tools/build/build.sh --check
assert_contains "$OUT" "known-hashes.txt"
if [ "$(git rev-parse --is-shallow-repository 2>/dev/null)" = false ]; then
  assert_contains "$OUT" "known-hashes: .company-os/known-hashes.txt is up to date"
  KH="$(make_tmp)/repo"
  git clone -q "$REPO_ROOT" "$KH"
  OLD_SHIP="$(sha "$KH/os/skills/ship/SKILL.md")"
  printf '\nA template change.\n' >> "$KH/os/skills/ship/SKILL.md"
  assert_exit 1 bash "$KH/tools/build/known-hashes.sh" --check
  assert_contains "$OUT" "is stale; run bash tools/build/known-hashes.sh"
  assert_exit 0 bash "$KH/tools/build/known-hashes.sh"
  KNOWN="$(cat "$KH/.company-os/known-hashes.txt")"
  assert_contains "$KNOWN" "$(sha "$KH/os/skills/ship/SKILL.md")  os/skills/ship/SKILL.md" "the new content is listed"
  assert_contains "$KNOWN" "$OLD_SHIP  os/skills/ship/SKILL.md" "earlier contents stay listed"
  assert_eq "" "$(grep -v '^#' "$KH/.company-os/known-hashes.txt" | grep -Ev '^[0-9a-f]{64}  [^ ]+$' || true)" "every line is <sha256>  <path>"
else
  echo "  note: shallow clone; known-hashes freshness is not checked here"
fi
NH="$(make_tmp)"
git archive HEAD | tar -x -C "$NH"
assert_exit 0 bash "$NH/tools/build/known-hashes.sh" --check
assert_contains "$OUT" "skipped (no git history here"

# A repository made from a release archive (one commit, no history: what
# "Use this template" produces) keeps the shipped list. Checking passes, a
# plain build leaves the file untouched, and a template change makes it stale
# until regenerated, which adds the new hash and drops none.
OC="$(make_tmp)/repo"
mkdir -p "$OC"
git archive HEAD | tar -x -C "$OC"
git -C "$OC" init -q
git -C "$OC" add -A
git -C "$OC" -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false commit -q -m "Initial commit"
assert_exit 0 bash "$OC/tools/build/build.sh" --check --strict
assert_contains "$OUT" "known-hashes: .company-os/known-hashes.txt is up to date"
assert_exit 0 bash "$OC/tools/build/build.sh"
assert_eq "" "$(git -C "$OC" status --porcelain)" "a build in a one-commit repo leaves the repository clean"
OC_OLD_SHIP="$(sha "$OC/os/skills/ship/SKILL.md")"
cp "$OC/.company-os/known-hashes.txt" "$OC/../before.txt"
printf '\nA template change.\n' >> "$OC/os/skills/ship/SKILL.md"
assert_exit 1 bash "$OC/tools/build/known-hashes.sh" --check
assert_contains "$OUT" "is stale; run bash tools/build/known-hashes.sh"
assert_exit 0 bash "$OC/tools/build/known-hashes.sh"
OC_KNOWN="$(cat "$OC/.company-os/known-hashes.txt")"
assert_contains "$OC_KNOWN" "$(sha "$OC/os/skills/ship/SKILL.md")  os/skills/ship/SKILL.md" "the new content is added"
assert_contains "$OC_KNOWN" "$OC_OLD_SHIP  os/skills/ship/SKILL.md" "the unchanged content stays listed"
assert_eq "" "$(grep -vxFf "$OC/.company-os/known-hashes.txt" "$OC/../before.txt" || true)" "no earlier entry is dropped"

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
# An unknown top-level field (a typo) is a warning, so --strict fails on it.
assert_exit 0 bash tools/build/validate-skill.sh tests/fixtures/skills/typo-field/SKILL.md
assert_contains "$OUT" "[warn] tests/fixtures/skills/typo-field/SKILL.md: unknown top-level field 'user-invocabel'"
assert_contains "$OUT" "valid with 1 warning(s)" "typo-field: exactly one warning"
assert_exit 1 bash tools/build/validate-skill.sh --strict tests/fixtures/skills/typo-field/SKILL.md
assert_exit 0 bash tools/build/validate-agent.sh tests/fixtures/agents/typo-agent.md
assert_contains "$OUT" "[warn] tests/fixtures/agents/typo-agent.md: unknown top-level field 'modle'"
assert_exit 1 bash tools/build/validate-agent.sh --strict tests/fixtures/agents/typo-agent.md
# Top-level fields Claude Code documents are accepted without a warning.
assert_exit 0 bash tools/build/validate-skill.sh --strict tests/fixtures/skills/claude-fields/SKILL.md
assert_not_contains "$OUT" "[warn]" "documented Claude Code skill fields: no warning"
assert_exit 0 bash tools/build/validate-agent.sh --strict tests/fixtures/agents/claude-agent.md
assert_not_contains "$OUT" "[warn]" "documented Claude Code agent fields: no warning"
# A legacy top-level user-invokable gets the deprecation warning only.
assert_exit 0 bash tools/build/validate-skill.sh "$B/os/skills/legacy-top/SKILL.md"
assert_contains "$OUT" "valid with 1 warning(s)" "legacy-top: deprecation warning only"

# --- Gemini and Codex builds regenerate AGENTS.md first, so a changed skill
# reaches GEMINI.md even when only that adapter is built ---
X="$(make_tmp)"
cp -R "$G/." "$X/"
sed -i.bak 's/^description: .*/description: Freshly edited ship description for the build test./' "$X/os/skills/ship/SKILL.md"
rm -f "$X/os/skills/ship/SKILL.md.bak"
assert_exit 0 bash "$X/tools/build/build.sh" --runtime=gemini
assert_contains "$(cat "$X/GEMINI.md")" "Freshly edited ship description" "build.sh --runtime=gemini picks up an os/ skill change"
sed -i.bak 's/^description: .*/description: Second edit of the ship description for the codex build./' "$X/os/skills/ship/SKILL.md"
rm -f "$X/os/skills/ship/SKILL.md.bak"
assert_exit 0 bash "$X/tools/build/build-codex.sh"
assert_contains "$(cat "$X/AGENTS.md")" "Second edit of the ship description" "build-codex.sh refreshes AGENTS.md"

# --- install-runtime.sh: names are checked before anything is built ---
I="$(make_tmp)"
cp -R "$G/." "$I/"
rm -f "$I/AGENTS.md"
assert_exit 1 bash "$I/tools/registry/install-runtime.sh" claud
assert_contains "$OUT" "Unknown runtime: claud"
assert_contains "$OUT" "claude, cursor, codex, gemini, aider"
assert_exit 1 bash "$I/tools/registry/install-runtime.sh" claude,all
assert_contains "$OUT" "'all' cannot be combined"
assert_exit 1 bash "$I/tools/registry/install-runtime.sh" agents
assert_file_missing "$I/AGENTS.md" "a rejected runtime builds nothing"
assert_exit 0 bash "$I/tools/registry/install-runtime.sh" aider
assert_file_exists "$I/AGENTS.md" "aider gets AGENTS.md"
assert_exit 0 bash "$I/tools/registry/install-runtime.sh" --help
assert_not_contains "$OUT" "does NOT touch"

finish
