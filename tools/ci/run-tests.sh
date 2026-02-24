#!/usr/bin/env bash
# Tool: T-CI-01 Run Tests
# Description: Runs the project test suite using the configured test framework
# Usage: ./tools/ci/run-tests.sh [test-path]
# Inputs: optional test path/pattern to run specific tests
# Outputs: test results summary, exit 0 if all pass
set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
CONFIG_FILE="$SCRIPT_DIR/../../company.config.yaml"
TEST_PATH="${1:-}"

# Read test framework from config (basic grep — upgrade to yq if available)
TEST_FRAMEWORK=""
if [[ -f "$CONFIG_FILE" ]]; then
  TEST_FRAMEWORK=$(grep "test_framework:" "$CONFIG_FILE" | sed 's/.*test_framework: *//' | tr -d '"' | tr -d "'" | xargs)
fi

if [[ -z "$TEST_FRAMEWORK" ]]; then
  echo "WARNING: No test_framework configured in company.config.yaml"
  echo "Attempting auto-detection..."

  if [[ -f "package.json" ]]; then
    if grep -q '"vitest"' package.json 2>/dev/null; then
      TEST_FRAMEWORK="Vitest"
    elif grep -q '"jest"' package.json 2>/dev/null; then
      TEST_FRAMEWORK="Jest"
    fi
  elif [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
    TEST_FRAMEWORK="pytest"
  elif [[ -f "go.mod" ]]; then
    TEST_FRAMEWORK="go test"
  elif [[ -f "Cargo.toml" ]]; then
    TEST_FRAMEWORK="cargo test"
  fi
fi

echo "Test Framework: ${TEST_FRAMEWORK:-not detected}"
echo "Test Path: ${TEST_PATH:-all}"
echo "================================"

case "$TEST_FRAMEWORK" in
  "Vitest"|"vitest")
    if [[ -n "$TEST_PATH" ]]; then
      npx vitest run "$TEST_PATH"
    else
      npx vitest run
    fi
    ;;
  "Jest"|"jest")
    if [[ -n "$TEST_PATH" ]]; then
      npx jest "$TEST_PATH"
    else
      npx jest
    fi
    ;;
  "pytest")
    if [[ -n "$TEST_PATH" ]]; then
      python -m pytest "$TEST_PATH" -v
    else
      python -m pytest -v
    fi
    ;;
  "go test")
    if [[ -n "$TEST_PATH" ]]; then
      go test "$TEST_PATH" -v
    else
      go test ./... -v
    fi
    ;;
  "cargo test")
    if [[ -n "$TEST_PATH" ]]; then
      cargo test "$TEST_PATH" -- --nocapture
    else
      cargo test -- --nocapture
    fi
    ;;
  *)
    echo "ERROR: Unknown or unconfigured test framework: '$TEST_FRAMEWORK'"
    echo "Set test_framework in company.config.yaml to one of: Vitest, Jest, pytest, go test, cargo test"
    exit 1
    ;;
esac
