#!/usr/bin/env bash
# install.sh end to end, offline: COMPANY_OS_SOURCE points at a `git archive
# HEAD` tarball, so this tests the committed tree (commit before running).
# Covers fresh installs per runtime, upgrades (.user doc copies, K-M8
# conflict paths), --dry-run, --check and the local-source guard rails.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/assert.sh"
source "$REPO_ROOT/tests/lib/links.sh"

INSTALL="$REPO_ROOT/install.sh"
VERSION="$(tr -d '[:space:]' < "$REPO_ROOT/.company-os/version")"
T="$(make_tmp)"
git -C "$REPO_ROOT" archive --format=tar.gz --prefix=company-os-test/ -o "$T/src.tgz" HEAD
export COMPANY_OS_SOURCE="$T/src.tgz"

new_project() {  # new_project <name>: an empty git repo
  mkdir -p "$T/$1"
  git -C "$T/$1" init -q
  echo "$T/$1"
}

run_install() {  # run_install <dir> [flags...]: sets OUT and RC
  local dir="$1"
  shift
  assert_exit 0 bash -c 'cd "$1" && shift && bash "$@" </dev/null' _ "$dir" "$INSTALL" "$@"
}

# tree_state <dir>: a listing that changes when any file is added, removed
# or edited (dry runs must leave it alone).
tree_state() {
  (cd "$1" && find . -path ./.git -prune -o -type f -print | sort | while IFS= read -r f; do
    printf '%s %s\n' "$(cksum < "$f" | tr -d ' ')" "$f"
  done)
}

# --- Fresh install: Claude Code ---
P="$(new_project claude)"
run_install "$P" --runtime claude
assert_contains "$OUT" "Using local archive (COMPANY_OS_SOURCE): $T/src.tgz"
assert_not_contains "$OUT" "Downloading from github.com"
for f in .claude/skills/ship/SKILL.md .claude/agents/orchestrator.md .claude/hooks/session-start.sh \
         .claude/settings.json os/skills/ship/SKILL.md os/agents/orchestrator.md AGENTS.md CLAUDE.md \
         company.config.yaml tools/lib/config.sh tools/lib/usage.sh tools/artifact/validate.sh \
         .company-os/manifest .company-os/docs/SETUP.md .company-os/docs/SKILL_SCHEMA.md \
         standards/brand/ux-baseline.md tasks/todo.md; do
  assert_file_exists "$P/$f"
done
assert_eq "$VERSION" "$(cat "$P/.company-os/version")" "installed version stamp"
assert_eq "8" "$(ls "$P/.company-os/docs/diagrams/"*.svg | wc -l | tr -d ' ')" "installed diagrams"
assert_eq "$(ls "$REPO_ROOT/standards/brand/archetypes" | wc -l | tr -d ' ')" \
  "$(ls "$P/standards/brand/archetypes" | wc -l | tr -d ' ')" "installed design archetypes"
for f in .cursor .cursorrules GEMINI.md .codex VERSION tests; do
  assert_file_missing "$P/$f"
done
assert_contains "$(grep '^user-invocable:' "$P/.claude/skills/ship/SKILL.md")" "user-invocable: true" "installed skill has lifted fields"
[ -x "$P/tools/artifact/validate.sh" ] || assert_eq "executable" "not executable" "tools/artifact/validate.sh mode"
assert_exit 0 bash -c 'cd "$1" && bash tools/build/build.sh --check' _ "$P"

# Links inside the installed guides resolve within the installed project.
DOCS_BROKEN="$(LINKS_ROOT="$P" check_links $(find "$P/.company-os/docs" -name '*.md' | sort))"
assert_eq "" "$DOCS_BROKEN" "broken links in installed .company-os/docs"

# --- --check ---
run_install "$P" --check
assert_contains "$OUT" "Up to date — Company OS $VERSION"
E="$(new_project empty-check)"
run_install "$E" --check
assert_contains "$OUT" "Not installed — Company OS $VERSION available"
assert_eq "" "$(ls -A "$E" | grep -v '^.git$' || true)" "--check in a fresh folder writes nothing"

# --- --dry-run writes nothing (fresh folder and upgrade) ---
D="$(new_project dry)"
run_install "$D" --runtime claude --dry-run
assert_contains "$OUT" "Preview — no changes will be made"
assert_eq "" "$(ls -A "$D" | grep -v '^.git$' || true)" "--dry-run on a fresh folder writes nothing"
printf '\nmy local note\n' >> "$P/.company-os/docs/FAQ.md"
BEFORE="$(tree_state "$P")"
run_install "$P" --runtime claude --force --dry-run
assert_contains "$OUT" "Would save .company-os/docs/FAQ.md.user"
assert_eq "$BEFORE" "$(tree_state "$P")" "--force --dry-run changes nothing"

# --- Upgrade keeps an edited guide as .user and refreshes the doc ---
run_install "$P" --runtime claude --force
assert_file_exists "$P/.company-os/docs/FAQ.md.user"
assert_contains "$(cat "$P/.company-os/docs/FAQ.md.user")" "my local note"
assert_eq "" "$(cmp "$P/.company-os/docs/FAQ.md" "$REPO_ROOT/.company-os/docs/FAQ.md" 2>&1 || echo differs)" "FAQ.md refreshed from the template"
assert_contains "$OUT" "saved as <name>.user"

