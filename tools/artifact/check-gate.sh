#!/usr/bin/env bash
# Tool: Stage Gate Checker
# Description: Checks whether a stage gate is satisfied before allowing transition
# Usage: ./tools/artifact/check-gate.sh <gate-name> <artifact-path-or-id>
# Gates: prd-to-rfc, rfc-to-impl, impl-to-qa, release
# Inputs: gate name + artifact path or ID to check against
# Outputs: exit 0 if gate passes, exit 1 with specific failures
#
# Stage-aware behavior (reads company.config.yaml):
#   idea  — all gates advisory (warnings only, never block)
#   mvp   — prd-to-rfc and rfc-to-impl enforced; impl-to-qa and release advisory
#   growth — all gates enforced (default)
#   scale  — all gates enforced
set -euo pipefail

GATE_NAME="${1:-}"
ARTIFACT_REF="${2:-}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
ARTIFACTS_DIR="$PROJECT_ROOT/artifacts"

# --- Stage-aware behavior ---
# Read company stage from config. Default to "growth" (full enforcement).
COMPANY_STAGE="growth"
CONFIG_FILE="$PROJECT_ROOT/company.config.yaml"
if [[ -f "$CONFIG_FILE" ]]; then
  STAGE_VALUE=$(grep "^  stage:" "$CONFIG_FILE" | sed 's/.*stage: *//' | tr -d '"' | tr -d "'" | sed 's/ *#.*//' || true)
  if [[ -n "$STAGE_VALUE" ]]; then
    COMPANY_STAGE="$STAGE_VALUE"
  fi
fi

# Determine if the current gate is advisory (warning-only) for this stage
is_gate_advisory() {
  local GATE="$1"
  case "$COMPANY_STAGE" in
    idea)
      # All gates are advisory in idea stage
      return 0
      ;;
    mvp)
      # Only prd-to-rfc and rfc-to-impl are enforced; others are advisory
      case "$GATE" in
        prd-to-rfc|rfc-to-impl) return 1 ;;
        *) return 0 ;;
      esac
      ;;
    growth|scale|"")
      # All gates enforced
      return 1
      ;;
    *)
      # Unknown stage — enforce by default
      return 1
      ;;
  esac
}

if [[ -z "$GATE_NAME" ]]; then
  echo "ERROR: No gate name provided"
  echo "Usage: ./tools/artifact/check-gate.sh <gate-name> <artifact-path-or-id>"
  echo ""
  echo "Available gates:"
  echo "  prd-to-rfc    — PRD must be approved with acceptance criteria"
  echo "  rfc-to-impl   — RFC must be approved, parent PRD approved"
  echo "  impl-to-qa    — RFC approved, implementation exists"
  echo "  release        — All required artifacts exist and approved"
  echo ""
  echo "Stage-aware behavior (reads company.config.yaml stage field):"
  echo "  idea   — all gates advisory (warnings only)"
  echo "  mvp    — prd-to-rfc and rfc-to-impl enforced; others advisory"
  echo "  growth — all gates enforced (default)"
  echo "  scale  — all gates enforced"
  exit 1
fi

# --- Helpers ---

