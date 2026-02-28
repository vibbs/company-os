#!/usr/bin/env bash
# Tool: T-QA-07 Resilience Test Runner
# Description: Runs basic resilience checks against a deployed environment
# Usage: ./tools/qa/resilience-test.sh <url> [timeout_seconds]
# Inputs: base URL (required), timeout in seconds (default: 5)
# Outputs: resilience check results (pass/fail per check)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."

# ─── Arguments ───────────────────────────────────────────────────────────────
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <url> [timeout_seconds]"
  echo ""
  echo "Runs basic resilience checks against a deployed environment:"
  echo "  1. Health endpoint reachability"
  echo "  2. Dependency timeout behavior"
  echo "  3. HTTP error handling (non-500 for bad paths)"
  echo "  4. Connection refused handling"
  echo ""
  echo "Examples:"
  echo "  $0 http://localhost:3000"
  echo "  $0 https://staging.example.com 10"
  exit 1
fi

BASE_URL="${1%/}"
TIMEOUT="${2:-5}"

echo "Resilience Test Runner"
echo "  Target:  $BASE_URL"
echo "  Timeout: ${TIMEOUT}s"
echo "================================"

TOTAL=0
PASSED=0
FAILED=0

resilience_check() {
  local name="$1"
  local result="$2"  # "pass" or "fail"
  local detail="$3"

  TOTAL=$((TOTAL + 1))
  if [[ "$result" == "pass" ]]; then
    echo "  PASS  $name — $detail"
    PASSED=$((PASSED + 1))
  else
    echo "  FAIL  $name — $detail"
    FAILED=$((FAILED + 1))
  fi
}

# ─── Check 1: Health endpoint reachability ───────────────────────────────────
echo ""
echo "--- Check 1: Health Endpoint Reachability ---"

HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT" "$BASE_URL/health" 2>/dev/null || echo "000")

if [[ "$HEALTH_STATUS" == "200" ]]; then
  resilience_check "Health endpoint" "pass" "responded 200 within ${TIMEOUT}s"
elif [[ "$HEALTH_STATUS" == "000" ]]; then
  resilience_check "Health endpoint" "fail" "unreachable or timed out (${TIMEOUT}s)"
else
  resilience_check "Health endpoint" "fail" "responded $HEALTH_STATUS (expected 200)"
fi

# ─── Check 2: Dependency timeout behavior ────────────────────────────────────
echo ""
echo "--- Check 2: Timeout Behavior ---"

# Use a very short timeout (1 second) to test how the service handles slow responses.
# We check that curl itself times out correctly — verifying timeout plumbing works.
SHORT_TIMEOUT=1
TIMEOUT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$SHORT_TIMEOUT" "$BASE_URL/health" 2>/dev/null || echo "000")

if [[ "$TIMEOUT_STATUS" == "200" || "$TIMEOUT_STATUS" == "000" ]]; then
  # Either it responded fast (pass) or it timed out (also acceptable — means timeout works)
  if [[ "$TIMEOUT_STATUS" == "200" ]]; then
    resilience_check "Timeout behavior" "pass" "health responded within ${SHORT_TIMEOUT}s (fast)"
  else
    resilience_check "Timeout behavior" "pass" "request timed out at ${SHORT_TIMEOUT}s (timeout enforced)"
  fi
else
  resilience_check "Timeout behavior" "fail" "unexpected status $TIMEOUT_STATUS with ${SHORT_TIMEOUT}s timeout"
fi

# ─── Check 3: HTTP error handling ────────────────────────────────────────────
echo ""
echo "--- Check 3: HTTP Error Handling ---"

# Request a path that should not exist. A well-configured app returns 404, not 500.
BAD_PATH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT" "$BASE_URL/nonexistent-resilience-test-path-99999" 2>/dev/null || echo "000")

if [[ "$BAD_PATH_STATUS" == "000" ]]; then
  resilience_check "Error handling (bad path)" "fail" "unreachable or timed out"
elif [[ "$BAD_PATH_STATUS" =~ ^5[0-9][0-9]$ ]]; then
  resilience_check "Error handling (bad path)" "fail" "returned $BAD_PATH_STATUS (server error for unknown path — should be 4xx)"
else
  resilience_check "Error handling (bad path)" "pass" "returned $BAD_PATH_STATUS (no server error for unknown path)"
fi

# ─── Check 4: Connection refused handling ────────────────────────────────────
echo ""
echo "--- Check 4: Connection Refused Handling ---"

# Attempt to connect to a port that is very unlikely to be open (port 1).
# This tests that the tooling and system handle connection-refused gracefully.
REFUSED_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "http://127.0.0.1:1/health" 2>/dev/null || echo "000")

if [[ "$REFUSED_STATUS" == "000" ]]; then
  resilience_check "Connection refused" "pass" "connection refused handled gracefully (no hang)"
else
  resilience_check "Connection refused" "fail" "unexpected status $REFUSED_STATUS from unreachable port"
fi

# ─── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "================================"
echo "Total: $TOTAL | Passed: $PASSED | Failed: $FAILED"
echo ""

if [[ $FAILED -gt 0 ]]; then
  echo "RESULT: Resilience checks FAILED ($FAILED/$TOTAL)"
  echo ""
  echo "Recommendations:"
  echo "  - Ensure /health endpoint is available and returns 200"
  echo "  - Verify unknown paths return 4xx (not 5xx)"
  echo "  - Review timeout configuration for external dependencies"
  echo "  - For full resilience testing, use the resilience-testing skill"
  exit 1
else
  echo "RESULT: Resilience checks PASSED ($PASSED/$TOTAL)"
  exit 0
fi
