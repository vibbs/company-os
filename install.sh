#!/usr/bin/env bash
# ============================================================================
# Company OS — Installer & Upgrader (Smart Merge + Version Tracking)
# ============================================================================
# Downloads and installs Company OS overlay files into any project.
# Smart-merges with existing Claude Code setups — preserves user permissions,
# custom agents/skills, and project-specific CLAUDE.md content.
#
# Supports manifest-based conflict detection: auto-updates unmodified files,
# protects user edits, and flags conflicts when both sides changed.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh | bash -s -- --force
#
# Flags:
#   --force      Update existing Company OS files (default: skip existing)
#   --branch     Use a specific branch (default: main)
#   --version    Install a specific version (e.g., --version 1.2.0)
#   --dry-run    Preview what would change without applying
#   --check      Check if an upgrade is available
#   --changelog  Show changelog since installed version
#   --backup     Create backup before upgrading (auto-enabled for major upgrades)
#   --help       Show this help message
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

# --- Parse flags ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)     FORCE=true; shift ;;
    --branch)    BRANCH="$2"; shift 2 ;;
    --version)   TARGET_VERSION="$2"; shift 2 ;;
    --dry-run)   DRY_RUN=true; shift ;;
    --check)     CHECK_ONLY=true; shift ;;
    --changelog) SHOW_CHANGELOG=true; shift ;;
    --backup)    BACKUP=true; shift ;;
    --help)
      echo "Usage: curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash"
      echo ""
      echo "Flags:"
      echo "  --force      Update existing Company OS files (preserves user config)"
      echo "  --branch     Use a specific branch (default: main)"
      echo "  --version    Install a specific version (e.g., --version 1.2.0)"
      echo "  --dry-run    Preview what would change without applying"
      echo "  --check      Check if an upgrade is available"
      echo "  --changelog  Show changelog since installed version"
      echo "  --backup     Create backup before upgrading (auto for major upgrades)"
      exit 0
      ;;
    *) echo "Unknown flag: $1"; exit 1 ;;
  esac
done

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
file_hash() {
  local file="$1"
  if command -v shasum &>/dev/null; then
    shasum -a 256 "$file" 2>/dev/null | awk '{print $1}'
  elif command -v sha256sum &>/dev/null; then
    sha256sum "$file" 2>/dev/null | awk '{print $1}'
  else
    # Fallback: use cksum if neither sha tool available
    cksum "$file" 2>/dev/null | awk '{print $1}'
  fi
}

# Read a file's hash from the manifest. Returns empty string if not found.
manifest_hash() {
  local file="$1"
  local manifest_file=""
  if [ -f ".company-os/manifest" ]; then
    manifest_file=".company-os/manifest"
  elif [ -f ".company-os-manifest" ]; then
    manifest_file=".company-os-manifest"
  fi
  if [ -n "$manifest_file" ]; then
    grep "  $file$" "$manifest_file" 2>/dev/null | awk '{print $1}' || true
  fi
}

# Generate manifest of all template files after installation
generate_manifest() {
  local version="$1"
  mkdir -p .company-os
  echo "# Company OS v$version manifest" > .company-os/manifest
  echo "# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> .company-os/manifest

  # Hash all template-owned files
  for dir in .claude/agents .claude/skills .claude/hooks tools; do
    if [ -d "$dir" ]; then
      while IFS= read -r file; do
        hash=$(file_hash "$file")
        echo "$hash  $file" >> .company-os/manifest
      done < <(find "$dir" -type f 2>/dev/null | sort)
    fi
  done
}

# Check if user modified a file (current hash differs from manifest hash)
user_modified() {
  local file="$1"
  local recorded
  recorded=$(manifest_hash "$file")
  if [ -z "$recorded" ]; then
    # Not in manifest — can't tell, assume not modified
    return 1
  fi
  local current
  current=$(file_hash "$file")
  [ "$current" != "$recorded" ]
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
  local version="$1"
  local backup_dir=".company-os/backup/$(date +%Y%m%d-%H%M%S)-v${version}"
  mkdir -p "$backup_dir"

  for dir in .claude/agents .claude/skills .claude/hooks tools; do
    if [ -d "$dir" ]; then
      local target_dir="$backup_dir/$dir"
      mkdir -p "$(dirname "$target_dir")"
      cp -r "$dir" "$target_dir"
    fi
  done

  # Also backup CLAUDE.md
  [ -f "CLAUDE.md" ] && cp "CLAUDE.md" "$backup_dir/"

  echo "$backup_dir"
}

