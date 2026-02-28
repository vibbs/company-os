#!/usr/bin/env bash
# Tool: T-QA-06 Test Health Analyzer
# Description: Analyzes test suite health — counts tests by type, checks pyramid balance, detects flaky patterns
# Usage: ./tools/qa/test-health.sh [list|analyze]
# Inputs: command (list = show recent reports, analyze = run basic analysis)
# Outputs: test health summary to stdout
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
REPORTS_DIR="$PROJECT_ROOT/artifacts/qa-reports"
COMMAND="${1:-analyze}"

# ─── Helper: count files matching patterns ────────────────────────────────────
count_test_files() {
  local DIR="$1"
  local PATTERN="$2"
  find "$DIR" -type f -name "$PATTERN" 2>/dev/null | wc -l | tr -d ' '
}

# ─── list: show recent test health reports ────────────────────────────────────
cmd_list() {
  echo "=== Test Health Reports ==="
  echo ""
  mkdir -p "$REPORTS_DIR"

  FOUND=false
  while IFS= read -r -d '' file; do
    if [[ "$(basename "$file")" == test-health-* ]]; then
      FOUND=true
      # Extract status from frontmatter
      STATUS=$(sed -n '/^---$/,/^---$/p' "$file" | grep "^status:" | sed 's/status: *//' | tr -d '"' | tr -d "'" || true)
      DATE_PART=$(basename "$file" | sed 's/test-health-//' | sed 's/\.md$//')
      printf "  %-25s  [%s]  %s\n" "$DATE_PART" "${STATUS:-unknown}" "$file"
    fi
  done < <(find "$REPORTS_DIR" -name "test-health-*.md" -print0 2>/dev/null)

  if [[ "$FOUND" == "false" ]]; then
    echo "  No test health reports found in $REPORTS_DIR"
    echo "  Run the test-intelligence skill to generate a health report."
  fi

  echo ""
}

