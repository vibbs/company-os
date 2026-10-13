# Skill and Agent Authoring Schema

This is the **runtime-neutral** schema for skills and agents. You author skills in
`os/skills/<name>/SKILL.md` and agents in `os/agents/<name>.md` using this spec.
The build scripts in `tools/build/` then generate each runtime's native files
(the *adapters*: `.claude/`, `.cursor/`, `.codex/`, `AGENTS.md`, `GEMINI.md`).

Never edit the generated adapters by hand: `bash tools/build/build.sh` overwrites
them. For the end-to-end editing workflow, see
[CUSTOMIZING.md](../../.company-os/docs/CUSTOMIZING.md).

## Why a neutral schema?

Claude Code, Cursor, Codex, and Gemini each have their own conventions for
what a "skill" or "agent" looks like. To keep one source of truth, we author
in a schema that's a documented superset of those conventions — and runtime-
specific extensions live under a `runtimes:` map so adapters can pick them up
without polluting the common surface.

## Skill schema

JSON Schema: [`tools/build/schema/skill.schema.json`](../../tools/build/schema/skill.schema.json)

### Required fields

| Field | Type | Notes |
|-------|------|-------|
| `name` | string (kebab-case) | Must match the containing directory name |
| `description` | string (≥10 chars) | One sentence; runtimes use it for skill activation |

### Optional fields

| Field | Type | Purpose |
|-------|------|---------|
| `id` | string (`S-XXX-01` pattern) | Stable internal ID for cross-referencing |
| `category` | enum | `product`, `engineering`, `qa`, `growth`, `ops-risk`, `orchestration`, `shared` |
| `inputs` | string[] | Inputs the procedure consumes |
| `outputs` | string[] | Artifacts the procedure produces |
| `tools_used` | string[] | Tool scripts the procedure invokes |
| `tags` | string[] | Searchable labels |
| `runtimes` | object | Runtime-specific extensions (see below) |
| `metadata` | object | Free-form bag |

### Runtime extensions

Each adapter reads `runtimes.<runtime-name>` for fields that don't make sense
in the neutral schema.

**`runtimes.claude`** — fields the Claude Code skill loader reads:

| Field | Type | Description |
|-------|------|-------------|
| `user-invokable` | boolean | Whether the skill appears as a `/<name>` slash command |
| `disable-model-invocation` | boolean | Block auto-invocation |
| `argument-hint` | string | Placeholder text shown after `/<name>` when the user runs it |
| `compatibility` | string | Min Claude Code version |
| `license` | string | SPDX identifier |

**`runtimes.cursor`** — fields the Cursor MDC writer reads:

| Field | Type | Description |
|-------|------|-------------|
| `globs` | string[] | File patterns that auto-attach this skill |
| `alwaysApply` | boolean | Apply on every prompt |

When you build, `tools/build/build-claude.sh` lifts every key under
`runtimes.claude` to the top level of the generated `.claude/skills/<name>/SKILL.md`,
because that is where Claude Code reads them. Other runtimes ignore the block.

### Legacy top-level fields

Older skills put Claude-only fields at the top level. All skills in `os/skills/`
have been migrated, but the validator still accepts the old form:

- `user-invokable`, `disable-model-invocation`, `compatibility`, `license` at the
  top level pass validation with a deprecation warning.
- `argument-hint` at the top level is accepted without a warning (it is also
  listed in `skill.schema.json`), but new skills should put it under
  `runtimes.claude`.

### Example (neutral, post-migration)

```yaml
---
name: ship
description: Kick off the full ship flow for a feature or objective.
id: S-ORG-08
category: orchestration
tools_used:
  - tools/artifact/validate.sh
  - tools/artifact/check-gate.sh
runtimes:
  claude:
    user-invokable: true
    argument-hint: "<what you want to build>"
  cursor:
    globs:
      - "artifacts/**"
---

# Ship

The primary entry point for the canonical ship flow...
```

## Agent schema

JSON Schema: [`tools/build/schema/agent.schema.json`](../../tools/build/schema/agent.schema.json)

### Required fields

| Field | Type | Notes |
|-------|------|-------|
| `name` | string (kebab-case) | Must match the filename (without `.md`) |
| `description` | string (≥10 chars) | One sentence describing the persona |

### Optional fields

| Field | Type | Purpose |
|-------|------|---------|
| `tools` | string[] | Logical tool capabilities (adapters map to runtime tool names) |
| `model` | enum | `opus`, `sonnet`, or `haiku` (runtimes pick concrete model IDs) |
| `skills` | string[] | Skills this agent has access to |
| `memory` | enum | `user`, `project`, or `local` |
| `runtimes` | object | Runtime-specific overrides |

### Example

```yaml
---
name: engineering
description: Staff Engineer — owns architecture, decomposes work, delegates to sub-agents.
tools: [Read, Write, Edit, Bash, Grep, Glob, Task]
model: opus
memory: project
skills:
  - architecture-draft
  - implementation-decomposer
  - code-review
---
```

## Validation

```bash
bash tools/build/validate-skill.sh --all          # validate every skill
bash tools/build/validate-skill.sh path/to/SKILL.md  # validate one
bash tools/build/validate-agent.sh --all
bash tools/build/validate-agent.sh path/to/agent.md
```

Run automatically by `bash tools/build/build.sh --check`.
