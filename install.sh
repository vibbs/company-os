#!/usr/bin/env bash
# ============================================================================
# Company OS — Installer & Upgrader (Smart Merge + Version Tracking)
# ============================================================================
# Downloads and installs Company OS overlay files into any project.
# Smart-merges with existing Claude Code setups — preserves user permissions,
# custom agents/skills, and project-specific CLAUDE.md content.
#
# Merges each template file three ways against a manifest of template hashes:
# files you did not edit are updated, files you edited are kept (with --force,
# replaced after your copy is saved under .company-os/conflicts/). Guides in
# .company-os/docs/ belong to the template: a version upgrade refreshes them
# and saves an edited one next to it as <name>.user.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh | bash -s -- --force
#   curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh | bash -s -- --runtime claude,cursor
#
# Flags:
#   --runtime    Runtimes to install adapters for: auto, all or core on its
#                own, or a comma-separated list of claude, cursor, codex,
#                gemini, aider (e.g. claude,cursor). Any other value stops the
#                installer before it writes anything.
#                Default: auto on a fresh install; on an upgrade, the adapters
#                the project already has.
#   --force      Also update files you edited (your copies are saved under
#                .company-os/conflicts/); default: keep them. Guides in
#                .company-os/docs/ are refreshed on any version upgrade, with
#                or without --force (an edited one is saved as <name>.user)
#   --branch     Use a specific branch (default: main)
#   --version    Install a specific version (e.g., --version 1.2.0)
#   --dry-run    Preview what would change without applying
#   --check      Check if an upgrade is available (compares with the install here)
#   --changelog  Show changelog since installed version
#   --backup     Create backup before upgrading (automatic for major upgrades
#                and for installs without a trusted manifest: none, or one
#                written by an installer before 1.12.0)
#   --help       Show this help message
#
# Environment:
#   COMPANY_OS_SOURCE  Path to a Company OS checkout or .tar.gz to install from
#                      instead of GitHub (offline installs, tests). Unset = download.
#
# Docs: https://github.com/vibbs/company-os#readme
# ============================================================================

set -euo pipefail

# --- Configuration ---
REPO="vibbs/company-os"
BRANCH="main"
FORCE=false
DRY_RUN=false
CHECK_ONLY=false
SHOW_CHANGELOG=false
BACKUP=false
TARGET_VERSION=""
RUNTIME_SPEC=""        # raw value passed to --runtime; resolved below
RUNTIME_GIVEN=false

# --- Parse flags ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)         FORCE=true; shift ;;
    --branch)        [[ $# -ge 2 ]] || { echo "ERROR: --branch requires a value" >&2; exit 1; }; BRANCH="$2"; shift 2 ;;
    --version)       [[ $# -ge 2 ]] || { echo "ERROR: --version requires a value" >&2; exit 1; }; TARGET_VERSION="$2"; shift 2 ;;
    --dry-run)       DRY_RUN=true; shift ;;
    --check)         CHECK_ONLY=true; shift ;;
    --changelog)     SHOW_CHANGELOG=true; shift ;;
    --backup)        BACKUP=true; shift ;;
    --runtime=*)     RUNTIME_SPEC="${1#*=}"; RUNTIME_GIVEN=true; shift ;;
    --runtime)       [[ $# -ge 2 ]] || { echo "ERROR: --runtime requires a value" >&2; exit 1; }; RUNTIME_SPEC="$2"; RUNTIME_GIVEN=true; shift 2 ;;
    --help|-h)
      cat <<HELP
Company OS installer and upgrader

Usage:
  curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash
  curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash -s -- [flags]
  bash install.sh [flags]            (after downloading the script to review it)

Flags:
  --runtime <names>  Runtimes to install adapters for. Default: auto on a fresh
                     install; on an upgrade, the adapters the project already has.
                     Names: claude | cursor | codex | gemini | aider
                     Combine names with commas: --runtime claude,cursor (or --runtime=claude,cursor)
                     Or use one of these on its own (not in a list):
                       auto  → detect installed agent CLIs/dirs and install for those
                       all   → install every adapter
                       core  → shared files only (os/, tools/, AGENTS.md, CLAUDE.md, config);
                               no runtime-specific adapter
                     Any other value is an error; nothing is written.
  --force            Also update Company OS files you edited; your copies are saved
                     under .company-os/conflicts/ (config and artifacts are never
                     touched). Without it, files you edited are kept.
                     Guides in .company-os/docs/ are refreshed on any version upgrade,
                     with or without --force: an edited guide is first saved next to
                     it as <name>.user.
  --branch <name>    Use a specific branch (default: main)
  --version <X.Y.Z>  Install a specific release, e.g. --version 1.12.0
  --dry-run          Preview what would change without writing anything
  --check            Check whether an upgrade is available
  --changelog        Show the changelog since the installed version
  --backup           Back up Company OS files before upgrading (automatic for major
                     upgrades and for installs without a trusted manifest: none, or
                     one written by an installer before 1.12.0)
  -h, --help         Show this help

Environment:
  COMPANY_OS_SOURCE  Install from a local checkout or .tar.gz instead of GitHub
                     (offline or air-gapped installs, tests). When unset or
                     empty, the installer downloads from GitHub as usual.

--check and --changelog compare against the Company OS install in the current
directory, so run them from an existing install. In a fresh directory --check
only reports the latest version and --changelog prints the full changelog.

Examples:
  # Install for whatever runtimes are detected
  curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash

  # Install for Claude Code and Cursor only
  curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash -s -- --runtime claude,cursor

  # Pin a release
  curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash -s -- --version 1.12.0

  # Preview an upgrade, then apply it
  curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash -s -- --force --dry-run
  curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash -s -- --force

Docs: https://github.com/$REPO#readme
Setup guide (after install): .company-os/docs/SETUP.md
HELP
      exit 0
      ;;
    *) echo "ERROR: Unknown flag: $1" >&2; echo "Run with --help for usage." >&2; exit 1 ;;
  esac
done

# --- Validate --runtime before anything else runs ---
# auto, all and core are valid only as the whole value; a comma-separated list
# may hold only concrete runtime names. RUNTIME_LIST is the validated list.
runtime_spec_error() {
  echo "ERROR: $1" >&2
  echo "Valid --runtime values: auto, all or core on its own, or a comma-separated list of" >&2
  echo "claude, cursor, codex, gemini, aider (e.g. --runtime claude,cursor)." >&2
  exit 1
}
RUNTIME_LIST=""
if [ "$RUNTIME_GIVEN" = true ]; then
  case "$RUNTIME_SPEC" in
    auto|all|core) ;;
    "") runtime_spec_error "--runtime requires a value" ;;
    *)
      rest="$RUNTIME_SPEC,"
      while [ -n "$rest" ]; do
        name="${rest%%,*}"
        rest="${rest#*,}"
        case "$name" in
          claude|cursor|codex|gemini|aider) RUNTIME_LIST="$RUNTIME_LIST $name" ;;
          "") runtime_spec_error "empty runtime name in --runtime $RUNTIME_SPEC" ;;
          auto|all|core) runtime_spec_error "'$name' cannot be combined with other names; use --runtime $name on its own" ;;
          *) runtime_spec_error "unknown runtime '$name' in --runtime $RUNTIME_SPEC" ;;
        esac
      done
      ;;
  esac
fi

# --- Existing install in this directory ---
# Read before choosing runtimes: an upgrade keeps the adapters the project has.
LOCAL_VERSION="unknown"
if [ -f ".company-os/version" ]; then
  LOCAL_VERSION=$(tr -d '[:space:]' < .company-os/version)
elif [ -f ".company-os-version" ]; then
  LOCAL_VERSION=$(tr -d '[:space:]' < .company-os-version)
fi
[ -n "$LOCAL_VERSION" ] || LOCAL_VERSION="unknown"

# The manifest from the last install (read-only during this run). Only a
# manifest with "<hash>  <path>" lines whose first line carries
# MANIFEST_MARKER counts. Installers before 1.12.0 wrote manifests
# without it that hashed the files on disk after install, user edits
# included, so such a manifest can make an edit look unedited. It is not
# used as a merge base: the run takes the no-manifest path instead.
MANIFEST_MARKER="manifest (hashes of the template copies)"
MANIFEST_FILE=""
OLD_MANIFEST=""
for m in .company-os/manifest .company-os-manifest; do
  if [ -f "$m" ] && grep -Eq '^[0-9a-f]{8,}  ' "$m" 2>/dev/null; then
    case "$(head -n 1 "$m")" in
      *"$MANIFEST_MARKER"*) MANIFEST_FILE="$m"; break ;;
    esac
    [ -n "$OLD_MANIFEST" ] || OLD_MANIFEST="$m"
  fi
done
[ -z "$MANIFEST_FILE" ] || OLD_MANIFEST=""

# Company OS files present (any version, stamped or not)?
COS_PRESENT=false
if [ -d "os/skills" ] || [ -f "tools/artifact/validate.sh" ] || [ -d ".company-os/docs" ] \
   || [ -f ".claude/skills/ship/SKILL.md" ] || [ -f ".claude/agents/orchestrator.md" ] \
   || { [ -f "CLAUDE.md" ] && grep -q "## Company OS Overview" CLAUDE.md 2>/dev/null; }; then
  COS_PRESENT=true
fi

# Upgrading an install that has no usable manifest: nothing tells us which
# files the user edited, so every file that differs is treated as edited and a
# backup is always taken. LEGACY = the same with no version stamp either (every
# install made from main between 1.9.0 and 1.11.x).
NO_MANIFEST_UPGRADE=false
LEGACY=false
if [ "$COS_PRESENT" = true ] && [ -z "$MANIFEST_FILE" ]; then
  NO_MANIFEST_UPGRADE=true
  if [ "$LOCAL_VERSION" = "unknown" ]; then LEGACY=true; fi
fi
IS_EXISTING_INSTALL=false
if [ "$LOCAL_VERSION" != "unknown" ] || [ -n "$MANIFEST_FILE" ] || [ "$COS_PRESENT" = true ]; then
  IS_EXISTING_INSTALL=true
fi

# Best-effort version of an unstamped install (display and backup label only).
detect_legacy_version() {
  local f v=""
  for f in .company-os/docs/CHANGELOG.md CHANGELOG.md; do
    [ -f "$f" ] || continue
    if [ "$f" = "CHANGELOG.md" ] && ! grep -q "Company OS" "$f" 2>/dev/null; then continue; fi
    v=$(grep -E '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' "$f" 2>/dev/null | head -1 | sed -E 's/^## \[([^]]*)\].*/\1/' || true)
    if [ -n "$v" ]; then echo "$v"; return; fi
  done
  if [ -f "VERSION" ]; then
    v=$(tr -d '[:space:]' < VERSION)
    if echo "$v" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then echo "$v"; return; fi
  fi
  echo "unknown"
}
LEGACY_VERSION=""
if [ "$LEGACY" = true ]; then LEGACY_VERSION=$(detect_legacy_version); fi

