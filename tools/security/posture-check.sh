#!/usr/bin/env bash
# Tool: T-SEC-04 Security Posture Check
# Tier: 0
# Description: Scans for compliance with security-posture.md standard — open threats, scan freshness, policy gaps
# Usage: ./tools/security/posture-check.sh [--json | --brief]
# Inputs: artifacts/security-reviews/, standards/security/security-posture.md
# Outputs: posture report to stdout, exit 0=healthy exit 1=issues found
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
SECURITY_REVIEWS_DIR="$PROJECT_ROOT/artifacts/security-reviews"
STANDARD_FILE="$PROJECT_ROOT/standards/security/security-posture.md"
CONFIG_FILE="$PROJECT_ROOT/company.config.yaml"

# --- Parse flags ---
OUTPUT_MODE="full"
for arg in "$@"; do
  case "$arg" in
    --json) OUTPUT_MODE="json" ;;
    --brief) OUTPUT_MODE="brief" ;;
    --help|-h)
      echo "Usage: ./tools/security/posture-check.sh [--json | --brief]"
      echo ""
      echo "Checks project security posture against standards/security/security-posture.md"
      echo ""
      echo "Flags:"
      echo "  --brief    One-line summary only"
      echo "  --json     Machine-readable JSON output"
      echo ""
      echo "Exit codes:"
      echo "  0  Posture healthy (no open CRITICAL findings)"
      echo "  1  Issues found (CRITICAL findings or missing standard)"
      exit 0
      ;;
  esac
done

# --- Counters ---
ISSUES=0
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
LOW_COUNT=0
TOTAL_REVIEWS=0
POSTURE_AGE="none"
STANDARD_EXISTS="false"
SCAN_DEP="unknown"
SCAN_SEC="unknown"
SCAN_SAST="unknown"

# --- Check standard exists ---
if [[ -f "$STANDARD_FILE" ]]; then
  STANDARD_EXISTS="true"
else
  STANDARD_EXISTS="false"
  ISSUES=$((ISSUES + 1))
fi

# --- Check company stage ---
STAGE=""
if [[ -f "$CONFIG_FILE" ]]; then
  STAGE=$(grep "^  stage:" "$CONFIG_FILE" 2>/dev/null | head -1 | sed 's/.*: *"\{0,1\}\([^"]*\)"\{0,1\}/\1/' | tr -d '[:space:]') || true
fi

