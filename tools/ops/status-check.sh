#!/usr/bin/env bash
# Tool: T-OPS-01 Status Check
# Description: Checks health of one or more HTTP endpoints (status code, response time, SSL)
# Usage: ./tools/ops/status-check.sh [--timeout <ms>] [--expected-status <code>] [--verbose] <url> [<url> ...]
# Inputs: one or more URLs to check
# Outputs: health report per URL, exit 0=healthy 1=degraded 2=down
set -euo pipefail

# ─── Defaults ───────────────────────────────────────────────────────────────────
TIMEOUT_MS=5000
EXPECTED_STATUS=200
VERBOSE=false
URLS=()

# ─── Color codes (portable: works on macOS and Linux) ───────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── Usage ──────────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <url> [<url> ...]

Check the health of one or more HTTP endpoints.

Options:
  --timeout <ms>           Connection timeout in milliseconds (default: 5000)
  --expected-status <code> Expected HTTP status code (default: 200)
  --verbose                Show additional details (headers, redirect chain)
  --help                   Show this help message

Examples:
  $(basename "$0") https://example.com
  $(basename "$0") --timeout 3000 --expected-status 200 https://api.example.com/health
  $(basename "$0") --verbose https://app.example.com https://api.example.com

Exit Codes:
  0  All endpoints healthy
  1  One or more endpoints degraded (slow response or unexpected status)
  2  One or more endpoints down (connection failed)
EOF
  exit 0
}

# ─── Parse arguments ────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help)
      usage
      ;;
    --timeout)
      TIMEOUT_MS="$2"
      shift 2
      ;;
    --expected-status)
      EXPECTED_STATUS="$2"
      shift 2
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    -*)
      echo "Unknown option: $1" >&2
      echo "Run with --help for usage." >&2
      exit 2
      ;;
    *)
      URLS+=("$1")
      shift
      ;;
  esac
done

# Show usage if no URLs provided
if [[ ${#URLS[@]} -eq 0 ]]; then
  echo "Error: No URLs provided." >&2
  echo ""
  usage
fi

# Convert timeout from milliseconds to seconds for curl (supports decimals)
TIMEOUT_SEC=$(awk "BEGIN {printf \"%.1f\", $TIMEOUT_MS / 1000}")

# ─── Counters for summary ──────────────────────────────────────────────────────
HEALTHY=0
DEGRADED=0
DOWN=0

# Threshold for "slow" response in seconds
SLOW_THRESHOLD=2.0

echo ""
echo -e "${BOLD}Service Health Check${RESET}"
echo "================================"
echo "Timeout: ${TIMEOUT_MS}ms | Expected status: ${EXPECTED_STATUS}"
echo ""

# ─── Check each URL ────────────────────────────────────────────────────────────
for URL in "${URLS[@]}"; do
  echo -e "${BOLD}Checking:${RESET} ${URL}"

  # Attempt the HTTP request, capturing status code and timing.
  # curl -o /dev/null discards the body, -s is silent, -w provides metrics.
  # --max-time caps total time, --connect-timeout caps the TCP connect phase.
  HTTP_STATUS=""
  RESPONSE_TIME=""
  CURL_EXIT=0

  CURL_OUTPUT=$(curl -o /dev/null -s -w "%{http_code} %{time_total} %{ssl_verify_result}" \
    --max-time "$TIMEOUT_SEC" \
    --connect-timeout "$TIMEOUT_SEC" \
    -L "$URL" 2>&1) || CURL_EXIT=$?

  if [[ $CURL_EXIT -ne 0 ]]; then
    # Connection failed entirely
    echo -e "  Status:        ${RED}CONNECTION FAILED${RESET} (curl exit code: ${CURL_EXIT})"
    echo -e "  Result:        ${RED}DOWN${RESET}"
    DOWN=$((DOWN + 1))
    echo ""
    continue
  fi

  # Parse curl output: "status_code time_total ssl_verify_result"
  HTTP_STATUS=$(echo "$CURL_OUTPUT" | awk '{print $1}')
  RESPONSE_TIME=$(echo "$CURL_OUTPUT" | awk '{print $2}')
  SSL_VERIFY=$(echo "$CURL_OUTPUT" | awk '{print $3}')

  # Determine status color
  STATUS_COLOR="$GREEN"
  if [[ "$HTTP_STATUS" != "$EXPECTED_STATUS" ]]; then
    STATUS_COLOR="$RED"
  fi

  # Determine response time color (green < 2s, yellow >= 2s)
  TIME_COLOR="$GREEN"
  IS_SLOW=false
  if awk "BEGIN {exit !($RESPONSE_TIME >= $SLOW_THRESHOLD)}" 2>/dev/null; then
    TIME_COLOR="$YELLOW"
    IS_SLOW=true
  fi

  # Display status code
  echo -e "  Status:        ${STATUS_COLOR}${HTTP_STATUS}${RESET}"

  # Display response time
  RESPONSE_TIME_MS=$(awk "BEGIN {printf \"%.0f\", $RESPONSE_TIME * 1000}")
  echo -e "  Response time: ${TIME_COLOR}${RESPONSE_TIME_MS}ms${RESET}"

  # Check SSL validity for HTTPS URLs
  if [[ "$URL" == https://* ]]; then
    if [[ "$SSL_VERIFY" == "0" ]]; then
      echo -e "  SSL:           ${GREEN}Valid${RESET}"
    else
      echo -e "  SSL:           ${RED}Invalid (verify result: ${SSL_VERIFY})${RESET}"
    fi
  else
    echo -e "  SSL:           N/A (not HTTPS)"
  fi

  # Verbose output: show response headers
  if [[ "$VERBOSE" == true ]]; then
    echo "  --- Verbose details ---"
    curl -s -I --max-time "$TIMEOUT_SEC" -L "$URL" 2>/dev/null | while IFS= read -r line; do
      echo "    $line"
    done
  fi

  # Classify result
  if [[ "$HTTP_STATUS" != "$EXPECTED_STATUS" ]]; then
    echo -e "  Result:        ${RED}DEGRADED${RESET} (expected ${EXPECTED_STATUS}, got ${HTTP_STATUS})"
    DEGRADED=$((DEGRADED + 1))
  elif [[ "$IS_SLOW" == true ]]; then
    echo -e "  Result:        ${YELLOW}DEGRADED${RESET} (slow response: ${RESPONSE_TIME_MS}ms)"
    DEGRADED=$((DEGRADED + 1))
  else
    echo -e "  Result:        ${GREEN}HEALTHY${RESET}"
    HEALTHY=$((HEALTHY + 1))
  fi

  echo ""
done

# ─── Summary ────────────────────────────────────────────────────────────────────
TOTAL=${#URLS[@]}
echo "================================"
echo -e "${BOLD}Summary${RESET}: ${TOTAL} endpoint(s) checked"
echo -e "  ${GREEN}Healthy:${RESET}  ${HEALTHY}"
echo -e "  ${YELLOW}Degraded:${RESET} ${DEGRADED}"
echo -e "  ${RED}Down:${RESET}     ${DOWN}"
echo ""

# ─── Exit code: 0=all healthy, 1=degraded, 2=down ──────────────────────────────
if [[ $DOWN -gt 0 ]]; then
  exit 2
elif [[ $DEGRADED -gt 0 ]]; then
  exit 1
else
  exit 0
fi