# --- Header ---
echo ""
echo -e "${BOLD}  Company OS — Installer${NC}"
echo -e "${DIM}  ─────────────────────────────────────${NC}"
echo ""

# --- Pre-flight checks ---
if ! command -v curl &>/dev/null && ! command -v wget &>/dev/null; then
  echo -e "${RED}Error:${NC} curl or wget is required but not installed."
  exit 1
fi

if ! command -v tar &>/dev/null; then
  echo -e "${RED}Error:${NC} tar is required but not installed."
  exit 1
fi

# --- Read local version ---
LOCAL_VERSION="unknown"
if [ -f ".company-os/version" ]; then
  LOCAL_VERSION=$(cat .company-os/version | tr -d '[:space:]')
elif [ -f ".company-os-version" ]; then
  LOCAL_VERSION=$(cat .company-os-version | tr -d '[:space:]')
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

# --- Determine download reference ---
DOWNLOAD_REF="$BRANCH"
if [ -n "$TARGET_VERSION" ]; then
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
trap "rm -rf $WORK_DIR" EXIT

echo -e "  ${DIM}Downloading from github.com/$REPO ($DOWNLOAD_REF)...${NC}"
ARCHIVE_URL="https://github.com/$REPO/archive/$DOWNLOAD_REF.tar.gz"

if command -v curl &>/dev/null; then
  curl -fsSL "$ARCHIVE_URL" | tar -xz -C "$WORK_DIR"
else
  wget -qO- "$ARCHIVE_URL" | tar -xz -C "$WORK_DIR"
fi

# Find the extracted directory (name varies by branch/tag)
SRC=$(find "$WORK_DIR" -maxdepth 1 -type d -name "company-os-*" | head -1)

if [ -z "$SRC" ] || [ ! -d "$SRC" ]; then
  echo -e "${RED}Error:${NC} Download failed or archive structure unexpected."
  exit 1
fi

echo -e "  ${GREEN}Downloaded${NC}"
echo ""

# --- Read incoming version ---
INCOMING_VERSION="unknown"
if [ -f "$SRC/VERSION" ]; then
  INCOMING_VERSION=$(cat "$SRC/VERSION" | tr -d '[:space:]')
fi

# --- Display version info ---
if [ "$LOCAL_VERSION" != "unknown" ] || [ "$INCOMING_VERSION" != "unknown" ]; then
  UPGRADE_TYPE=$(upgrade_type "$LOCAL_VERSION" "$INCOMING_VERSION")

  echo -e "  ${BOLD}Version${NC}"
  echo -e "    Installed:  ${BOLD}$LOCAL_VERSION${NC}"
  echo -e "    Available:  ${BOLD}$INCOMING_VERSION${NC} ($UPGRADE_TYPE)"
  echo ""
fi

# ============================================================================
# Check-only mode
# ============================================================================
if [ "$CHECK_ONLY" = true ]; then
  if [ "$LOCAL_VERSION" = "$INCOMING_VERSION" ]; then
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
    if [ -f "$SRC/CHANGELOG.md" ]; then
      extract_changelog "$SRC/CHANGELOG.md" "$LOCAL_VERSION" "$INCOMING_VERSION"
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
  if [ -f "$SRC/CHANGELOG.md" ]; then
    if [ "$LOCAL_VERSION" = "unknown" ]; then
      echo -e "  ${BOLD}Full Changelog:${NC}"
      echo ""
      cat "$SRC/CHANGELOG.md" | sed 's/^/  /'
    else
      extract_changelog "$SRC/CHANGELOG.md" "$LOCAL_VERSION" "$INCOMING_VERSION"
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

      if [ -f "$SRC/CHANGELOG.md" ]; then
        extract_changelog "$SRC/CHANGELOG.md" "$LOCAL_VERSION" "$INCOMING_VERSION"
        echo ""
      fi

      echo -e "  Use ${BOLD}--force${NC} to proceed, or ${BOLD}--dry-run --force${NC} to preview first."
      exit 1
    fi
  fi
fi

# ============================================================================
# Backup (if requested or auto-enabled for major upgrades)
# ============================================================================
if [ "$BACKUP" = true ] && [ "$DRY_RUN" = false ] && [ "$LOCAL_VERSION" != "unknown" ]; then
  backup_path=$(create_backup "$LOCAL_VERSION")
  echo -e "  ${BLUE}Backup${NC}   Created at $backup_path"
  echo ""
fi

# ============================================================================
# Smart Merge Functions
# ============================================================================

