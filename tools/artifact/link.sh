#!/usr/bin/env bash
# Tool: Artifact Linker
# Description: Links two artifacts by updating parent/children/depends_on fields in both files
# Usage: ./tools/artifact/link.sh <parent-path> <child-path>
# Inputs: parent artifact path + child artifact path
# Outputs: updated frontmatter in both files with linkage + audit log entry
set -euo pipefail

PARENT_PATH="${1:-}"
CHILD_PATH="${2:-}"

if [[ -z "$PARENT_PATH" || -z "$CHILD_PATH" ]]; then
  echo "ERROR: Missing arguments"
  echo "Usage: ./tools/artifact/link.sh <parent-path> <child-path>"
  exit 1
fi

if [[ ! -f "$PARENT_PATH" ]]; then
  echo "ERROR: Parent file not found: $PARENT_PATH"
  exit 1
fi

if [[ ! -f "$CHILD_PATH" ]]; then
  echo "ERROR: Child file not found: $CHILD_PATH"
  exit 1
fi

# --- Helper: cross-platform sed -i ---
sed_inplace() {
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# --- Helper: extract frontmatter field value ---
extract_field() {
  local FILE="$1"
  local FIELD="$2"
  sed -n '/^---$/,/^---$/p' "$FILE" | grep "^${FIELD}:" | sed "s/${FIELD}: *//" | tr -d '"' | tr -d "'"
}

# Extract IDs
PARENT_ID=$(extract_field "$PARENT_PATH" "id")
CHILD_ID=$(extract_field "$CHILD_PATH" "id")

if [[ -z "$PARENT_ID" ]]; then
  echo "ERROR: Could not extract ID from parent artifact: $PARENT_PATH"
  exit 1
fi

if [[ -z "$CHILD_ID" ]]; then
  echo "ERROR: Could not extract ID from child artifact: $CHILD_PATH"
  exit 1
fi

echo "Linking: $PARENT_ID → $CHILD_ID"

# --- 1. Set parent on child ---
CURRENT_PARENT=$(extract_field "$CHILD_PATH" "parent")

if [[ -z "$CURRENT_PARENT" || "$CURRENT_PARENT" == "null" ]]; then
  # Set parent field
  sed_inplace "s/^parent: .*/parent: $PARENT_ID/" "$CHILD_PATH"
  echo "  ✅ Set parent on child: $CHILD_ID → parent: $PARENT_ID"
elif [[ "$CURRENT_PARENT" == "$PARENT_ID" ]]; then
  echo "  ℹ️  Child already has parent: $PARENT_ID (no change)"
else
  echo "  ERROR: Child already has a different parent: '$CURRENT_PARENT'. Cannot re-parent."
  echo "  To change parent, manually update the parent field first."
  exit 1
fi

# --- 2. Add child to parent's children array ---
CURRENT_CHILDREN=$(extract_field "$PARENT_PATH" "children")

if echo "$CURRENT_CHILDREN" | grep -q "$CHILD_ID"; then
  echo "  ℹ️  Parent already has $CHILD_ID in children (no change)"
else
  if [[ "$CURRENT_CHILDREN" == "[]" || -z "$CURRENT_CHILDREN" ]]; then
    # Empty array — replace with single item
    sed_inplace "s/^children: \[\]/children: [$CHILD_ID]/" "$PARENT_PATH"
  else
    # Non-empty array — append
    # Remove trailing ] and add ", CHILD_ID]"
    sed_inplace "s/^children: \[\(.*\)\]/children: [\1, $CHILD_ID]/" "$PARENT_PATH"
  fi
  echo "  ✅ Added $CHILD_ID to parent's children"
fi

# --- 3. Add parent to child's depends_on array ---
CURRENT_DEPENDS=$(extract_field "$CHILD_PATH" "depends_on")

if echo "$CURRENT_DEPENDS" | grep -q "$PARENT_ID"; then
  echo "  ℹ️  Child already has $PARENT_ID in depends_on (no change)"
else
  if [[ "$CURRENT_DEPENDS" == "[]" || -z "$CURRENT_DEPENDS" ]]; then
    sed_inplace "s/^depends_on: \[\]/depends_on: [$PARENT_ID]/" "$CHILD_PATH"
  else
    sed_inplace "s/^depends_on: \[\(.*\)\]/depends_on: [\1, $PARENT_ID]/" "$CHILD_PATH"
  fi
  echo "  ✅ Added $PARENT_ID to child's depends_on"
fi

# --- 4. Validate both files ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "Validating linked artifacts..."
VALID=true
if ! "$SCRIPT_DIR/validate.sh" "$PARENT_PATH"; then
  VALID=false
fi
if ! "$SCRIPT_DIR/validate.sh" "$CHILD_PATH"; then
  VALID=false
fi

if [[ "$VALID" == "false" ]]; then
  echo ""
  echo "⚠️  Linking completed but validation found issues (see above)"
fi

# --- 5. Log the linkage ---
LOG_DIR="$SCRIPT_DIR/../../artifacts/.audit-log"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/promotions.log"

echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] LINK: $PARENT_ID → $CHILD_ID ($PARENT_PATH → $CHILD_PATH)" >> "$LOG_FILE"

echo ""
echo "✅ Link complete: $PARENT_ID → $CHILD_ID"
echo "  Logged to: $LOG_FILE"
