#!/usr/bin/env bash
# install.sh end to end, offline: COMPANY_OS_SOURCE points at a `git archive
# HEAD` tarball, so this tests the committed tree (commit before running).
# Covers fresh installs per runtime, upgrades (three-way merge against the
# template-hash manifest, .user doc copies, K-M8 conflict paths, copies never
# overwritten), runtime-preserving upgrades, legacy installs without a version
# stamp, --dry-run, --check and the local-source guard rails.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/assert.sh"
source "$REPO_ROOT/tests/lib/links.sh"

INSTALL="${INSTALL_UNDER_TEST:-$REPO_ROOT/install.sh}"  # override to run these tests against another installer
VERSION="$(tr -d '[:space:]' < "$REPO_ROOT/.company-os/version")"
T="$(make_tmp)"
git -C "$REPO_ROOT" archive --format=tar.gz --prefix=company-os-test/ -o "$T/src.tgz" HEAD
export COMPANY_OS_SOURCE="$T/src.tgz"

# Upgrade sources: the same tree with a newer version and template changes in a
# few files, so an upgrade has something to merge.
mkdir -p "$T/unpacked"
tar -xzf "$T/src.tgz" -C "$T/unpacked"
BASE_SRC="$T/unpacked/company-os-test"
make_next() {  # make_next <dir> <version>
  cp -R "$BASE_SRC" "$1"
  echo "$2" > "$1/.company-os/version"
  local f
  for f in .company-os/docs/FAQ.md os/agents/engineering.md .claude/agents/engineering.md os/agents/growth.md AGENTS.md; do
    printf '\ntemplate change in %s\n' "$2" >> "$1/$f"
  done
}
NEXT1="${VERSION%%.*}.98.0"   # same major: a plain upgrade must not stop at the major-upgrade prompt
NEXT2="${VERSION%%.*}.99.0"
make_next "$T/next1" "$NEXT1"
make_next "$T/next2" "$NEXT2"

sha() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}'; else sha256sum "$1" | awk '{print $1}'; fi
}
manifest_entry() {  # manifest_entry <project> <path>: the recorded hash
  awk -v f="$2" '{ i = index($0, "  "); if (i > 0 && substr($0, i + 2) == f) print substr($0, 1, i - 1) }' "$1/.company-os/manifest"
}

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
assert_contains "$OUT" "Created  AGENTS.md"
assert_contains "$OUT" "Guide: .company-os/docs/SETUP.md"
for f in .claude/skills/ship/SKILL.md .claude/agents/orchestrator.md .claude/hooks/session-start.sh \
         .claude/settings.json os/skills/ship/SKILL.md os/agents/orchestrator.md AGENTS.md CLAUDE.md \
         company.config.yaml tools/lib/config.sh tools/lib/usage.sh tools/artifact/validate.sh \
         .company-os/manifest .company-os/docs/SETUP.md .company-os/docs/SKILL_SCHEMA.md \
         standards/brand/ux-baseline.md tasks/todo.md .company-os/setup.sh; do
  assert_file_exists "$P/$f"
done
# The setup.sh fallback runs from the project root at its installed path.
assert_exit 0 bash -c 'cd "$1" && bash .company-os/setup.sh --help' _ "$P"
assert_contains "$OUT" "bash .company-os/setup.sh"
# The manifest records template hashes.
assert_eq "$(sha "$BASE_SRC/os/skills/ship/SKILL.md")" "$(manifest_entry "$P" os/skills/ship/SKILL.md)" "manifest: template hash after a fresh install"
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

# Backups and conflict copies stay out of git; adding the lines is idempotent.
assert_eq "1" "$(grep -cxF '.company-os/backup/' "$P/.gitignore" 2>/dev/null || true)" ".gitignore ignores backups"
assert_eq "1" "$(grep -cxF '.company-os/conflicts/' "$P/.gitignore" 2>/dev/null || true)" ".gitignore ignores conflict copies"

