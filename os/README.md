# `os/`: the source you edit

This folder is the **source of truth** for Company OS skills and agents. Every runtime adapter (`.claude/`, `.cursor/`, `.codex/`, `AGENTS.md`, `GEMINI.md`) is generated from it. Edit here, never in the generated files.

![Multi-runtime build: os/skills and os/agents are validated, then build.sh generates .claude/, AGENTS.md, GEMINI.md, .cursor/rules and .codex/](../docs/diagrams/svg/multi-runtime-build.svg)

## Layout

| Path | Contents | Status |
|------|----------|--------|
| `os/skills/<name>/SKILL.md` | Skills: step-by-step procedures such as PRD writing, code review and the ship flow. Written in the [authoring schema](../docs/contributing/SKILL_SCHEMA.md). | In use |
| `os/agents/<name>.md` | Agents: role definitions such as Product, Engineering, and QA & Release. Same [schema](../docs/contributing/SKILL_SCHEMA.md). | In use |
| `os/playbooks/` | Reusable content that skills can point to, such as interview scripts and checklists | Placeholder, currently empty |
| `os/hooks/` | Runtime-neutral versions of the lifecycle hooks | Placeholder, currently empty. The working hooks are in `.claude/hooks/` (see [hooks/README.md](hooks/README.md)) |

## Editing

1. Edit the file under `os/`.
2. Run `bash tools/build/build.sh` to regenerate every adapter.
3. Commit both `os/` and the regenerated adapters, so a fresh clone works without a build step.

`bash tools/build/build.sh --check` validates every skill and agent against the schema without writing anything. The full workflow, including adding skills and agents, is in [CUSTOMIZING.md](../.company-os/docs/CUSTOMIZING.md).

## Why one neutral source?

Writing each skill once and generating per-runtime files keeps Company OS portable. It works in Claude Code, Cursor, Codex CLI and Gemini CLI through their generated files, and in Aider and any other agent that follows the [AGENTS.md](https://agents.md/) convention through `AGENTS.md` alone. Aider has no adapter of its own.