# --- Scan security reviews ---
if [[ -d "$SECURITY_REVIEWS_DIR" ]]; then
  # Find all security review .md files (exclude POSTURE- for finding counts)
  while IFS= read -r file; do
    TOTAL_REVIEWS=$((TOTAL_REVIEWS + 1))

    # Check for severity markers in file body
    if grep -qi "CRITICAL" "$file" 2>/dev/null; then
      # Check if the finding is open (not mitigated/resolved)
      status=$(grep -i "^status:" "$file" 2>/dev/null | head -1 | tr '[:upper:]' '[:lower:]') || true
      if echo "$status" | grep -q "draft\|review" 2>/dev/null; then
        c=$(grep -ci "CRITICAL" "$file" 2>/dev/null) || true
        CRITICAL_COUNT=$((CRITICAL_COUNT + ${c:-0}))
      fi
    fi
    if grep -qi "HIGH" "$file" 2>/dev/null; then
      status=$(grep -i "^status:" "$file" 2>/dev/null | head -1 | tr '[:upper:]' '[:lower:]') || true
      if echo "$status" | grep -q "draft\|review" 2>/dev/null; then
        h=$(grep -ci "HIGH" "$file" 2>/dev/null) || true
        HIGH_COUNT=$((HIGH_COUNT + ${h:-0}))
      fi
    fi
  done < <(find "$SECURITY_REVIEWS_DIR" -name "*.md" ! -name "POSTURE-*" 2>/dev/null || true)

  # Check most recent POSTURE- artifact age
  LATEST_POSTURE=$(find "$SECURITY_REVIEWS_DIR" -name "POSTURE-*.md" -type f 2>/dev/null | sort -r | head -1) || true
  if [[ -n "${LATEST_POSTURE:-}" ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
      POSTURE_MTIME=$(stat -f %m "$LATEST_POSTURE" 2>/dev/null) || true
      NOW=$(date +%s)
    else
      POSTURE_MTIME=$(stat -c %Y "$LATEST_POSTURE" 2>/dev/null) || true
      NOW=$(date +%s)
    fi
    if [[ -n "${POSTURE_MTIME:-}" ]]; then
      AGE_DAYS=$(( (NOW - POSTURE_MTIME) / 86400 ))
      POSTURE_AGE="${AGE_DAYS}d"
      if [[ $AGE_DAYS -gt 30 ]]; then
        ISSUES=$((ISSUES + 1))
      fi
    fi
  else
    POSTURE_AGE="none"
  fi
fi

# --- Check scan tool freshness (look for scripts existing) ---
if [[ -x "$SCRIPT_DIR/dependency-scan.sh" ]]; then
  SCAN_DEP="available"
else
  SCAN_DEP="missing"
fi

if [[ -x "$SCRIPT_DIR/secrets-scan.sh" ]]; then
  SCAN_SEC="available"
else
  SCAN_SEC="missing"
fi

if [[ -x "$SCRIPT_DIR/sast.sh" ]]; then
  SCAN_SAST="available"
else
  SCAN_SAST="missing"
fi

# --- Check .env / .gitignore ---
ENV_IGNORED="false"
if [[ -f "$PROJECT_ROOT/.gitignore" ]]; then
  if grep -q "\.env" "$PROJECT_ROOT/.gitignore" 2>/dev/null; then
    ENV_IGNORED="true"
  fi
fi

ENV_EXAMPLE_EXISTS="false"
if [[ -f "$PROJECT_ROOT/.env.example" ]]; then
  ENV_EXAMPLE_EXISTS="true"
fi

# --- Determine if CRITICAL findings exist ---
if [[ $CRITICAL_COUNT -gt 0 ]]; then
  ISSUES=$((ISSUES + 1))
fi

# --- Determine overall verdict ---
if [[ $CRITICAL_COUNT -gt 0 ]]; then
  VERDICT="AT RISK"
elif [[ $ISSUES -gt 0 ]]; then
  VERDICT="CAUTION"
else
  VERDICT="HEALTHY"
fi

# --- Output ---
if [[ "$OUTPUT_MODE" == "json" ]]; then
  cat <<ENDJSON
{
  "verdict": "$VERDICT",
  "critical_count": $CRITICAL_COUNT,
  "high_count": $HIGH_COUNT,
  "total_reviews": $TOTAL_REVIEWS,
  "posture_age": "$POSTURE_AGE",
  "standard_exists": $STANDARD_EXISTS,
  "stage": "$STAGE",
  "scans": {
    "dependency": "$SCAN_DEP",
    "secrets": "$SCAN_SEC",
    "sast": "$SCAN_SAST"
  },
  "env_ignored": $ENV_IGNORED,
  "env_example_exists": $ENV_EXAMPLE_EXISTS,
  "issues": $ISSUES
}
ENDJSON

elif [[ "$OUTPUT_MODE" == "brief" ]]; then
  echo "POSTURE: $VERDICT | CRITICAL: $CRITICAL_COUNT | HIGH: $HIGH_COUNT | Reviews: $TOTAL_REVIEWS | Last snapshot: $POSTURE_AGE"

else
  # Full output
  echo "╔══════════════════════════════════════════╗"
  echo "║       SECURITY POSTURE CHECK             ║"
  echo "╚══════════════════════════════════════════╝"
  echo ""

  if [[ "$VERDICT" == "HEALTHY" ]]; then
    echo "  Overall: ✓ HEALTHY"
  elif [[ "$VERDICT" == "CAUTION" ]]; then
    echo "  Overall: ⚠ CAUTION"
  else
    echo "  Overall: ✗ AT RISK"
  fi
  echo ""

  echo "── Findings ──────────────────────────────"
  echo "  CRITICAL (open): $CRITICAL_COUNT"
  echo "  HIGH (open):     $HIGH_COUNT"
  echo "  Total reviews:   $TOTAL_REVIEWS"
  echo ""

  echo "── Scan Tools ────────────────────────────"
  echo "  dependency-scan.sh: $SCAN_DEP"
  echo "  secrets-scan.sh:    $SCAN_SEC"
  echo "  sast.sh:            $SCAN_SAST"
  echo ""

  echo "── Posture Snapshot ──────────────────────"
  if [[ "$POSTURE_AGE" == "none" ]]; then
    echo "  Last snapshot: NONE — run /security-posture to generate"
  else
    echo "  Last snapshot: $POSTURE_AGE ago"
    if [[ "${AGE_DAYS:-0}" -gt 30 ]]; then
      echo "  ⚠ Snapshot is stale (>30 days) — regenerate before release"
    fi
  fi
  echo ""

  echo "── Policy Checks ─────────────────────────"
  if [[ "$STANDARD_EXISTS" == "true" ]]; then
    echo "  Security posture standard: ✓ Found"
  else
    echo "  Security posture standard: ✗ MISSING"
    echo "    Create standards/security/security-posture.md"
  fi

  if [[ "$ENV_IGNORED" == "true" ]]; then
    echo "  .env in .gitignore:        ✓ Yes"
  else
    echo "  .env in .gitignore:        ⚠ Not found"
  fi

  if [[ "$ENV_EXAMPLE_EXISTS" == "true" ]]; then
    echo "  .env.example exists:       ✓ Yes"
  else
    echo "  .env.example exists:       — Not found (optional)"
  fi
  echo ""

  if [[ "$STAGE" == "growth" || "$STAGE" == "scale" ]]; then
    echo "── Stage: $STAGE (all gates enforced) ──"
    echo "  Posture snapshot required before release."
    echo ""
  fi

  if [[ $ISSUES -gt 0 ]]; then
    echo "── Recommendations ───────────────────────"
    if [[ "$STANDARD_EXISTS" == "false" ]]; then
      echo "  1. Create standards/security/security-posture.md"
    fi
    if [[ $CRITICAL_COUNT -gt 0 ]]; then
      echo "  → Resolve $CRITICAL_COUNT open CRITICAL findings before release"
    fi
    if [[ "$POSTURE_AGE" == "none" ]]; then
      echo "  → Generate first posture snapshot: /security-posture"
    fi
    echo ""
  fi
fi

# --- Exit code ---
if [[ "$VERDICT" == "AT RISK" ]]; then
  exit 1
elif [[ "$STANDARD_EXISTS" == "false" ]]; then
  exit 1
else
  exit 0
fi
