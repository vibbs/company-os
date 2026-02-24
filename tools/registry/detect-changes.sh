#!/usr/bin/env bash
# Tool: Detect Changes
# Description: Scans standards/ and artifacts/ for new or recently modified files
# Usage: ./tools/registry/detect-changes.sh [--since YYYY-MM-DD] [--dir standards|artifacts|all]
# Inputs: optional date filter, optional directory filter
# Outputs: structured report of new/modified files
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SCRIPT_DIR/../.."
STANDARDS_DIR="$BASE_DIR/standards"
ARTIFACTS_DIR="$BASE_DIR/artifacts"

# Parse arguments
SINCE=""
DIR_FILTER="all"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --since)
      SINCE="$2"
      shift 2
      ;;
    --dir)
      DIR_FILTER="$2"
      shift 2
      ;;
    *)
      echo "ERROR: Unknown argument: $1"
      echo "Usage: ./tools/registry/detect-changes.sh [--since YYYY-MM-DD] [--dir standards|artifacts|all]"
      exit 1
      ;;
  esac
done

# Validate dir filter
if [[ "$DIR_FILTER" != "all" && "$DIR_FILTER" != "standards" && "$DIR_FILTER" != "artifacts" ]]; then
  echo "ERROR: --dir must be 'standards', 'artifacts', or 'all'"
  exit 1
fi

# --- Helpers ---

extract_field() {
  local FILE="$1"
  local FIELD="$2"
  sed -n '/^---$/,/^---$/p' "$FILE" | grep "^${FIELD}:" | sed "s/${FIELD}: *//" | tr -d '"' | tr -d "'" 2>/dev/null || true
}

format_size() {
  local SIZE="$1"
  if [[ "$SIZE" -gt 1048576 ]]; then
    echo "$((SIZE / 1048576)).$(( (SIZE % 1048576) / 104858 ))MB"
  elif [[ "$SIZE" -gt 1024 ]]; then
    echo "$((SIZE / 1024)).$(( (SIZE % 1024) / 103 ))KB"
  else
    echo "${SIZE}B"
  fi
}

# Determine the date filter for find command
TEMP_REF=""
if [[ -n "$SINCE" ]]; then
  # Validate date format
  if ! date -j -f "%Y-%m-%d" "$SINCE" "+%s" > /dev/null 2>&1 && \
     ! date -d "$SINCE" "+%s" > /dev/null 2>&1; then
    echo "ERROR: Invalid date format: '$SINCE' (expected YYYY-MM-DD)"
    exit 1
  fi

  # Create a temp file with the reference date for -newer
  TEMP_REF=$(mktemp)
  if [[ "$(uname)" == "Darwin" ]]; then
    touch -t "$(date -j -f '%Y-%m-%d' "$SINCE" '+%Y%m%d0000')" "$TEMP_REF"
  else
    touch -d "$SINCE" "$TEMP_REF"
  fi
  SINCE_LABEL="since $SINCE"
else
  SINCE_LABEL="all files"
fi

# Helper: run find with optional date filter
find_files() {
  local DIR="$1"
  if [[ -n "$TEMP_REF" ]]; then
    find "$DIR" -type f -newer "$TEMP_REF" -print0 2>/dev/null
  else
    find "$DIR" -type f -print0 2>/dev/null
  fi
}

# --- Scan directories ---

STANDARDS_COUNT=0
ARTIFACTS_COUNT=0

echo "=== Change Detection Report ($SINCE_LABEL) ==="
echo ""

# Scan standards/
if [[ "$DIR_FILTER" == "all" || "$DIR_FILTER" == "standards" ]]; then
  echo "STANDARDS:"

  FOUND_ANY=false
  while IFS= read -r -d '' file; do
    # Skip .gitkeep
    [[ "$(basename "$file")" == ".gitkeep" ]] && continue

    FOUND_ANY=true
    STANDARDS_COUNT=$((STANDARDS_COUNT + 1))

    # Get file info
    REL_PATH="${file#$BASE_DIR/}"
    if [[ "$(uname)" == "Darwin" ]]; then
      FILE_SIZE=$(stat -f %z "$file")
      FILE_DATE=$(stat -f %Sm -t "%Y-%m-%d" "$file")
    else
      FILE_SIZE=$(stat -c %s "$file")
      FILE_DATE=$(stat -c %y "$file" | cut -d' ' -f1)
    fi
    SIZE_FMT=$(format_size "$FILE_SIZE")

    # Determine subdirectory category
    SUBDIR=$(echo "$REL_PATH" | cut -d'/' -f2)

    echo "  [$SUBDIR] $REL_PATH  ($FILE_DATE, $SIZE_FMT)"

  done < <(find_files "$STANDARDS_DIR")

  if [[ "$FOUND_ANY" == "false" ]]; then
    echo "  (no files found)"
  fi
  echo ""
fi

# Scan artifacts/
if [[ "$DIR_FILTER" == "all" || "$DIR_FILTER" == "artifacts" ]]; then
  echo "ARTIFACTS:"

  FOUND_ANY=false
  while IFS= read -r -d '' file; do
    # Skip .gitkeep, audit log
    [[ "$(basename "$file")" == ".gitkeep" ]] && continue
    [[ "$file" == *".audit-log"* ]] && continue

    FOUND_ANY=true
    ARTIFACTS_COUNT=$((ARTIFACTS_COUNT + 1))

    # Get file info
    REL_PATH="${file#$BASE_DIR/}"
    if [[ "$(uname)" == "Darwin" ]]; then
      FILE_SIZE=$(stat -f %z "$file")
      FILE_DATE=$(stat -f %Sm -t "%Y-%m-%d" "$file")
    else
      FILE_SIZE=$(stat -c %s "$file")
      FILE_DATE=$(stat -c %y "$file" | cut -d' ' -f1)
    fi
    SIZE_FMT=$(format_size "$FILE_SIZE")

    # Extract artifact metadata if it's a .md file
    META=""
    if [[ "$file" == *.md ]]; then
      FIRST_LINE=$(head -1 "$file" 2>/dev/null || true)
      if [[ "$FIRST_LINE" == "---" ]]; then
        A_TYPE=$(extract_field "$file" "type")
        A_STATUS=$(extract_field "$file" "status")
        A_ID=$(extract_field "$file" "id")
        [[ -n "$A_TYPE" || -n "$A_STATUS" ]] && META="  (type: $A_TYPE, status: $A_STATUS, id: $A_ID)"
      fi
    fi

    echo "  $REL_PATH  ($FILE_DATE, $SIZE_FMT)${META}"

  done < <(find_files "$ARTIFACTS_DIR")

  if [[ "$FOUND_ANY" == "false" ]]; then
    echo "  (no files found)"
  fi
  echo ""
fi

# Cleanup temp file
[[ -n "${TEMP_REF:-}" ]] && rm -f "$TEMP_REF"

# Summary
echo "=== SUMMARY ==="
echo "  Standards files: $STANDARDS_COUNT"
echo "  Artifact files: $ARTIFACTS_COUNT"
echo "  Total: $((STANDARDS_COUNT + ARTIFACTS_COUNT))"