# A same-version re-run that changes nothing suggests no commit.
SETTINGS_BEFORE="$(cksum < "$P/.claude/settings.json")"
run_install "$P"
assert_contains "$OUT" "Already installed"
assert_not_contains "$OUT" "Commit the upgrade"
assert_eq "$SETTINGS_BEFORE" "$(cksum < "$P/.claude/settings.json")" "settings.json not rewritten when nothing is added"
assert_eq "1" "$(grep -cxF '.company-os/backup/' "$P/.gitignore" 2>/dev/null || true)" ".gitignore lines not duplicated"

# build.sh in an installed project rebuilds only the adapters it has.
assert_exit 0 bash -c 'cd "$1" && bash tools/build/build.sh' _ "$P"
assert_contains "$OUT" "Building the adapters this project has"
for f in .cursor .cursorrules GEMINI.md .codex; do
  assert_file_missing "$P/$f" "build.sh adds no adapter the project did not have ($f)"
done

# --- --check ---
run_install "$P" --check
assert_contains "$OUT" "Up to date — Company OS $VERSION"
E="$(new_project empty-check)"
run_install "$E" --check
assert_contains "$OUT" "Not installed — Company OS $VERSION available"
assert_eq "" "$(ls -A "$E" | grep -v '^.git$' || true)" "--check in a fresh folder writes nothing"

# --- --dry-run writes nothing on a fresh folder ---
D="$(new_project dry)"
run_install "$D" --runtime claude --dry-run
assert_contains "$OUT" "Preview — no changes will be made"
assert_eq "" "$(ls -A "$D" | grep -v '^.git$' || true)" "--dry-run on a fresh folder writes nothing"

# --- Three-way merge: an edit is kept when the template did not change the file ---
printf '\nmy local note\n' >> "$P/.company-os/docs/FAQ.md"
printf '\nmy growth edit\n' >> "$P/os/agents/growth.md"
run_install "$P" --runtime claude --force
assert_contains "$(cat "$P/os/agents/growth.md")" "my growth edit" "edit kept: template unchanged (--force)"
assert_contains "$(cat "$P/.company-os/docs/FAQ.md")" "my local note" "edited guide kept: template unchanged"
assert_file_missing "$P/.company-os/conflicts" "no conflict copies when the template did not change"
assert_file_missing "$P/.company-os/docs/FAQ.md.user"
assert_eq "$(sha "$BASE_SRC/os/agents/growth.md")" "$(manifest_entry "$P" os/agents/growth.md)" "manifest: template hash for an edited file"

# --- --force --dry-run on an upgrade changes nothing ---
BEFORE="$(tree_state "$P")"
COMPANY_OS_SOURCE="$T/next1" run_install "$P" --runtime claude --force --dry-run
assert_contains "$OUT" "Would save .company-os/docs/FAQ.md.user"
assert_contains "$OUT" ".company-os/conflicts/os/agents/growth.md.user"
assert_eq "$BEFORE" "$(tree_state "$P")" "--force --dry-run changes nothing"

# --- A plain upgrade keeps edits, and the manifest still marks them as edits ---
COMPANY_OS_SOURCE="$T/next1" run_install "$P" --runtime claude
assert_contains "$(cat "$P/os/agents/growth.md")" "my growth edit" "plain upgrade keeps the edit"
assert_not_contains "$(cat "$P/os/agents/growth.md")" "template change in $NEXT1"
assert_contains "$OUT" "Kept your edits"
assert_contains "$OUT" "os/agents/growth.md"
assert_eq "$(sha "$BASE_SRC/os/agents/growth.md")" "$(manifest_entry "$P" os/agents/growth.md)" "manifest keeps the template copy the edit is based on"
assert_eq "$(sha "$T/next1/os/agents/engineering.md")" "$(manifest_entry "$P" os/agents/engineering.md)" "manifest: new template hash for an updated file"
assert_contains "$(cat "$P/os/agents/engineering.md")" "template change in $NEXT1" "unedited file updated without --force"
# The guide is template-owned: an upgrade refreshes it and keeps yours as .user.
assert_file_exists "$P/.company-os/docs/FAQ.md.user"
assert_contains "$(cat "$P/.company-os/docs/FAQ.md.user" 2>/dev/null)" "my local note"
assert_eq "" "$(cmp "$P/.company-os/docs/FAQ.md" "$T/next1/.company-os/docs/FAQ.md" 2>&1 || echo differs)" "FAQ.md refreshed from the template"
assert_contains "$OUT" "saved as <name>.user"

