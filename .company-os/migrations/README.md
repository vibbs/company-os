# Migrations

Migration scripts run automatically during Company OS upgrades when the user's installed version is older than the migration's target version.

## Naming Convention

```
v<MAJOR>.<MINOR>.<PATCH>.sh
```

Examples: `v1.4.0.sh`, `v2.0.0.sh`

## Script Requirements

1. **Idempotent** — Safe to run multiple times. Check for preconditions before making changes.
2. **Non-destructive** — Back up anything you modify. Never delete user files.
3. **Clear output** — Print what you're doing so the user can follow along.
4. **Exit codes** — Exit `0` on success, non-zero on failure. A failed migration halts the upgrade.

## Template

```bash
#!/usr/bin/env bash
# Migration: v1.x → v2.0.0
# Breaking change: [describe what changed and why]
set -euo pipefail

echo "Migration v2.0.0: [brief description]"
echo ""

# Check if already migrated
if [condition]; then
  echo "  Already migrated. Skipping."
  exit 0
fi

# Perform migration
echo "  Migrating..."
# [migration steps]

echo "  Done."
```

## How Migrations Run

The installer (`install.sh`) runs migrations automatically:

1. Reads the user's installed version from `.company-os/version`
2. Scans `.company-os/migrations/v*.sh` for versions newer than the installed version
3. Runs each applicable migration in version order
4. If any migration fails, the upgrade halts (files already updated are safe; the user can fix and re-run)

Migrations run **after** template files are updated but **before** the version stamp is written. This means if a migration fails, `.company-os/version` still shows the old version and the migration will re-run on the next upgrade attempt.
