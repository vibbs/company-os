#!/usr/bin/env bash
# Documentation integrity: relative links, images and #anchors resolve; the
# README's commands and counts match the skills, agents and tools on disk.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/assert.sh"
cd "$REPO_ROOT"

source "$REPO_ROOT/tests/lib/links.sh"
WORK="$(make_tmp)"

# --- The checker itself catches broken links (fixture) ---
FX="$(make_tmp)"
mkdir -p "$FX/sub"
printf '# Real heading\n\nok\n' > "$FX/sub/ok.md"
cat > "$FX/doc.md" <<'EOF'
# Top

[good](sub/ok.md) [good anchor](sub/ok.md#real-heading) [self](#top)
![missing image](img/none.svg) [bad](sub/nope.md) [bad anchor](sub/ok.md#nope)
[web](https://example.com) `[code](not/checked.md)`

```
[fenced](not/checked/either.md)
```
EOF
FX_OUT="$(check_links "$FX/doc.md")"
assert_eq "3" "$(printf '%s\n' "$FX_OUT" | grep -c '^BROKEN')" "fixture: exactly the three bad links are reported"
assert_contains "$FX_OUT" "img/none.svg"
assert_contains "$FX_OUT" "sub/nope.md"
assert_contains "$FX_OUT" "no heading for #nope"

# --- Every relative link in the docs resolves ---
DOCS="README.md CLAUDE.md $(find os .company-os/docs docs -name '*.md' -type f | sort | tr '\n' ' ')"
# shellcheck disable=SC2086
BROKEN="$(check_links $DOCS)"
assert_eq "" "$BROKEN" "broken links in docs"
LINK_COUNT="$(for f in $DOCS; do awk -f "$LINKS_AWK_DIR/links.awk" "$f"; done | grep -cv 'https\{0,1\}://' || true)"
if [ "$LINK_COUNT" -lt 50 ]; then
  assert_eq "at least 50" "$LINK_COUNT" "relative links found (the extractor may be broken)"
fi

# --- Skills on disk ---
SKILL_COUNT="$(find os/skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
AGENT_COUNT="$(find os/agents -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')"
TOOL_COUNT="$(find tools -name '*.sh' -type f -not -path 'tools/build/*' -not -path 'tools/lib/*' | wc -l | tr -d ' ')"

# Skills with runtimes.claude.user-invocable: true (or the legacy spelling,
# or the field at the top level).
invocable_skills() {
  local f
  for f in os/skills/*/SKILL.md; do
    if awk '
      { sub(/\r$/, "") }
      /^---[ \t]*$/ { c++; next }
      c != 1 { next }
      /^[^ \t#]/ { rt = ($0 ~ /^runtimes[ \t]*:/); cl = 0 }
      rt && /^  [^ \t#]/ { cl = ($0 ~ /^  claude[ \t]*:/) }
      /^user-invo[ck]able[ \t]*:[ \t]*true/ { found = 1 }
      rt && cl && /^    user-invo[ck]able[ \t]*:[ \t]*true/ { found = 1 }
      END { exit !found }
    ' "$f"; then
      basename "$(dirname "$f")"
    fi
  done
}
INVOCABLE="$(invocable_skills | sort)"
INVOCABLE_COUNT="$(printf '%s\n' "$INVOCABLE" | grep -c . || true)"

# --- README Commands table lists exactly the user-invocable skills ---
COMMANDS_SECTION="$(awk '/^## Commands/ { on = 1; next } on && /^## / { exit } on' README.md)"
TABLE_CMDS="$(printf '%s\n' "$COMMANDS_SECTION" | sed -n 's/^| `\/\([a-z0-9-]*\)`.*/\1/p' | sort)"
printf '%s\n' "$INVOCABLE" > "$WORK/invocable.txt"
printf '%s\n' "$TABLE_CMDS" > "$WORK/table.txt"
assert_eq "" "$(comm -23 "$WORK/invocable.txt" "$WORK/table.txt" | tr '\n' ' ')" "user-invocable skills missing from the README Commands table"
assert_eq "" "$(comm -13 "$WORK/invocable.txt" "$WORK/table.txt" | tr '\n' ' ')" "README Commands table rows that are not user-invocable skills"
assert_eq "46" "$INVOCABLE_COUNT" "user-invocable skills (update README counts if this changed)"
assert_eq "" "$(printf '%s\n' "$TABLE_CMDS" | uniq -d)" "README Commands table has no duplicates"

# Each <summary> count matches the rows in its table.
SECTION_MISMATCH="$(printf '%s\n' "$COMMANDS_SECTION" | awk '
  /<summary>/ { if (title != "" && rows != want) print title ": says " want ", has " rows
                title = $0; sub(/.*<strong>/, "", title); sub(/<\/strong>.*/, "", title)
                want = $0; sub(/.*\(/, "", want); sub(/\).*/, "", want); rows = 0 }
  /^\| `\// { rows++ }
  END { if (title != "" && rows != want) print title ": says " want ", has " rows }
')"
assert_eq "" "$SECTION_MISMATCH" "README Commands section counts"

# --- Every /command mentioned in README is a real skill ---
UNKNOWN=""
for cmd in $(grep -o '`/[a-z][a-z0-9-]*[` ]' README.md | sed 's/^`\///; s/[` ]$//' | sort -u); do
  [ "$cmd" = "name" ] && continue  # placeholder in the glossary ("run it as /name")
  [ -d "os/skills/$cmd" ] || UNKNOWN="$UNKNOWN /$cmd"
done
assert_eq "" "$UNKNOWN" "README mentions commands with no matching skill"

# --- Counts in README match the filesystem ---
assert_eq "64" "$SKILL_COUNT" "skills in os/skills (update README and docs if this changed)"
assert_eq "9" "$AGENT_COUNT" "agents in os/agents"
assert_eq "33" "$TOOL_COUNT" "runnable tool scripts"
README="$(cat README.md)"
assert_contains "$README" "There are $SKILL_COUNT skills in total. The $INVOCABLE_COUNT below are meant to be run directly; the other $((SKILL_COUNT - INVOCABLE_COUNT)) are used by agents"
assert_contains "$README" "All $INVOCABLE_COUNT commands are listed"
assert_contains "$README" "\`os/agents/\` ($AGENT_COUNT agents)"
assert_contains "$README" "\`os/skills/\` ($SKILL_COUNT skills)"
assert_contains "$README" "\`tools/\` ($TOOL_COUNT scripts)"

# CONTRIBUTING tells a PR author how to fix a stale known-hashes.txt.
CONTRIB="$(cat CONTRIBUTING.md)"
assert_contains "$CONTRIB" "If CI reports \`known-hashes.txt\` as stale"
assert_contains "$CONTRIB" "bash tools/build/known-hashes.sh"

finish