# --- ...so a later --force saves the edit instead of overwriting it silently ---
COMPANY_OS_SOURCE="$T/next1" run_install "$P" --runtime claude --force
C="$P/.company-os/conflicts"
assert_contains "$(cat "$C/os/agents/growth.md.user" 2>/dev/null)" "my growth edit" "--force after a plain upgrade saves the edit"
assert_file_exists "$C/os/agents/growth.md.new"
assert_eq "" "$(cmp "$P/os/agents/growth.md" "$T/next1/os/agents/growth.md" 2>&1 || echo differs)" "conflicted file replaced by the template"
assert_contains "$OUT" "conflict(s) detected"

# --- K-M8: same-named files in different folders keep separate conflict copies.
# Conflict copies from an earlier upgrade are never overwritten. ---
printf '\nedit in os\n' >> "$P/os/agents/engineering.md"
printf '\nedit in claude\n' >> "$P/.claude/agents/engineering.md"
printf '\nsecond growth edit\n' >> "$P/os/agents/growth.md"
printf '\nsecond note\n' >> "$P/.company-os/docs/FAQ.md"
COMPANY_OS_SOURCE="$T/next2" run_install "$P" --runtime claude --force
assert_file_exists "$C/os/agents/engineering.md.user"
assert_file_exists "$C/os/agents/engineering.md.new"
assert_file_exists "$C/.claude/agents/engineering.md.user"
assert_file_exists "$C/.claude/agents/engineering.md.new"
assert_contains "$(cat "$C/os/agents/engineering.md.user" 2>/dev/null)" "edit in os"
assert_contains "$(cat "$C/.claude/agents/engineering.md.user" 2>/dev/null)" "edit in claude"
assert_not_contains "$(cat "$C/os/agents/engineering.md.user" 2>/dev/null)" "edit in claude"
assert_contains "$(cat "$C/os/agents/growth.md.user" 2>/dev/null)" "my growth edit" "first conflict copy not overwritten"
assert_not_contains "$(cat "$C/os/agents/growth.md.user" 2>/dev/null)" "second growth edit" "first conflict copy not overwritten"
assert_contains "$(cat "$C"/os/agents/growth.md.user.* 2>/dev/null)" "second growth edit" "second conflict copy gets a timestamp suffix"
assert_contains "$OUT" "Saved    .company-os/conflicts/os/agents/growth.md.user."
assert_contains "$(cat "$P/.company-os/docs/FAQ.md.user" 2>/dev/null)" "my local note" "first .user guide copy not overwritten"
assert_contains "$(cat "$P"/.company-os/docs/FAQ.md.user.* 2>/dev/null)" "second note" "second .user guide copy gets a timestamp suffix"

# --check reports an available upgrade from an older stamp.
echo "1.11.0" > "$P/.company-os/version"
run_install "$P" --check
assert_contains "$OUT" "Update available — 1.11.0 → $VERSION"

# --- An upgrade without --runtime keeps the project's adapters ---
# This machine "has" Cursor, Codex and Gemini; the project has only Claude Code.
mkdir -p "$T/home/.cursor" "$T/home/.codex" "$T/home/.gemini"
R="$(new_project runtimes)"
run_install "$R" --runtime claude
HOME="$T/home" COMPANY_OS_SOURCE="$T/next1" run_install "$R"
assert_contains "$OUT" "Runtime adapters (from this project): claude"
for f in .cursor .cursorrules GEMINI.md .codex; do
  assert_file_missing "$R/$f" "upgrade adds no adapter the project did not have ($f)"
done
assert_contains "$(cat "$R/.claude/agents/engineering.md")" "template change in $NEXT1" ".claude adapter upgraded"

