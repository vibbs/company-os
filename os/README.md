# `os/` — Runtime-Agnostic Authoring Source

This directory is the **source of truth** for Company OS skills, agents,
playbooks, and lifecycle hooks. Every runtime adapter (`.claude/`, `.cursor/`,
`.codex/`, `AGENTS.md`, `GEMINI.md`) is generated from here.

## Layout

| Path | Purpose |
|------|---------|
| `os/skills/<name>/SKILL.md` | Procedural skills (PRD writing, code review, ship flow, …). Authored in the [neutral skill schema](../docs/contributing/SKILL_SCHEMA.md). |
| `os/agents/<name>.md` | Persona definitions (Product, Engineering, QA & Release, …). Authored in the [neutral agent schema](../docs/contributing/SKILL_SCHEMA.md). |
| `os/playbooks/` | Cross-runtime workflows that skills reference (e.g. interview scripts, checklists). |
| `os/hooks/` | Portable lifecycle hooks. Runtime-specific wiring lives under each adapter (e.g. `.claude/hooks/`). |

## Editing

1. Edit the file under `os/`.
2. Run `bash tools/build/build.sh` to regenerate every adapter.
3. Commit both `os/` and the regenerated adapter outputs.

Validators run on every build (`build.sh --check`) and fail CI when authored
files diverge from the [schema](../docs/contributing/SKILL_SCHEMA.md).

## Why a neutral source?

Authoring once and generating per-runtime keeps Company OS portable: it works
in Claude Code, Cursor, Codex, Gemini CLI, Aider, and any agent that follows
the [AGENTS.md](https://agents.md/) convention without forking the methodology.