# --- Runtime selection ---
# RUNTIMES is a space-separated whitelist used by should_install_runtime().
# Always-on universal AGENTS.md is governed by INSTALL_AGENTS_MD (true unless
# RUNTIME_SPEC explicitly excludes it via "core" pruning — currently no path
# does, so AGENTS.md is always installed).
INSTALL_AGENTS_MD=true

# Adapters already in this project (used for upgrades without --runtime).
detect_project_runtimes() {
  local out=""
  if [ -d ".claude" ]; then out="$out claude"; fi
  if [ -d ".cursor" ] || [ -f ".cursorrules" ]; then out="$out cursor"; fi
  if [ -d ".codex" ]; then out="$out codex"; fi
  if [ -f "GEMINI.md" ]; then out="$out gemini"; fi
  echo "$out"
}

detect_local_runtimes() {
  local out=""
  if command -v claude >/dev/null 2>&1 || [ -d "$HOME/.claude" ]; then out="$out claude"; fi
  if command -v cursor >/dev/null 2>&1 || [ -d "$HOME/.cursor" ] || [ -d "$HOME/Library/Application Support/Cursor" ]; then out="$out cursor"; fi
  if command -v codex >/dev/null 2>&1 || [ -d "$HOME/.codex" ]; then out="$out codex"; fi
  if command -v gemini >/dev/null 2>&1 || [ -d "$HOME/.gemini" ]; then out="$out gemini"; fi
  if command -v aider >/dev/null 2>&1; then out="$out aider"; fi
  echo "$out"
}

case "${RUNTIME_SPEC:-}" in
  "")
    if [ "$IS_EXISTING_INSTALL" = true ]; then
      # Upgrade: keep the project's adapters, whatever this machine has installed.
      RUNTIMES="$(detect_project_runtimes)"
      RUNTIME_MODE="from this project"
    else
      RUNTIMES="$(detect_local_runtimes)"
      RUNTIME_MODE="auto"
    fi
    ;;
  auto)
    RUNTIMES="$(detect_local_runtimes)"
    if [ -z "$RUNTIMES" ]; then
      # No agent CLI detected — install only the universal AGENTS.md story.
      RUNTIMES=""
    fi
    RUNTIME_MODE="auto"
    ;;
  all)
    RUNTIMES="claude cursor codex gemini aider"
    RUNTIME_MODE="all"
    ;;
  core)
    RUNTIMES=""
    RUNTIME_MODE="core"
    ;;
  *)
    # Comma-separated list of runtime names (validated above)
    RUNTIMES="$RUNTIME_LIST"
    RUNTIME_MODE="custom"
    ;;
esac

should_install_runtime() {
  local r="$1"
  case " $RUNTIMES " in
    *" $r "*) return 0 ;;
    *)        return 1 ;;
  esac
}

# --- Colors ---
if [ -t 1 ]; then
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  RED='\033[0;31m'
  BLUE='\033[0;34m'
  BOLD='\033[1m'
  DIM='\033[2m'
  NC='\033[0m'
else
  GREEN='' YELLOW='' RED='' BLUE='' BOLD='' DIM='' NC=''
fi

# --- Counters ---
CREATED=0
ADDED=0
SKIPPED=0
UPDATED=0
MERGED=0
CONFLICTS=0
KEPT_EDITS=0

# ============================================================================
# Version Comparison Functions
# ============================================================================

# Parse semver into components. Usage: parse_semver "1.2.3" → sets SEMVER_MAJOR, SEMVER_MINOR, SEMVER_PATCH
parse_semver() {
  local version="$1"
  SEMVER_MAJOR="${version%%.*}"
  local rest="${version#*.}"
  SEMVER_MINOR="${rest%%.*}"
  SEMVER_PATCH="${rest#*.}"
}

# Compare two semver strings. Returns 0 if $1 > $2, 1 otherwise.
version_gt() {
  local v1="$1" v2="$2"

  parse_semver "$v1"
  local v1_major="$SEMVER_MAJOR" v1_minor="$SEMVER_MINOR" v1_patch="$SEMVER_PATCH"

  parse_semver "$v2"
  local v2_major="$SEMVER_MAJOR" v2_minor="$SEMVER_MINOR" v2_patch="$SEMVER_PATCH"

  if [ "$v1_major" -gt "$v2_major" ] 2>/dev/null; then return 0; fi
  if [ "$v1_major" -lt "$v2_major" ] 2>/dev/null; then return 1; fi
  if [ "$v1_minor" -gt "$v2_minor" ] 2>/dev/null; then return 0; fi
  if [ "$v1_minor" -lt "$v2_minor" ] 2>/dev/null; then return 1; fi
  if [ "$v1_patch" -gt "$v2_patch" ] 2>/dev/null; then return 0; fi
  return 1
}

# Check if this is a major version upgrade
is_major_upgrade() {
  local from="$1" to="$2"
  if [ "$from" = "unknown" ]; then return 1; fi
  parse_semver "$from"
  local from_major="$SEMVER_MAJOR"
  parse_semver "$to"
  local to_major="$SEMVER_MAJOR"
  [ "$to_major" -gt "$from_major" ] 2>/dev/null
}

# Describe the upgrade type
upgrade_type() {
  local from="$1" to="$2"
  if [ "$from" = "unknown" ]; then echo "install"; return; fi
  if [ "$from" = "$to" ]; then echo "up-to-date"; return; fi

  parse_semver "$from"
  local from_major="$SEMVER_MAJOR" from_minor="$SEMVER_MINOR"
  parse_semver "$to"
  local to_major="$SEMVER_MAJOR" to_minor="$SEMVER_MINOR"

  if [ "$to_major" -gt "$from_major" ] 2>/dev/null; then echo "MAJOR"; return; fi
  if [ "$to_minor" -gt "$from_minor" ] 2>/dev/null; then echo "minor"; return; fi
  echo "patch"
}

# ============================================================================
# Manifest Functions
# ============================================================================

# Compute SHA256 hash of a file (cross-platform)
if command -v shasum &>/dev/null; then
  HASH_CMD="shasum -a 256"
elif command -v sha256sum &>/dev/null; then
  HASH_CMD="sha256sum"
else
  HASH_CMD="cksum"   # fallback when neither sha tool is available
fi
file_hash() {
  $HASH_CMD "$1" 2>/dev/null | awk '{print $1}'
}

# Read a path's hash from the previous manifest (exact path match). Prints
# nothing when the path is not recorded or there is no manifest.
manifest_hash() {
  [ -n "$MANIFEST_FILE" ] || return 0
  awk -v f="$1" '
    /^#/ { next }
    { i = index($0, "  "); if (i > 0 && substr($0, i + 2) == f) { print substr($0, 1, i - 1); exit } }
  ' "$MANIFEST_FILE"
}

# The new manifest records, for every template-owned file, the hash of the
# TEMPLATE copy that file is based on, never the hash of whatever is on disk.
# A file the user edited therefore still reads as edited on the next upgrade.
# A kept file with no known template copy is recorded as "unknown".
# Lines are collected in $MANIFEST_NEW during the run (see record_manifest).
record_manifest() {  # record_manifest <hash> <path>
  echo "$1  $2" >> "$MANIFEST_NEW"
}

# Write .company-os/manifest from the recorded lines. Entries of the old
# manifest that this run did not touch (for example an adapter left out with
# --runtime) are kept when the file still exists and is a template file.
# When only the "# Generated:" line would change, the file is left as it is,
# so a re-run that changes nothing leaves git status clean.
generate_manifest() {
  local version="$1" tmp=".company-os/manifest.tmp" path
  mkdir -p .company-os
  {
    echo "# Company OS v$version $MANIFEST_MARKER"
    echo "# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    awk '!seen[substr($0, index($0, "  ") + 2)]++' "$MANIFEST_NEW"
    if [ -n "$MANIFEST_FILE" ]; then
      awk 'NR == FNR { done[substr($0, index($0, "  ") + 2)] = 1; next }
           /^#/ { next }
           { i = index($0, "  "); if (i > 0 && !(substr($0, i + 2) in done)) print }' \
        "$MANIFEST_NEW" "$MANIFEST_FILE" | while IFS= read -r line; do
          path="${line#*  }"
          if [ -f "$path" ] && [ -f "$SRC/$path" ]; then echo "$line"; fi
        done
    fi
  } > "$tmp"
  if [ -f .company-os/manifest ] \
     && [ "$(grep -v '^# Generated: ' .company-os/manifest || true)" = "$(grep -v '^# Generated: ' "$tmp" || true)" ]; then
    rm -f "$tmp"
    return
  fi
  mv "$tmp" .company-os/manifest
}

# Where a conflict or .user copy goes: <path> itself, or, when an earlier copy
# is still there (not merged yet), <path>.<YYYYmmdd-HHMMSS> so it is never
# overwritten.
RUN_STAMP=$(date +%Y%m%d-%H%M%S)
unique_copy_path() {
  local p="$1" cand n=1
  if [ ! -e "$p" ]; then echo "$p"; return; fi
  cand="$p.$RUN_STAMP"
  while [ -e "$cand" ]; do
    n=$((n + 1))
    cand="$p.$RUN_STAMP-$n"
  done
  echo "$cand"
}

# ============================================================================
# Changelog Functions
# ============================================================================

# Extract changelog entries between two versions
extract_changelog() {
  local changelog="$1" from_version="$2" to_version="$3"

  if [ ! -f "$changelog" ]; then
    return
  fi

  echo ""
  echo -e "  ${BOLD}What's new:${NC}"
  echo ""

  awk -v from="$from_version" -v to="$to_version" '
    /^## \[/ {
      version = $2; gsub(/[\[\]]/, "", version)
      if (found_start && version == from) { exit }
      if (version == to) { found_start = 1 }
    }
    found_start { print "  " $0 }
  ' "$changelog"
}

# ============================================================================
# Backup Functions
# ============================================================================