# --- A symlinked template file is never written through ---
Y="$(new_project symlink)"
run_install "$Y" --runtime claude
rm -f "$Y/AGENTS.md"
ln -s CLAUDE.md "$Y/AGENTS.md"
CLAUDE_BEFORE="$(cksum < "$Y/CLAUDE.md")"
COMPANY_OS_SOURCE="$T/next1" run_install "$Y" --force
[ -L "$Y/AGENTS.md" ] || assert_eq "symlink" "regular file" "AGENTS.md is still a symlink"
assert_eq "$CLAUDE_BEFORE" "$(cksum < "$Y/CLAUDE.md")" "symlink target CLAUDE.md not overwritten"
assert_contains "$OUT" "AGENTS.md (a symlink; left as is"

# --- Stamped install without a manifest: a plain upgrade keeps edits, and the
# --force it advises then saves them (the kept file is recorded as "unknown") ---
N="$(new_project no-manifest)"
run_install "$N" --runtime claude
rm -f "$N/.company-os/manifest"
printf '\nno-manifest edit\n' >> "$N/os/agents/growth.md"
COMPANY_OS_SOURCE="$T/next1" run_install "$N"
assert_contains "$OUT" "without a manifest"
assert_contains "$(cat "$N/os/agents/growth.md")" "no-manifest edit"
assert_eq "unknown" "$(manifest_entry "$N" os/agents/growth.md)" "kept file without a known base"
COMPANY_OS_SOURCE="$T/next1" run_install "$N" --force
assert_contains "$(cat "$N/.company-os/conflicts/os/agents/growth.md.user" 2>/dev/null)" "no-manifest edit" "--force then saves the edit"
assert_contains "$(cat "$N/os/agents/growth.md")" "template change in $NEXT1" "--force then applies the template change"

# --- A manifest written by an older installer (1.4 to 1.8) hashed the files
# on disk after install, so it can record an edit as if it were the template
# copy. It is not trusted: the run takes the no-manifest path (backup, edits
# kept, .user copies on --force) ---
O="$(new_project old-manifest)"
run_install "$O" --runtime claude
printf '\nold-manifest edit\n' >> "$O/os/agents/growth.md"
printf '# Company OS v1.8.0 manifest\n# Generated: 2026-03-01T00:00:00Z\n%s  os/agents/growth.md\n' \
  "$(sha "$O/os/agents/growth.md")" > "$O/.company-os/manifest"
COMPANY_OS_SOURCE="$T/next1" run_install "$O"
assert_contains "$OUT" "manifest from an older installer"
assert_contains "$(cat "$O/os/agents/growth.md")" "old-manifest edit" "edit recorded by an old manifest is kept"
assert_eq "1" "$(ls "$O/.company-os/backup" 2>/dev/null | wc -l | tr -d ' ')" "backup taken for an old manifest"
assert_eq "unknown" "$(manifest_entry "$O" os/agents/growth.md)" "kept file recorded without a known base"
COMPANY_OS_SOURCE="$T/next1" run_install "$O" --force
assert_contains "$(cat "$O/.company-os/conflicts/os/agents/growth.md.user" 2>/dev/null)" "old-manifest edit" "--force saves the edit"
# The same for the pre-1.4 root manifest .company-os-manifest.
O2="$(new_project old-root-manifest)"
run_install "$O2" --runtime claude
rm -f "$O2/.company-os/manifest"
printf '\nroot-manifest edit\n' >> "$O2/os/agents/growth.md"
printf '# Company OS v1.3.0 manifest\n%s  os/agents/growth.md\n' "$(sha "$O2/os/agents/growth.md")" > "$O2/.company-os-manifest"
COMPANY_OS_SOURCE="$T/next1" run_install "$O2" --force
assert_contains "$(cat "$O2/.company-os/conflicts/os/agents/growth.md.user" 2>/dev/null)" "root-manifest edit" "old root manifest: --force saves the edit"

