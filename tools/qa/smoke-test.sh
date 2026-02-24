#!/usr/bin/env bash
# Tool: T-QA-03 Smoke Test Runner
# Description: Runs basic smoke tests against a deployed environment
# Usage: ./tools/qa/smoke-test.sh <base-url>
# Inputs: base URL of deployed environment
# Outputs: smoke test results (pass/fail per endpoint)
set -euo pipefail

BASE_URL="${1:-}"

if [[ -z "$BASE_URL" ]]; then
  echo "ERROR: No base URL provided"
  echo "Usage: ./tools/qa/smoke-test.sh <base-url>"
  exit 1
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