create_backup() {
  local label="$1"
  local backup_dir=".company-os/backup/$(date +%Y%m%d-%H%M%S)-v${label}"
  local p
  mkdir -p "$backup_dir"

  for p in os/agents os/skills os/playbooks os/hooks .claude/agents .claude/skills .claude/hooks \
           .cursor .codex tools .company-os/docs; do
    if [ -d "$p" ]; then
      mkdir -p "$(dirname "$backup_dir/$p")"
      cp -R "$p" "$backup_dir/$p"
    fi
  done
  for p in CLAUDE.md AGENTS.md GEMINI.md .cursorrules .company-os/setup.sh \
           .company-os/version .company-os/manifest; do
    if [ -f "$p" ]; then
      mkdir -p "$(dirname "$backup_dir/$p")"
      cp "$p" "$backup_dir/$p"
    fi
  done

  echo "$backup_dir"
}

# --- Header ---
echo ""
echo -e "${BOLD}  Company OS — Installer${NC}"
echo -e "${DIM}  ─────────────────────────────────────${NC}"
if [ -n "$RUNTIMES" ]; then
  echo -e "${DIM}  Runtime adapters ($RUNTIME_MODE): ${NC}${BOLD}$(echo "$RUNTIMES" | xargs)${NC}"
else
  echo -e "${DIM}  Runtime adapters ($RUNTIME_MODE): ${NC}${BOLD}(core only — AGENTS.md)${NC}"
fi
echo ""

# --- Local source (offline installs and tests) ---
# COMPANY_OS_SOURCE=<checkout dir or .tar.gz> installs from that copy instead
# of downloading from GitHub. It is used only when the variable is set and not
# empty; --branch and --version are then ignored.
LOCAL_SOURCE="${COMPANY_OS_SOURCE:-}"

# --- Pre-flight checks ---
if [ -z "$LOCAL_SOURCE" ] && ! command -v curl &>/dev/null && ! command -v wget &>/dev/null; then
  echo -e "${RED}Error:${NC} curl or wget is required but not installed."
  exit 1
fi

if ! command -v tar &>/dev/null; then
  echo -e "${RED}Error:${NC} tar is required but not installed."
  exit 1
fi

# --- Detect existing setup ---
HAS_CLAUDE_DIR=false
HAS_SETTINGS=false
HAS_CLAUDE_MD=false
HAS_TOOLS=false
HAS_CONFIG=false

[ -d ".claude" ] && HAS_CLAUDE_DIR=true
[ -f ".claude/settings.json" ] && HAS_SETTINGS=true
[ -f "CLAUDE.md" ] && HAS_CLAUDE_MD=true
[ -d "tools" ] && HAS_TOOLS=true
[ -f "company.config.yaml" ] && HAS_CONFIG=true

if [ "$HAS_CLAUDE_DIR" = true ] || [ "$HAS_CLAUDE_MD" = true ]; then
  echo -e "  ${BLUE}Detected existing Claude Code setup${NC} — will smart-merge"
  if [ "$LOCAL_VERSION" != "unknown" ]; then
    echo -e "  ${DIM}Installed version: $LOCAL_VERSION${NC}"
  fi
  echo ""
fi
if [ "$LEGACY" = true ]; then
  echo -e "  ${YELLOW}Existing Company OS install without a version stamp${NC} (detected version: $LEGACY_VERSION)"
  echo -e "  ${DIM}It has no version stamp or manifest (installs from 1.9 to 1.11 recorded neither), so the${NC}"
  echo -e "  ${DIM}installer cannot tell which files you edited. It treats every file that differs as edited.${NC}"
  echo ""
elif [ "$NO_MANIFEST_UPGRADE" = true ] && [ -n "$OLD_MANIFEST" ]; then
  echo -e "  ${YELLOW}Existing Company OS install with a manifest from an older installer${NC} ($OLD_MANIFEST)"
  echo -e "  ${DIM}That manifest may record your edits as template files, so it is not used: files that${NC}"
  echo -e "  ${DIM}differ are treated as edited, and a backup is made first.${NC}"
  echo ""
elif [ "$NO_MANIFEST_UPGRADE" = true ]; then
  echo -e "  ${YELLOW}Existing Company OS install without a manifest${NC} — files that differ are treated as edited"
  echo ""
fi

# --- Determine download reference ---
DOWNLOAD_REF="$BRANCH"
if [ -n "$LOCAL_SOURCE" ]; then
  DOWNLOAD_REF="local"
elif [ -n "$TARGET_VERSION" ]; then
  DOWNLOAD_REF="v$TARGET_VERSION"
elif [ "$BRANCH" = "main" ]; then
  # Try to fetch latest release tag from GitHub API
  LATEST_TAG=""
  if command -v curl &>/dev/null; then
    LATEST_TAG=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null \
      | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"//;s/".*//' || true)
  fi
  if [ -n "$LATEST_TAG" ]; then
    DOWNLOAD_REF="$LATEST_TAG"
  fi
fi

# --- Download ---
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT
MANIFEST_NEW="$WORK_DIR/manifest.new"
: > "$MANIFEST_NEW"

# Find the extracted directory. GitHub names it company-os-<ref>; a local
# archive may use another top-level folder or none (plain `git archive`).
find_extracted_src() {
  local dir
  dir=$(find "$WORK_DIR" -maxdepth 1 -type d -name "company-os-*" | head -1)
  if [ -z "$dir" ] && [ -d "$WORK_DIR/os" ]; then
    dir="$WORK_DIR"
  fi
  if [ -z "$dir" ]; then
    dir=$(find "$WORK_DIR" -mindepth 2 -maxdepth 2 -type d -name os | head -1)
    [ -n "$dir" ] && dir=$(dirname "$dir")
  fi
  echo "$dir"
}

if [ -n "$LOCAL_SOURCE" ]; then
  if [ -d "$LOCAL_SOURCE" ]; then
    SRC=$(cd "$LOCAL_SOURCE" && pwd)
    if [ "$SRC" = "$(pwd)" ]; then
      echo -e "${RED}Error:${NC} COMPANY_OS_SOURCE points at this directory. Run the installer from your project, not from the source."
      exit 1
    fi
    echo -e "  ${BLUE}Using local source${NC} (COMPANY_OS_SOURCE): $SRC"
  elif [ -f "$LOCAL_SOURCE" ]; then
    echo -e "  ${BLUE}Using local archive${NC} (COMPANY_OS_SOURCE): $LOCAL_SOURCE"
    if ! tar -xzf "$LOCAL_SOURCE" -C "$WORK_DIR"; then
      echo -e "${RED}Error:${NC} Could not extract $LOCAL_SOURCE (expected a .tar.gz archive)."
      exit 1
    fi
    SRC=$(find_extracted_src)
  else
    echo -e "${RED}Error:${NC} COMPANY_OS_SOURCE not found: $LOCAL_SOURCE"
    exit 1
  fi
  if [ -z "$SRC" ] || [ ! -d "$SRC/os" ]; then
    echo -e "${RED}Error:${NC} COMPANY_OS_SOURCE does not look like Company OS (no os/ folder): $LOCAL_SOURCE"
    exit 1
  fi
else
  echo -e "  ${DIM}Downloading from github.com/$REPO ($DOWNLOAD_REF)...${NC}"
  ARCHIVE_URL="https://github.com/$REPO/archive/$DOWNLOAD_REF.tar.gz"

  DOWNLOAD_OK=true
  if command -v curl &>/dev/null; then
    curl -fsSL "$ARCHIVE_URL" | tar -xz -C "$WORK_DIR" || DOWNLOAD_OK=false
  else
    wget -qO- "$ARCHIVE_URL" | tar -xz -C "$WORK_DIR" || DOWNLOAD_OK=false
  fi
  if [ "$DOWNLOAD_OK" = false ]; then
    echo -e "${RED}Error:${NC} Download failed: $ARCHIVE_URL"
    echo -e "  Check your connection and the --version or --branch value. Offline? See https://github.com/$REPO/blob/main/.company-os/docs/TROUBLESHOOTING.md#installing-offline"
    exit 1
  fi

  SRC=$(find_extracted_src)

  if [ -z "$SRC" ] || [ ! -d "$SRC" ]; then
    echo -e "${RED}Error:${NC} Download failed or archive structure unexpected."
    exit 1
  fi

  echo -e "  ${GREEN}Downloaded${NC}"
fi
echo ""

# --- Read incoming version ---
# Since v1.9.0 the version and changelog live under .company-os/; older
# template releases keep them at the repo root, so fall back to those paths.
INCOMING_VERSION="unknown"
if [ -f "$SRC/.company-os/version" ]; then
  INCOMING_VERSION=$(cat "$SRC/.company-os/version" | tr -d '[:space:]')
elif [ -f "$SRC/VERSION" ]; then
  INCOMING_VERSION=$(cat "$SRC/VERSION" | tr -d '[:space:]')
fi
INCOMING_CHANGELOG=""
if [ -f "$SRC/.company-os/docs/CHANGELOG.md" ]; then
  INCOMING_CHANGELOG="$SRC/.company-os/docs/CHANGELOG.md"
elif [ -f "$SRC/CHANGELOG.md" ]; then
  INCOMING_CHANGELOG="$SRC/CHANGELOG.md"
fi

# --- Display version info ---
if [ "$LEGACY" = true ]; then
  UPGRADE_TYPE="legacy upgrade"
  echo -e "  ${BOLD}Version${NC}"
  echo -e "    Installed:  ${BOLD}$LEGACY_VERSION${NC} (no version stamp)"
  echo -e "    Available:  ${BOLD}$INCOMING_VERSION${NC} ($UPGRADE_TYPE)"
  echo ""
elif [ "$LOCAL_VERSION" != "unknown" ] || [ "$INCOMING_VERSION" != "unknown" ]; then
  UPGRADE_TYPE=$(upgrade_type "$LOCAL_VERSION" "$INCOMING_VERSION")

  echo -e "  ${BOLD}Version${NC}"
  echo -e "    Installed:  ${BOLD}$LOCAL_VERSION${NC}"
  echo -e "    Available:  ${BOLD}$INCOMING_VERSION${NC} ($UPGRADE_TYPE)"
  echo ""
fi

# The command to re-run this installer with --force (printed as advice).
force_command() {
  local flags="--force"
  [ -n "$RUNTIME_SPEC" ] && flags="--runtime $RUNTIME_SPEC $flags"
  if [ -n "$LOCAL_SOURCE" ] && [ -f "$0" ]; then
    echo "COMPANY_OS_SOURCE=$LOCAL_SOURCE bash $0 $flags"
  elif [ -f "$0" ] && [ "$(basename "$0")" = "install.sh" ]; then
    echo "bash $0 $flags"
  else
    echo "curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash -s -- $flags"
  fi
}

