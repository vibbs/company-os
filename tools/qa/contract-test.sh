#!/usr/bin/env bash
# Tool: T-QA-01 Contract Test Runner
# Description: Runs API contract tests against OpenAPI spec
# Usage: ./tools/qa/contract-test.sh <spec-path> [base-url]
# Inputs: OpenAPI spec path, optional base URL (default: http://localhost:3000)
# Outputs: contract test results
set -euo pipefail

SPEC_PATH="${1:-}"
BASE_URL="${2:-http://localhost:3000}"

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
