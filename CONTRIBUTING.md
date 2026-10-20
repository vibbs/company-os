# Contributing to Company OS

Thanks for helping. This guide is for people who change Company OS itself: its skills, agents, tools, docs or installer. If you only want to use it in your own product, start with the [README](README.md) and [Customizing](.company-os/docs/CUSTOMIZING.md).

## Repo layout

| Path | What it holds |
|------|---------------|
| `os/` | Source of truth: `skills/`, `agents/`, `playbooks/`, `hooks/`. **Edit here.** |
| `.claude/`, `.cursor/`, `.codex/`, `AGENTS.md`, `GEMINI.md` | Generated adapters. Never edit by hand; the build overwrites them. |
| `CLAUDE.md` | Project instructions. The adapters are built from it too. |
| `tools/` | Shell scripts that run fixed actions. `tools/build/` makes the adapters; `tools/lib/` holds shared helpers. |
| `tests/` | The test suite (`tests/run.sh`). |
| `.company-os/docs/` | User guides, `SKILL_SCHEMA.md`, `CHANGELOG.md` and the SVG diagrams in `diagrams/`. |
| `docs/diagrams/` | `render.js`, the script that draws those SVGs. |
| `install.sh` | The installer and upgrader. |

## Set up

You need `bash`, `git`, `tar` and `node`. `python3` is optional; a few tests skip without it. Nothing else is required.

## Add or edit a skill or agent

1. Edit or add the file under `os/skills/<name>/SKILL.md` or `os/agents/<name>.md`. The fields are described in [SKILL_SCHEMA.md](.company-os/docs/SKILL_SCHEMA.md).
2. Run `bash tools/build/build.sh`. This regenerates every adapter. Commit the regenerated files with your change.
3. If you added, removed or renamed a skill, agent or tool, run the `system-maintenance` procedure (`os/skills/system-maintenance/SKILL.md`) so counts and docs stay in sync. Update the hard-coded counts in `tests/test_docs.sh` and `tests/test_tools_help.sh`, then run `node docs/diagrams/render.js` to redraw the diagrams. The Commands table in the README is copied by hand and no test checks it, so update its descriptions yourself.

## Check your work

```bash
bash tools/build/build.sh --check --strict   # validate skills and agents; warnings fail
bash tests/run.sh                            # whole suite (about a minute)
/bin/bash tests/run.sh                       # macOS: same suite under bash 3.2
node docs/diagrams/render.js                 # redraw the diagrams if numbers or flows changed
node docs/diagrams/render.js --check         # confirm the SVGs are current
```

CI runs the first command, the last command and the test suite on Linux and macOS, with full git history (`build.sh --check` needs it for the next section).

## Known template hashes

`.company-os/known-hashes.txt` lists the sha256 of every version of every template file the installer manages, built from the git history by `tools/build/known-hashes.sh`. The installer uses it to recognise unedited copies in installs that have no manifest (1.11 and earlier), so an upgrade does not save them as `.user` copies. A full `bash tools/build/build.sh` in this repo refreshes it, and `build.sh --check` fails when it is stale.

Commit it with the change that made it stale. At release, after the last template change is committed (including the CHANGELOG), run `bash tools/build/known-hashes.sh`, commit the file if it changed, and confirm `bash tools/build/known-hashes.sh --check` passes before tagging. Regenerating only adds: the file keeps every entry it has and gains the hashes the available history gives, so a fork made from a release archive (one commit) never loses older releases. `--check` fails only when a hash from the available history is missing from the file. The script needs the full history: in a shallow clone or a release archive it skips with a message. It runs only in the Company OS source repo; in an installed project (even one with its own `install.sh`) it skips and never writes the file.

If CI reports `known-hashes.txt` as stale on your pull request, usually because `main` moved on after you branched: merge or rebase onto the latest `main`, run `bash tools/build/known-hashes.sh` (or `bash tools/build/build.sh`), and commit the updated `.company-os/known-hashes.txt`. If git shows a conflict in that file, take either side and run the script again: it adds any missing hashes to whichever side you took, so the result has all of them. Scripts must work in macOS bash 3.2: no `${var,,}`, no associative arrays, no `mapfile`.

## Commit style

Use conventional commits: `feat:`, `fix:`, `docs:`, `test:`, `ci:`, `refactor:`, `chore:`. Keep the subject under 72 characters and use the body to explain why. One concern per commit.

## Version and changelog

Every user-visible change needs a line in [CHANGELOG.md](.company-os/docs/CHANGELOG.md) under `[Unreleased]`. Maintainers bump `.company-os/version` when they release: MINOR for new features, PATCH for fixes, MAJOR for breaking changes. Then they regenerate `.company-os/known-hashes.txt` (see above).

## Pull request checklist

- [ ] `bash tools/build/build.sh --check --strict` passes, and adapters are rebuilt and committed (CI runs `bash tools/build/build.sh --runtime=all` and fails if that changes any file)
- [ ] `bash tests/run.sh` passes
- [ ] New behavior has a test
- [ ] CHANGELOG entry added
- [ ] Docs updated; diagrams regenerated if they changed
- [ ] No hand edits to generated files

## Reporting problems

Bugs and questions go to [issues](https://github.com/vibbs/company-os/issues). Security problems follow [SECURITY.md](SECURITY.md).