# ─── analyze: run basic test suite analysis ───────────────────────────────────
cmd_analyze() {
  echo "=== Test Suite Health Analysis ==="
  echo ""

  # Find test directories
  TEST_DIRS=()
  for DIR in "$PROJECT_ROOT/tests" "$PROJECT_ROOT/test" "$PROJECT_ROOT/__tests__" "$PROJECT_ROOT/spec" "$PROJECT_ROOT/src"; do
    if [[ -d "$DIR" ]]; then
      TEST_DIRS+=("$DIR")
    fi
  done

  if [[ ${#TEST_DIRS[@]} -eq 0 ]]; then
    echo "  No test directories found (checked: tests/, test/, __tests__/, spec/, src/)"
    echo "  Ensure your test files are in a standard location."
    echo ""
    echo "Done."
    return
  fi

  echo "Test directories found: ${TEST_DIRS[*]}"
  echo ""

  # Count test files by pattern
  UNIT_COUNT=0
  INTEGRATION_COUNT=0
  E2E_COUNT=0
  TOTAL_TEST_FILES=0

  for DIR in "${TEST_DIRS[@]}"; do
    # Unit tests: files in unit/ dirs or named *.unit.*
    UNIT_IN_DIR=$(find "$DIR" -type f \( -path "*/unit/*" -o -name "*.unit.*" \) \( -name "*.test.*" -o -name "*.spec.*" -o -name "test_*" \) 2>/dev/null | wc -l | tr -d ' ')
    UNIT_COUNT=$((UNIT_COUNT + UNIT_IN_DIR))

    # Integration tests: files in integration/ dirs or named *.integration.*
    INT_IN_DIR=$(find "$DIR" -type f \( -path "*/integration/*" -o -name "*.integration.*" \) \( -name "*.test.*" -o -name "*.spec.*" -o -name "test_*" \) 2>/dev/null | wc -l | tr -d ' ')
    INTEGRATION_COUNT=$((INTEGRATION_COUNT + INT_IN_DIR))

    # E2E tests: files in e2e/ or cypress/ dirs or named *.e2e.*
    E2E_IN_DIR=$(find "$DIR" -type f \( -path "*/e2e/*" -o -path "*/cypress/*" -o -name "*.e2e.*" \) \( -name "*.test.*" -o -name "*.spec.*" -o -name "test_*" \) 2>/dev/null | wc -l | tr -d ' ')
    E2E_COUNT=$((E2E_COUNT + E2E_IN_DIR))

    # Total test files (any *.test.*, *.spec.*, test_*)
    TOTAL_IN_DIR=$(find "$DIR" -type f \( -name "*.test.*" -o -name "*.spec.*" -o -name "test_*" \) 2>/dev/null | wc -l | tr -d ' ')
    TOTAL_TEST_FILES=$((TOTAL_TEST_FILES + TOTAL_IN_DIR))
  done

  # Unclassified = total minus classified
  CLASSIFIED=$((UNIT_COUNT + INTEGRATION_COUNT + E2E_COUNT))
  UNCLASSIFIED=$((TOTAL_TEST_FILES - CLASSIFIED))
  if [[ $UNCLASSIFIED -lt 0 ]]; then
    UNCLASSIFIED=0
  fi

  echo "--- Test File Counts ---"
  echo "  Unit tests:        $UNIT_COUNT"
  echo "  Integration tests: $INTEGRATION_COUNT"
  echo "  E2E tests:         $E2E_COUNT"
  echo "  Unclassified:      $UNCLASSIFIED"
  echo "  Total test files:  $TOTAL_TEST_FILES"
  echo ""

  # Calculate pyramid ratio
  if [[ $CLASSIFIED -gt 0 ]]; then
    UNIT_PCT=$((UNIT_COUNT * 100 / CLASSIFIED))
    INT_PCT=$((INTEGRATION_COUNT * 100 / CLASSIFIED))
    E2E_PCT=$((E2E_COUNT * 100 / CLASSIFIED))

    echo "--- Test Pyramid ---"
    echo "  Current ratio:  ${UNIT_PCT}% unit : ${INT_PCT}% integration : ${E2E_PCT}% e2e"
    echo "  Ideal ratio:    70% unit : 20% integration : 10% e2e"
    echo ""

    # Flag pyramid issues
    if [[ $E2E_PCT -gt $UNIT_PCT && $UNIT_PCT -gt 0 ]]; then
      echo "  WARNING: Pyramid inversion detected (ice cream cone) -- more E2E tests than unit tests"
    elif [[ $INT_PCT -gt 50 ]]; then
      echo "  WARNING: Diamond shape detected -- majority integration tests, consider adding more unit tests"
    elif [[ $UNIT_PCT -gt 0 && $INT_PCT -eq 0 && $E2E_PCT -gt 0 ]]; then
      echo "  WARNING: Hourglass shape detected -- unit and E2E tests but no integration tests"
    elif [[ $CLASSIFIED -gt 0 ]]; then
      echo "  Pyramid shape looks reasonable."
    fi
  else
    echo "--- Test Pyramid ---"
    echo "  Cannot calculate pyramid ratio -- no tests classified by type."
    echo "  Organize tests into unit/, integration/, e2e/ directories for analysis."
  fi
  echo ""

  # Scan for common flaky test patterns
  echo "--- Flaky Test Pattern Scan ---"
  FLAKY_PATTERNS=0

  for DIR in "${TEST_DIRS[@]}"; do
    # setTimeout / sleep in test files
    TIMEOUT_HITS=$(grep -rl "setTimeout\|sleep(" "$DIR" --include="*.test.*" --include="*.spec.*" 2>/dev/null | wc -l | tr -d ' ' || true)
    if [[ -z "$TIMEOUT_HITS" ]]; then TIMEOUT_HITS=0; fi
    FLAKY_PATTERNS=$((FLAKY_PATTERNS + TIMEOUT_HITS))

    # Date.now / new Date() in assertions
    DATE_HITS=$(grep -rl "Date\.now\|new Date()" "$DIR" --include="*.test.*" --include="*.spec.*" 2>/dev/null | wc -l | tr -d ' ' || true)
    if [[ -z "$DATE_HITS" ]]; then DATE_HITS=0; fi
    FLAKY_PATTERNS=$((FLAKY_PATTERNS + DATE_HITS))

    # Math.random in test files
    RANDOM_HITS=$(grep -rl "Math\.random\|random\." "$DIR" --include="*.test.*" --include="*.spec.*" 2>/dev/null | wc -l | tr -d ' ' || true)
    if [[ -z "$RANDOM_HITS" ]]; then RANDOM_HITS=0; fi
    FLAKY_PATTERNS=$((FLAKY_PATTERNS + RANDOM_HITS))
  done

  if [[ $FLAKY_PATTERNS -gt 0 ]]; then
    echo "  Found $FLAKY_PATTERNS test files with potential flaky patterns"
    echo "  (setTimeout/sleep, Date.now/new Date, Math.random)"
    echo "  Run the test-intelligence skill for detailed analysis and quarantine recommendations."
  else
    echo "  No common flaky patterns detected."
  fi
  echo ""

  echo "=== Summary ==="
  echo "  Total test files: $TOTAL_TEST_FILES"
  echo "  Classified:       $CLASSIFIED (unit: $UNIT_COUNT, integration: $INTEGRATION_COUNT, e2e: $E2E_COUNT)"
  echo "  Flaky risk files: $FLAKY_PATTERNS"
  echo ""
  echo "  For a full health report, run the test-intelligence skill."
  echo ""
  echo "Done."
}

# ─── Main ─────────────────────────────────────────────────────────────────────
case "$COMMAND" in
  list)
    cmd_list
    ;;
  analyze)
    cmd_analyze
    ;;
  *)
    echo "Usage: $0 [list|analyze]"
    echo ""
    echo "  list     List recent test health reports in artifacts/qa-reports/"
    echo "  analyze  Run basic test suite analysis (counts, pyramid, flaky patterns)"
    echo ""
    exit 1
    ;;
esac