# merge_directory: Copies items from src_dir into dst_dir individually.
# Uses manifest for three-way conflict detection when available.
# New items are always added. Existing items use manifest-based logic.
# Usage: merge_directory <src_dir> <dst_dir> <label>
merge_directory() {
  local src_dir="$1" dst_dir="$2" label="$3"
  local new_count=0 existing_count=0 conflict_count=0 auto_updated=0

  if [ ! -d "$src_dir" ]; then
    return
  fi

  if [ "$DRY_RUN" = false ]; then
    mkdir -p "$dst_dir"
  fi

  for item in "$src_dir"/*; do
    [ -e "$item" ] || continue  # skip if glob matched nothing
    local name
    name=$(basename "$item")

    if [ -e "$dst_dir/$name" ]; then
      # --- Manifest-based three-way merge ---
      if [ -f ".company-os/manifest" ] || [ -f ".company-os-manifest" ]; then
        # Determine if user modified the existing file(s)
        local has_user_mods=false
        if [ -d "$dst_dir/$name" ]; then
          # Directory: check if any file inside was modified
          while IFS= read -r subfile; do
            if user_modified "$subfile"; then
              has_user_mods=true
              break
            fi
          done < <(find "$dst_dir/$name" -type f 2>/dev/null)
        else
          # Single file
          if user_modified "$dst_dir/$name"; then
            has_user_mods=true
          fi
        fi

        if [ "$has_user_mods" = true ]; then
          # User modified this — check if template also changed
          # (We can't easily diff template versions, so if user modified + force, warn about conflict)
          if [ "$FORCE" = true ]; then
            if [ "$DRY_RUN" = false ]; then
              # Save conflict copies
              mkdir -p ".company-os/conflicts"
              if [ -d "$dst_dir/$name" ]; then
                cp -r "$dst_dir/$name" ".company-os/conflicts/${name}.user"
                cp -r "$item" ".company-os/conflicts/${name}.new"
              else
                cp "$dst_dir/$name" ".company-os/conflicts/${name}.user"
                cp "$item" ".company-os/conflicts/${name}.new"
              fi
              rm -rf "$dst_dir/$name"
              cp -r "$item" "$dst_dir/$name"
            fi
            conflict_count=$((conflict_count + 1))
            CONFLICTS=$((CONFLICTS + 1))
            UPDATED=$((UPDATED + 1))
          else
            existing_count=$((existing_count + 1))
            SKIPPED=$((SKIPPED + 1))
          fi
        else
          # User did NOT modify — safe to auto-update
          if [ "$DRY_RUN" = false ]; then
            rm -rf "$dst_dir/$name"
            cp -r "$item" "$dst_dir/$name"
          fi
          auto_updated=$((auto_updated + 1))
          UPDATED=$((UPDATED + 1))
        fi
      else
        # --- No manifest: fall back to original skip/force behavior ---
        if [ "$FORCE" = true ]; then
          if [ "$DRY_RUN" = false ]; then
            rm -rf "$dst_dir/$name"
            cp -r "$item" "$dst_dir/$name"
          fi
          UPDATED=$((UPDATED + 1))
        else
          existing_count=$((existing_count + 1))
          SKIPPED=$((SKIPPED + 1))
        fi
      fi
    else
      # New item — always add
      if [ "$DRY_RUN" = false ]; then
        cp -r "$item" "$dst_dir/$name"
      fi
      new_count=$((new_count + 1))
      ADDED=$((ADDED + 1))
    fi
  done

  # Report
  if [ "$conflict_count" -gt 0 ]; then
    echo -e "  ${RED}Conflict${NC} $label ($conflict_count conflicts — see .company-os/conflicts/)"
  elif [ "$auto_updated" -gt 0 ] && [ "$new_count" -gt 0 ]; then
    echo -e "  ${GREEN}Updated${NC}  $label ($new_count new, $auto_updated auto-updated)"
  elif [ "$auto_updated" -gt 0 ]; then
    echo -e "  ${GREEN}Updated${NC}  $label ($auto_updated auto-updated)"
  elif [ "$FORCE" = true ] && [ "$existing_count" -eq 0 ] && [ "$new_count" -gt 0 ]; then
    echo -e "  ${GREEN}Created${NC}  $label ($new_count items)"
  elif [ "$new_count" -gt 0 ] && [ "$existing_count" -gt 0 ]; then
    echo -e "  ${GREEN}Added${NC}    $label ($new_count new, $existing_count existing preserved)"
  elif [ "$new_count" -gt 0 ]; then
    echo -e "  ${GREEN}Created${NC}  $label ($new_count items)"
  elif [ "$FORCE" = true ]; then
    echo -e "  ${YELLOW}Updated${NC}  $label"
  else
    echo -e "  ${DIM}Exists${NC}   $label ($existing_count items preserved)"
  fi
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

# Write merged result
with open(dst_path, "w") as f:
    json.dump(dst, f, indent=2)
    f.write("\n")

# Report
total_added = added_allow + added_deny
total_preserved = preserved_allow + preserved_deny
hooks_msg = ", hooks added" if hooks_added else ""
print(f"added {total_added} rules, preserved {total_preserved} custom{hooks_msg}")
PYEOF
  ) || true

  if [ -n "$result" ]; then
    echo -e "  ${GREEN}Merged${NC}   .claude/settings.json ($result)"
    MERGED=$((MERGED + 1))
  else
    echo -e "  ${YELLOW}Warning${NC}  .claude/settings.json — merge failed, existing file preserved"
    SKIPPED=$((SKIPPED + 1))
  fi
}

# merge_claude_md: Appends Company OS section to existing CLAUDE.md.
# Detects the "## Company OS Overview" marker to avoid double-appending.
# Usage: merge_claude_md <src_file> <dst_file>
merge_claude_md() {
  local src_file="$1" dst_file="$2"

  if [ ! -f "$dst_file" ]; then
    # No existing CLAUDE.md — just copy
    if [ "$DRY_RUN" = false ]; then
      cp "$src_file" "$dst_file"
    fi
    echo -e "  ${GREEN}Created${NC}  CLAUDE.md"
    CREATED=$((CREATED + 1))
    return
  fi

  # Check if Company OS section already exists
  if grep -q "## Company OS Overview" "$dst_file" 2>/dev/null; then
    if [ "$FORCE" = true ]; then
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

      printf '%s\n\n---\n\n%s\n' "$user_content" "$cos_section" > "$dst_file"
      echo -e "  ${YELLOW}Updated${NC}  CLAUDE.md (Company OS section refreshed, user content preserved)"
      UPDATED=$((UPDATED + 1))
    else
      echo -e "  ${DIM}Exists${NC}   CLAUDE.md (Company OS section already present)"
      SKIPPED=$((SKIPPED + 1))
    fi
    return
  fi

  # No Company OS section found — append it
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

# --- .claude/ (per-component smart merge) ---
if [ "$DRY_RUN" = false ]; then
  mkdir -p .claude
fi
merge_directory "$SRC/.claude/agents"  ".claude/agents"  ".claude/agents/"
merge_directory "$SRC/.claude/skills"  ".claude/skills"  ".claude/skills/"
merge_directory "$SRC/.claude/hooks"   ".claude/hooks"   ".claude/hooks/"
merge_settings_json "$SRC/.claude/settings.json" ".claude/settings.json"

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

# --- Version stamp (Company OS version only — NOT app version files) ---
# Company OS tracks its installed version via .company-os/version (not VERSION or CHANGELOG.md).
# VERSION and CHANGELOG.md are intentionally NOT copied to user projects — they would conflict
# with the user's own app version and changelog files. Users read the Company OS changelog
# via /upgrade-company-os or GitHub.
if [ -f "$SRC/VERSION" ]; then
  if [ "$DRY_RUN" = false ]; then
    mkdir -p .company-os
    cp "$SRC/VERSION" ".company-os/version"
  fi
fi

# --- Scaffold directories (create if missing, never overwrite) ---
if [ "$DRY_RUN" = false ]; then
  for dir in \
    artifacts/prds artifacts/rfcs artifacts/test-plans artifacts/qa-reports \
    artifacts/launch-briefs artifacts/security-reviews artifacts/decision-memos \
    artifacts/.audit-log \
    standards/api standards/coding standards/compliance standards/templates \
    standards/brand standards/ops standards/analytics standards/docs \
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
      cp "$migration_file" ".company-os/migrations/$mig_name"
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
    echo -e "  ${YELLOW}Warning:${NC} $CONFLICTS file(s) modified by you AND changed in template."
    echo -e "  ${DIM}These will be saved to .company-os/conflicts/ on upgrade.${NC}"
  fi
  echo ""
  echo -e "  ${DIM}Run without --dry-run to apply these changes.${NC}"
else
  TOTAL=$((CREATED + ADDED + UPDATED + MERGED))
  if [ "$TOTAL" -eq 0 ] && [ "$SKIPPED" -gt 0 ]; then
    echo -e "  ${GREEN}Done!${NC} Already installed — $SKIPPED items unchanged."
    echo -e "  ${DIM}Use --force to update Company OS files${NC}"
  else
    if [ "$LOCAL_VERSION" != "unknown" ] && [ "$INCOMING_VERSION" != "unknown" ] && [ "$LOCAL_VERSION" != "$INCOMING_VERSION" ]; then
      echo -e "  ${GREEN}Done!${NC} Upgraded $LOCAL_VERSION → $INCOMING_VERSION"
    else
      echo -e "  ${GREEN}Done!${NC} Created $CREATED, added $ADDED, merged $MERGED, updated $UPDATED, skipped $SKIPPED."
    fi
  fi
  if [ "$CONFLICTS" -gt 0 ]; then
    echo ""
    echo -e "  ${YELLOW}$CONFLICTS conflict(s) detected${NC} — your modified versions saved to .company-os/conflicts/"
    echo -e "  ${DIM}Review the conflicts and merge manually.${NC}"
  fi
  if [ "$INCOMING_VERSION" != "unknown" ]; then
    echo ""
    echo -e "  ${DIM}Stamped${NC}  .company-os/version → $INCOMING_VERSION"
  fi
fi
echo ""

# --- Next steps (only on fresh install) ---
if [ "$LOCAL_VERSION" = "unknown" ] && [ "$DRY_RUN" = false ]; then
  echo -e "  ${BOLD}Next steps:${NC}"
  echo ""
  echo -e "    ${BLUE}1.${NC} Open Claude Code in this directory:"
  echo -e "       ${DIM}$ claude${NC}"
  echo ""
  echo -e "    ${BLUE}2.${NC} Run the setup wizard:"
  echo -e "       ${DIM}> /setup${NC}"
  echo ""
  echo -e "       Three ways to configure:"
  echo -e "       ${DIM}> /setup                              ${NC}${DIM}# interactive wizard${NC}"
  echo -e "       ${DIM}> /setup https://yoursite.com          ${NC}${DIM}# auto-extract from URL${NC}"
  echo -e "       ${DIM}> /setup                              ${NC}${DIM}# + paste config block${NC}"
  echo ""
  echo -e "    ${BLUE}3.${NC} Build your first feature:"
  echo -e "       ${DIM}> Build [feature] for [product]${NC}"
  echo ""

  # --- Git hint ---
  if [ -d ".git" ]; then
    echo -e "  ${DIM}Tip: Commit the Company OS files before running /setup${NC}"
    echo -e "  ${DIM}$ git add .claude tools .company-os company.config.yaml CLAUDE.md && git commit -m \"Add Company OS\"${NC}"
  else
    echo -e "  ${YELLOW}Note:${NC} No git repo detected. Run ${DIM}git init${NC} first — Company OS uses git for audit trails."
  fi
  echo ""
fi

# --- Upgrade next steps (on subsequent installs) ---
if [ "$LOCAL_VERSION" != "unknown" ] && [ "$DRY_RUN" = false ]; then
  TOTAL_CHANGES=$((CREATED + ADDED + UPDATED + MERGED))
  if [ "$TOTAL_CHANGES" -gt 0 ] || [ "$CONFLICTS" -gt 0 ]; then
    echo -e "  ${BOLD}Next steps:${NC}"
    echo ""
    STEP=1

    # If conflicts exist, that's the top priority
    if [ "$CONFLICTS" -gt 0 ]; then
      echo -e "    ${BLUE}${STEP}.${NC} Review conflicts in ${BOLD}.company-os/conflicts/${NC}:"
      echo -e "       ${DIM}Each conflict has a .user (your version) and .new (template version)${NC}"
      echo -e "       ${DIM}Merge the changes you want to keep, then delete the conflict files.${NC}"
      STEP=$((STEP + 1))
      echo ""
    fi

    # Verify
    echo -e "    ${BLUE}${STEP}.${NC} Verify everything works:"
    echo -e "       ${DIM}> /status${NC}"
    STEP=$((STEP + 1))
    echo ""

    # Commit the upgrade
    if [ -d ".git" ]; then
      echo -e "    ${BLUE}${STEP}.${NC} Commit the upgrade:"
      echo -e "       ${DIM}$ git add .claude tools .company-os CLAUDE.md && git commit -m \"chore: upgrade Company OS ${LOCAL_VERSION} → ${INCOMING_VERSION}\"${NC}"
      STEP=$((STEP + 1))
      echo ""
    fi
  fi

  echo -e "  ${DIM}Future: /upgrade-company-os check | preview | apply | rollback${NC}"
  echo ""
fi
