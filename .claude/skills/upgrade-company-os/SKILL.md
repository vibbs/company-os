---
name: upgrade-company-os
description: Checks for, previews, applies or rolls back Company OS updates. Use when you want the latest version or need to undo an upgrade.
user-invocable: true
argument-hint: "[check | preview | apply | rollback]"
---

# Upgrade Company OS

Checks for updates, previews changes, upgrades, or rolls back Company OS to a previous version.

## Subcommands

### `/upgrade-company-os` or `/upgrade-company-os check`

Check if an update is available:

1. Read `.company-os/version` for the currently installed version
2. If checking against remote, advise the user to run:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh | bash -s -- --check
   ```
3. If `.company-os/version` doesn't exist, inform the user this is a pre-versioning install and recommend running `--force` to stamp the version

What you will see:

```text
  Installed:  1.11.0
  Available:  1.12.0 (minor)
  Update available - 1.11.0 -> 1.12.0
```

Or, when nothing is newer: `Up to date - Company OS 1.11.0`.

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

What you will see:

```text
  Preview  .claude/settings.json (would merge permissions)
  Preview: Would create 2, add 5, merge 1, update 12, skip 40.
  Warning: 1 file(s) modified by you AND changed in template.
  These will be saved to .company-os/conflicts/ on upgrade.
  Run without --dry-run to apply these changes.
```

Nothing on disk changes during a preview.

### `/upgrade-company-os apply`

Perform the upgrade:

1. Show current version from `.company-os/version`
2. For MAJOR upgrades: display migration notes from `.company-os/docs/CHANGELOG.md` and ask for confirmation before proceeding
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
5. Display post-upgrade summary including new version from `.company-os/version`
6. If conflicts were detected (`.company-os/conflicts/` exists and is non-empty), list the conflicted files and advise manual resolution

What you will see:

```text
  Backup   Created at .company-os/backup/20261013-101500-v1.11.0
  ...file-by-file results...
  1 conflict(s) detected - your modified versions saved to .company-os/conflicts/
  Review the conflicts and merge manually.
```

Each conflict keeps the folder path of the original file, so same-named files never collide. For example, a changed `tools/qa/run.sh` is saved as `.company-os/conflicts/tools/qa/run.sh.user` (your version) and `run.sh.new` (the template version). Merge what you want to keep, then delete the conflict files. If you see `Up to date`, there was nothing to apply. The guides in `.company-os/docs/` are template-owned and always refreshed on upgrade; a guide the user edited is kept next to the new copy as `<name>.user` (for example `.company-os/docs/SETUP.md.user`).

### `/upgrade-company-os rollback`

Restore from a previous backup:

1. List available backups:
   ```bash
   ls -d .company-os/backup/*/ 2>/dev/null
   ```
2. If no backups exist, inform the user that backups are created automatically during major upgrades or with the `--backup` flag
3. If backups exist, present them to the user with timestamps and versions
4. After user selects a backup, restore by copying the backup files over current template files. The backup holds exactly these paths, so restore all of them that are present:
   - `os/agents/`, `os/skills/`, `os/playbooks/`, `os/hooks/` (the source of truth)
   - `.claude/agents/`, `.claude/skills/`, `.claude/hooks/`
   - `tools/`
   - `CLAUDE.md`

   Copying over does not remove skills or agents that the newer version added. List the directories in `os/skills/` and `os/agents/` that are not in the backup, show them to the user, and delete them only if the user agrees (they may be the user's own).
5. The other runtime adapters (`AGENTS.md`, `GEMINI.md`, `.cursor/`, `.codex/`) are not in the backup because they are generated from `os/`. Rebuild only the adapters this project already has, so the rollback does not add runtimes the user never installed:
   ```bash
   [ -d .claude ] && bash tools/build/build.sh --runtime=claude
   [ -f AGENTS.md ] && bash tools/build/build.sh --runtime=agents
   [ -f GEMINI.md ] && bash tools/build/build.sh --runtime=gemini
   { [ -d .cursor ] || [ -f .cursorrules ]; } && bash tools/build/build.sh --runtime=cursor
   [ -d .codex ] && bash tools/build/build.sh --runtime=codex
   ```
   Do not run `build.sh` with no arguments: it builds every adapter.
6. Update `.company-os/version` to the backup's version (parse from the backup directory name)
7. Rebuild the manifest so the next upgrade compares against the restored version. Re-install that same version, passing only the runtimes the project already has (for example `claude,cursor`):
   ```bash
   bash install.sh --force --version <backup-version> --runtime <installed runtimes>
   ```
   (Without a local `install.sh`, the user runs the `curl ... | bash -s -- --force --version <backup-version> --runtime <...>` form in their terminal.) This re-applies the same files, so content does not change; any `.user`/`.new` pairs it reports for restored files are identical and can be deleted. Never run `install.sh --force` without `--version` here: it downloads and applies the latest release, which undoes the rollback.

What you will see:

```text
Available backups:
  .company-os/backup/20261013-101500-v1.11.0/   (version 1.11.0)
Which one should I restore?
```

After you choose, the skill restores the template files and reports the restored version. With no backups it says so and explains how backups are created. Your own files (`artifacts/`, `tasks/`, `company.config.yaml`) are never touched by a rollback.

## Version File Locations

| File | Purpose |
|------|---------|
| `.company-os/version` | Template version — single source of truth |
| `.company-os/manifest` | SHA256 hashes of installed template files |
| `.company-os/backup/` | Timestamped backups (auto for major upgrades) |
| `.company-os/conflicts/` | Conflicting file versions during upgrade |
| `.company-os/docs/CHANGELOG.md` | Human-readable changelog (Keep a Changelog format) |

## Reference

- **ID**: S-ORG-10
- **Category**: Orchestration
- **Inputs**: `.company-os/version`, `.company-os/manifest`, remote release metadata
- **Outputs**: upgraded system files, backup in `.company-os/backup/`
- **Used by**: User (directly), Orchestrator Agent

## Notes

- The `curl` command is denied in `.claude/settings.json`. For remote operations (check against latest, download updates), advise the user to run the command in their terminal directly.
- For local operations (reading version files, listing backups, running local `install.sh`), use Bash tool directly.
- Always show the user what will change before applying upgrades.
- For major version upgrades, always recommend `--dry-run` first.
