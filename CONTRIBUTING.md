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
3. If you added, removed or renamed a skill, agent or tool, run the `system-maintenance` procedure (`os/skills/system-maintenance/SKILL.md`) so counts and docs stay in sync.

## Check your work

```bash
bash tools/build/build.sh --check --strict   # validate skills and agents; warnings fail
bash tests/run.sh                            # whole suite (about a minute)
/bin/bash tests/run.sh                       # macOS: same suite under bash 3.2
node docs/diagrams/render.js                 # redraw the diagrams if numbers or flows changed
node docs/diagrams/render.js --check         # confirm the SVGs are current
```

CI runs the first, fourth and fifth commands plus the suite on Linux and macOS. Scripts must work in macOS bash 3.2: no `${var,,}`, no associative arrays, no `mapfile`.

## Commit style

Use conventional commits: `feat:`, `fix:`, `docs:`, `test:`, `ci:`, `refactor:`, `chore:`. Keep the subject under 72 characters and use the body to explain why. One concern per commit.

## Version and changelog

Every user-visible change needs a line in [CHANGELOG.md](.company-os/docs/CHANGELOG.md) under `[Unreleased]`. Maintainers bump `.company-os/version` when they release: MINOR for new features, PATCH for fixes, MAJOR for breaking changes.

## Pull request checklist

- [ ] `bash tools/build/build.sh --check --strict` passes, and adapters are rebuilt and committed
- [ ] `bash tests/run.sh` passes
- [ ] New behavior has a test
- [ ] CHANGELOG entry added
- [ ] Docs updated; diagrams regenerated if they changed
- [ ] No hand edits to generated files

## Reporting problems

Bugs and questions go to [issues](https://github.com/vibbs/company-os/issues). Security problems follow [SECURITY.md](SECURITY.md).