resolve_artifact_id() {
  local TARGET_ID="$1"
  grep -rl "^id: *${TARGET_ID} *$" "$ARTIFACTS_DIR" --include="*.md" 2>/dev/null | head -1 || true
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

# Resolve artifact reference to a file path (accepts path or ID)
resolve_ref() {
  local REF="$1"
  if [[ -f "$REF" ]]; then
    echo "$REF"
  else
    resolve_artifact_id "$REF"
  fi
}

# Find artifacts by type that are related to a given artifact (share lineage)
find_related_by_type() {
  local SOURCE_ID="$1"
  local TARGET_TYPE="$2"
  # Search all artifacts of the target type
  local FOUND=""
  while IFS= read -r -d '' file; do
    local FILE_TYPE=$(extract_field "$file" "type")
    if [[ "$FILE_TYPE" == "$TARGET_TYPE" ]]; then
      local PARENT=$(extract_field "$file" "parent")
      local DEPENDS=$(extract_field "$file" "depends_on")
      # Check if this artifact is related to our source
      if [[ "$PARENT" == "$SOURCE_ID" ]] || echo "$DEPENDS" | grep -q "$SOURCE_ID"; then
        FOUND="$file"
        break
      fi
    fi
  done < <(find "$ARTIFACTS_DIR" -name "*.md" ! -path "*/.audit-log/*" ! -name ".gitkeep" -print0 2>/dev/null)
  echo "$FOUND"
}

FAILURES=()
PASSES=()
ADVISORY_WARNINGS=()

case "$GATE_NAME" in

  "prd-to-rfc")
    if [[ -z "$ARTIFACT_REF" ]]; then
      echo "ERROR: prd-to-rfc gate requires a PRD path or ID"
      exit 1
    fi

    PRD_FILE=$(resolve_ref "$ARTIFACT_REF")
    if [[ -z "$PRD_FILE" ]]; then
      FAILURES+=("PRD not found: '$ARTIFACT_REF'")
    else
      # Check PRD is approved
      PRD_STATUS=$(extract_field "$PRD_FILE" "status")
      if [[ "$PRD_STATUS" == "approved" ]]; then
        PASSES+=("PRD status: approved")
      else
        FAILURES+=("PRD status is '$PRD_STATUS' (must be 'approved')")
      fi

      # Check PRD has acceptance criteria (look for AC- or "Acceptance Criteria" in body)
      BODY=$(sed -n '/^---$/,/^---$/!p' "$PRD_FILE")
      if echo "$BODY" | grep -qi "acceptance criteria\|AC-"; then
        PASSES+=("PRD has acceptance criteria")
      else
        FAILURES+=("PRD missing acceptance criteria section")
      fi

      # Run validate
      if "$SCRIPT_DIR/validate.sh" "$PRD_FILE" > /dev/null 2>&1; then
        PASSES+=("PRD passes validation")
      else
        FAILURES+=("PRD fails validation (run validate.sh for details)")
      fi
    fi
    ;;

  "rfc-to-impl")
    if [[ -z "$ARTIFACT_REF" ]]; then
      echo "ERROR: rfc-to-impl gate requires an RFC path or ID"
      exit 1
    fi

    RFC_FILE=$(resolve_ref "$ARTIFACT_REF")
    if [[ -z "$RFC_FILE" ]]; then
      FAILURES+=("RFC not found: '$ARTIFACT_REF'")
    else
      # Check RFC is approved
      RFC_STATUS=$(extract_field "$RFC_FILE" "status")
      if [[ "$RFC_STATUS" == "approved" ]]; then
        PASSES+=("RFC status: approved")
      else
        FAILURES+=("RFC status is '$RFC_STATUS' (must be 'approved')")
      fi

      # Check parent PRD is approved
      PARENT_ID=$(extract_field "$RFC_FILE" "parent")
      if [[ -n "$PARENT_ID" && "$PARENT_ID" != "null" ]]; then
        PARENT_FILE=$(resolve_artifact_id "$PARENT_ID")
        if [[ -z "$PARENT_FILE" ]]; then
          FAILURES+=("Parent PRD '$PARENT_ID' not found")
        else
          PARENT_STATUS=$(extract_field "$PARENT_FILE" "status")
          if [[ "$PARENT_STATUS" == "approved" ]]; then
            PASSES+=("Parent PRD '$PARENT_ID': approved")
          else
            FAILURES+=("Parent PRD '$PARENT_ID' is '$PARENT_STATUS' (must be 'approved')")
          fi
        fi
      else
        FAILURES+=("RFC has no parent PRD linked")
      fi

      # Run validate
      if "$SCRIPT_DIR/validate.sh" "$RFC_FILE" > /dev/null 2>&1; then
        PASSES+=("RFC passes validation")
      else
        FAILURES+=("RFC fails validation (run validate.sh for details)")
      fi
    fi
    ;;

  "impl-to-qa")
    if [[ -z "$ARTIFACT_REF" ]]; then
      echo "ERROR: impl-to-qa gate requires an RFC path or ID"
      exit 1
    fi

    RFC_FILE=$(resolve_ref "$ARTIFACT_REF")
    if [[ -z "$RFC_FILE" ]]; then
      FAILURES+=("RFC not found: '$ARTIFACT_REF'")
    else
      RFC_ID=$(extract_field "$RFC_FILE" "id")

      # Check RFC is approved
      RFC_STATUS=$(extract_field "$RFC_FILE" "status")
      if [[ "$RFC_STATUS" == "approved" ]]; then
        PASSES+=("RFC status: approved")
      else
        FAILURES+=("RFC status is '$RFC_STATUS' (must be 'approved')")
      fi

      # Extract parent PRD ID (used by both test plan and seed catalog checks)
      PARENT_ID=$(extract_field "$RFC_FILE" "parent")

      # Check test plan exists for this feature
      TEST_PLAN=$(find_related_by_type "$RFC_ID" "test-plan")
      if [[ -n "$TEST_PLAN" ]]; then
        PASSES+=("Test plan exists: $TEST_PLAN")
      else
        # Also check via PRD parent
        if [[ -n "$PARENT_ID" && "$PARENT_ID" != "null" ]]; then
          TEST_PLAN=$(find_related_by_type "$PARENT_ID" "test-plan")
        fi
        if [[ -n "$TEST_PLAN" ]]; then
          PASSES+=("Test plan exists (via PRD): $TEST_PLAN")
        else
          FAILURES+=("No test plan found related to this RFC or its parent PRD")
        fi
      fi

      # Advisory: check for seed data catalog (never blocks, just informs)
      SEED_CATALOG=""
      SEED_CATALOG=$(find_related_by_type "$RFC_ID" "test-data")
      if [[ -z "$SEED_CATALOG" && -n "$PARENT_ID" && "$PARENT_ID" != "null" ]]; then
        SEED_CATALOG=$(find_related_by_type "$PARENT_ID" "test-data")
      fi
      if [[ -n "$SEED_CATALOG" ]]; then
        CATALOG_ID=$(extract_field "$SEED_CATALOG" "id")
        PASSES+=("Seed data catalog exists: ${CATALOG_ID:-$SEED_CATALOG}")
      else
        ADVISORY_WARNINGS+=("No seed data catalog found — consider running /seed-data before QA")
      fi
    fi
    ;;

  "release")
    if [[ -z "$ARTIFACT_REF" ]]; then
      echo "ERROR: release gate requires a PRD path or ID as the root artifact"
      exit 1
    fi

    PRD_FILE=$(resolve_ref "$ARTIFACT_REF")
    if [[ -z "$PRD_FILE" ]]; then
      FAILURES+=("PRD not found: '$ARTIFACT_REF'")
    else
      PRD_ID=$(extract_field "$PRD_FILE" "id")

      # 1. PRD must be approved
      PRD_STATUS=$(extract_field "$PRD_FILE" "status")
      if [[ "$PRD_STATUS" == "approved" ]]; then
        PASSES+=("PRD '$PRD_ID': approved")
      else
        FAILURES+=("PRD '$PRD_ID' is '$PRD_STATUS' (must be 'approved')")
      fi

      # 2. RFC must exist and be approved
      RFC_FILE=$(find_related_by_type "$PRD_ID" "rfc")
      if [[ -n "$RFC_FILE" ]]; then
        RFC_ID=$(extract_field "$RFC_FILE" "id")
        RFC_STATUS=$(extract_field "$RFC_FILE" "status")
        if [[ "$RFC_STATUS" == "approved" ]]; then
          PASSES+=("RFC '$RFC_ID': approved")
        else
          FAILURES+=("RFC '$RFC_ID' is '$RFC_STATUS' (must be 'approved')")
        fi
      else
        FAILURES+=("No RFC found linked to PRD '$PRD_ID'")
        RFC_ID=""
      fi

      # 3. Security review must exist (even minimal)
      SEC_FILE=""
      if [[ -n "$RFC_ID" ]]; then
        SEC_FILE=$(find_related_by_type "$RFC_ID" "security-review")
      fi
      if [[ -z "$SEC_FILE" ]]; then
        SEC_FILE=$(find_related_by_type "$PRD_ID" "security-review")
      fi
      if [[ -n "$SEC_FILE" ]]; then
        PASSES+=("Security review exists: $(extract_field "$SEC_FILE" "id")")
      else
        FAILURES+=("No security review found for this feature")
      fi

      # 4. QA report must exist and be approved
      QA_FILE=""
      if [[ -n "$RFC_ID" ]]; then
        QA_FILE=$(find_related_by_type "$RFC_ID" "qa-report")
      fi
      if [[ -z "$QA_FILE" ]]; then
        QA_FILE=$(find_related_by_type "$PRD_ID" "qa-report")
      fi
      if [[ -n "$QA_FILE" ]]; then
        QA_STATUS=$(extract_field "$QA_FILE" "status")
        if [[ "$QA_STATUS" == "approved" ]]; then
          PASSES+=("QA report: approved")
        else
          FAILURES+=("QA report is '$QA_STATUS' (must be 'approved')")
        fi
      else
        FAILURES+=("No QA report found for this feature")
      fi

      # 5. App version file exists, valid semver, and bumped since last release
      VERSION_VAL=""
      VERSION_SRC=""
      if [[ -f "package.json" ]]; then
        VERSION_VAL=$(grep '"version"' package.json | head -1 | sed 's/.*"version": *"\([^"]*\)".*/\1/' || true)
        VERSION_SRC="package.json"
      elif [[ -f "pyproject.toml" ]]; then
        VERSION_VAL=$(grep '^version = ' pyproject.toml | head -1 | sed 's/version = "\([^"]*\)".*/\1/' || true)
        VERSION_SRC="pyproject.toml"
      elif [[ -f "VERSION" ]]; then
        # Skip if this is Company OS's VERSION (matches .company-os-version)
        APP_VER_CHECK=$(head -1 VERSION | tr -d '[:space:]')
        COS_VER_CHECK=""
        if [[ -f ".company-os-version" ]]; then
          COS_VER_CHECK=$(head -1 .company-os-version | tr -d '[:space:]')
        fi
        if [[ "$APP_VER_CHECK" != "$COS_VER_CHECK" ]]; then
          VERSION_VAL="$APP_VER_CHECK"
          VERSION_SRC="VERSION"
        fi
      fi

      if [[ -n "$VERSION_VAL" ]]; then
        if [[ "$VERSION_VAL" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
          PASSES+=("App version: $VERSION_VAL ($VERSION_SRC, valid semver)")
          # Check if bumped since last release
          if [[ -f ".previous-version" ]]; then
            PREV_VER_CHECK=$(head -1 .previous-version | tr -d '[:space:]')
            if [[ "$VERSION_VAL" == "$PREV_VER_CHECK" ]]; then
              FAILURES+=("App version unchanged since last release ($PREV_VER_CHECK) — run version bump before release")
            else
              PASSES+=("Version bumped: $PREV_VER_CHECK → $VERSION_VAL")
            fi
          fi
        else
          FAILURES+=("App version '$VERSION_VAL' is not valid semver (expected MAJOR.MINOR.PATCH)")
        fi
      else
        FAILURES+=("No app version file found (expected package.json, pyproject.toml, or VERSION)")
      fi
    fi
    ;;

  *)
    echo "ERROR: Unknown gate: '$GATE_NAME'"
    echo "Available gates: prd-to-rfc, rfc-to-impl, impl-to-qa, release"
    exit 1
    ;;
esac

# --- Report ---
echo ""
echo "=== Gate Check: $GATE_NAME ==="

if [[ "$COMPANY_STAGE" != "growth" && "$COMPANY_STAGE" != "scale" && -n "$COMPANY_STAGE" ]]; then
  echo "  📋 Stage: $COMPANY_STAGE"
fi

if [[ ${#PASSES[@]} -gt 0 ]]; then
  for pass in "${PASSES[@]}"; do
    echo "  ✅ $pass"
  done
fi

# Print advisory warnings (informational, never block)
if [[ ${#ADVISORY_WARNINGS[@]} -gt 0 ]]; then
  for warn in "${ADVISORY_WARNINGS[@]}"; do
    echo "  ℹ️  $warn"
  done
fi

if [[ ${#FAILURES[@]} -gt 0 ]]; then
  if is_gate_advisory "$GATE_NAME"; then
    # Advisory mode — report as warnings, exit 0
    for fail in "${FAILURES[@]}"; do
      echo "  ⚠️  $fail"
    done
    echo ""
    echo "⚠️  GATE ADVISORY: $GATE_NAME — ${#FAILURES[@]} issue(s) noted (stage: $COMPANY_STAGE, not blocking)"
    exit 0
  else
    # Enforced mode — report as failures, exit 1
    for fail in "${FAILURES[@]}"; do
      echo "  ❌ $fail"
    done
    echo ""
    echo "❌ GATE FAILED: $GATE_NAME — ${#FAILURES[@]} issue(s) must be resolved"
    exit 1
  fi
else
  echo ""
  echo "✅ GATE PASSED: $GATE_NAME"
  exit 0
fi