# --- K-M8: same-named files in different folders keep separate conflict copies ---
printf '\nedit in os\n' >> "$P/os/agents/engineering.md"
printf '\nedit in claude\n' >> "$P/.claude/agents/engineering.md"
run_install "$P" --runtime claude --force
C="$P/.company-os/conflicts"
assert_file_exists "$C/os/agents/engineering.md.user"
assert_file_exists "$C/os/agents/engineering.md.new"
assert_file_exists "$C/.claude/agents/engineering.md.user"
assert_file_exists "$C/.claude/agents/engineering.md.new"
assert_contains "$(cat "$C/os/agents/engineering.md.user" 2>/dev/null)" "edit in os"
assert_contains "$(cat "$C/.claude/agents/engineering.md.user" 2>/dev/null)" "edit in claude"
assert_not_contains "$(cat "$C/os/agents/engineering.md.user" 2>/dev/null)" "edit in claude"
assert_eq "" "$(cmp "$P/os/agents/engineering.md" "$REPO_ROOT/os/agents/engineering.md" 2>&1 || echo differs)" "conflicted file replaced by the template"
assert_contains "$OUT" "conflict(s) detected"

# --check reports an available upgrade from an older stamp.
echo "1.11.0" > "$P/.company-os/version"
run_install "$P" --check
assert_contains "$OUT" "Update available — 1.11.0 → $VERSION"

# --- Fresh install: Cursor ---
P="$(new_project cursor)"
run_install "$P" --runtime cursor
assert_file_exists "$P/.cursor/rules/00-company-os.mdc"
assert_file_exists "$P/.cursor/rules/10-skills.mdc"
assert_file_exists "$P/.cursorrules"
assert_file_exists "$P/AGENTS.md"
assert_file_exists "$P/os/skills/ship/SKILL.md"
assert_file_exists "$P/tools/lib/config.sh"
assert_file_exists "$P/.company-os/docs/diagrams/system-overview.svg"
assert_file_missing "$P/.claude"
assert_file_missing "$P/GEMINI.md"

# --- Fresh install: core only, from an archive without a top-level folder ---
git -C "$REPO_ROOT" archive --format=tar.gz -o "$T/flat.tgz" HEAD
P="$(new_project core)"
COMPANY_OS_SOURCE="$T/flat.tgz" run_install "$P" --runtime core
assert_contains "$OUT" "Using local archive"
for f in AGENTS.md CLAUDE.md company.config.yaml os/skills/ship/SKILL.md tools/lib/usage.sh \
         .company-os/docs/diagrams/system-overview.svg standards/brand/ux-baseline.md; do
  assert_file_exists "$P/$f"
done
for f in .claude .cursor .cursorrules GEMINI.md .codex; do
  assert_file_missing "$P/$f"
done

# --- A checkout folder works as a source too ---
mkdir -p "$T/unpacked"
tar -xzf "$T/src.tgz" -C "$T/unpacked"
P="$(new_project from-dir)"
COMPANY_OS_SOURCE="$T/unpacked/company-os-test" run_install "$P" --runtime core
assert_contains "$OUT" "Using local source (COMPANY_OS_SOURCE): $T/unpacked/company-os-test"
assert_file_exists "$P/os/skills/ship/SKILL.md"

# --- Guard rails ---
P="$(new_project guard)"
assert_exit 1 bash -c 'cd "$1" && COMPANY_OS_SOURCE="$2" bash "$3" --runtime core </dev/null' _ "$P" "$T/missing.tgz" "$INSTALL"
assert_contains "$OUT" "COMPANY_OS_SOURCE not found"
mkdir -p "$T/not-company-os"
assert_exit 1 bash -c 'cd "$1" && COMPANY_OS_SOURCE="$2" bash "$3" --runtime core </dev/null' _ "$P" "$T/not-company-os" "$INSTALL"
assert_contains "$OUT" "does not look like Company OS"
assert_exit 1 bash -c 'cd "$1" && COMPANY_OS_SOURCE="$1" bash "$2" --runtime core </dev/null' _ "$T/unpacked/company-os-test" "$INSTALL"
assert_contains "$OUT" "points at this directory"
assert_eq "" "$(ls -A "$P" | grep -v '^.git$' || true)" "failed local installs write nothing"

# An empty COMPANY_OS_SOURCE is ignored: the installer goes to GitHub. A fake
# curl that always fails stands in for the network.
mkdir -p "$T/fakebin"
printf '#!/bin/sh\necho "$*" >> "%s/curl.log"\nexit 22\n' "$T" > "$T/fakebin/curl"
chmod +x "$T/fakebin/curl"
assert_exit 1 bash -c 'cd "$1" && PATH="$2:$PATH" COMPANY_OS_SOURCE= bash "$3" --runtime core </dev/null' _ "$P" "$T/fakebin" "$INSTALL"
assert_contains "$OUT" "Downloading from github.com"
assert_contains "$OUT" "Error: Download failed: https://github.com/"
assert_not_contains "$OUT" "Using local"
assert_contains "$(cat "$T/curl.log" 2>/dev/null)" "github.com"

finish
