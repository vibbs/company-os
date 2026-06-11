#!/usr/bin/env bash
# ============================================================================
# validate-agent.sh — Validate a single agent file against the neutral schema
# ============================================================================
# Usage:
#   bash tools/build/validate-agent.sh path/to/agent.md
#   bash tools/build/validate-agent.sh --all
# ============================================================================

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

source tools/build/lib-frontmatter.sh
source tools/build/lib-agent-index.sh

validate_one() {
  local file="$1"
  local errors=0
  local warnings=0

  if [ ! -f "$file" ]; then
    echo "✗ $file: not found" >&2
    return 2
  fi

  local fm
  fm="$(fm_extract "$file")"
  if [ -z "$fm" ]; then
    echo "✗ $file: no YAML frontmatter found" >&2
    return 1
  fi

  # name
  local name
  name="$(fm_field "$file" "name")"
  if [ -z "$name" ]; then
    echo "✗ $file: missing required field 'name'" >&2
    errors=$((errors + 1))
  else
    if ! echo "$name" | grep -qE '^[a-z][a-z0-9-]*$'; then
      echo "✗ $file: 'name' must be kebab-case, got: $name" >&2
      errors=$((errors + 1))
    fi
    # name must match file
    local file_name
    file_name="$(basename "$file" .md)"
    if [ "$file_name" != "$name" ]; then
      echo "✗ $file: 'name' ($name) does not match filename ($file_name)" >&2
      errors=$((errors + 1))
    fi
  fi

  # description
  local desc
  desc="$(fm_field "$file" "description")"
  if [ -z "$desc" ]; then
    echo "✗ $file: missing required field 'description'" >&2
    errors=$((errors + 1))
  elif [ "${#desc}" -lt 10 ]; then
    echo "✗ $file: 'description' too short" >&2
    errors=$((errors + 1))
  fi

  # model (optional, but validate the enum if present)
  local model
  model="$(fm_field "$file" "model" || true)"
  if [ -n "$model" ]; then
    case "$model" in
      opus|sonnet|haiku) ;;
      *)
        echo "⚠ $file: 'model' should be opus|sonnet|haiku, got: $model" >&2
        warnings=$((warnings + 1))
        ;;
    esac
  fi

  # memory (optional)
  local memory
  memory="$(fm_field "$file" "memory" || true)"
  if [ -n "$memory" ]; then
    case "$memory" in
      user|project|local) ;;
      *)
        echo "⚠ $file: 'memory' should be user|project|local, got: $memory" >&2
        warnings=$((warnings + 1))
        ;;
    esac
  fi

  # Body must exist
  local body
  body="$(fm_body "$file")"
  if [ -z "$body" ]; then
    echo "⚠ $file: empty body — agent has no persona description" >&2
    warnings=$((warnings + 1))
  fi

  if [ "$errors" -gt 0 ]; then
    return 1
  fi
  if [ "$warnings" -gt 0 ]; then
    echo "⚠ $file: valid with $warnings warning(s)"
    return 0
  fi
  echo "✓ $file"
  return 0
}

if [ "${1:-}" = "--all" ]; then
  src="$(agent_source_dir)"
  total=0
  fail=0
  warn=0
  while IFS= read -r agent; do
    [ -z "$agent" ] && continue
    total=$((total + 1))
    file="$(agent_file "$agent")"
    if ! validate_one "$file" >/tmp/validate-agent-out.$$ 2>&1; then
      fail=$((fail + 1))
    fi
    if grep -q "^⚠" /tmp/validate-agent-out.$$ 2>/dev/null; then
      warn=$((warn + 1))
    fi
    cat /tmp/validate-agent-out.$$
  done < <(agent_list)
  rm -f /tmp/validate-agent-out.$$
  echo ""
  echo "Agents: $total | Failed: $fail | With warnings: $warn"
  [ "$fail" -eq 0 ]
elif [ -n "${1:-}" ]; then
  validate_one "$1"
else
  echo "Usage: bash tools/build/validate-agent.sh <file> | --all"
  exit 1
fi
