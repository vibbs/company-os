#!/usr/bin/env bash
# ============================================================================
# Company OS — Installer
# ============================================================================
# Downloads and installs Company OS overlay files into any project.
# This is the first step — run /setup in Claude Code afterward to configure.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh | bash -s -- --force
#
# Flags:
#   --force    Overwrite existing Company OS files (default: skip existing)
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
      echo "  --force    Overwrite existing Company OS files"
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

# The extracted directory name depends on the branch
SRC="$TMPDIR/company-os-$BRANCH"

if [ ! -d "$SRC" ]; then
  echo -e "${RED}Error:${NC} Download failed or archive structure unexpected."
  exit 1
fi

echo -e "  ${GREEN}Downloaded${NC}"
echo ""

# --- Install overlay files ---
COPIED=0
SKIPPED=0
UPDATED=0

copy_item() {
  local src="$1" dst="$2" label="$3"

  if [ -e "$dst" ]; then
    if [ "$FORCE" = true ]; then
      rm -rf "$dst"
      cp -r "$src" "$dst"
      echo -e "  ${YELLOW}Updated${NC}  $label"
      UPDATED=$((UPDATED + 1))
    else
      SKIPPED=$((SKIPPED + 1))
    fi
  else
    mkdir -p "$(dirname "$dst")"
    cp -r "$src" "$dst"
    echo -e "  ${GREEN}Created${NC}  $label"
    COPIED=$((COPIED + 1))
  fi
}

echo -e "  ${BOLD}Installing overlay files...${NC}"
echo ""

# Core overlay — these ARE Company OS
copy_item "$SRC/.claude"              ".claude"              ".claude/ (agents, skills, hooks, settings)"
copy_item "$SRC/tools"                "tools"                "tools/ (enforcement scripts)"
copy_item "$SRC/company.config.yaml"  "company.config.yaml"  "company.config.yaml (central config)"
copy_item "$SRC/CLAUDE.md"            "CLAUDE.md"            "CLAUDE.md (agent instructions)"

# Scaffold directories — create if missing, never overwrite
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
    # Add .gitkeep to empty directories
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

echo ""
echo -e "  ${DIM}─────────────────────────────────────${NC}"
echo -e "  ${GREEN}Done!${NC} Created $COPIED, updated $UPDATED, skipped $SKIPPED existing."
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
