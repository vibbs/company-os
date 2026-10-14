#!/usr/bin/env bash
# cfg_get (tools/lib/config.sh): the shipped config and edge-case fixtures.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/assert.sh"
source "$REPO_ROOT/tools/lib/config.sh"

# --- Shipped company.config.yaml (via the default path) ---
unset CONFIG_FILE
assert_eq "opus" "$(cfg_get models.orchestrator)" "shipped: models.orchestrator"
assert_eq "sonnet" "$(cfg_get models.engineering_backend)" "shipped: models.engineering_backend"
assert_eq "auto" "$(cfg_get design.dark_mode)" "shipped: quoted value with comment"
assert_eq "false" "$(cfg_get conventions.monorepo)" "shipped: bare value with comment"
assert_eq "" "$(cfg_get company.stage)" "shipped: empty quoted value"
assert_eq "" "$(cfg_get company.no_such_key)" "shipped: missing key"
assert_eq "" "$(cfg_get stage)" "shipped: one-part key matches top level only"

# --- Fixture with comments, quotes, nesting and look-alike keys ---
T="$(make_tmp)"
cat > "$T/config.yaml" <<'EOF'
# Top comment: company:
company:
  name: "Acme # Inc"          # hash inside quotes stays
  product: 'Rocket'           # single quotes
  stage: growth               # bare value, trailing comment
  # stage: idea               <- commented out, must be ignored
  domain:                     # empty value with comment
tech_stack:
  database:
    orm: Prisma
    engine: "PostgreSQL 16"
  orm: Drizzle
  cache:   Redis
ai:
  llm_provider: anthropic
    # deeper comment line
other:
  name: Wrong
EOF
F="$T/config.yaml"
assert_eq "Acme # Inc" "$(cfg_get company.name "$F")" "fixture: hash inside double quotes"
assert_eq "Rocket" "$(cfg_get company.product "$F")" "fixture: single quotes"
assert_eq "growth" "$(cfg_get company.stage "$F")" "fixture: commented duplicate ignored"
assert_eq "" "$(cfg_get company.domain "$F")" "fixture: empty value with comment"
assert_eq "Prisma" "$(cfg_get tech_stack.database.orm "$F")" "fixture: three-level key"
assert_eq "PostgreSQL 16" "$(cfg_get tech_stack.database.engine "$F")" "fixture: quoted value with space"
assert_eq "Drizzle" "$(cfg_get tech_stack.orm "$F")" "fixture: sibling with same name as nested key"
assert_eq "Redis" "$(cfg_get tech_stack.cache "$F")" "fixture: extra spaces trimmed"
assert_eq "anthropic" "$(cfg_get ai.llm_provider "$F")" "fixture: value before indented comment"
assert_eq "Wrong" "$(cfg_get other.name "$F")" "fixture: same key under another parent"
assert_eq "" "$(cfg_get company.missing "$F")" "fixture: missing key"
assert_eq "" "$(cfg_get nope.name "$F")" "fixture: missing parent"
assert_eq "" "$(cfg_get company.name "$T/does-not-exist.yaml")" "missing file prints empty"
assert_eq "" "$(cfg_get "" "$F")" "empty key prints empty"

# --- CONFIG_FILE environment override ---
assert_eq "growth" "$(CONFIG_FILE="$F" cfg_get company.stage)" "CONFIG_FILE override"

# --- CRLF line endings ---
sed 's/$/\r/' "$F" > "$T/crlf.yaml"
assert_eq "growth" "$(cfg_get company.stage "$T/crlf.yaml")" "CRLF: bare value"
assert_eq "Acme # Inc" "$(cfg_get company.name "$T/crlf.yaml")" "CRLF: quoted value"
assert_eq "Prisma" "$(cfg_get tech_stack.database.orm "$T/crlf.yaml")" "CRLF: nested key"

# --- Never aborts a set -euo pipefail caller ---
assert_exit 0 bash -c "set -euo pipefail; source '$REPO_ROOT/tools/lib/config.sh'; v=\$(cfg_get nope.nope '$F'); echo \"[\$v]\""
assert_eq "[]" "$OUT" "strict caller survives a missing key"

finish
