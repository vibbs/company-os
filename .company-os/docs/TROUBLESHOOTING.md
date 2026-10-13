# Troubleshooting

Find your symptom, apply the fix. If nothing here helps, run the [health check](#run-the-health-check) and open an issue at [github.com/vibbs/company-os/issues](https://github.com/vibbs/company-os/issues) with its output.

| Symptom | Jump to |
|---------|---------|
| Installer says "No git repo detected" | [Git is not initialized](#git-is-not-initialized) |
| "python3 not found, skipping merge" or hooks never fire | [python3 or jq is missing](#python3-or-jq-is-missing) |
| You do not want to pipe a script into bash | [Reviewing the installer first](#reviewing-the-installer-first) |
| Files for the wrong editor were installed, or none were | [Wrong runtime detected](#wrong-runtime-detected) |
| `/setup` or `/ship` is not recognized | [Slash commands missing](#slash-commands-missing) |
| A promotion is blocked with "Artifact validation failed before promotion" | [A hook blocks a promotion](#a-hook-blocks-a-promotion) |
| `validate.sh` prints `❌ INVALID` | [Validation errors](#validation-errors) |
| `check-gate.sh` prints `GATE FAILED` | [A gate fails](#a-gate-fails) |
| Claude Code keeps asking permission to run commands | [Too many permission prompts](#too-many-permission-prompts) |

---

## Git is not initialized

Company OS uses git history as its audit trail, so run the installer inside a git repo.

```bash
git init
git add -A && git commit -m "Initial commit"
```

You can install first and run `git init` afterwards; nothing is lost. Commit the installed files before running `/setup`, so you can review exactly what the wizard changes.

## python3 or jq is missing

| Missing | Effect | Fix |
|---------|--------|-----|
| `python3` | If you already had a `.claude/settings.json`, the installer cannot merge Company OS permissions and hooks into it. It keeps your file and prints a warning. | Install Python 3 and re-run the installer, or copy the `permissions` and `hooks` blocks from the [template settings](https://github.com/vibbs/company-os/blob/main/.claude/settings.json) by hand |
| `jq` | The two artifact hooks (validate before promote, header check after write) exit silently, so nothing is checked automatically | Install `jq` (`brew install jq` or `apt install jq`). The session-start hook does not need it. |

## Reviewing the installer first

Piping a script from the internet into `bash` runs it without showing you what it does. To read it first:

```bash
curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh -o install.sh
less install.sh                 # read it
bash install.sh --dry-run       # preview every change without writing anything
bash install.sh                 # install
```

To pin a release instead of the latest, add `--version 1.11.0`.

## Wrong runtime detected

By default the installer installs files for every runtime it finds on your machine: a `claude`, `cursor`, `codex`, `gemini` or `aider` command, or a `~/.claude`, `~/.cursor`, `~/.codex` or `~/.gemini` folder. A leftover folder from a tool you no longer use counts too.

- See what was detected and what is installed: `./tools/registry/list-runtimes.sh`
- Add a missing runtime: `./tools/registry/install-runtime.sh cursor` (or `claude`, `codex`, `gemini`, `all`)
- Install exactly what you want: re-run the installer with `--runtime`, for example `bash install.sh --runtime claude,cursor`
- Remove an unwanted runtime: delete its files (see the [uninstall list](FAQ.md#how-do-i-uninstall-company-os)).

If no runtime is found, you get the core install only: `os/`, `tools/`, `AGENTS.md` and `CLAUDE.md`.

## Slash commands missing

Slash commands exist only in Claude Code. In Cursor, Codex, Gemini or Aider, ask the agent to "run the setup skill".

In Claude Code:

1. Check `.claude/skills/setup/SKILL.md` exists. If it does not, the Claude Code files were not installed: run `./tools/registry/install-runtime.sh claude`.
2. Start a new `claude` session in the project root; skills load at session start.
3. If you edited a skill in `os/`, run `bash tools/build/build.sh` so `.claude/skills/` picks up the change.

## A hook blocks a promotion

In Claude Code, the `pre-promote-validate.sh` hook runs `validate.sh` before every `promote.sh`. If validation fails, it denies the command and shows the validation output. This is intended: an invalid artifact cannot change status.

Fix the errors it lists (see the next section), then promote again. Do not disable the hook to get past it.

## Validation errors

Run `./tools/artifact/validate.sh <file>` for one artifact, or `./tools/artifact/validate.sh --all` for everything under `artifacts/`.

| Error | Fix |
|-------|-----|
| `Empty or malformed YAML frontmatter` | The file must start with a `---` line, the YAML fields, then another `---` line |
| `Missing required field: <field>` | Add it. Required: `id`, `type`, `title`, `status`, `created`, `author` |
| `Invalid status` | Use `draft`, `review`, `approved` or `archived` |
| `Invalid type` | Use one of the types listed in the message (and in [CONCEPTS.md](CONCEPTS.md#artifacts-and-lineage)) |
| `parent '<ID>' does not resolve` (or `children`, `depends_on`, `blocks`) | The ID is misspelled or that artifact does not exist yet. Fix the ID, create the artifact, or remove the link. |
| `Bidirectional: ...` warning (with `--strict`) | The two files disagree about a link. Run `./tools/artifact/link.sh <parent> <child>` to fix both sides. |

`File not found` means the path is wrong; paths are relative to the project root.

## A gate fails

`./tools/artifact/check-gate.sh <gate> <file>` lists each missing condition. Exit codes:

| Exit code | Meaning | What to do |
|-----------|---------|------------|
| 0 | Passed, or failed in advisory mode (`GATE ADVISORY ... not blocking`) | Nothing required; read the warnings |
| 1 | `GATE FAILED`: at least one condition is not met | Fix the listed items. Usually an artifact still needs approval (`promote.sh <file> approved`) or is missing (for example a test plan before `impl-to-qa`). |
| 2 | The artifact path or ID does not exist | Check the path, or pass the artifact ID instead |

Gates that block you at your stage:

- `idea`: none; every gate only warns.
- `mvp`: `prd-to-rfc` and `rfc-to-impl` block.
- `growth`, `scale`, or an empty `company.stage`: every gate blocks.

If gates block more than you expected, check `company.stage` in `company.config.yaml`. An empty stage means full enforcement. Change the stage only if it really describes your company; see [stages and gates](CONCEPTS.md#stages-and-gates).

## Too many permission prompts

Claude Code asks before running any command not on the allow list in `.claude/settings.json`.

- Run `/setup` (or re-run it). It writes allow rules for your tech stack, such as `npm`, `pip` or `go`.
- To allow a command yourself, add it to `permissions.allow`, for example `"Bash(make *)"`.
- Some commands are deliberately on the deny list, including `rm -rf`, `sudo`, `git push --force`, `git reset --hard`, `curl` and `wget`. Agents cannot run these. Run them yourself if you really need to.

## Run the health check

```bash
./tools/registry/health-check.sh
```

It checks every skill and agent for valid structure and required fields, and ends with `Health check PASSED` or a list of problems. Also useful:

| Command | Checks |
|---------|--------|
| `bash tools/build/build.sh --check` | Skills and agents in `os/` match the schema |
| `./tools/artifact/validate.sh --all` | Every artifact's header and links |
| `./tools/registry/list-runtimes.sh` | Which runtimes are detected and which adapters are installed |
| `/upgrade-company-os check` | Whether a newer Company OS version is available |
| `<tool> --help` | Usage for any tool script |
