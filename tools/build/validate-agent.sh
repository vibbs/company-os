#!/usr/bin/env bash
# ============================================================================
# validate-agent.sh — Validate a single agent file against the neutral schema
# ============================================================================
# Usage:
#   bash tools/build/validate-agent.sh [--strict] path/to/agent.md
#   bash tools/build/validate-agent.sh [--strict] --all
# Options:
#   --strict   treat warnings as failures (exit 1 when any file has a warning)
#
# Output uses ASCII markers ([ok], [warn], [fail]) when stdout is not a terminal
# or NO_COLOR is set.
#
# Exit codes:
#   0 - valid (and, with --strict, no warnings)
#   1 - invalid, or warnings under --strict
#   2 - file not found
# ============================================================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/usage.sh"
usage_help_if_requested "${BASH_SOURCE[0]}" "${1:-}"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

source tools/build/lib-frontmatter.sh
source tools/build/lib-markers.sh
source tools/build/lib-agent-index.sh

# Fields the schema defines. Any other top-level key is allowed but warned
# (usually a typo), so --strict fails on it.
KNOWN_FIELDS="name description tools model skills memory runtimes"

LAST_WARNINGS=0

validate_one() {
  local file="$1"
  local errors=0
  local warnings=0

  if [ ! -f "$file" ]; then
    echo "$MARK_FAIL $file: not found" >&2
    return 2
  fi

  local fm
  fm="$(fm_extract "$file")"
  if [ -z "$fm" ]; then
    echo "$MARK_FAIL $file: no YAML frontmatter found" >&2
    return 1
  fi

  # name
  local name
  name="$(fm_field "$file" "name")"
  if [ -z "$name" ]; then
    echo "$MARK_FAIL $file: missing required field 'name'" >&2
    errors=$((errors + 1))
  else
    if ! echo "$name" | grep -qE '^[a-z][a-z0-9-]*$'; then
      echo "$MARK_FAIL $file: 'name' must be kebab-case, got: $name" >&2
      errors=$((errors + 1))
    fi
    # name must match file
    local file_name
    file_name="$(basename "$file" .md)"
    if [ "$file_name" != "$name" ]; then
      echo "$MARK_FAIL $file: 'name' ($name) does not match filename ($file_name)" >&2
      errors=$((errors + 1))
    fi
  fi

  # description
  local desc
  desc="$(fm_field "$file" "description")"
  if [ -z "$desc" ]; then
    echo "$MARK_FAIL $file: missing required field 'description'" >&2
    errors=$((errors + 1))
  elif [ "${#desc}" -lt 10 ]; then
    echo "$MARK_FAIL $file: 'description' too short" >&2
    errors=$((errors + 1))
  fi

  # model (optional, but validate the enum if present)
  local model
  model="$(fm_field "$file" "model" || true)"
  if [ -n "$model" ]; then
    case "$model" in
      opus|sonnet|haiku) ;;
      *)
        echo "$MARK_WARN $file: 'model' should be opus|sonnet|haiku, got: $model" >&2
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
        echo "$MARK_WARN $file: 'memory' should be user|project|local, got: $memory" >&2
        warnings=$((warnings + 1))
        ;;
    esac
  fi

  # Unknown top-level fields
  local key
  while IFS= read -r key; do
    case " $KNOWN_FIELDS " in
      *" $key "*) ;;
      *)
        echo "$MARK_WARN $file: unknown top-level field '$key' (a typo? see .company-os/docs/SKILL_SCHEMA.md)" >&2
        warnings=$((warnings + 1))
        ;;
    esac
  done < <(fm_top_keys "$file")

  # Body must exist
  local body
  body="$(fm_body "$file")"
  if [ -z "$body" ]; then
    echo "$MARK_WARN $file: empty body — agent has no persona description" >&2
    warnings=$((warnings + 1))
  fi

  LAST_WARNINGS="$warnings"
  if [ "$errors" -gt 0 ]; then
    return 1
  fi
  if [ "$warnings" -gt 0 ]; then
    echo "$MARK_WARN $file: valid with $warnings warning(s)"
    return 0
  fi
  echo "$MARK_OK $file"
  return 0
}

STRICT=false
TARGET=""
for arg in "$@"; do
  case "$arg" in
    --strict) STRICT=true ;;
    -h|--help) usage_print_header "${BASH_SOURCE[0]}"; exit 0 ;;
    *) TARGET="${TARGET:-$arg}" ;;
  esac
done

if [ "$TARGET" = "--all" ]; then
  src="$(agent_source_dir)"
  total=0
  fail=0
  warn=0
  while IFS= read -r agent; do
    [ -z "$agent" ] && continue
    total=$((total + 1))
    file="$(agent_file "$agent")"
    LAST_WARNINGS=0
    if ! validate_one "$file" >/tmp/validate-agent-out.$$ 2>&1; then
      fail=$((fail + 1))
    fi
    if [ "$LAST_WARNINGS" -gt 0 ]; then
      warn=$((warn + 1))
    fi
    cat /tmp/validate-agent-out.$$
  done < <(agent_list)
  rm -f /tmp/validate-agent-out.$$
  echo ""
  echo "Agents: $total | Failed: $fail | With warnings: $warn"
  [ "$fail" -eq 0 ] || exit 1
  if [ "$STRICT" = true ] && [ "$warn" -gt 0 ]; then exit 1; fi
elif [ -n "$TARGET" ]; then
  rc=0
  validate_one "$TARGET" || rc=$?
  if [ "$rc" -eq 0 ] && [ "$STRICT" = true ] && [ "$LAST_WARNINGS" -gt 0 ]; then rc=1; fi
  exit "$rc"
else
  echo "Usage: bash tools/build/validate-agent.sh [--strict] <file> | --all"
  exit 1
fi
