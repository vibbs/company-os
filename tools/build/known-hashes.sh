#!/usr/bin/env bash
# ============================================================================
# known-hashes.sh — List every template file version Company OS has shipped
# ============================================================================
# Writes .company-os/known-hashes.txt: for each template file the installer
# manages, the sha256 of every distinct content that path has had in this
# repository's history (all commits reachable from HEAD), plus the content in
# the working tree. install.sh reads the list from the release it installs
# from. When a project has no trusted manifest (installs made before 1.12.0),
# a file whose hash is on the list for its path is an unedited copy of an
# older template, so the upgrade replaces it without saving a .user copy.
#
# Paths covered (as installed in a project): os/{agents,skills,playbooks,hooks},
# .claude/{agents,skills,hooks}, tools/<dir>/, .company-os/docs/, AGENTS.md,
# GEMINI.md, .cursorrules, .cursor/rules/, .codex/, .company-os/setup.sh
# (setup.sh at the repo root in releases before 1.12.0) and the Company OS
# section of CLAUDE.md (key CLAUDE.md#company-os: the text from
# "## Company OS Overview" to the end, as install.sh hashes it).
#
# Format: a comment header, then "<sha256>  <path>" lines sorted by path,
# then hash. No timestamp, so the same history always gives the same file.
#
# Regenerating only adds: the file becomes the union of its existing entries
# and what the available history gives, so a short history (a fork made from a
# release archive) never drops older releases. --check passes while the file
# lists every hash the available history gives; extra entries are fine.
#
# Runs only in the Company OS source repository (install.sh at the root and a
# full git history). In an installed project, a git archive or a shallow clone
# it prints why it skipped and exits 0.
#
# Usage:
#   bash tools/build/known-hashes.sh            # add new hashes to the file
#   bash tools/build/known-hashes.sh --check    # exit 1 if a hash is missing from the file
#
# Exit codes:
#   0 - written, fresh, or skipped (not the source repo, no history)
#   1 - --check found the file missing or stale, bad flag, or git error
# ============================================================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/usage.sh"
usage_help_if_requested "${BASH_SOURCE[0]}" "${1:-}"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

CHECK=false
for arg in "$@"; do
  case "$arg" in
    --check) CHECK=true ;;
    *) echo "ERROR: Unknown flag: $arg (see --help)" >&2; exit 1 ;;
  esac
done

OUT_FILE=".company-os/known-hashes.txt"

# Only the source repository has the history this list is built from. It is
# the source repo when its install.sh is the Company OS installer (it defines
# the manifest marker) and it is not itself an installed project (no
# .company-os/manifest written by that installer). A project with its own
# install.sh, or any installed project, never gets, keeps or needs the list.
MANIFEST_MARKER="manifest (hashes of the template copies)"
is_company_os_source() {
  [ -d os ] && [ -f install.sh ] \
    && grep -qF "MANIFEST_MARKER=\"$MANIFEST_MARKER\"" install.sh 2>/dev/null || return 1
  if [ -f .company-os/manifest ]; then
    case "$(head -n 1 .company-os/manifest)" in *"$MANIFEST_MARKER"*) return 1 ;; esac
  fi
  return 0
}
if ! is_company_os_source; then
  echo "known-hashes: skipped (not the Company OS source repository)"
  exit 0
fi
if ! git rev-parse --git-dir >/dev/null 2>&1 || ! git rev-parse --verify -q HEAD >/dev/null; then
  echo "known-hashes: skipped (no git history here, e.g. a release archive; $OUT_FILE is checked in the repository)"
  exit 0
fi
if [ "$(git rev-parse --is-shallow-repository 2>/dev/null || echo false)" = true ]; then
  echo "known-hashes: skipped (shallow clone; run git fetch --unshallow to build or check $OUT_FILE)"
  exit 0
fi

# The same hash install.sh's file_hash computes.
if command -v shasum >/dev/null 2>&1; then
  HASH_CMD="shasum -a 256"
elif command -v sha256sum >/dev/null 2>&1; then
  HASH_CMD="sha256sum"
else
  echo "ERROR: known-hashes needs shasum or sha256sum" >&2
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/cos-known.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

PATHSPECS="os/agents os/skills os/playbooks os/hooks .claude/agents .claude/skills .claude/hooks
tools .company-os/docs AGENTS.md GEMINI.md .cursorrules .cursor/rules .codex .company-os/setup.sh
setup.sh CLAUDE.md"

