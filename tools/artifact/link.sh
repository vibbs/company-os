#!/usr/bin/env bash
# Tool: Artifact Linker
# Description: Links two artifacts by updating parent/children/depends_on fields in both files
# Usage: ./tools/artifact/link.sh <parent-path> <child-path>
# Inputs: parent artifact path + child artifact path
# Outputs: updated frontmatter in both files with linkage + audit log entry
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/usage.sh"
usage_help_if_requested "${BASH_SOURCE[0]}" "${1:-}"

PARENT_PATH="${1:-}"
CHILD_PATH="${2:-}"

if [[ -z "$PARENT_PATH" || -z "$CHILD_PATH" ]]; then
  echo "ERROR: Missing arguments" >&2
  echo "Usage: ./tools/artifact/link.sh <parent-path> <child-path>" >&2
  exit 1
fi

if [[ ! -f "$PARENT_PATH" ]]; then
  echo "ERROR: Parent file not found: $PARENT_PATH" >&2
  exit 1
fi

if [[ ! -f "$CHILD_PATH" ]]; then
  echo "ERROR: Child file not found: $CHILD_PATH" >&2
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
  sed -n '1,/^---$/p' "$FILE" | { grep "^${FIELD}:" || true; } | sed "s/${FIELD}: *//" | tr -d '"' | tr -d "'"
}

# --- Helper: frontmatter-only text of one field ---
# Prints the field line plus any block-list items ("  - X") that follow it.
# Only the first frontmatter block is read, so body lines never match.
field_text() {
  awk -v f="$2" '
    NR==1 { next }
    /^---$/ { exit }
    infield && /^[ \t]*-/ { print; next }
    { infield = 0 }
    index($0, f ":") == 1 { infield = 1; print }
  ' "$1"
}

# --- Helper: rewrite a file through awk, keeping the original on failure ---
rewrite() {
  local FILE="$1" TMP
  shift
  TMP=$(mktemp)
  awk "$@" "$FILE" > "$TMP" && cat "$TMP" > "$FILE"
  rm -f "$TMP"
}

# --- Helper: set a scalar field in the first frontmatter block ---
# Replaces the field when present; otherwise adds it after `id:`.
set_scalar() {
  local FILE="$1" FIELD="$2" VALUE="$3"
  rewrite "$FILE" -v f="$FIELD" -v v="$VALUE" '
    NR==1 { print; next }
    done_fm { print; next }
    /^---$/ { done_fm = 1; print; next }
    index($0, f ":") == 1 { print f ": " v; set = 1; next }
    { print }
    /^id: / && !set { print f ": " v; set = 1 }
  '
}

# --- Helper: append an ID to a list field (inline [a, b] or block "  - a") ---
# Adds the field after `id:` when the frontmatter does not have it yet.
# A block list stays a block list; an inline list stays inline.
add_array_item() {
  local FILE="$1" FIELD="$2" ITEM="$3" TEXT FIRST
  TEXT=$(field_text "$FILE" "$FIELD")
  FIRST=$(printf '%s\n' "$TEXT" | head -n 1 | sed "s/^${FIELD}: *//" | tr -d '"' | tr -d "'")
  if [[ -z "$TEXT" ]]; then
    set_scalar "$FILE" "$FIELD" "[$ITEM]"
  elif [[ "$FIRST" == "[]" || ( -z "$FIRST" && "$(printf '%s\n' "$TEXT" | wc -l | tr -d ' ')" == "1" ) ]]; then
    set_scalar "$FILE" "$FIELD" "[$ITEM]"
  elif [[ -z "$FIRST" ]]; then
    # Block list: insert after the last "- item" line, same indentation.
    rewrite "$FILE" -v f="$FIELD" -v item="$ITEM" '
      NR==1 { print; next }
      done_fm { print; next }
      /^---$/ { if (infield) emit(); done_fm = 1; print; next }
      infield && /^[ \t]*-/ { last = $0; print; next }
      infield { emit() }
      index($0, f ":") == 1 { infield = 1 }
      { print }
      function emit(   ind) {
        ind = last; sub(/-.*/, "", ind)
        print ind "- " item
        infield = 0
      }
    '
  else
    set_scalar "$FILE" "$FIELD" "$(printf '%s' "$FIRST" | sed 's/\]$//'), $ITEM]"
  fi
}

# Extract IDs
PARENT_ID=$(extract_field "$PARENT_PATH" "id")
CHILD_ID=$(extract_field "$CHILD_PATH" "id")

if [[ -z "$PARENT_ID" ]]; then
  echo "ERROR: Could not extract ID from parent artifact: $PARENT_PATH" >&2
  exit 1
fi

if [[ -z "$CHILD_ID" ]]; then
  echo "ERROR: Could not extract ID from child artifact: $CHILD_PATH" >&2
  exit 1
fi

echo "Linking: $PARENT_ID → $CHILD_ID"

# --- 1. Set parent on child ---
CURRENT_PARENT=$(extract_field "$CHILD_PATH" "parent")

if [[ -z "$CURRENT_PARENT" || "$CURRENT_PARENT" == "null" ]]; then
  set_scalar "$CHILD_PATH" parent "$PARENT_ID"
  echo "  ✅ Set parent on child: $CHILD_ID → parent: $PARENT_ID"
elif [[ "$CURRENT_PARENT" == "$PARENT_ID" ]]; then
  echo "  ℹ️  Child already has parent: $PARENT_ID (no change)"
else
  echo "  ERROR: Child already has a different parent: '$CURRENT_PARENT'. Cannot re-parent." >&2
  echo "  To change parent, manually update the parent field first." >&2
  exit 1
fi

# --- 2. Add child to parent's children array ---
CURRENT_CHILDREN=$(field_text "$PARENT_PATH" "children")

if echo "$CURRENT_CHILDREN" | grep -qF -- "$CHILD_ID"; then
  echo "  ℹ️  Parent already has $CHILD_ID in children (no change)"
else
  add_array_item "$PARENT_PATH" children "$CHILD_ID"
  echo "  ✅ Added $CHILD_ID to parent's children"
fi

# --- 3. Add parent to child's depends_on array ---
CURRENT_DEPENDS=$(field_text "$CHILD_PATH" "depends_on")

if echo "$CURRENT_DEPENDS" | grep -qF -- "$PARENT_ID"; then
  echo "  ℹ️  Child already has $PARENT_ID in depends_on (no change)"
else
  add_array_item "$CHILD_PATH" depends_on "$PARENT_ID"
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