# ============================================================================
# Check-only mode
# ============================================================================
if [ "$CHECK_ONLY" = true ]; then
  if [ "$LEGACY" = true ]; then
    echo -e "  ${YELLOW}Company OS found without a version stamp${NC} (detected version: $LEGACY_VERSION) — $INCOMING_VERSION available"
    echo ""
    echo -e "  Commit or back up your project, then upgrade with --force. A backup is made"
    echo -e "  first and every file you changed is saved under .company-os/conflicts/:"
    echo -e "  ${DIM}$(force_command)${NC}"
    exit 0
  elif [ "$LOCAL_VERSION" = "$INCOMING_VERSION" ]; then
    echo -e "  ${GREEN}Up to date${NC} — Company OS $LOCAL_VERSION"
    exit 0
  elif [ "$LOCAL_VERSION" = "unknown" ]; then
    echo -e "  ${YELLOW}Not installed${NC} — Company OS $INCOMING_VERSION available"
    echo ""
    echo -e "  Run without --check to install."
    exit 0
  else
    echo -e "  ${YELLOW}Update available${NC} — $LOCAL_VERSION → $INCOMING_VERSION"

    # Show changelog if available
    if [ -n "$INCOMING_CHANGELOG" ]; then
      extract_changelog "$INCOMING_CHANGELOG" "$LOCAL_VERSION" "$INCOMING_VERSION"
    fi

    echo ""
    echo -e "  To upgrade:"
    echo -e "  ${DIM}curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash -s -- --force${NC}"
    exit 0
  fi
fi

# ============================================================================
# Changelog-only mode
# ============================================================================
if [ "$SHOW_CHANGELOG" = true ]; then
  if [ -n "$INCOMING_CHANGELOG" ]; then
    if [ "$LOCAL_VERSION" = "unknown" ]; then
      echo -e "  ${BOLD}Full Changelog:${NC}"
      echo ""
      cat "$INCOMING_CHANGELOG" | sed 's/^/  /'
    else
      extract_changelog "$INCOMING_CHANGELOG" "$LOCAL_VERSION" "$INCOMING_VERSION"
    fi
  else
    echo -e "  ${DIM}No changelog available.${NC}"
  fi
  exit 0
fi

# ============================================================================
# Major upgrade safety
# ============================================================================
if [ "$INCOMING_VERSION" != "unknown" ] && [ "$LOCAL_VERSION" != "unknown" ]; then
  if is_major_upgrade "$LOCAL_VERSION" "$INCOMING_VERSION"; then
    BACKUP=true  # Auto-enable backup for major upgrades

    if [ "$DRY_RUN" = false ] && [ "$FORCE" = false ]; then
      echo -e "  ${RED}MAJOR UPGRADE${NC} — Breaking changes may require action."
      echo ""

      if [ -n "$INCOMING_CHANGELOG" ]; then
        extract_changelog "$INCOMING_CHANGELOG" "$LOCAL_VERSION" "$INCOMING_VERSION"
        echo ""
      fi

      echo -e "  Use ${BOLD}--force${NC} to proceed, or ${BOLD}--dry-run --force${NC} to preview first."
      exit 1
    fi
  fi
fi

# ============================================================================
# Backup (if requested, a major upgrade, or an install without a manifest)
# ============================================================================
BACKUP_MADE=false
if [ "$DRY_RUN" = false ] && [ "$IS_EXISTING_INSTALL" = true ] \
   && { [ "$BACKUP" = true ] || [ "$NO_MANIFEST_UPGRADE" = true ]; }; then
  backup_label="$LOCAL_VERSION"
  if [ "$LEGACY" = true ]; then
    backup_label="legacy"
    [ "$LEGACY_VERSION" != "unknown" ] && backup_label="${LEGACY_VERSION}-legacy"
  fi
  backup_path=$(create_backup "$backup_label")
  BACKUP_MADE=true
  echo -e "  ${BLUE}Backup${NC}   Created at $backup_path"
  echo ""
fi

# An unstamped install is upgraded only with --force. Without it, show what
# --force would do and change nothing else: no files, no version stamp, no
# manifest (a stamp over old files would hide the pending upgrade).
LEGACY_PREVIEW=false
if [ "$LEGACY" = true ] && [ "$FORCE" = false ]; then
  LEGACY_PREVIEW=true
  DRY_RUN=true
  FORCE=true
  echo -e "  ${YELLOW}Not upgraded yet.${NC} Below is what an upgrade with --force would do."
  echo ""
fi

# ============================================================================
# Smart Merge Functions
# ============================================================================

# Every template-owned file goes through merge_template_file, a three-way
# merge between the template copy the user last got (its hash in the old
# manifest = "base"), the file on disk, and the incoming template copy:
#
#   missing on disk                     -> add the template copy
#   disk == incoming                    -> nothing to do
#   disk == base                        -> not edited: update to the template
#   disk != base, incoming == base      -> edited, template unchanged: keep it
#   edited and template changed (or no
#   base to compare, e.g. no manifest):
#     --force    -> save <path>.user (yours) and <path>.new (template) under
#                   .company-os/conflicts/, then install the template copy
#     no --force -> keep the user's file and report it
#
# Sets MERGE_RESULT to: added | current | updated | kept | conflict | held.
# Paths saved in conflicts/ are appended to $CONFLICT_LOG.
CONFLICT_LOG="$WORK_DIR/conflicts.log"
HELD_LOG="$WORK_DIR/held.log"
: > "$CONFLICT_LOG"
: > "$HELD_LOG"
CONFLICT_USER_COPIES=0

save_conflict_copies() {  # save_conflict_copies <src_file> <dst_file> <with_new:true|false>
  local src="$1" dst="$2" with_new="$3" cbase=".company-os/conflicts/$2" ucopy ncopy
  ucopy=$(unique_copy_path "$cbase.user")
  if [ "$DRY_RUN" = false ]; then
    mkdir -p "$(dirname "$cbase")"
    cp "$dst" "$ucopy"
  fi
  echo "$ucopy" >> "$CONFLICT_LOG"
  CONFLICT_USER_COPIES=$((CONFLICT_USER_COPIES + 1))
  if [ "$with_new" = true ]; then
    ncopy=$(unique_copy_path "$cbase.new")
    [ "$DRY_RUN" = false ] && cp "$src" "$ncopy"
  fi
  if [ "$ucopy" != "$cbase.user" ]; then
    echo -e "    ${YELLOW}Saved${NC}    $ucopy ${DIM}(an earlier copy you have not merged is still at $cbase.user)${NC}"
  fi
}

merge_template_file() {  # merge_template_file <src_file> <dst_file>
  local src="$1" dst="$2" inc base disk
  MERGE_NOTE="your edits; template changed"
  inc=$(file_hash "$src")
  if [ ! -e "$dst" ] && [ ! -L "$dst" ]; then
    if [ "$DRY_RUN" = false ]; then
      mkdir -p "$(dirname "$dst")"
      cp "$src" "$dst"
    fi
    record_manifest "$inc" "$dst"
    MERGE_RESULT=added
    return
  fi
  if [ -L "$dst" ]; then
    # A symlink (e.g. AGENTS.md -> CLAUDE.md): writing would change its target.
    MERGE_NOTE="a symlink; left as is so its target is not overwritten"
    echo "$dst ($MERGE_NOTE)" >> "$HELD_LOG"
    MERGE_RESULT=held
    return
  fi
  if [ ! -f "$dst" ]; then
    # Something else (a folder) is in the way: leave it alone.
    MERGE_NOTE="not a regular file; left as is"
    echo "$dst ($MERGE_NOTE)" >> "$HELD_LOG"
    MERGE_RESULT=held
    return
  fi
  disk=$(file_hash "$dst")
  if [ "$disk" = "$inc" ]; then
    record_manifest "$inc" "$dst"
    MERGE_RESULT=current
    return
  fi
  base=$(manifest_hash "$dst")
  if [ -n "$base" ] && [ "$disk" = "$base" ]; then
    [ "$DRY_RUN" = false ] && cp "$src" "$dst"
    record_manifest "$inc" "$dst"
    MERGE_RESULT=updated
    return
  fi
  if [ -n "$base" ] && [ "$inc" = "$base" ]; then
    record_manifest "$base" "$dst"
    MERGE_RESULT=kept
    return
  fi
  if [ "$FORCE" = true ]; then
    # With a base this is a real conflict: keep both sides. Without one (no
    # manifest) the new copy is the live file, so only the user's is saved.
    if [ -n "$base" ]; then
      save_conflict_copies "$src" "$dst" true
    else
      save_conflict_copies "$src" "$dst" false
    fi
    [ "$DRY_RUN" = false ] && cp "$src" "$dst"
    record_manifest "$inc" "$dst"
    MERGE_RESULT=conflict
    return
  fi
  # Keep the user's file. Record the template copy it is based on, or
  # "unknown" when there is none, so the next upgrade still sees the edit AND
  # the pending template change (recording the incoming hash would make a
  # later --force read it as "template unchanged" and skip it).
  record_manifest "${base:-unknown}" "$dst"
  echo "$dst" >> "$HELD_LOG"
  MERGE_RESULT=held
}

# merge_directory: merges every file under src_dir into dst_dir with
# merge_template_file. Files the template does not have (your own tools,
# notes inside a skill folder) are never touched.
# Usage: merge_directory <src_dir> <dst_dir> <label>
merge_directory() {
  local src_dir="${1%/}" dst_dir="${2%/}" label="$3"
  local added=0 current=0 updated=0 kept=0 conflict=0 held=0 f rel

  if [ ! -d "$src_dir" ]; then
    return
  fi

  while IFS= read -r f; do
    rel="${f#"$src_dir"/}"
    merge_template_file "$f" "$dst_dir/$rel"
    case "$MERGE_RESULT" in
      added)    added=$((added + 1)) ;;
      current)  current=$((current + 1)) ;;
      updated)  updated=$((updated + 1)) ;;
      kept)     kept=$((kept + 1)) ;;
      conflict) conflict=$((conflict + 1)) ;;
      held)     held=$((held + 1)) ;;
    esac
  done < <(find "$src_dir" -type f 2>/dev/null | sort)

  ADDED=$((ADDED + added))
  UPDATED=$((UPDATED + updated + conflict))
  SKIPPED=$((SKIPPED + current + kept + held))
  CONFLICTS=$((CONFLICTS + conflict))
  KEPT_EDITS=$((KEPT_EDITS + kept + held))

  local parts=""
  [ "$added" -gt 0 ] && parts="$parts, $added new"
  [ "$updated" -gt 0 ] && parts="$parts, $updated updated"
  [ "$conflict" -gt 0 ] && parts="$parts, $conflict replaced (your copies saved)"
  [ "$kept" -gt 0 ] && parts="$parts, $kept kept (your edits)"
  [ "$held" -gt 0 ] && parts="$parts, $held kept (your edits; template changed)"
  [ "$current" -gt 0 ] && parts="$parts, $current unchanged"
  parts="${parts#, }"

  if [ "$conflict" -gt 0 ]; then
    echo -e "  ${YELLOW}Updated${NC}  $label ($parts)"
  elif [ $((added + updated)) -gt 0 ]; then
    if [ $((current + updated + kept + held)) -eq 0 ]; then
      echo -e "  ${GREEN}Created${NC}  $label ($added files)"
    else
      echo -e "  ${GREEN}Updated${NC}  $label ($parts)"
    fi
  elif [ "$held" -gt 0 ] || [ "$kept" -gt 0 ]; then
    echo -e "  ${BLUE}Kept${NC}     $label ($parts)"
  else
    echo -e "  ${DIM}Exists${NC}   $label (up to date)"
  fi
}

