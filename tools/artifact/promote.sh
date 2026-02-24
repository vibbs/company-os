#!/usr/bin/env bash
# Tool: Artifact Promote
# Description: Promotes artifact status with lifecycle ordering and prerequisite checks
# Usage: ./tools/artifact/promote.sh <artifact-path> <new-status>
# Inputs: artifact path + target status (draft → review → approved → archived)
# Outputs: updated artifact file + audit log entry
set -euo pipefail

ARTIFACT_PATH="${1:-}"
NEW_STATUS="${2:-}"

if [[ -z "$ARTIFACT_PATH" || -z "$NEW_STATUS" ]]; then
  echo "ERROR: Missing arguments"
  echo "Usage: ./tools/artifact/promote.sh <artifact-path> <new-status>"
  echo "  Lifecycle: draft → review → approved → archived"
  exit 1
fi

if [[ ! -f "$ARTIFACT_PATH" ]]; then
  echo "ERROR: File not found: $ARTIFACT_PATH"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ARTIFACTS_DIR="$SCRIPT_DIR/../../artifacts"

# --- Helpers ---

sed_inplace() {
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

extract_field() {
  local FILE="$1"
  local FIELD="$2"
  sed -n '/^---$/,/^---$/p' "$FILE" | grep "^${FIELD}:" | sed "s/${FIELD}: *//" | tr -d '"' | tr -d "'"
}

extract_array_items() {
  local VALUE="$1"
  echo "$VALUE" | tr -d '[]' | tr ',' '\n' | sed 's/^ *//' | sed 's/ *$//' | grep -v '^$' || true
}

resolve_artifact_id() {
  local TARGET_ID="$1"
  grep -rl "^id: *${TARGET_ID} *$" "$ARTIFACTS_DIR" --include="*.md" 2>/dev/null | head -1 || true
}

status_ordinal() {
  case "$1" in
    draft) echo 0 ;;
    review) echo 1 ;;
    approved) echo 2 ;;
    archived) echo 3 ;;
    *) echo -1 ;;
  esac
}

ordinal_to_status() {
  case "$1" in
    0) echo "draft" ;;
    1) echo "review" ;;
    2) echo "approved" ;;
    3) echo "archived" ;;
  esac
}

# --- Validate new status ---
VALID_STATUSES=("draft" "review" "approved" "archived")
VALID=false
for vs in "${VALID_STATUSES[@]}"; do
  if [[ "$NEW_STATUS" == "$vs" ]]; then
    VALID=true
    break
  fi
done

if [[ "$VALID" == "false" ]]; then
  echo "ERROR: Invalid status: '$NEW_STATUS' (must be: draft, review, approved, archived)"
  exit 1
fi

# --- Extract current status ---
CURRENT_STATUS=$(extract_field "$ARTIFACT_PATH" "status")

if [[ -z "$CURRENT_STATUS" ]]; then
  echo "ERROR: Could not extract current status from $ARTIFACT_PATH"
  exit 1
fi

if [[ "$CURRENT_STATUS" == "$NEW_STATUS" ]]; then
  echo "WARNING: Artifact is already in status '$NEW_STATUS'"
  exit 0
fi

# --- Check transition ordering ---
CURRENT_ORD=$(status_ordinal "$CURRENT_STATUS")
NEW_ORD=$(status_ordinal "$NEW_STATUS")

# Allow archival from any state
if [[ "$NEW_STATUS" != "archived" ]]; then
  EXPECTED_ORD=$((CURRENT_ORD + 1))
  if [[ "$NEW_ORD" -ne "$EXPECTED_ORD" ]]; then
    EXPECTED_STATUS=$(ordinal_to_status "$EXPECTED_ORD")
    echo "ERROR: Cannot promote from '$CURRENT_STATUS' to '$NEW_STATUS'"
    echo "  Expected next status: '$EXPECTED_STATUS'"
    echo "  Lifecycle: draft → review → approved → archived"
    echo "  (Archival is allowed from any status)"
    exit 1
  fi
fi

# --- Run validation before promotion ---
echo "Running validation..."
if ! "$SCRIPT_DIR/validate.sh" "$ARTIFACT_PATH"; then
  echo ""
  echo "ERROR: Artifact validation failed. Fix errors before promoting."
  exit 1
fi

# --- Prerequisite checks for → approved ---
if [[ "$NEW_STATUS" == "approved" ]]; then
  echo "Checking prerequisites for approval..."

  # Check parent is approved
  PARENT_ID=$(extract_field "$ARTIFACT_PATH" "parent")
  if [[ -n "$PARENT_ID" && "$PARENT_ID" != "null" ]]; then
    PARENT_FILE=$(resolve_artifact_id "$PARENT_ID")
    if [[ -z "$PARENT_FILE" ]]; then
      echo "ERROR: Parent '$PARENT_ID' not found — cannot verify approval status"
      exit 1
    fi
    PARENT_STATUS=$(extract_field "$PARENT_FILE" "status")
    if [[ "$PARENT_STATUS" != "approved" ]]; then
      echo "ERROR: Cannot approve — parent '$PARENT_ID' is still '$PARENT_STATUS' (must be 'approved')"
      exit 1
    fi
    echo "  ✅ Parent '$PARENT_ID': approved"
  fi

  # Check all depends_on are approved
  DEPENDS_VAL=$(extract_field "$ARTIFACT_PATH" "depends_on")
  while IFS= read -r dep_id; do
    [[ -z "$dep_id" ]] && continue
    DEP_FILE=$(resolve_artifact_id "$dep_id")
    if [[ -z "$DEP_FILE" ]]; then
      echo "ERROR: Dependency '$dep_id' not found — cannot verify approval status"
      exit 1
    fi
    DEP_STATUS=$(extract_field "$DEP_FILE" "status")
    if [[ "$DEP_STATUS" != "approved" ]]; then
      echo "ERROR: Cannot approve — dependency '$dep_id' is still '$DEP_STATUS' (must be 'approved')"
      exit 1
    fi
    echo "  ✅ Dependency '$dep_id': approved"
  done < <(extract_array_items "$DEPENDS_VAL")
fi

# --- Update status in frontmatter ---
sed_inplace "s/^status: .*/status: $NEW_STATUS/" "$ARTIFACT_PATH"

# --- Log the promotion ---
LOG_DIR="$ARTIFACTS_DIR/.audit-log"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/promotions.log"

echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $ARTIFACT_PATH: $CURRENT_STATUS → $NEW_STATUS" >> "$LOG_FILE"

echo ""
echo "✅ Promoted: $ARTIFACT_PATH"
echo "  $CURRENT_STATUS → $NEW_STATUS"
echo "  Logged to: $LOG_FILE"
