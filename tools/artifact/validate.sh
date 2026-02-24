#!/usr/bin/env bash
# Tool: Artifact Validate
# Description: Validates artifact files have correct YAML frontmatter, required fields, and reference integrity
# Usage: ./tools/artifact/validate.sh [--strict] <artifact-path>
# Inputs: path to artifact markdown file, optional --strict flag for bidirectional checks
# Outputs: exit 0 if valid, exit 1 with errors listed
set -euo pipefail

# Parse flags
STRICT=false
ARTIFACT_PATH=""

for arg in "$@"; do
  case "$arg" in
    --strict) STRICT=true ;;
    *) ARTIFACT_PATH="$arg" ;;
  esac
done

if [[ -z "$ARTIFACT_PATH" ]]; then
  echo "ERROR: No artifact path provided"
  echo "Usage: ./tools/artifact/validate.sh [--strict] <artifact-path>"
  echo ""
  echo "Flags:"
  echo "  --strict    Also check bidirectional link consistency"
  exit 1
fi

if [[ ! -f "$ARTIFACT_PATH" ]]; then
  echo "ERROR: File not found: $ARTIFACT_PATH"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ARTIFACTS_DIR="$SCRIPT_DIR/../../artifacts"

ERRORS=()
WARNINGS=()

# --- Helper: resolve an artifact ID to a file path ---
resolve_artifact_id() {
  local TARGET_ID="$1"
  grep -rl "^id: *${TARGET_ID} *$" "$ARTIFACTS_DIR" --include="*.md" 2>/dev/null | head -1 || true
}

# --- Helper: extract frontmatter field value ---
extract_field() {
  local FILE="$1"
  local FIELD="$2"
  sed -n '/^---$/,/^---$/p' "$FILE" | grep "^${FIELD}:" | sed "s/${FIELD}: *//" | tr -d '"' | tr -d "'"
}

# --- Helper: extract YAML inline array items ---
extract_array_items() {
  local VALUE="$1"
  # Handle: [item1, item2] or [item1] or [] or empty
  echo "$VALUE" | tr -d '[]' | tr ',' '\n' | sed 's/^ *//' | sed 's/ *$//' | grep -v '^$' || true
}

# Check file has YAML frontmatter (starts with ---)
FIRST_LINE=$(head -1 "$ARTIFACT_PATH")
if [[ "$FIRST_LINE" != "---" ]]; then
  ERRORS+=("Missing YAML frontmatter (file must start with ---)")
fi

# Extract frontmatter (between first and second ---)
FRONTMATTER=$(sed -n '/^---$/,/^---$/p' "$ARTIFACT_PATH" | sed '1d;$d')

if [[ -z "$FRONTMATTER" ]]; then
  ERRORS+=("Empty or malformed YAML frontmatter")
