#!/usr/bin/env bash
# Tool: T-QA-01 Contract Test Runner
# Description: Runs API contract tests against OpenAPI spec
# Usage: ./tools/qa/contract-test.sh <spec-path> [base-url]
# Inputs: OpenAPI spec path, optional base URL (auto-resolved from .env if omitted)
# Outputs: contract test results
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."

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

SPEC_PATH="${1:-}"
BASE_URL="${2:-$(resolve_app_url "$PROJECT_ROOT")}"

if [[ -z "$SPEC_PATH" ]]; then
  echo "ERROR: No spec path provided"
  echo "Usage: ./tools/qa/contract-test.sh <spec-path> [base-url]"
  exit 1
fi

echo "API Contract Test Runner"
echo "  Spec: $SPEC_PATH"
echo "  Base URL: $BASE_URL"
echo "================================"

# Try common contract test tools
if command -v dredd &> /dev/null; then
  dredd "$SPEC_PATH" "$BASE_URL"
elif command -v schemathesis &> /dev/null; then
  schemathesis run "$SPEC_PATH" --base-url "$BASE_URL" --checks all
elif command -v prism &> /dev/null; then
  prism proxy "$SPEC_PATH" "$BASE_URL" --errors
else
  echo "NOTE: No contract test tool found."
  echo "Install one of:"
  echo "  npm install -g dredd"
  echo "  pip install schemathesis"
  echo "  npm install -g @stoplight/prism-cli"
  echo ""
  echo "Manual contract test checklist:"
  echo "  [ ] All endpoints in spec return expected status codes"
  echo "  [ ] Response bodies match schema shapes"
  echo "  [ ] Auth enforcement works (401/403 for protected routes)"
  echo "  [ ] Error responses follow configured error format"
  exit 1
fi
