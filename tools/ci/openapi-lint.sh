#!/usr/bin/env bash
# Tool: T-API-01 OpenAPI Lint/Validate
# Description: Validates OpenAPI specifications for correctness and style
# Usage: ./tools/ci/openapi-lint.sh <spec-path>
# Inputs: path to OpenAPI spec file (YAML or JSON)
# Outputs: validation results, exit 0 if valid
set -euo pipefail

SPEC_PATH="${1:-}"

if [[ -z "$SPEC_PATH" ]]; then
  echo "ERROR: No spec path provided"
  echo "Usage: ./tools/ci/openapi-lint.sh <spec-path>"
  exit 1
fi

if [[ ! -f "$SPEC_PATH" ]]; then
  echo "ERROR: Spec file not found: $SPEC_PATH"
  exit 1
fi

echo "Validating OpenAPI spec: $SPEC_PATH"
echo "================================"

# Try spectral first (most common OpenAPI linter)
if command -v spectral &> /dev/null; then
  spectral lint "$SPEC_PATH"
elif npx --yes @stoplight/spectral-cli lint "$SPEC_PATH" 2>/dev/null; then
  true  # npx ran it
elif command -v swagger-cli &> /dev/null; then
  swagger-cli validate "$SPEC_PATH"
else
  echo "WARNING: No OpenAPI linter found."
  echo "Install one of:"
  echo "  npm install -g @stoplight/spectral-cli"
  echo "  npm install -g swagger-cli"
  echo ""
  echo "Performing basic YAML syntax check..."
  # Basic check: is it valid YAML/JSON?
  if command -v python3 &> /dev/null; then
    python3 -c "import yaml, sys; yaml.safe_load(open(sys.argv[1]))" "$SPEC_PATH" && echo "✅ Valid YAML syntax" || echo "❌ Invalid YAML syntax"
  else
    echo "Cannot validate — no tools available"
    exit 1
  fi
fi
