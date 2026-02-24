#!/usr/bin/env bash
# Tool: T-SEC-02 Secrets Scan
# Description: Scans repository for accidentally committed secrets (API keys, tokens, passwords)
# Usage: ./tools/security/secrets-scan.sh [path]
# Inputs: optional path to scan (default: current directory)
# Outputs: list of potential secrets found, exit 0 if clean
set -euo pipefail

SCAN_PATH="${1:-.}"

echo "Secrets Scan"
echo "  Path: $SCAN_PATH"
echo "================================"

if command -v gitleaks &> /dev/null; then
  gitleaks detect --source "$SCAN_PATH" --no-git -v
elif command -v trufflehog &> /dev/null; then
  trufflehog filesystem "$SCAN_PATH"
else
  echo "No dedicated secrets scanner found. Running basic pattern scan..."
  echo ""

  EXIT_CODE=0
  PATTERNS=(
    "AKIA[0-9A-Z]{16}"                    # AWS Access Key
    "sk-[a-zA-Z0-9]{20,}"                 # OpenAI / Stripe secret key
    "ghp_[a-zA-Z0-9]{36}"                 # GitHub personal access token
    "glpat-[a-zA-Z0-9\-]{20,}"            # GitLab personal access token
    "xoxb-[0-9]{10,}-[a-zA-Z0-9]{20,}"    # Slack bot token
    "-----BEGIN (RSA |EC )?PRIVATE KEY-----"  # Private keys
  )

  for pattern in "${PATTERNS[@]}"; do
    MATCHES=$(grep -rnE "$pattern" "$SCAN_PATH" \
      --include="*.ts" --include="*.js" --include="*.py" --include="*.go" \
      --include="*.yaml" --include="*.yml" --include="*.json" --include="*.env" \
      --include="*.toml" --include="*.cfg" --include="*.conf" \
      2>/dev/null || true)

    if [[ -n "$MATCHES" ]]; then
      echo "⚠️  Potential secret found matching pattern: $pattern"
      echo "$MATCHES" | head -5
      echo ""
      EXIT_CODE=1
    fi
  done

  echo "================================"
  if [[ $EXIT_CODE -eq 0 ]]; then
    echo "✅ No secrets detected (basic scan)"
    echo "NOTE: For comprehensive scanning, install gitleaks or trufflehog:"
    echo "  brew install gitleaks"
    echo "  pip install trufflehog"
  else
    echo "❌ Potential secrets found — review above matches"
  fi
  exit $EXIT_CODE
fi
