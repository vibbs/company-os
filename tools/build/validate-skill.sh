#!/usr/bin/env bash
# ============================================================================
# validate-skill.sh — Validate a single skill file against the neutral schema
# ============================================================================
# Usage:
#   bash tools/build/validate-skill.sh path/to/SKILL.md
#   bash tools/build/validate-skill.sh --all          # validate every skill in source dir
#
# Exit codes:
#   0 — valid
#   1 — invalid (errors printed to stderr)
#   2 — file not found
# ============================================================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/usage.sh"
usage_help_if_requested "${BASH_SOURCE[0]}" "${1:-}"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

source tools/build/lib-frontmatter.sh
source tools/build/lib-skill-index.sh

# Reserved fields per the JSON schema. Any other top-level key is allowed but warned.
KNOWN_FIELDS="name description id category argument-hint inputs outputs tools_used tags runtimes user-invocable user-invokable disable-model-invocation compatibility license metadata"

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

  # --- Required: name ---
  local name
  name="$(fm_field "$file" "name")"
  if [ -z "$name" ]; then
    echo "✗ $file: missing required field 'name'" >&2
    errors=$((errors + 1))
  else
    if ! echo "$name" | grep -qE '^[a-z][a-z0-9-]*$'; then
      echo "✗ $file: 'name' must be kebab-case ([a-z][a-z0-9-]*), got: $name" >&2
      errors=$((errors + 1))
    fi
    # name must match directory
    local dir_name
    dir_name="$(basename "$(dirname "$file")")"
    if [ "$dir_name" != "$name" ]; then
      echo "✗ $file: 'name' ($name) does not match directory name ($dir_name)" >&2
      errors=$((errors + 1))
    fi
  fi

  # --- Required: description ---
  local desc
  desc="$(fm_field "$file" "description")"
  if [ -z "$desc" ]; then
    echo "✗ $file: missing required field 'description'" >&2
    errors=$((errors + 1))
  elif [ "${#desc}" -lt 10 ]; then
    echo "✗ $file: 'description' must be at least 10 chars, got: $desc" >&2
    errors=$((errors + 1))
  fi

  # --- Body must exist ---
  local body
  body="$(fm_body "$file")"
  if [ -z "$body" ]; then
    echo "⚠ $file: empty body — skill has no procedure" >&2
    warnings=$((warnings + 1))
  fi

  # --- Deprecation warnings ---
  for legacy in user-invocable user-invokable disable-model-invocation compatibility license; do
    local val target
    val="$(fm_field "$file" "$legacy" || true)"
    if [ -n "$val" ]; then
      target="$legacy"
      [ "$legacy" = "user-invokable" ] && target="user-invocable"
      echo "⚠ $file: top-level '$legacy' is deprecated — move under runtimes.claude.$target" >&2
      warnings=$((warnings + 1))
    fi
  done
  # Legacy spelling under runtimes.claude: still lifted (as user-invocable), but warn.
  if printf '%s\n' "$fm" | grep -qE '^[[:space:]]+user-invokable:'; then
    echo "⚠ $file: 'user-invokable' is a deprecated spelling — Claude Code reads 'user-invocable'" >&2
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

# --- Entry point ---
if [ "${1:-}" = "--all" ]; then
  src="$(skill_source_dir)"
  total=0
  fail=0
  warn=0
  while IFS= read -r skill; do
    [ -z "$skill" ] && continue
    total=$((total + 1))
    file="$(skill_file "$skill")"
    if ! validate_one "$file" >/tmp/validate-skill-out.$$ 2>&1; then
      fail=$((fail + 1))
    fi
    # Count warnings only on successful validations
    if grep -q "^⚠" /tmp/validate-skill-out.$$ 2>/dev/null; then
      warn=$((warn + 1))
    fi
    cat /tmp/validate-skill-out.$$
  done < <(skill_list)
  rm -f /tmp/validate-skill-out.$$
  echo ""
  echo "Skills: $total | Failed: $fail | With warnings: $warn"
  [ "$fail" -eq 0 ]
elif [ -n "${1:-}" ]; then
  validate_one "$1"
else
  echo "Usage: bash tools/build/validate-skill.sh <file> | --all"
  exit 1
fi
