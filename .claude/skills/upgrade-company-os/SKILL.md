---
name: upgrade-company-os
description: Check for Company OS updates, preview changes, and upgrade to the latest version. Shows changelog, migration notes, and handles breaking changes safely.
user-invokable: true
argument-hint: "[check | preview | apply | rollback]"
---

# Upgrade Company OS

Checks for updates, previews changes, upgrades, or rolls back Company OS to a previous version.

## Subcommands

### `/upgrade-company-os` or `/upgrade-company-os check`

Check if an update is available:

1. Read `.company-os-version` for the currently installed version
2. Read `VERSION` for the version in the current template (if running from the repo itself)
3. If checking against remote, advise the user to run:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh | bash -s -- --check
   ```
4. If `.company-os-version` doesn't exist, inform the user this is a pre-versioning install and recommend running `--force` to stamp the version

### `/upgrade-company-os preview`

Preview what would change without applying:

1. Run the install script in dry-run mode:
   ```bash
   bash install.sh --dry-run --force
   ```
2. If `install.sh` is not available locally (user installed via curl), advise:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh | bash -s -- --dry-run --force
   ```
3. Parse and display the output — highlight new files, updated files, conflicts, and migration notes

### `/upgrade-company-os apply`

Perform the upgrade:

1. Show current version from `.company-os-version`
2. For MAJOR upgrades: display migration notes from `CHANGELOG.md` and ask for confirmation before proceeding
3. Run the upgrade:
   ```bash
   bash install.sh --force
   ```
   Or if not available locally:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh | bash -s -- --force
   ```
4. After upgrade, verify with:
   ```bash
   ./tools/registry/health-check.sh
   ```
5. Display post-upgrade summary including new version from `.company-os-version`
6. If conflicts were detected (`.company-os-conflicts/` exists and is non-empty), list the conflicted files and advise manual resolution

### `/upgrade-company-os rollback`

Restore from a previous backup:

1. List available backups:
   ```bash
   ls -d .company-os-backup/*/ 2>/dev/null
   ```
2. If no backups exist, inform the user that backups are created automatically during major upgrades or with the `--backup` flag
3. If backups exist, present them to the user with timestamps and versions
4. After user selects a backup, restore by copying the backup files over current template files:
   - `.claude/agents/` — restore from backup
   - `.claude/skills/` — restore from backup
   - `.claude/hooks/` — restore from backup
   - `tools/` — restore from backup
   - `CLAUDE.md` — restore if present in backup
5. Update `.company-os-version` to the backup's version (parse from the backup directory name)
6. Regenerate the manifest by running install with `--force` flag or manually stamping

## Version File Locations

| File | Purpose |
|------|---------|
| `VERSION` | Template source of truth (in the repo) |
| `.company-os-version` | Installed version stamp (in user's project) |
| `.company-os-manifest` | SHA256 hashes of installed template files |
| `.company-os-backup/` | Timestamped backups (auto for major upgrades) |
| `.company-os-conflicts/` | Conflicting file versions during upgrade |
| `CHANGELOG.md` | Human-readable changelog (Keep a Changelog format) |

## Notes

- The `curl` command is denied in `.claude/settings.json`. For remote operations (check against latest, download updates), advise the user to run the command in their terminal directly.
- For local operations (reading version files, listing backups, running local `install.sh`), use Bash tool directly.
- Always show the user what will change before applying upgrades.
- For major version upgrades, always recommend `--dry-run` first.