# --- Legacy install: Company OS files but no version stamp and no manifest
# (every install made from main between 1.9.0 and 1.11.x) ---
L="$(new_project legacy)"
run_install "$L" --runtime claude
rm -f "$L/.company-os/version" "$L/.company-os/manifest"
printf '\nlegacy skill edit\n' >> "$L/os/skills/ship/SKILL.md"
printf '\nlegacy tool edit\n' >> "$L/tools/artifact/validate.sh"
printf '\nlegacy faq edit\n' >> "$L/.company-os/docs/FAQ.md"
printf '\n## My notes\nkeep me\n' >> "$L/CLAUDE.md"
run_install "$L" --check
assert_contains "$OUT" "Company OS found without a version stamp"
assert_not_contains "$OUT" "Not installed"
# Without --force: a backup, a preview, and no false version stamp.
BEFORE="$(tree_state "$L" | grep -v ' ./.company-os/backup/' || true)"
run_install "$L"
assert_contains "$OUT" "without a version stamp"
assert_contains "$OUT" "Nothing was changed"
assert_contains "$OUT" ".company-os/conflicts/os/skills/ship/SKILL.md.user"
assert_file_missing "$L/.company-os/version" "no version stamp without --force"
assert_file_missing "$L/.company-os/manifest" "no manifest without --force"
assert_eq "$BEFORE" "$(tree_state "$L" | grep -v ' ./.company-os/backup/' || true)" "legacy run without --force changes no file"
assert_eq "1" "$(ls "$L/.company-os/backup" 2>/dev/null | grep -c 'legacy' || true)" "backup taken"
# With --force: backup, user copies, then the upgrade.
run_install "$L" --force
LC="$L/.company-os/conflicts"
assert_eq "2" "$(ls "$L/.company-os/backup" 2>/dev/null | grep -c 'legacy' || true)" "backup taken before the forced upgrade"
assert_contains "$(cat "$LC/os/skills/ship/SKILL.md.user" 2>/dev/null)" "legacy skill edit"
assert_contains "$(cat "$LC/tools/artifact/validate.sh.user" 2>/dev/null)" "legacy tool edit"
assert_contains "$(cat "$LC/CLAUDE.md.user" 2>/dev/null)" "keep me"
assert_contains "$(cat "$L/.company-os/docs/FAQ.md.user" 2>/dev/null)" "legacy faq edit"
assert_eq "" "$(cmp "$L/os/skills/ship/SKILL.md" "$BASE_SRC/os/skills/ship/SKILL.md" 2>&1 || echo differs)" "legacy file updated to the template"
assert_eq "$VERSION" "$(cat "$L/.company-os/version" 2>/dev/null)" "stamped after the forced upgrade"
assert_contains "$OUT" "conflict(s) detected"
assert_contains "$(ls "$L/.company-os/backup/"*legacy*/os/skills/ship/SKILL.md 2>/dev/null | head -1 | xargs cat 2>/dev/null)" "legacy skill edit" "backup holds the user's file"

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

# --runtime: every listed name must be a runtime; auto, all and core only on
# their own. A bad value stops the installer before it writes anything.
for bad in claud claude,all core,cursor claude, ""; do
  assert_exit 1 bash -c 'cd "$1" && bash "$2" --runtime "$3" </dev/null' _ "$P" "$INSTALL" "$bad"
  assert_contains "$OUT" "claude, cursor, codex, gemini, aider" "--runtime '$bad' lists the valid values"
done
assert_exit 1 bash -c 'cd "$1" && bash "$2" --runtime=claud </dev/null' _ "$P" "$INSTALL"
assert_contains "$OUT" "unknown runtime 'claud'"
assert_exit 1 bash -c 'cd "$1" && bash "$2" --runtime claude,all </dev/null' _ "$P" "$INSTALL"
assert_contains "$OUT" "'all' cannot be combined"
assert_eq "" "$(ls -A "$P" | grep -v '^.git$' || true)" "a bad --runtime writes nothing"
assert_exit 0 bash "$INSTALL" --help
assert_contains "$OUT" "Or use one of these on its own"
# Header and --help describe what an upgrade does with edited files.
assert_contains "$OUT" "Guides in .company-os/docs/ are refreshed on any version upgrade"
assert_contains "$OUT" "it as <name>.user."
assert_contains "$OUT" "without a trusted manifest"
assert_contains "$(sed -n '2,45p' "$INSTALL")" "or without --force (an edited one is saved as <name>.user)"
assert_contains "$(sed -n '2,45p' "$INSTALL")" "installs without a trusted manifest"

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
