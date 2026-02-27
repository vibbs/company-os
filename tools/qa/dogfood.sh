#!/usr/bin/env bash
# Tool: Dogfood Pre-flight
# Description: Validates target URL, detects product type, and scaffolds dogfood output directories
# Usage: ./tools/qa/dogfood.sh <url> [--prd <prd-id>] [--journey <name>] [--api-only]
# Inputs: target URL, optional PRD ID, optional journey name
# Outputs: exit 0 if pre-flight passes, exit 1 if URL unreachable or config missing
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
CONFIG_FILE="$PROJECT_ROOT/company.config.yaml"
ARTIFACTS_DIR="$PROJECT_ROOT/artifacts"

# Parse arguments
URL=""
PRD_ID=""
JOURNEY=""
API_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prd)
      PRD_ID="$2"
      shift 2
      ;;
    --journey)
      JOURNEY="$2"
      shift 2
      ;;
    --api-only)
      API_ONLY=true
      shift
      ;;
    -*)
      echo "ERROR: Unknown flag: $1"
      echo "Usage: ./tools/qa/dogfood.sh <url> [--prd <prd-id>] [--journey <name>] [--api-only]"
      exit 1
      ;;
    *)
      URL="$1"
      shift
      ;;
  esac
done

# ─── Resolve app URL from .env → .env.example → framework defaults ───────────
resolve_app_url() {
  local ROOT="${1:-.}"
  local PORT=""

  # 1. Try .env
  if [[ -f "$ROOT/.env" ]]; then
    PORT=$(grep -E '^(API_)?PORT=' "$ROOT/.env" | head -1 | sed 's/.*=//' | sed 's/ *#.*//' | tr -d '"' | tr -d "'" | tr -d '[:space:]' || true)
  fi

  # 2. Try .env.example
  if [[ -z "$PORT" && -f "$ROOT/.env.example" ]]; then
    PORT=$(grep -E '^(API_)?PORT=' "$ROOT/.env.example" | head -1 | sed 's/.*=//' | sed 's/ *#.*//' | tr -d '"' | tr -d "'" | tr -d '[:space:]' || true)
  fi

  # 3. Fall back to framework default
  if [[ -z "$PORT" ]]; then
    local CONFIG="$ROOT/company.config.yaml"
    local FRAMEWORK=""
    if [[ -f "$CONFIG" ]]; then
      FRAMEWORK=$(grep "^  framework:" "$CONFIG" 2>/dev/null | sed 's/.*framework: *//' | tr -d '"' | tr -d "'" | sed 's/ *#.*//' || true)
    fi
    case "${FRAMEWORK,,}" in
      *next*|*nest*|*express*|*rails*) PORT="3000" ;;
      *fastapi*|*django*|*laravel*) PORT="8000" ;;
      *flask*) PORT="5000" ;;
      *gin*|*spring*) PORT="8080" ;;
      *vite*|*react*|*svelte*) PORT="5173" ;;
      *) PORT="3000" ;;
    esac
  fi

  echo "http://localhost:${PORT}"
}

if [[ -z "$URL" ]]; then
  URL=$(resolve_app_url "$PROJECT_ROOT")
  echo "NOTE: No URL provided — resolved from .env / framework defaults: $URL"
  echo ""
fi

echo "=== Dogfood Pre-flight ==="
echo "URL: $URL"
echo "PRD: ${PRD_ID:-"(auto-detect most recent)"}"
echo "Journey: ${JOURNEY:-"(all)"}"
echo "API-only: $API_ONLY"
echo ""

# --- Step 1: Validate URL is reachable ---
echo "Checking URL reachability..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 --max-time 30 "$URL" 2>/dev/null || echo "000")
HTTP_STATUS="${HTTP_STATUS:-000}"

if [[ "$HTTP_STATUS" == "000" ]]; then
  echo "ERROR: Cannot reach $URL (connection failed or timed out)"
  echo "Make sure the application is running before dogfooding"
  exit 1
elif [[ "$HTTP_STATUS" -ge 500 ]]; then
  echo "WARNING: $URL returned HTTP $HTTP_STATUS (server error)"
  echo "The application may be unhealthy. Proceeding with caution."
else
  echo "OK: $URL is reachable (HTTP $HTTP_STATUS)"
fi

# --- Step 2: Detect product type ---
echo ""
echo "Detecting product type..."