# merge_file: one template-owned top-level file (AGENTS.md, GEMINI.md,
# .cursorrules, .company-os/setup.sh), merged with merge_template_file.
# Usage: merge_file <src_file> <dst_file>
merge_file() {
  local src_file="$1" dst_file="$2"
  if [ ! -f "$src_file" ]; then
    return
  fi
  merge_template_file "$src_file" "$dst_file"
  case "$MERGE_RESULT" in
    added)    ADDED=$((ADDED + 1)); echo -e "  ${GREEN}Created${NC}  $dst_file" ;;
    updated)  UPDATED=$((UPDATED + 1)); echo -e "  ${GREEN}Updated${NC}  $dst_file" ;;
    conflict) UPDATED=$((UPDATED + 1)); CONFLICTS=$((CONFLICTS + 1))
              echo -e "  ${YELLOW}Updated${NC}  $dst_file (your copy saved under .company-os/conflicts/)" ;;
    kept)     SKIPPED=$((SKIPPED + 1)); KEPT_EDITS=$((KEPT_EDITS + 1)); echo -e "  ${BLUE}Kept${NC}     $dst_file (your edits)" ;;
    held)     SKIPPED=$((SKIPPED + 1)); KEPT_EDITS=$((KEPT_EDITS + 1)); echo -e "  ${BLUE}Kept${NC}     $dst_file ($MERGE_NOTE)" ;;
    *)        SKIPPED=$((SKIPPED + 1)) ;;
  esac
}

# merge_settings_json: Merges Company OS permissions and hooks into existing settings.json.
# Never replaces — always merges, even with --force. Uses python3 for JSON handling.
# Usage: merge_settings_json <src_file> <dst_file>
merge_settings_json() {
  local src_file="$1" dst_file="$2"

  if [ ! -f "$dst_file" ]; then
    # No existing settings — just copy
    if [ "$DRY_RUN" = false ]; then
      mkdir -p "$(dirname "$dst_file")"
      cp "$src_file" "$dst_file"
    fi
    echo -e "  ${GREEN}Created${NC}  .claude/settings.json"
    CREATED=$((CREATED + 1))
    return
  fi

  # Existing settings — merge
  if ! command -v python3 &>/dev/null; then
    echo -e "  ${YELLOW}Warning${NC}  .claude/settings.json — python3 not found, skipping merge"
    echo -e "           ${DIM}Install python3 to enable automatic permission merging${NC}"
    SKIPPED=$((SKIPPED + 1))
    return
  fi

  if [ "$DRY_RUN" = true ]; then
    echo -e "  ${DIM}Preview${NC}  .claude/settings.json (would merge permissions)"
    MERGED=$((MERGED + 1))
    return
  fi

  # Use python3 to merge JSON arrays (permissions) and add hooks
  local result
  result=$(MERGE_SRC="$src_file" MERGE_DST="$dst_file" python3 << 'PYEOF'
import json
import os

src_path = os.environ["MERGE_SRC"]
dst_path = os.environ["MERGE_DST"]

try:
    with open(src_path) as f:
        src = json.load(f)
    with open(dst_path) as f:
        dst = json.load(f)
except Exception as e:
    print(f"ERROR:{e}")
    exit(1)

# Track counts
added_allow = 0
added_deny = 0
preserved_allow = 0
preserved_deny = 0

# Merge permissions.allow
dst_allow = dst.get("permissions", {}).get("allow", [])
preserved_allow = len(dst_allow)
dst_allow_set = set(dst_allow)
for rule in src.get("permissions", {}).get("allow", []):
    if rule not in dst_allow_set:
        dst_allow.append(rule)
        added_allow += 1

# Merge permissions.deny
dst_deny = dst.get("permissions", {}).get("deny", [])
preserved_deny = len(dst_deny)
dst_deny_set = set(dst_deny)
for rule in src.get("permissions", {}).get("deny", []):
    if rule not in dst_deny_set:
        dst_deny.append(rule)
        added_deny += 1

# Ensure permissions structure
if "permissions" not in dst:
    dst["permissions"] = {}
dst["permissions"]["allow"] = dst_allow
dst["permissions"]["deny"] = dst_deny

# Add hooks if user doesn't have any
if "hooks" not in dst and "hooks" in src:
    dst["hooks"] = src["hooks"]
    hooks_added = True
else:
    hooks_added = False

total_added = added_allow + added_deny
if total_added == 0 and not hooks_added:
    print("UNCHANGED")
    exit(0)

# Write merged result
with open(dst_path, "w") as f:
    json.dump(dst, f, indent=2)
    f.write("\n")

# Report
total_preserved = preserved_allow + preserved_deny
hooks_msg = ", hooks added" if hooks_added else ""
print(f"added {total_added} rules, preserved {total_preserved} custom{hooks_msg}")
PYEOF
  ) || true

  if [ "$result" = "UNCHANGED" ]; then
    echo -e "  ${DIM}Exists${NC}   .claude/settings.json (already has the Company OS rules)"
    SKIPPED=$((SKIPPED + 1))
  elif [ -n "$result" ]; then
    echo -e "  ${GREEN}Merged${NC}   .claude/settings.json ($result)"
    MERGED=$((MERGED + 1))
  else
    echo -e "  ${YELLOW}Warning${NC}  .claude/settings.json — merge failed, existing file preserved"
    SKIPPED=$((SKIPPED + 1))
  fi
}

