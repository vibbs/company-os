---
name: upgrade-company-os
description: Checks for, previews, applies or rolls back Company OS updates. Use when you want the latest version or need to undo an upgrade.
runtimes:
  claude:
    user-invocable: true
    argument-hint: "[check | preview | apply | rollback]"
---

# Upgrade Company OS

Checks for updates, previews changes, upgrades, or rolls back Company OS to a previous version.

## When to Use

- You want to know whether a newer Company OS release exists.
- You want to see what an upgrade would change before it touches any file.
- You want to apply an upgrade, or undo one that went wrong.

## Subcommands

### `/upgrade-company-os` or `/upgrade-company-os check`

Check if an update is available:

1. Read `.company-os/version` for the currently installed version
2. If checking against remote, advise the user to run:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh | bash -s -- --check
   ```
   To read the script first, download it to a temporary folder, review it, then run it:
   ```bash
   tmp=$(mktemp -d) && curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh -o "$tmp/install.sh"
   less "$tmp/install.sh"
   bash "$tmp/install.sh" --check
   ```
   Inside an AI tool `less` is not interactive. Show the user only the header and version lines (`head -n 20 "$tmp/install.sh"`) and the path, and ask them to review the whole file in their own terminal.
3. If `.company-os/version` doesn't exist, inform the user this is a pre-versioning install (1.11 or earlier). The installer backs up first. A run without `--force` only previews. With no manifest, the installer compares each file with every version Company OS has shipped (`.company-os/known-hashes.txt` in the release): a file that matches one is an unedited copy and is updated. `--force` saves each file that matches no shipped version (the user's edits) as `.company-os/conflicts/<path>.user`, then replaces it

What you will see:

```text
  Installed:  1.11.0
  Available:  1.12.0 (minor)
  Update available - 1.11.0 -> 1.12.0
```

Or, when nothing is newer: `Up to date - Company OS 1.11.0`.

### `/upgrade-company-os preview`

Preview what would change without applying:

1. Get the installer. Never run an `install.sh` that sits in the project root: it may be the user's own script or a stale download. Download the current one to a temporary folder (`curl` is denied for the agent, so the user runs this in their terminal):
   ```bash
   tmp=$(mktemp -d) && curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh -o "$tmp/install.sh"
   ```
2. Check that the file is the Company OS installer before running it: `head -n 5 "$tmp/install.sh"` must contain `Company OS`. If it does not, stop and tell the user. Then run it in dry-run mode:
   ```bash
   bash "$tmp/install.sh" --dry-run --force
   ```
   (Downloading to a file first lets the user read the script before it runs. Piping the script straight into `bash` works too, but nothing is reviewed.)
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
   bash "$tmp/install.sh" --force
   ```
   Use the same verified download as in preview. If the shell has no `$tmp`, download again to a new temporary folder and run the same header check. The user can also run these steps in their own terminal after reading the file with `less "$tmp/install.sh"`.
   To upgrade to a specific release instead of the latest, pin it with `--version`, for example `bash "$tmp/install.sh" --force --version 1.12.0`. Pinning also works for a downgrade or when a team wants everyone on the same version.
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

Each conflict keeps the folder path of the original file, so same-named files never collide. A file the user edited that the template did not change is left alone and is not a conflict. A plain upgrade (no `--force`) keeps the user's version of a conflicting file and lists it; `--force` saves both and installs the template copy. A saved copy is never overwritten: a later one gets a timestamp suffix. Upgrades keep the adapters the project already has. For example, a changed `tools/qa/run.sh` is saved as `.company-os/conflicts/tools/qa/run.sh.user` (your version) and `run.sh.new` (the template version). Merge what you want to keep, then delete the conflict files. If you see `Up to date`, there was nothing to apply. The guides in `.company-os/docs/` are template-owned and always refreshed on upgrade; a guide the user edited is kept next to the new copy as `<name>.user` (for example `.company-os/docs/SETUP.md.user`).

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
   bash "$tmp/install.sh" --force --version <backup-version> --runtime <installed runtimes>
   ```
   (Use the verified download from the apply step. Or the user runs the `curl ... | bash -s -- --force --version <backup-version> --runtime <...>` form in their terminal.) This re-applies the same files, so content does not change; any `.user`/`.new` pairs it reports for restored files are identical and can be deleted. Never run the installer with `--force` and no `--version` here: it downloads and applies the latest release, which undoes the rollback.

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
- For local operations (reading version files, listing backups), use Bash tool directly. Never run an `install.sh` found in the project root; use the verified download in a temporary folder.
- Always show the user what will change before applying upgrades.
- For major version upgrades, always recommend `--dry-run` first.
