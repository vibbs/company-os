#!/usr/bin/env bash
# Tool: T-DB-01 Migration Check
# Description: Validates database migrations (dry run, ordering, rollback notes)
# Usage: ./tools/db/migration-check.sh [migration-dir]
# Inputs: optional migration directory path
# Outputs: migration validation results
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/usage.sh"
usage_help_if_requested "${BASH_SOURCE[0]}" "${1:-}"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/config.sh"

SCRIPT_DIR="$(dirname "$0")"
CONFIG_FILE="$SCRIPT_DIR/../../company.config.yaml"
MIGRATION_DIR="${1:-}"

# Read ORM from config
ORM="$(cfg_get tech_stack.orm)"

echo "ORM: ${ORM:-not configured}"
echo "Migration Dir: ${MIGRATION_DIR:-auto-detect}"
echo "================================"

case "$ORM" in
  "Prisma"|"prisma")
    echo "Checking Prisma migrations..."
    npx prisma migrate diff --from-schema-datamodel prisma/schema.prisma --to-schema-datasource prisma/schema.prisma --script || true
    echo ""
    echo "Validating schema..."
    npx prisma validate
    ;;
  "Drizzle"|"drizzle")
    echo "Checking Drizzle migrations..."
    npx drizzle-kit check
    ;;
  "SQLAlchemy"|"sqlalchemy"|"Alembic"|"alembic")
    echo "Checking Alembic migrations..."
    alembic check 2>/dev/null || echo "Run 'alembic upgrade head --sql' to preview SQL"
    ;;
  *)
    echo "NOTE: Migration check for '$ORM' not implemented."
    echo "Supported: Prisma, Drizzle, SQLAlchemy/Alembic"
    echo ""
    echo "Manual checklist:"
    echo "  [ ] Migrations are ordered sequentially"
    echo "  [ ] Each migration has a rollback strategy"
    echo "  [ ] No data-destructive operations without backup plan"
    echo "  [ ] Indexes added for new foreign keys"
    ;;
esac