# installed_path <repo path>: where install.sh puts it; empty = not installed.
installed_path_awk='
  function installed(p) {
    if (p ~ /^tools\/[^\/]+\/./) return p          # install.sh merges tools/<dir>/ only
    if (p ~ /^tools\//) return ""
    if (p == "setup.sh") return ".company-os/setup.sh"
    if (p == "CLAUDE.md") return "CLAUDE.md#company-os"
    return p
  }'

# 1. Every (blob, path) pair in history. -m lists merge results too, so a
#    conflict resolution made in a merge commit is not missed.
# shellcheck disable=SC2086
git log -m --format= --raw --no-abbrev --no-renames HEAD -- $PATHSPECS \
  | awk -F'\t' '{ split($1, m, " "); if (m[4] !~ /^0+$/) print "blobs/" m[4] "\t" $2 }' \
  > "$TMP/pairs"

# 2. Blob contents into files named by blob id (one per distinct blob). One
#    git cat-file --batch stream, split by awk on the sizes it reports (a
#    process per blob took several seconds). Any file whose size does not
#    match (a binary blob awk cannot pass through) is rewritten directly.
mkdir -p "$TMP/blobs"
cut -f1 "$TMP/pairs" | sort -u | sed 's#^blobs/##' > "$TMP/blob-ids"
git cat-file --batch < "$TMP/blob-ids" | LC_ALL=C awk -v dir="$TMP/blobs" '
  function start(   n, h) {
    n = split($0, h, " ")
    if (n != 3 || h[2] != "blob") { file = ""; return }
    file = dir "/" h[1]; size = h[3] + 0; got = 0
    printf "" > file
    if (size == 0) { close(file); skip = 1; file = "" }
  }
  skip { skip = 0; next }                       # the newline git adds after each blob
  file == "" { start(); next }
  {
    got += length($0) + 1
    if (got == size)          { printf "%s\n", $0 > file; close(file); file = ""; skip = 1 }
    else if (got == size + 1) { printf "%s", $0 > file; close(file); file = "" }
    else                      { printf "%s\n", $0 > file }
  }'
( cd "$TMP/blobs" && find . -type f -exec wc -c {} + ) \
  | awk '$2 != "total" { sub(/^\.\//, "", $2); print $2 " " $1 }' > "$TMP/have-sizes"
git cat-file --batch-check < "$TMP/blob-ids" \
  | awk 'NR == FNR { have[$1] = $2; next } !($1 in have) || have[$1] != $3 { print $1 }' "$TMP/have-sizes" - \
  | while IFS= read -r blob; do
      git cat-file blob "$blob" > "$TMP/blobs/$blob"
    done

# 3. The working tree's tracked files, so a regenerate before committing
#    already covers the content being committed.
mkdir -p "$TMP/work"
# shellcheck disable=SC2086
git ls-files -z -- $PATHSPECS | while IFS= read -r -d '' f; do
  [ -f "$f" ] || continue
  key="work-$(printf '%s' "$f" | cksum | tr -d ' ')"
  cp "$f" "$TMP/work/$key"
  printf 'work/%s\t%s\n' "$key" "$f" >> "$TMP/pairs"
done

# 4. CLAUDE.md is hashed by its Company OS section, as install.sh does.
awk -F'\t' '$2 == "CLAUDE.md" { print $1 }' "$TMP/pairs" | sort -u | while IFS= read -r c; do
  sed -n '/## Company OS Overview/,$p' "$TMP/$c" > "$TMP/$c.section"
done

# 5. Hash every content file at once, then join hashes to installed paths.
( cd "$TMP" && find blobs work -type f -print0 | xargs -0 $HASH_CMD ) \
  | awk '{ h = $1; f = substr($0, index($0, "  ") + 2); print f "\t" h }' > "$TMP/hashes"

{
  echo "# Company OS known template hashes: sha256 of every content each template file has had."
  echo "# Generated by tools/build/known-hashes.sh from the git history; do not edit."
  awk -F'\t' "$installed_path_awk"'
    NR == FNR { hash[$1] = $2; next }
    {
      p = installed($2); if (p == "") next
      f = (p == "CLAUDE.md#company-os") ? $1 ".section" : $1
      if (!(f in hash)) next
      if (p == "CLAUDE.md#company-os" && hash[f] == EMPTY) next   # no Company OS section
      print hash[f] "  " p
    }' EMPTY="$(printf '' | $HASH_CMD | awk '{print $1}')" "$TMP/hashes" "$TMP/pairs" \
    | LC_ALL=C sort -u | LC_ALL=C sort -k2,2 -k1,1
} > "$TMP/known"

# Entries the history and working tree give, without the comment header.
grep -v '^#' "$TMP/known" > "$TMP/found" || true

if [ "$CHECK" = true ]; then
  if [ ! -f "$OUT_FILE" ]; then
    echo "known-hashes: $OUT_FILE is missing; run bash tools/build/known-hashes.sh" >&2
    exit 1
  fi
  # Fresh when the file lists everything the available history gives. Extra
  # entries (older releases a shorter history cannot show) are fine.
  grep -vxFf "$OUT_FILE" "$TMP/found" > "$TMP/missing" || true
  if [ -s "$TMP/missing" ]; then
    echo "known-hashes: $OUT_FILE is stale; run bash tools/build/known-hashes.sh and commit it" >&2
    head -5 "$TMP/missing" | sed 's/^/> /' >&2
    exit 1
  fi
  echo "known-hashes: $OUT_FILE is up to date ($(grep -vc '^#' "$OUT_FILE" || true) hashes)"
  exit 0
fi

# Regenerating only adds: the new file is the union of the entries already in
# it and the ones found now, so a short history never drops older releases.
{
  grep '^#' "$TMP/known" || true
  { grep -v '^#' "$OUT_FILE" 2>/dev/null || true; cat "$TMP/found"; } \
    | LC_ALL=C sort -u | LC_ALL=C sort -k2,2 -k1,1
} > "$TMP/merged"

mkdir -p .company-os
if [ -f "$OUT_FILE" ] && cmp -s "$TMP/merged" "$OUT_FILE"; then
  echo "known-hashes: $OUT_FILE unchanged"
else
  cp "$TMP/merged" "$OUT_FILE"
  echo "known-hashes: wrote $OUT_FILE ($(grep -vc '^#' "$OUT_FILE" || true) hashes)"
fi
