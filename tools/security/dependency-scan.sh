#!/usr/bin/env bash
# Tool: T-SEC-01 Dependency Scan
# Description: Scans project dependencies for known vulnerabilities
# Usage: ./tools/security/dependency-scan.sh
# Inputs: none (reads from project lock files)
# Outputs: vulnerability report, exit 0 if clean
set -euo pipefail

echo "Dependency Security Scan"
echo "================================"

EXIT_CODE=0

# Node.js projects
if [[ -f "package-lock.json" ]] || [[ -f "yarn.lock" ]] || [[ -f "pnpm-lock.yaml" ]]; then
  echo "Scanning Node.js dependencies..."
  npm audit --production 2>/dev/null || EXIT_CODE=$?
fi

# Python projects
if [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
  echo "Scanning Python dependencies..."
  if command -v pip-audit &> /dev/null; then
    pip-audit || EXIT_CODE=$?
  elif command -v safety &> /dev/null; then
    safety check || EXIT_CODE=$?
  else
    echo "NOTE: Install pip-audit or safety for Python dependency scanning"
    echo "  pip install pip-audit"
  fi
fi

# Go projects
if [[ -f "go.sum" ]]; then
  echo "Scanning Go dependencies..."
  if command -v govulncheck &> /dev/null; then
    govulncheck ./... || EXIT_CODE=$?
  else
    echo "NOTE: Install govulncheck for Go dependency scanning"
    echo "  go install golang.org/x/vuln/cmd/govulncheck@latest"
  fi
fi

# Rust projects
if [[ -f "Cargo.lock" ]]; then
  echo "Scanning Rust dependencies..."
  if command -v cargo-audit &> /dev/null; then
    cargo audit || EXIT_CODE=$?
  else
    echo "NOTE: Install cargo-audit for Rust dependency scanning"
    echo "  cargo install cargo-audit"
  fi
fi

echo ""
echo "================================"
if [[ $EXIT_CODE -eq 0 ]]; then
  echo "✅ No known vulnerabilities found"
else
  echo "⚠️  Vulnerabilities detected — review above output"
fi
exit $EXIT_CODE
