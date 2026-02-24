#!/usr/bin/env bash
# Tool: T-SEC-03 Basic SAST (Static Application Security Testing)
# Description: Runs basic static analysis for common security patterns
# Usage: ./tools/security/sast.sh [path]
# Inputs: optional path to scan (default: current directory)
# Outputs: security findings, exit 0 if clean
set -euo pipefail

SCAN_PATH="${1:-.}"

echo "Basic SAST Scan"
echo "  Path: $SCAN_PATH"
echo "================================"

if command -v semgrep &> /dev/null; then
  semgrep --config auto "$SCAN_PATH"
elif command -v bandit &> /dev/null; then
  # Python-specific
  bandit -r "$SCAN_PATH"
else
  echo "No SAST tool found. Running basic pattern check..."
  echo ""

  EXIT_CODE=0

  # Check for common insecure patterns
  echo "Checking for common security anti-patterns..."

  # SQL injection patterns
  SQL_MATCHES=$(grep -rnE "(query|execute)\s*\(.*\+.*\)|f['\"].*SELECT|f['\"].*INSERT|f['\"].*UPDATE|f['\"].*DELETE" "$SCAN_PATH" \
    --include="*.ts" --include="*.js" --include="*.py" --include="*.go" 2>/dev/null || true)
  if [[ -n "$SQL_MATCHES" ]]; then
    echo "⚠️  Potential SQL injection (string concatenation in queries):"
    echo "$SQL_MATCHES" | head -5
    echo ""
    EXIT_CODE=1
  fi

  # Hardcoded credentials
  CRED_MATCHES=$(grep -rnEi "(password|secret|api_key|apikey|token)\s*=\s*['\"][^'\"]+['\"]" "$SCAN_PATH" \
    --include="*.ts" --include="*.js" --include="*.py" --include="*.go" 2>/dev/null || true)
  if [[ -n "$CRED_MATCHES" ]]; then
    echo "⚠️  Potential hardcoded credentials:"
    echo "$CRED_MATCHES" | head -5
    echo ""
    EXIT_CODE=1
  fi

  echo "================================"
  if [[ $EXIT_CODE -eq 0 ]]; then
    echo "✅ No issues found (basic scan)"
  else
    echo "⚠️  Potential issues found — review above"
  fi
  echo ""
  echo "NOTE: For comprehensive SAST, install semgrep:"
  echo "  pip install semgrep"
  exit $EXIT_CODE
fi