# Extract framework from config
extract_config() {
  local KEY="$1"
  if [[ -f "$CONFIG_FILE" ]]; then
    grep "^  ${KEY}:" "$CONFIG_FILE" 2>/dev/null | sed "s/.*${KEY}: *//" | tr -d '"' | tr -d "'" || true
  fi
}

FRAMEWORK=$(extract_config "framework")
PRODUCT_TYPE="unknown"

if [[ "$API_ONLY" == "true" ]]; then
  PRODUCT_TYPE="api-only"
else
  # Check response content type
  CONTENT_TYPE=$(curl -s -o /dev/null -w "%{content_type}" --connect-timeout 10 --max-time 30 "$URL" 2>/dev/null || echo "")

  case "${FRAMEWORK,,}" in
    *next*|*react*|*vue*|*nuxt*|*svelte*|*angular*|*astro*|*remix*|*django*|*rails*)
      PRODUCT_TYPE="web-app"
      ;;
    *express*|*fastapi*|*flask*|*gin*|*echo*|*hono*|*koa*|*fastify*)
      PRODUCT_TYPE="api-only"
      ;;
    *)
      # Fallback: check content type
      if echo "$CONTENT_TYPE" | grep -qi "text/html"; then
        PRODUCT_TYPE="web-app"
      elif echo "$CONTENT_TYPE" | grep -qi "application/json"; then
        PRODUCT_TYPE="api-only"
      else
        PRODUCT_TYPE="web-app"  # Default to web-app
      fi
      ;;
  esac
fi

echo "Product type: $PRODUCT_TYPE"

# --- Step 3: Validate PRD exists (if specified) ---
if [[ -n "$PRD_ID" ]]; then
  echo ""
  echo "Looking for PRD: $PRD_ID..."
  PRD_FILE=$(grep -rl "^id: *${PRD_ID} *$" "$ARTIFACTS_DIR/prds/" --include="*.md" 2>/dev/null | head -1 || true)
  if [[ -z "$PRD_FILE" ]]; then
    echo "WARNING: PRD '$PRD_ID' not found in artifacts/prds/"
    echo "Dogfooding will proceed without PRD-scoped journeys"
  else
    echo "OK: Found PRD at $PRD_FILE"
  fi
fi

# --- Step 4: Check seed data ---
echo ""
echo "Checking seed data..."
SEEDS_DIR="$PROJECT_ROOT/seeds"
if [[ -d "$SEEDS_DIR" ]]; then
  SCENARIO_COUNT=$(ls -1 "$SEEDS_DIR/scenarios/" 2>/dev/null | wc -l | tr -d ' ')
  echo "OK: seeds/ directory exists ($SCENARIO_COUNT scenario files found)"
  echo "Recommendation: Run './tools/db/seed.sh nominal' before dogfooding for realistic data"
else
  echo "WARNING: No seeds/ directory found"
  echo "Recommendation: Run '/seed-data' to generate seed data, then seed with './tools/db/seed.sh nominal'"
fi

# --- Step 5: Check agent-browser availability (for web apps) ---
if [[ "$PRODUCT_TYPE" == "web-app" ]]; then
  echo ""
  echo "Checking browser automation..."
  BROWSER_SKILL="$PROJECT_ROOT/.claude/skills/agent-browser"
  if [[ -d "$BROWSER_SKILL" ]]; then
    echo "OK: agent-browser skill found locally"
  else
    # Check if it's available as an external skill (can't verify from shell, note it)
    echo "NOTE: agent-browser not found locally — it may be an external/MCP skill"
    echo "If browser automation fails, dogfooding will fall back to API-only or manual checklist mode"
  fi
fi

# --- Step 6: Create output directory ---
echo ""
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_DIR="$ARTIFACTS_DIR/qa-reports/dogfood-runs/$TIMESTAMP"
mkdir -p "$OUTPUT_DIR"
echo "Output directory created: $OUTPUT_DIR"

# --- Summary ---
echo ""
echo "=== Pre-flight Summary ==="
echo "URL:          $URL (HTTP $HTTP_STATUS)"
echo "Product type: $PRODUCT_TYPE"
echo "PRD:          ${PRD_ID:-"auto-detect"}"
echo "Output:       $OUTPUT_DIR"
echo ""
echo "Pre-flight complete. Ready for dogfooding."
echo ""
echo "Next: The dogfood skill will extract user journeys from the PRD and execute them against $URL"

exit 0