else
  # Check required fields
  REQUIRED_FIELDS=("id" "type" "title" "status" "created" "author")
  for field in "${REQUIRED_FIELDS[@]}"; do
    if ! echo "$FRONTMATTER" | grep -q "^${field}:"; then
      ERRORS+=("Missing required field: $field")
    fi
  done

  # Check status is valid
  STATUS=""
  if echo "$FRONTMATTER" | grep -q "^status:"; then
    STATUS=$(extract_field "$ARTIFACT_PATH" "status")
    VALID_STATUSES=("draft" "review" "approved" "archived")
    FOUND=false
    for vs in "${VALID_STATUSES[@]}"; do
      if [[ "$STATUS" == "$vs" ]]; then
        FOUND=true
        break
      fi
    done
    if [[ "$FOUND" == "false" ]]; then
      ERRORS+=("Invalid status: '$STATUS' (must be one of: draft, review, approved, archived)")
    fi
  fi

  # Check type is valid
  TYPE=""
  if echo "$FRONTMATTER" | grep -q "^type:"; then
    TYPE=$(extract_field "$ARTIFACT_PATH" "type")
    VALID_TYPES=("prd" "rfc" "test-plan" "qa-report" "launch-brief" "security-review" "decision-memo")
    FOUND=false
    for vt in "${VALID_TYPES[@]}"; do
      if [[ "$TYPE" == "$vt" ]]; then
        FOUND=true
        break
      fi
    done
    if [[ "$FOUND" == "false" ]]; then
      ERRORS+=("Invalid type: '$TYPE' (expected: prd, rfc, test-plan, qa-report, launch-brief, security-review, decision-memo)")
    fi
  fi

  # --- Reference Integrity Checks ---

  # Extract this artifact's ID for bidirectional checks
  THIS_ID=$(extract_field "$ARTIFACT_PATH" "id")

  # Check parent reference
  if echo "$FRONTMATTER" | grep -q "^parent:"; then
    PARENT_VAL=$(extract_field "$ARTIFACT_PATH" "parent")
    if [[ -n "$PARENT_VAL" && "$PARENT_VAL" != "null" ]]; then
      PARENT_FILE=$(resolve_artifact_id "$PARENT_VAL")
      if [[ -z "$PARENT_FILE" ]]; then
        ERRORS+=("parent '$PARENT_VAL' does not resolve to any artifact in artifacts/")
      elif [[ "$STRICT" == "true" && -n "$THIS_ID" ]]; then
        # Bidirectional check: parent should list this ID in children
        PARENT_CHILDREN=$(extract_field "$PARENT_FILE" "children")
        if ! echo "$PARENT_CHILDREN" | grep -q "$THIS_ID"; then
          WARNINGS+=("Bidirectional: parent '$PARENT_VAL' does not list '$THIS_ID' in its children")
        fi
      fi
    fi
  fi

  # Check depends_on references
  if echo "$FRONTMATTER" | grep -q "^depends_on:"; then
    DEPENDS_VAL=$(extract_field "$ARTIFACT_PATH" "depends_on")
    while IFS= read -r dep_id; do
      [[ -z "$dep_id" ]] && continue
      DEP_FILE=$(resolve_artifact_id "$dep_id")
      if [[ -z "$DEP_FILE" ]]; then
        ERRORS+=("depends_on '$dep_id' does not resolve to any artifact in artifacts/")
      fi
    done < <(extract_array_items "$DEPENDS_VAL")
  fi

  # Check children references
  if echo "$FRONTMATTER" | grep -q "^children:"; then
    CHILDREN_VAL=$(extract_field "$ARTIFACT_PATH" "children")
    while IFS= read -r child_id; do
      [[ -z "$child_id" ]] && continue
      CHILD_FILE=$(resolve_artifact_id "$child_id")
      if [[ -z "$CHILD_FILE" ]]; then
        ERRORS+=("children '$child_id' does not resolve to any artifact in artifacts/")
      elif [[ "$STRICT" == "true" ]]; then
        # Bidirectional check: child should list this ID as parent
        CHILD_PARENT=$(extract_field "$CHILD_FILE" "parent")
        if [[ "$CHILD_PARENT" != "$THIS_ID" ]]; then
          WARNINGS+=("Bidirectional: child '$child_id' has parent '$CHILD_PARENT', expected '$THIS_ID'")
        fi
      fi
    done < <(extract_array_items "$CHILDREN_VAL")
  fi

  # Check blocks references
  if echo "$FRONTMATTER" | grep -q "^blocks:"; then
    BLOCKS_VAL=$(extract_field "$ARTIFACT_PATH" "blocks")
    while IFS= read -r block_id; do
      [[ -z "$block_id" ]] && continue
      BLOCK_FILE=$(resolve_artifact_id "$block_id")
      if [[ -z "$BLOCK_FILE" ]]; then
        ERRORS+=("blocks '$block_id' does not resolve to any artifact in artifacts/")
      fi
    done < <(extract_array_items "$BLOCKS_VAL")
  fi
fi

# Check file has content beyond frontmatter
BODY=$(sed -n '/^---$/,/^---$/!p' "$ARTIFACT_PATH" | sed '/^$/d')
if [[ -z "$BODY" ]]; then
  ERRORS+=("Artifact has no content body (only frontmatter)")
fi

# Report results
if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  echo "⚠️  WARNINGS: $ARTIFACT_PATH"
  for warn in "${WARNINGS[@]}"; do
    echo "    - $warn"
  done
fi

if [[ ${#ERRORS[@]} -eq 0 ]]; then
  echo "✅ VALID: $ARTIFACT_PATH"
  [[ -n "$TYPE" ]] && echo "  Type: $TYPE"
  [[ -n "$STATUS" ]] && echo "  Status: $STATUS"
  exit 0
else
  echo "❌ INVALID: $ARTIFACT_PATH"
  echo "  Errors:"
  for err in "${ERRORS[@]}"; do
    echo "    - $err"
  done
  exit 1
fi
