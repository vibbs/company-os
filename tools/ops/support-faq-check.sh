#!/usr/bin/env bash
# Tool: T-OPS-02 Support FAQ Coverage Check
# Description: Validates FAQ coverage against PRD features
# Usage: ./tools/ops/support-faq-check.sh [prd-path]
# Inputs: optional path to a specific PRD file
# Outputs: coverage report, exit 0=good coverage 1=gaps found
set -euo pipefail

# ─── Color codes ──────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── Paths ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PRD_DIR="$REPO_ROOT/artifacts/prds"
FAQ_DIR="$REPO_ROOT/artifacts/support"

# ─── Usage ────────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] [prd-path]

Validate FAQ coverage against PRD acceptance criteria.

If prd-path is provided:
  Extract acceptance criteria from that PRD and check if FAQ entries exist.

If no prd-path:
  Scan all PRDs in artifacts/prds/ and report overall FAQ coverage.

Options:
  --help    Show this help message

Examples:
  $(basename "$0")
  $(basename "$0") artifacts/prds/PRD-001-user-auth.md
EOF
  exit 0
}

# ─── Parse arguments ──────────────────────────────────────────────────────────
PRD_PATH=""
if [[ ${1:-} == "--help" ]]; then
  usage
fi
if [[ $# -gt 0 ]]; then
  PRD_PATH="$1"
fi

# ─── Helper: extract acceptance criteria from a PRD ───────────────────────────
extract_criteria() {
  local prd_file="$1"
  # Look for lines that appear to be acceptance criteria:
  # - Lines under "Acceptance Criteria" heading
  # - Lines starting with "- [ ]" or "- [x]" or "- " in criteria sections
  # We use a broad match and let the caller interpret
  grep -iE '^\s*[-*]\s*(\[.\])?\s*.+' "$prd_file" 2>/dev/null || true
}

# ─── Helper: count FAQ entries ────────────────────────────────────────────────
count_faq_entries() {
  local faq_dir="$1"
  if [[ ! -d "$faq_dir" ]]; then
    echo "0"
    return
  fi
  local count
  count=$(grep -rl '^##\|^\*\*Q:' "$faq_dir" 2>/dev/null | wc -l || true)
  echo "${count// /}"
}

# ─── Helper: extract PRD title ───────────────────────────────────────────────
extract_prd_title() {
  local prd_file="$1"
  # Try to get the id from frontmatter, fall back to filename
  local prd_id
  prd_id=$(grep -m1 '^id:' "$prd_file" 2>/dev/null | sed 's/^id:\s*//' || true)
  if [[ -z "$prd_id" ]]; then
    prd_id=$(basename "$prd_file" .md)
  fi
  echo "$prd_id"
}

echo ""
echo -e "${BOLD}Support FAQ Coverage Check${RESET}"
echo "================================"
echo ""

# ─── Single PRD mode ──────────────────────────────────────────────────────────
if [[ -n "$PRD_PATH" ]]; then
  if [[ ! -f "$PRD_PATH" ]]; then
    echo -e "${RED}Error: PRD file not found: $PRD_PATH${RESET}" >&2
    exit 1
  fi

  PRD_TITLE=$(extract_prd_title "$PRD_PATH")
  echo -e "${BOLD}PRD:${RESET} $PRD_TITLE ($PRD_PATH)"
  echo ""

  # Extract acceptance criteria
  CRITERIA=$(extract_criteria "$PRD_PATH")
  CRITERIA_COUNT=$(echo "$CRITERIA" | grep -c '.' || true)

  if [[ "$CRITERIA_COUNT" -eq 0 ]]; then
    echo -e "${YELLOW}Warning: No acceptance criteria found in PRD.${RESET}"
    echo "Ensure the PRD has acceptance criteria formatted as bullet points."
    exit 0
  fi

  echo -e "${BOLD}Acceptance Criteria Found:${RESET} $CRITERIA_COUNT"
  echo ""

  # Check for FAQ files that reference this PRD
  FAQ_MATCHES=0
  if [[ -d "$FAQ_DIR" ]]; then
    FAQ_MATCHES=$(grep -rl "$PRD_TITLE" "$FAQ_DIR" 2>/dev/null | wc -l || true)
    FAQ_MATCHES="${FAQ_MATCHES// /}"
  fi

  if [[ "$FAQ_MATCHES" -gt 0 ]]; then
    echo -e "${GREEN}FAQ files referencing this PRD: $FAQ_MATCHES${RESET}"
    grep -rl "$PRD_TITLE" "$FAQ_DIR" 2>/dev/null | while IFS= read -r f; do
      echo "  - $f"
    done
  else
    echo -e "${RED}No FAQ files reference this PRD.${RESET}"
    echo ""
    echo "Recommendation: Create artifacts/support/faq-$(echo "$PRD_TITLE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-').md"
    echo "covering the $CRITERIA_COUNT acceptance criteria found."
  fi

  echo ""
  echo "================================"
  if [[ "$FAQ_MATCHES" -eq 0 ]]; then
    echo -e "${RED}Result: FAQ COVERAGE GAP${RESET}"
    exit 1
  else
    echo -e "${GREEN}Result: FAQ COVERAGE EXISTS${RESET}"
    exit 0
  fi
fi

# ─── All PRDs mode ────────────────────────────────────────────────────────────
if [[ ! -d "$PRD_DIR" ]]; then
  echo -e "${YELLOW}No PRD directory found at $PRD_DIR${RESET}"
  echo "Nothing to check."
  exit 0
fi

PRD_FILES=$(find "$PRD_DIR" -name "*.md" -not -name ".gitkeep" 2>/dev/null | sort || true)
PRD_COUNT=$(echo "$PRD_FILES" | grep -c '.' || true)

if [[ "$PRD_COUNT" -eq 0 ]]; then
  echo -e "${YELLOW}No PRD files found in $PRD_DIR${RESET}"
  echo "Nothing to check."
  exit 0
fi

echo -e "${BOLD}PRDs found:${RESET} $PRD_COUNT"

# Check FAQ directory
if [[ ! -d "$FAQ_DIR" ]]; then
  echo -e "${YELLOW}No FAQ directory found at $FAQ_DIR${RESET}"
  echo ""
  echo -e "${RED}Coverage: 0% (0/$PRD_COUNT PRDs have FAQ entries)${RESET}"
  echo ""
  echo "Recommendation: Run the support-operations skill to generate FAQ documents."
  exit 1
fi

FAQ_FILES=$(find "$FAQ_DIR" -name "faq-*.md" 2>/dev/null | sort || true)
FAQ_COUNT=$(echo "$FAQ_FILES" | grep -c '.' || true)

echo -e "${BOLD}FAQ files found:${RESET} $FAQ_COUNT"
echo ""

# Check coverage: for each PRD, see if a corresponding FAQ exists
COVERED=0
UNCOVERED=0
UNCOVERED_LIST=""

echo "$PRD_FILES" | while IFS= read -r prd_file; do
  [[ -z "$prd_file" ]] && continue
  prd_title=$(extract_prd_title "$prd_file")
  # Check if any FAQ file references this PRD
  faq_match=$(grep -rl "$prd_title" "$FAQ_DIR" 2>/dev/null | head -1 || true)
  if [[ -n "$faq_match" ]]; then
    echo -e "  ${GREEN}[covered]${RESET}   $prd_title"
  else
    echo -e "  ${RED}[missing]${RESET}   $prd_title"
  fi
done

# Calculate coverage percentage
COVERED_COUNT=$(echo "$PRD_FILES" | while IFS= read -r prd_file; do
  [[ -z "$prd_file" ]] && continue
  prd_title=$(extract_prd_title "$prd_file")
  faq_match=$(grep -rl "$prd_title" "$FAQ_DIR" 2>/dev/null | head -1 || true)
  if [[ -n "$faq_match" ]]; then
    echo "1"
  fi
done | wc -l || true)
COVERED_COUNT="${COVERED_COUNT// /}"

if [[ "$PRD_COUNT" -gt 0 ]]; then
  COVERAGE_PCT=$((COVERED_COUNT * 100 / PRD_COUNT))
else
  COVERAGE_PCT=0
fi

echo ""
echo "================================"
echo -e "${BOLD}Coverage:${RESET} ${COVERAGE_PCT}% (${COVERED_COUNT}/${PRD_COUNT} PRDs have FAQ entries)"
echo ""

if [[ "$COVERAGE_PCT" -ge 80 ]]; then
  echo -e "${GREEN}Result: GOOD COVERAGE${RESET}"
  exit 0
elif [[ "$COVERAGE_PCT" -ge 50 ]]; then
  echo -e "${YELLOW}Result: PARTIAL COVERAGE${RESET} -- consider generating FAQs for uncovered PRDs"
  exit 1
else
  echo -e "${RED}Result: LOW COVERAGE${RESET} -- run the support-operations skill to generate FAQ documents"
  exit 1
fi