# write_claude_generated_list: writes .claude/.generated-by-company-os, the
# list of files tools/build/build-claude.sh generates from os/, with the same
# header and order the build uses. Without it the first build in a fresh
# install would create it as a new untracked file. Entries of the old list
# whose os/ source is gone stay listed so the next build still removes those
# generated files. Written only when its content changes.
CLAUDE_GENERATED_LIST=".claude/.generated-by-company-os"
write_claude_generated_list() {
  local tmp="$WORK_DIR/generated-list" d name f existed=false
  {
    echo "# Written by tools/build/build-claude.sh: the files it generated from os/."
    echo "# The next build removes or overwrites only files listed here."
    for d in os/skills/*/; do
      [ -d "$d" ] || continue
      name="$(basename "$d")"
      find "os/skills/$name" -type f | sort | while IFS= read -r f; do
        echo "skills/$name/${f#os/skills/$name/}"
      done
    done
    for f in os/agents/*.md; do
      [ -f "$f" ] || continue
      echo "agents/$(basename "$f")"
    done
    if [ -f "$CLAUDE_GENERATED_LIST" ]; then
      grep -v '^#' "$CLAUDE_GENERATED_LIST" | while IFS= read -r f; do
        [ -n "$f" ] || continue
        if [ ! -f "os/$f" ] && [ -f ".claude/$f" ]; then echo "$f"; fi
      done
    fi
  } > "$tmp"
  [ -f "$CLAUDE_GENERATED_LIST" ] && existed=true
  if [ "$existed" = true ] && cmp -s "$tmp" "$CLAUDE_GENERATED_LIST"; then
    return
  fi
  mkdir -p .claude
  cp "$tmp" "$CLAUDE_GENERATED_LIST"
  if [ "$existed" = true ]; then
    echo -e "  ${GREEN}Updated${NC}  $CLAUDE_GENERATED_LIST (files the build generates from os/)"
    UPDATED=$((UPDATED + 1))
  else
    echo -e "  ${GREEN}Created${NC}  $CLAUDE_GENERATED_LIST (files the build generates from os/)"
    ADDED=$((ADDED + 1))
  fi
}

# merge_claude_md: Appends Company OS section to existing CLAUDE.md.
# Detects the "## Company OS Overview" marker to avoid double-appending.
# The Company OS section runs from that marker to the end of the file. Its
# template hash is recorded in the manifest under "CLAUDE.md#company-os", so
# an upgrade refreshes an unedited section and saves a copy of CLAUDE.md
# under .company-os/conflicts/ before replacing an edited one (text you added
# after the section counts as an edit).
# Usage: merge_claude_md <src_file> <dst_file>
CLAUDE_MD_KEY="CLAUDE.md#company-os"
claude_section_hash() {  # hash of the Company OS section of $1
  local tmp="$WORK_DIR/claude-section"
  sed -n '/## Company OS Overview/,$p' "$1" > "$tmp"
  file_hash "$tmp"
}

merge_claude_md() {
  local src_file="$1" dst_file="$2"
  local inc_section
  inc_section=$(claude_section_hash "$src_file")

  if [ ! -f "$dst_file" ]; then
    # No existing CLAUDE.md — just copy
    if [ "$DRY_RUN" = false ]; then
      cp "$src_file" "$dst_file"
    fi
    record_manifest "$inc_section" "$CLAUDE_MD_KEY"
    echo -e "  ${GREEN}Created${NC}  CLAUDE.md"
    CREATED=$((CREATED + 1))
    return
  fi

  # Check if Company OS section already exists
  if grep -q "## Company OS Overview" "$dst_file" 2>/dev/null; then
    local disk_section base
    disk_section=$(claude_section_hash "$dst_file")
    base=$(manifest_hash "$CLAUDE_MD_KEY")
    if [ "$disk_section" = "$inc_section" ]; then
      record_manifest "$inc_section" "$CLAUDE_MD_KEY"
      echo -e "  ${DIM}Exists${NC}   CLAUDE.md (Company OS section up to date)"
      SKIPPED=$((SKIPPED + 1))
      return
    fi
    local edited=true
    [ -n "$base" ] && [ "$disk_section" = "$base" ] && edited=false
    if [ "$edited" = true ] && [ -n "$base" ] && [ "$inc_section" = "$base" ]; then
      record_manifest "$base" "$CLAUDE_MD_KEY"
      echo -e "  ${BLUE}Kept${NC}     CLAUDE.md (your edits to the Company OS section; template unchanged)"
      SKIPPED=$((SKIPPED + 1))
      KEPT_EDITS=$((KEPT_EDITS + 1))
      return
    fi
    if [ "$edited" = true ] && [ "$FORCE" = false ]; then
      record_manifest "${base:-unknown}" "$CLAUDE_MD_KEY"
      echo -e "  ${DIM}Exists${NC}   CLAUDE.md (Company OS section kept; rerun with --force to refresh it, your copy is saved first)"
      echo "CLAUDE.md (Company OS section)" >> "$HELD_LOG"
      SKIPPED=$((SKIPPED + 1))
      KEPT_EDITS=$((KEPT_EDITS + 1))
      return
    fi

    if [ "$edited" = true ]; then
      save_conflict_copies "$src_file" "$dst_file" false
      CONFLICTS=$((CONFLICTS + 1))
    fi
    record_manifest "$inc_section" "$CLAUDE_MD_KEY"
    if [ "$DRY_RUN" = true ]; then
      echo -e "  ${DIM}Preview${NC}  CLAUDE.md (would refresh Company OS section)"
      UPDATED=$((UPDATED + 1))
      return
    fi

    # Extract user content (everything before Company OS section) and replace Company OS part
    local marker_line
    marker_line=$(grep -n "## Company OS Overview" "$dst_file" | head -1 | cut -d: -f1)

    # Find the separator line (---) just before the marker, if any
    local start_line=$marker_line
    if [ "$marker_line" -gt 1 ]; then
      local prev_line=$((marker_line - 1))
      local prev_content
      prev_content=$(sed -n "${prev_line}p" "$dst_file")
      if [ "$prev_content" = "---" ]; then
        start_line=$prev_line
      fi
      # Check one more line back for blank line before ---
      if [ "$start_line" -gt 1 ]; then
        local prev2=$((start_line - 1))
        local prev2_content
        prev2_content=$(sed -n "${prev2}p" "$dst_file")
        if [ -z "$prev2_content" ]; then
          start_line=$prev2
        fi
      fi
    fi

    # Keep user content, replace Company OS section
    local user_content
    user_content=$(head -n "$((start_line - 1))" "$dst_file")

    # Extract Company OS section from source (everything from ## Company OS Overview onward)
    local cos_section
    cos_section=$(sed -n '/## Company OS Overview/,$p' "$src_file")

    if [ -n "$user_content" ]; then
      printf '%s\n\n---\n\n%s\n' "$user_content" "$cos_section" > "$dst_file"
    else
      printf '%s\n' "$cos_section" > "$dst_file"
    fi
    if [ "$edited" = true ]; then
      echo -e "  ${YELLOW}Updated${NC}  CLAUDE.md (Company OS section refreshed; your previous CLAUDE.md is saved under .company-os/conflicts/)"
    else
      echo -e "  ${GREEN}Updated${NC}  CLAUDE.md (Company OS section refreshed, user content preserved)"
    fi
    UPDATED=$((UPDATED + 1))
    return
  fi

  # No Company OS section found — append it
  record_manifest "$inc_section" "$CLAUDE_MD_KEY"
  if [ "$DRY_RUN" = true ]; then
    echo -e "  ${DIM}Preview${NC}  CLAUDE.md (would append Company OS section)"
    MERGED=$((MERGED + 1))
    return
  fi

  local cos_section
  cos_section=$(sed -n '/## Company OS Overview/,$p' "$src_file")

  if [ -n "$cos_section" ]; then
    printf '\n\n---\n\n%s\n' "$cos_section" >> "$dst_file"
    echo -e "  ${GREEN}Appended${NC} CLAUDE.md (Company OS section added to existing)"
    MERGED=$((MERGED + 1))
  else
    # Fallback: append entire source file content
    printf '\n\n---\n\n' >> "$dst_file"
    cat "$src_file" >> "$dst_file"
    echo -e "  ${GREEN}Appended${NC} CLAUDE.md (Company OS content added)"
    MERGED=$((MERGED + 1))
  fi
}

# ============================================================================
# Install / Upgrade
# ============================================================================

if [ "$DRY_RUN" = true ]; then
  echo -e "  ${BOLD}Preview — no changes will be made${NC}"
else
  echo -e "  ${BOLD}Installing overlay files...${NC}"
fi
echo ""

# --- os/ (neutral authoring source) ---
if [ "$DRY_RUN" = false ]; then
  mkdir -p os
fi
merge_directory "$SRC/os/agents"      "os/agents"      "os/agents/"
merge_directory "$SRC/os/skills"      "os/skills"      "os/skills/"
merge_directory "$SRC/os/playbooks"   "os/playbooks"   "os/playbooks/"
merge_directory "$SRC/os/hooks"       "os/hooks"       "os/hooks/"

# --- .claude/ (Claude Code adapter — gated by runtime selection) ---
if should_install_runtime claude; then
  if [ "$DRY_RUN" = false ]; then
    mkdir -p .claude
  fi
  merge_directory "$SRC/.claude/agents"  ".claude/agents"  ".claude/agents/"
  merge_directory "$SRC/.claude/skills"  ".claude/skills"  ".claude/skills/"
  merge_directory "$SRC/.claude/hooks"   ".claude/hooks"   ".claude/hooks/"
  merge_settings_json "$SRC/.claude/settings.json" ".claude/settings.json"
  [ "$DRY_RUN" = true ] || write_claude_generated_list
fi

# --- AGENTS.md (universal runtime-neutral instruction file — always installed) ---
if [ "$INSTALL_AGENTS_MD" = true ] && [ -f "$SRC/AGENTS.md" ]; then
  merge_file "$SRC/AGENTS.md" "AGENTS.md"
fi

# Warn when the downloaded release predates an adapter (multi-runtime needs 1.12.0+).
warn_missing_adapter() {
  echo -e "  ${YELLOW}Warning${NC}  This release has no $1 adapter (needs Company OS 1.12.0 or later). Skipped." >&2
}

# --- Cursor adapter ---
if should_install_runtime cursor; then
  if [ ! -d "$SRC/.cursor" ] && [ ! -f "$SRC/.cursorrules" ]; then warn_missing_adapter Cursor; fi
  [ -f "$SRC/.cursorrules" ] && merge_file "$SRC/.cursorrules" ".cursorrules" || true
  if [ -d "$SRC/.cursor" ]; then
    merge_directory "$SRC/.cursor/rules"  ".cursor/rules"  ".cursor/rules/"
  fi
fi

# --- Gemini adapter ---
if should_install_runtime gemini; then
  [ -f "$SRC/GEMINI.md" ] || warn_missing_adapter Gemini
  [ -f "$SRC/GEMINI.md" ] && merge_file "$SRC/GEMINI.md" "GEMINI.md" || true
fi

# --- Codex adapter (relies on AGENTS.md plus a thin Codex pointer) ---
if should_install_runtime codex; then
  [ -d "$SRC/.codex" ] || warn_missing_adapter Codex
  if [ -d "$SRC/.codex" ]; then
    merge_directory "$SRC/.codex"  ".codex"  ".codex/"
  fi
fi

# --- Aider (just uses AGENTS.md — no extra files) ---
# (No-op; AGENTS.md handled above.)

# --- tools/ (per-subdirectory smart merge) ---
if [ "$DRY_RUN" = false ]; then
  mkdir -p tools
fi
for tool_dir in "$SRC"/tools/*/; do
  [ -d "$tool_dir" ] || continue
  local_name=$(basename "$tool_dir")
  merge_directory "$tool_dir" "tools/$local_name" "tools/$local_name/"
done

# --- CLAUDE.md (smart append) ---
merge_claude_md "$SRC/CLAUDE.md" "CLAUDE.md"

# --- company.config.yaml (always protected) ---
if [ ! -f "company.config.yaml" ]; then
  if [ "$DRY_RUN" = false ]; then
    cp "$SRC/company.config.yaml" "company.config.yaml"
  fi
  echo -e "  ${GREEN}Created${NC}  company.config.yaml"
  CREATED=$((CREATED + 1))
else
  echo -e "  ${DIM}Kept${NC}     company.config.yaml (existing config preserved)"
  SKIPPED=$((SKIPPED + 1))
fi

# --- .company-os/docs/ (template-owned user guides, diagrams, skill schema) ---
# These docs belong to the template, so an upgrade refreshes them, using the
# same three-way rules as merge_template_file. A copy you edited is saved next
# to it as <name>.user (or <name>.user.<timestamp> when an earlier .user copy
# is still there) before the new version replaces it. Without a manifest
# entry to compare against, a doc that differs counts as edited.
# VERSION is NOT copied — it would conflict with the user's app version file.
DOCS_ADDED=0 DOCS_REFRESHED=0 DOCS_USER_SAVED=0 DOCS_KEPT=0 DOCS_HELD=0
IS_UPGRADE=false
if [ "$FORCE" = true ] || { [ "$LOCAL_VERSION" != "unknown" ] && [ "$LOCAL_VERSION" != "$INCOMING_VERSION" ]; }; then
  IS_UPGRADE=true
fi
if [ -d "$SRC/.company-os/docs" ]; then
  while IFS= read -r doc_file; do
    doc_rel="${doc_file#"$SRC"/.company-os/docs/}"
    doc_dst=".company-os/docs/$doc_rel"
    doc_inc=$(file_hash "$doc_file")
    if [ ! -f "$doc_dst" ]; then
      if [ "$DRY_RUN" = false ]; then
        mkdir -p "$(dirname "$doc_dst")"
        cp "$doc_file" "$doc_dst"
      fi
      record_manifest "$doc_inc" "$doc_dst"
      DOCS_ADDED=$((DOCS_ADDED + 1))
      continue
    fi
    if [ -L "$doc_dst" ]; then
      echo "$doc_dst (a symlink; left as is so its target is not overwritten)" >> "$HELD_LOG"
      DOCS_HELD=$((DOCS_HELD + 1))
      continue
    fi
    doc_disk=$(file_hash "$doc_dst")
    if [ "$doc_disk" = "$doc_inc" ]; then
      record_manifest "$doc_inc" "$doc_dst"
      continue
    fi
    doc_base=$(manifest_hash "$doc_dst")
    if [ -n "$doc_base" ] && [ "$doc_disk" = "$doc_base" ]; then
      [ "$DRY_RUN" = false ] && cp "$doc_file" "$doc_dst"
      record_manifest "$doc_inc" "$doc_dst"
      DOCS_REFRESHED=$((DOCS_REFRESHED + 1))
    elif [ -n "$doc_base" ] && [ "$doc_inc" = "$doc_base" ]; then
      # You edited it and the template did not change it: keep yours.
      record_manifest "$doc_base" "$doc_dst"
      DOCS_KEPT=$((DOCS_KEPT + 1))
    elif [ "$IS_UPGRADE" = true ]; then
      doc_user=$(unique_copy_path "$doc_dst.user")
      if [ "$DRY_RUN" = false ]; then
        cp "$doc_dst" "$doc_user"
        cp "$doc_file" "$doc_dst"
      else
        echo -e "    ${DIM}Would save${NC} $doc_user (your edits), then refresh $doc_dst"
      fi
      if [ "$doc_user" != "$doc_dst.user" ] && [ "$DRY_RUN" = false ]; then
        echo -e "    ${YELLOW}Saved${NC}    $doc_user ${DIM}(an earlier copy you have not merged is still at $doc_dst.user)${NC}"
      fi
      record_manifest "$doc_inc" "$doc_dst"
      DOCS_USER_SAVED=$((DOCS_USER_SAVED + 1))
    else
      record_manifest "${doc_base:-unknown}" "$doc_dst"
      echo "$doc_dst" >> "$HELD_LOG"
      DOCS_HELD=$((DOCS_HELD + 1))
    fi
  done < <(find "$SRC/.company-os/docs" -type f | sort)
  ADDED=$((ADDED + DOCS_ADDED))
  UPDATED=$((UPDATED + DOCS_REFRESHED + DOCS_USER_SAVED))
  SKIPPED=$((SKIPPED + DOCS_KEPT + DOCS_HELD))
  KEPT_EDITS=$((KEPT_EDITS + DOCS_KEPT + DOCS_HELD))
  docs_verb="Updated"
  [ $((DOCS_REFRESHED + DOCS_USER_SAVED)) -eq 0 ] && docs_verb="Created"
  [ "$DRY_RUN" = true ] && docs_verb="Preview"
  if [ $((DOCS_ADDED + DOCS_REFRESHED + DOCS_USER_SAVED)) -gt 0 ]; then
    echo -e "  ${GREEN}${docs_verb}${NC}  .company-os/docs/ ($DOCS_ADDED new, $((DOCS_REFRESHED + DOCS_USER_SAVED)) refreshed)"
  else
    echo -e "  ${DIM}Exists${NC}   .company-os/docs/ (up to date)"
  fi
  if [ "$DOCS_USER_SAVED" -gt 0 ]; then
    echo -e "  ${YELLOW}Note${NC}     $DOCS_USER_SAVED doc(s) you edited were saved as <name>.user next to the new copy"
  fi
  if [ "$DOCS_KEPT" -gt 0 ]; then
    echo -e "  ${BLUE}Kept${NC}     $DOCS_KEPT doc(s) you edited in .company-os/docs/ (the template did not change them)"
  fi
  if [ "$DOCS_HELD" -gt 0 ]; then
    echo -e "  ${DIM}Kept${NC}     $DOCS_HELD edited doc(s) in .company-os/docs/ (rerun with --force to refresh them; your edits are kept as <name>.user)"
  fi
fi

# --- .company-os/setup.sh (bash fallback for /setup; template-owned) ---
# Releases before 1.12.0 keep it at the repo root.
if [ -f "$SRC/.company-os/setup.sh" ]; then
  merge_file "$SRC/.company-os/setup.sh" ".company-os/setup.sh"
elif [ -f "$SRC/setup.sh" ]; then
  merge_file "$SRC/setup.sh" ".company-os/setup.sh"
fi

# --- Scaffold directories (create if missing, never overwrite) ---
if [ "$DRY_RUN" = false ]; then
  # Copy reference standards that skills and agents read (design archetypes,
  # UX baseline, SOPs, security posture, ...) only when absent. They become
  # yours to edit, so they are never overwritten. example-* files are samples
  # and are not copied.
  STANDARDS_ADDED=0
  if [ -d "$SRC/standards" ]; then
    while IFS= read -r std_file; do
      std_rel="${std_file#"$SRC"/}"
      if [ ! -f "$std_rel" ]; then
        mkdir -p "$(dirname "$std_rel")"
        cp "$std_file" "$std_rel"
        STANDARDS_ADDED=$((STANDARDS_ADDED + 1))
      fi
    done < <(find "$SRC/standards" -type f -name '*.md' -not -name 'example-*' | sort)
  fi
  if [ "$STANDARDS_ADDED" -gt 0 ]; then
    echo -e "  ${GREEN}Added${NC}    standards/ ($STANDARDS_ADDED reference docs; existing files kept)"
    ADDED=$((ADDED + STANDARDS_ADDED))
  fi

  for dir in \
    artifacts/prds artifacts/rfcs artifacts/test-plans artifacts/qa-reports \
    artifacts/launch-briefs artifacts/security-reviews artifacts/decision-memos \
    artifacts/.audit-log \
    standards/api standards/coding standards/compliance standards/templates \
    standards/brand standards/brand/archetypes standards/ops standards/analytics standards/docs \
    standards/email standards/engineering \
    imports tasks .company-os/migrations \
    seeds artifacts/test-data; do
    if [ ! -d "$dir" ]; then
      mkdir -p "$dir"
      if [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
        touch "$dir/.gitkeep"
      fi
    fi
  done

  # Keep upgrade backups and conflict copies out of commits (idempotent).
  GITIGNORE_ADDED=0
  for ignore_line in ".company-os/backup/" ".company-os/conflicts/"; do
    if [ ! -f .gitignore ] || ! grep -qxF "$ignore_line" .gitignore; then
      if [ -s .gitignore ] && [ -n "$(tail -c 1 .gitignore)" ]; then echo "" >> .gitignore; fi
      if [ "$GITIGNORE_ADDED" -eq 0 ]; then echo "# Company OS upgrade backups and conflict copies" >> .gitignore; fi
      echo "$ignore_line" >> .gitignore
      GITIGNORE_ADDED=$((GITIGNORE_ADDED + 1))
    fi
  done
  if [ "$GITIGNORE_ADDED" -gt 0 ]; then
    echo -e "  ${GREEN}Updated${NC}  .gitignore (ignores .company-os/backup/ and .company-os/conflicts/)"
    MERGED=$((MERGED + 1))
  fi

  # Create tasks files if missing
  if [ ! -f "tasks/todo.md" ]; then
    echo -e "# Todo\n\nCurrent task tracking for this session." > "tasks/todo.md"
  fi
  if [ ! -f "tasks/lessons.md" ]; then
    echo -e "# Lessons\n\nAccumulated corrections and patterns from agent interactions." > "tasks/lessons.md"
  fi

  # Copy migrations from template (check new path first, fall back to old)
  MIGRATION_TEMPLATE=""
  if [ -d "$SRC/.company-os/migrations" ]; then
    MIGRATION_TEMPLATE="$SRC/.company-os/migrations"
  elif [ -d "$SRC/migrations" ]; then
    MIGRATION_TEMPLATE="$SRC/migrations"
  fi
  if [ -n "$MIGRATION_TEMPLATE" ]; then
    mkdir -p ".company-os/migrations"
    for migration_file in "$MIGRATION_TEMPLATE"/*; do
      [ -e "$migration_file" ] || continue
      mig_name=$(basename "$migration_file")
      # Only copy if missing (don't overwrite user-patched migrations)
      if [ ! -f ".company-os/migrations/$mig_name" ]; then
        cp "$migration_file" ".company-os/migrations/$mig_name"
      fi
    done
  fi

  # Make all tool scripts executable
  find tools/ -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true
fi

# ============================================================================
# Run Migrations (after file updates, before summary)
# ============================================================================
MIGRATION_RUN_SRC=""
if [ -d "$SRC/.company-os/migrations" ]; then
  MIGRATION_RUN_SRC="$SRC/.company-os/migrations"
elif [ -d "$SRC/migrations" ]; then
  MIGRATION_RUN_SRC="$SRC/migrations"
fi
if [ "$DRY_RUN" = false ] && [ -n "$MIGRATION_RUN_SRC" ] && [ "$LOCAL_VERSION" != "unknown" ]; then
  migration_ran=false
  for migration in "$MIGRATION_RUN_SRC"/v*.sh; do
    [ -f "$migration" ] || continue
    MIGRATION_VERSION=$(basename "$migration" .sh | sed 's/^v//')

    if version_gt "$MIGRATION_VERSION" "$LOCAL_VERSION" 2>/dev/null; then
      if [ "$migration_ran" = false ]; then
        echo ""
        echo -e "  ${BOLD}Running migrations...${NC}"
        migration_ran=true
      fi
      echo -e "  ${BLUE}Migrate${NC}  → v$MIGRATION_VERSION"
      bash "$migration" || {
        echo -e "  ${RED}Migration failed${NC} — v$MIGRATION_VERSION (see output above)"
        echo -e "  ${DIM}Your files are safe. Fix the issue and re-run.${NC}"
        exit 1
      }
    fi
  done
fi

# ============================================================================
# Version Stamp + Manifest
# ============================================================================
if [ "$DRY_RUN" = false ] && [ "$INCOMING_VERSION" != "unknown" ]; then
  mkdir -p .company-os
  echo "$INCOMING_VERSION" > .company-os/version
  generate_manifest "$INCOMING_VERSION"
fi

# Did this run move the installed version (an upgrade, or a downgrade)?
VERSION_CHANGED=false
if [ "$DRY_RUN" = false ] && [ "$INCOMING_VERSION" != "unknown" ]; then
  if [ "$LEGACY" = true ] || { [ "$LOCAL_VERSION" != "unknown" ] && [ "$LOCAL_VERSION" != "$INCOMING_VERSION" ]; }; then
    VERSION_CHANGED=true
  fi
fi

# print_paths <log> <max>: list paths from a log, at most <max> of them.
print_paths() {
  local log="$1" max="$2" total
  total=$(wc -l < "$log" | tr -d ' ')
  head -n "$max" "$log" | while IFS= read -r line; do
    echo -e "    ${DIM}$line${NC}"
  done
  if [ "$total" -gt "$max" ]; then
    echo -e "    ${DIM}... and $((total - max)) more${NC}"
  fi
}

# --- Summary ---
echo ""
echo -e "  ${DIM}─────────────────────────────────────${NC}"

if [ "$DRY_RUN" = true ]; then
  TOTAL=$((CREATED + ADDED + UPDATED + MERGED))
  if [ "$TOTAL" -eq 0 ] && [ "$SKIPPED" -gt 0 ]; then
    echo -e "  ${GREEN}Preview:${NC} No changes needed — $SKIPPED items unchanged."
  else
    echo -e "  ${GREEN}Preview:${NC} Would create $CREATED, add $ADDED, merge $MERGED, update $UPDATED, skip $SKIPPED."
  fi
  if [ "$CONFLICTS" -gt 0 ]; then
    echo -e "  ${YELLOW}Warning:${NC} $CONFLICTS file(s) differ from the new template and may hold your edits."
    echo -e "  ${DIM}Your copies would be saved first, at:${NC}"
    print_paths "$CONFLICT_LOG" 15
  fi
  echo ""
  if [ "$LEGACY_PREVIEW" = true ]; then
    if [ "$BACKUP_MADE" = true ]; then
      echo -e "  ${BOLD}Nothing was changed${NC} (apart from the backup above)."
    else
      echo -e "  ${BOLD}Nothing was changed.${NC}"
    fi
    echo -e "  This install has no version stamp, so it is upgraded only with --force."
    echo -e "  Commit or back up your project first, then run:"
    echo -e "    ${BOLD}$(force_command)${NC}"
    echo -e "  ${DIM}Every file you changed is saved under .company-os/conflicts/<path>.user (guides in${NC}"
    echo -e "  ${DIM}.company-os/docs/ next to the file as <name>.user) before the new copy replaces it.${NC}"
  else
    echo -e "  ${DIM}Run without --dry-run to apply these changes.${NC}"
  fi
else
  TOTAL=$((CREATED + ADDED + UPDATED + MERGED))
  # A version change is reported as an upgrade even when no file was written
  # (every changed file held your edits): the version stamp still moved.
  if [ "$VERSION_CHANGED" = true ]; then
    from_label="$LOCAL_VERSION"
    [ "$LEGACY" = true ] && from_label="$LEGACY_VERSION (no version stamp)"
    echo -e "  ${GREEN}Done!${NC} Upgraded $from_label → $INCOMING_VERSION: $((UPDATED + MERGED)) updated, $((ADDED + CREATED)) added, $KEPT_EDITS kept with your edits."
  elif [ "$TOTAL" -eq 0 ]; then
    echo -e "  ${GREEN}Done!${NC} Already installed — nothing changed."
    if [ -s "$HELD_LOG" ]; then
      echo -e "  ${DIM}Use --force to update the files you edited (your copies are saved first)${NC}"
    fi
  else
    echo -e "  ${GREEN}Done!${NC} Created $CREATED, added $ADDED, merged $MERGED, updated $UPDATED, skipped $SKIPPED."
  fi
  if [ "$CONFLICTS" -gt 0 ]; then
    echo ""
    echo -e "  ${YELLOW}$CONFLICTS conflict(s) detected${NC} — $CONFLICT_USER_COPIES copy(ies) of your edited files saved at .company-os/conflicts/:"
    print_paths "$CONFLICT_LOG" 15
    echo -e "  ${DIM}Review the conflicts and merge manually.${NC}"
  fi
  if [ -s "$HELD_LOG" ]; then
    echo ""
    echo -e "  ${BLUE}Kept your edits${NC} in $(wc -l < "$HELD_LOG" | tr -d ' ') file(s) the template also changed:"
    print_paths "$HELD_LOG" 15
    echo -e "  ${DIM}To get the template version, rerun with --force (your copies are saved under .company-os/conflicts/ first).${NC}"
  fi
  if [ "$INCOMING_VERSION" != "unknown" ]; then
    echo ""
    echo -e "  ${DIM}Stamped${NC}  .company-os/version → $INCOMING_VERSION"
  fi
fi
echo ""

# Paths this install actually put in the project (for the git add hint).
installed_paths() {
  local out="" p
  for p in os tools .company-os company.config.yaml CLAUDE.md AGENTS.md \
           .claude .cursor .cursorrules GEMINI.md .codex \
           artifacts standards imports tasks seeds; do
    [ -e "$p" ] && out="$out $p"
  done
  echo "${out# }"
}

# --- Next steps (only on fresh install) ---
if [ "$IS_EXISTING_INSTALL" = false ] && [ "$DRY_RUN" = false ]; then
  echo -e "  ${BOLD}Next steps${NC} (one block per installed runtime):"
  echo ""
  SHOWN_RUNTIME=false
  if should_install_runtime claude; then
    echo -e "  ${BOLD}Claude Code${NC}"
    echo -e "    ${BLUE}1.${NC} Open Claude Code in this directory:  ${DIM}$ claude${NC}"
    echo -e "    ${BLUE}2.${NC} Run the setup wizard:  ${DIM}> /setup${NC}"
    echo -e "    ${BLUE}3.${NC} Build your first feature:  ${DIM}> /ship Build [feature] for [product]${NC}"
    echo ""
    SHOWN_RUNTIME=true
  fi
  if should_install_runtime cursor; then
    echo -e "  ${BOLD}Cursor${NC}"
    echo -e "    ${BLUE}1.${NC} Open Cursor in this directory. ${BOLD}.cursor/rules/00-company-os.mdc${NC} is always on; the skill catalog (${BOLD}10-skills.mdc${NC}) loads when a task needs it."
    echo -e "    ${BLUE}2.${NC} Ask Cursor to run the ${BOLD}setup${NC} skill (os/skills/setup/SKILL.md)."
    echo -e "    ${BLUE}3.${NC} Then ask it to run the ${BOLD}ship${NC} skill for your first feature."
    echo ""
    SHOWN_RUNTIME=true
  fi
  if should_install_runtime codex; then
    echo -e "  ${BOLD}Codex CLI${NC}"
    echo -e "    ${BLUE}1.${NC} Run ${BOLD}codex${NC} in this directory; it reads ${BOLD}AGENTS.md${NC} automatically."
    echo -e "    ${BLUE}2.${NC} Ask the agent to run the ${BOLD}setup${NC} skill (listed in the AGENTS.md skill catalog)."
    echo ""
    SHOWN_RUNTIME=true
  fi
  if should_install_runtime gemini; then
    echo -e "  ${BOLD}Gemini CLI${NC}"
    echo -e "    ${BLUE}1.${NC} Run ${BOLD}gemini${NC} in this directory; it reads ${BOLD}GEMINI.md${NC} automatically."
    echo -e "    ${BLUE}2.${NC} Ask the agent to run the ${BOLD}setup${NC} skill."
    echo ""
    SHOWN_RUNTIME=true
  fi
  if should_install_runtime aider; then
    echo -e "  ${BOLD}Aider${NC}"
    echo -e "    ${BLUE}1.${NC} Aider reads ${BOLD}AGENTS.md${NC} at session start; open the project as usual."
    echo -e "    ${BLUE}2.${NC} Ask aider to follow the ${BOLD}setup${NC} skill listed in AGENTS.md."
    echo ""
    SHOWN_RUNTIME=true
  fi
  if [ "$SHOWN_RUNTIME" = false ]; then
    echo -e "    ${BLUE}1.${NC} No specific runtime adapter installed."
    echo -e "       ${BOLD}AGENTS.md${NC} is present — any AGENTS.md-compatible agent can use it."
    echo -e "    ${BLUE}2.${NC} Add an adapter later with:"
    echo -e "       ${DIM}./tools/registry/install-runtime.sh <runtime>${NC}"
    echo ""
  fi
  echo -e "  ${DIM}Guide: ${NC}${BOLD}.company-os/docs/SETUP.md${NC}"
  echo -e "  ${DIM}Tip: ${NC}${DIM}see installed/available runtimes with: ${NC}${BOLD}./tools/registry/list-runtimes.sh${NC}"
  echo ""

  # --- Git hint ---
  if [ -d ".git" ]; then
    echo -e "  ${DIM}Tip: Commit the Company OS files before running setup${NC}"
    echo -e "  ${DIM}$ git add $(installed_paths) && git commit -m \"Add Company OS\"${NC}"
  else
    echo -e "  ${YELLOW}Note:${NC} No git repo detected. Run ${DIM}git init${NC} first — Company OS uses git for audit trails."
  fi
  echo ""
fi

# --- Upgrade next steps (on subsequent installs) ---
if [ "$IS_EXISTING_INSTALL" = true ] && [ "$DRY_RUN" = false ]; then
  TOTAL_CHANGES=$((CREATED + ADDED + UPDATED + MERGED))
  if [ "$TOTAL_CHANGES" -gt 0 ] || [ "$CONFLICTS" -gt 0 ] || [ "$VERSION_CHANGED" = true ]; then
    echo -e "  ${BOLD}Next steps:${NC}"
    echo ""
    STEP=1

    # If conflicts exist, that's the top priority
    if [ "$CONFLICTS" -gt 0 ]; then
      echo -e "    ${BLUE}${STEP}.${NC} Review conflicts in ${BOLD}.company-os/conflicts/${NC}:"
      echo -e "       ${DIM}Each conflict keeps its folder path (e.g. tools/qa/run.sh.user is yours, .new is the template;${NC}"
      echo -e "       ${DIM}with no .new, the file in place is the template copy). Later copies get a timestamp suffix.${NC}"
      echo -e "       ${DIM}Merge the changes you want to keep, then delete the conflict files.${NC}"
      STEP=$((STEP + 1))
      echo ""
    fi

    # Verify
    echo -e "    ${BLUE}${STEP}.${NC} Verify everything works:"
    echo -e "       ${DIM}$ bash tools/registry/health-check.sh${NC}   ${DIM}(or /status in Claude Code)${NC}"
    STEP=$((STEP + 1))
    echo ""

    # Commit the upgrade
    if [ -d ".git" ]; then
      if [ "$LOCAL_VERSION" = "$INCOMING_VERSION" ]; then
        commit_msg="chore: re-install Company OS ${INCOMING_VERSION}"
      elif [ "$LEGACY" = true ]; then
        commit_msg="chore: upgrade Company OS ${LEGACY_VERSION} → ${INCOMING_VERSION}"
      else
        commit_msg="chore: upgrade Company OS ${LOCAL_VERSION} → ${INCOMING_VERSION}"
      fi
      echo -e "    ${BLUE}${STEP}.${NC} Commit the upgrade:"
      echo -e "       ${DIM}$ git add $(installed_paths) && git commit -m \"$commit_msg\"${NC}"
      STEP=$((STEP + 1))
      echo ""
    fi
  fi

  echo -e "  ${DIM}Future: /upgrade-company-os check | preview | apply | rollback${NC}"
  echo ""
fi
