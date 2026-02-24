#!/usr/bin/env bash
# Tool: T-CI-02 Lint/Format
# Description: Runs linter and formatter using the configured tools
# Usage: ./tools/ci/lint-format.sh [--fix]
# Inputs: optional --fix flag to auto-fix issues
# Outputs: lint/format results, exit 0 if clean
set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
CONFIG_FILE="$SCRIPT_DIR/../../company.config.yaml"
FIX_FLAG="${1:-}"

# Read config
LINTER=""
FORMATTER=""
if [[ -f "$CONFIG_FILE" ]]; then
  LINTER=$(grep "linter:" "$CONFIG_FILE" | sed 's/.*linter: *//' | tr -d '"' | tr -d "'" | xargs)
  FORMATTER=$(grep "formatter:" "$CONFIG_FILE" | sed 's/.*formatter: *//' | tr -d '"' | tr -d "'" | xargs)
fi

echo "Linter: ${LINTER:-not configured}"
echo "Formatter: ${FORMATTER:-not configured}"
echo "Mode: ${FIX_FLAG:-check only}"
echo "================================"

EXIT_CODE=0

# Run linter
if [[ -n "$LINTER" ]]; then
  echo ""
  echo "Running linter: $LINTER"
  case "$LINTER" in
    "ESLint"|"eslint")
      if [[ "$FIX_FLAG" == "--fix" ]]; then
        npx eslint . --fix || EXIT_CODE=$?
      else
        npx eslint . || EXIT_CODE=$?
      fi
      ;;
    "Biome"|"biome")
      if [[ "$FIX_FLAG" == "--fix" ]]; then
        npx biome check --write . || EXIT_CODE=$?
      else
        npx biome check . || EXIT_CODE=$?
      fi
      ;;
    "Ruff"|"ruff")
      if [[ "$FIX_FLAG" == "--fix" ]]; then
        ruff check --fix . || EXIT_CODE=$?
      else
        ruff check . || EXIT_CODE=$?
      fi
      ;;
    "golangci-lint")
      golangci-lint run ./... || EXIT_CODE=$?
      ;;
    *)
      echo "WARNING: Unknown linter '$LINTER' — skipping"
      ;;
  esac
fi

# Run formatter
if [[ -n "$FORMATTER" ]]; then
  echo ""
  echo "Running formatter: $FORMATTER"
  case "$FORMATTER" in
    "Prettier"|"prettier")
      if [[ "$FIX_FLAG" == "--fix" ]]; then
        npx prettier --write . || EXIT_CODE=$?
      else
        npx prettier --check . || EXIT_CODE=$?
      fi
      ;;
    "Biome"|"biome")
      if [[ "$FIX_FLAG" == "--fix" ]]; then
        npx biome format --write . || EXIT_CODE=$?
      else
        npx biome format . || EXIT_CODE=$?
      fi
      ;;
    "Black"|"black")
      if [[ "$FIX_FLAG" == "--fix" ]]; then
        black . || EXIT_CODE=$?
      else
        black --check . || EXIT_CODE=$?
      fi
      ;;
    "gofmt")
      if [[ "$FIX_FLAG" == "--fix" ]]; then
        gofmt -w . || EXIT_CODE=$?
      else
        UNFORMATTED=$(gofmt -l .)
        if [[ -n "$UNFORMATTED" ]]; then
          echo "Unformatted files:"
          echo "$UNFORMATTED"
          EXIT_CODE=1
        fi
      fi
      ;;
    *)
      echo "WARNING: Unknown formatter '$FORMATTER' — skipping"
      ;;
  esac
fi

echo ""
echo "================================"
if [[ $EXIT_CODE -eq 0 ]]; then
  echo "✅ Lint/Format: CLEAN"
else
  echo "❌ Lint/Format: ISSUES FOUND"
fi
exit $EXIT_CODE
