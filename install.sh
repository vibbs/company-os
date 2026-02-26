#!/usr/bin/env bash
# ============================================================================
# Company OS — Installer (Smart Merge)
# ============================================================================
# Downloads and installs Company OS overlay files into any project.
# Smart-merges with existing Claude Code setups — preserves user permissions,
# custom agents/skills, and project-specific CLAUDE.md content.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh | bash -s -- --force
#
# Flags:
#   --force    Update existing Company OS files (default: skip existing)
#   --branch   Use a specific branch (default: main)
#   --help     Show this help message
# ============================================================================

set -euo pipefail

# --- Configuration ---
REPO="vibbs/company-os"
BRANCH="main"
FORCE=false

# --- Parse flags ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)  FORCE=true; shift ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --help)
      echo "Usage: curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash"
      echo ""
      echo "Flags:"
      echo "  --force    Update existing Company OS files (preserves user config)"
      echo "  --branch   Use a specific branch (default: main)"
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
  echo ""
fi

# --- Download ---
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo -e "  ${DIM}Downloading from github.com/$REPO ($BRANCH)...${NC}"
ARCHIVE_URL="https://github.com/$REPO/archive/$BRANCH.tar.gz"

if command -v curl &>/dev/null; then
  curl -fsSL "$ARCHIVE_URL" | tar -xz -C "$TMPDIR"
else
  wget -qO- "$ARCHIVE_URL" | tar -xz -C "$TMPDIR"
fi

SRC="$TMPDIR/company-os-$BRANCH"

if [ ! -d "$SRC" ]; then
  echo -e "${RED}Error:${NC} Download failed or archive structure unexpected."
  exit 1
fi

echo -e "  ${GREEN}Downloaded${NC}"
echo ""

# ============================================================================
# Smart Merge Functions
# ============================================================================

# merge_directory: Copies items from src_dir into dst_dir individually.
# New items are always added. Existing items are skipped (or replaced with --force).
# Usage: merge_directory <src_dir> <dst_dir> <label>
merge_directory() {
  local src_dir="$1" dst_dir="$2" label="$3"
  local new_count=0 existing_count=0

  if [ ! -d "$src_dir" ]; then
    return
  fi

  mkdir -p "$dst_dir"

  for item in "$src_dir"/*; do
    [ -e "$item" ] || continue  # skip if glob matched nothing
    local name
    name=$(basename "$item")

    if [ -e "$dst_dir/$name" ]; then
      if [ "$FORCE" = true ]; then
        rm -rf "$dst_dir/$name"
        cp -r "$item" "$dst_dir/$name"
        UPDATED=$((UPDATED + 1))
      else
        existing_count=$((existing_count + 1))
        SKIPPED=$((SKIPPED + 1))
      fi
    else
      cp -r "$item" "$dst_dir/$name"
      new_count=$((new_count + 1))
      ADDED=$((ADDED + 1))
    fi
  done

  # Report
  if [ "$FORCE" = true ] && [ "$existing_count" -eq 0 ] && [ "$new_count" -gt 0 ]; then
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
    mkdir -p "$(dirname "$dst_file")"
    cp "$src_file" "$dst_file"
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
    cp "$src_file" "$dst_file"
    echo -e "  ${GREEN}Created${NC}  CLAUDE.md"
    CREATED=$((CREATED + 1))
    return
  fi

  # Check if Company OS section already exists
  if grep -q "## Company OS Overview" "$dst_file" 2>/dev/null; then
    if [ "$FORCE" = true ]; then
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
# Install
# ============================================================================

echo -e "  ${BOLD}Installing overlay files...${NC}"
echo ""

# --- .claude/ (per-component smart merge) ---
mkdir -p .claude
merge_directory "$SRC/.claude/agents"  ".claude/agents"  ".claude/agents/"
merge_directory "$SRC/.claude/skills"  ".claude/skills"  ".claude/skills/"
merge_directory "$SRC/.claude/hooks"   ".claude/hooks"   ".claude/hooks/"
merge_settings_json "$SRC/.claude/settings.json" ".claude/settings.json"

# --- tools/ (per-subdirectory smart merge) ---
mkdir -p tools
for tool_dir in "$SRC"/tools/*/; do
  [ -d "$tool_dir" ] || continue
  local_name=$(basename "$tool_dir")
  merge_directory "$tool_dir" "tools/$local_name" "tools/$local_name/"
done

# --- CLAUDE.md (smart append) ---
merge_claude_md "$SRC/CLAUDE.md" "CLAUDE.md"

# --- company.config.yaml (always protected) ---
if [ ! -f "company.config.yaml" ]; then
  cp "$SRC/company.config.yaml" "company.config.yaml"
  echo -e "  ${GREEN}Created${NC}  company.config.yaml"
  CREATED=$((CREATED + 1))
else
  echo -e "  ${DIM}Kept${NC}     company.config.yaml (existing config preserved)"
  SKIPPED=$((SKIPPED + 1))
fi

# --- Scaffold directories (create if missing, never overwrite) ---
for dir in \
  artifacts/prds artifacts/rfcs artifacts/test-plans artifacts/qa-reports \
  artifacts/launch-briefs artifacts/security-reviews artifacts/decision-memos \
  artifacts/.audit-log \
  standards/api standards/coding standards/compliance standards/templates \
  standards/brand standards/ops standards/analytics standards/docs \
  standards/email standards/engineering \
  imports tasks; do
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

# Make all tool scripts executable
find tools/ -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true

# --- Summary ---
echo ""
echo -e "  ${DIM}─────────────────────────────────────${NC}"
TOTAL=$((CREATED + ADDED + UPDATED + MERGED))
if [ "$TOTAL" -eq 0 ] && [ "$SKIPPED" -gt 0 ]; then
  echo -e "  ${GREEN}Done!${NC} Already installed — $SKIPPED items unchanged."
  echo -e "  ${DIM}Use --force to update Company OS files${NC}"
else
  echo -e "  ${GREEN}Done!${NC} Created $CREATED, added $ADDED, merged $MERGED, updated $UPDATED, skipped $SKIPPED."
fi
echo ""

# --- Next steps ---
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
  echo -e "  ${DIM}$ git add .claude tools company.config.yaml CLAUDE.md && git commit -m \"Add Company OS\"${NC}"
else
  echo -e "  ${YELLOW}Note:${NC} No git repo detected. Run ${DIM}git init${NC} first — Company OS uses git for audit trails."
fi
echo ""
