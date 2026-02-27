#!/usr/bin/env bash
# Tool: T-QA-03 Smoke Test Runner
# Description: Runs basic smoke tests against a deployed environment
# Usage: ./tools/qa/smoke-test.sh [base-url]
# Inputs: base URL (auto-resolved from .env if omitted)
# Outputs: smoke test results (pass/fail per endpoint)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."

# ─── Resolve app URL from .env → .env.example → framework defaults ───────────
resolve_app_url() {
  local ROOT="${1:-.}"
  local PORT=""

  # 1. Try .env (prefer PORT for fullstack, then API_PORT for backend-only)
  if [[ -f "$ROOT/.env" ]]; then
    PORT=$(grep -E '^PORT=' "$ROOT/.env" | head -1 | sed 's/.*=//' | sed 's/ *#.*//' | tr -d '"' | tr -d "'" | tr -d '[:space:]' || true)
    if [[ -z "$PORT" ]]; then
      PORT=$(grep -E '^API_PORT=' "$ROOT/.env" | head -1 | sed 's/.*=//' | sed 's/ *#.*//' | tr -d '"' | tr -d "'" | tr -d '[:space:]' || true)
    fi
  fi

  # 2. Try .env.example
  if [[ -z "$PORT" && -f "$ROOT/.env.example" ]]; then
    PORT=$(grep -E '^PORT=' "$ROOT/.env.example" | head -1 | sed 's/.*=//' | sed 's/ *#.*//' | tr -d '"' | tr -d "'" | tr -d '[:space:]' || true)
    if [[ -z "$PORT" ]]; then
      PORT=$(grep -E '^API_PORT=' "$ROOT/.env.example" | head -1 | sed 's/.*=//' | sed 's/ *#.*//' | tr -d '"' | tr -d "'" | tr -d '[:space:]' || true)
    fi
  fi

  # 3. Fall back to framework default
  if [[ -z "$PORT" ]]; then
    local CONFIG="$ROOT/company.config.yaml"
    local FRAMEWORK=""
    if [[ -f "$CONFIG" ]]; then
      FRAMEWORK=$(grep "^  framework:" "$CONFIG" 2>/dev/null | sed 's/.*framework: *//' | tr -d '"' | tr -d "'" | sed 's/ *#.*//' | tr '[:upper:]' '[:lower:]' || true)
    fi
    case "$FRAMEWORK" in
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

BASE_URL="${1:-}"

if [[ -z "$BASE_URL" ]]; then
  BASE_URL=$(resolve_app_url "$PROJECT_ROOT")
  echo "NOTE: No URL provided — resolved from .env / framework defaults: $BASE_URL"
fi

# Remove trailing slash
BASE_URL="${BASE_URL%/}"

echo "Smoke Test Runner"
echo "  Target: $BASE_URL"
echo "================================"

TOTAL=0
PASSED=0
FAILED=0

smoke_test() {
  local name="$1"
  local url="$2"
  local expected_status="${3:-200}"

  TOTAL=$((TOTAL + 1))
  ACTUAL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null || echo "000")

  if [[ "$ACTUAL_STATUS" == "$expected_status" ]]; then
    echo "  ✅ $name — $ACTUAL_STATUS"
    PASSED=$((PASSED + 1))
  else
    echo "  ❌ $name — expected $expected_status, got $ACTUAL_STATUS"
    FAILED=$((FAILED + 1))
  fi
}

# Basic smoke tests
smoke_test "Health check" "$BASE_URL/health" "200"
smoke_test "API root" "$BASE_URL/api" "200"
smoke_test "404 handling" "$BASE_URL/nonexistent-path-12345" "404"

echo ""
echo "================================"
echo "Total: $TOTAL | Passed: $PASSED | Failed: $FAILED"

if [[ $FAILED -gt 0 ]]; then
  echo "❌ Smoke tests FAILED"
  exit 1
else
  echo "✅ Smoke tests PASSED"
  exit 0
fi
