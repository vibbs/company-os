# Company OS — Authoring Schema

This is the **runtime-neutral** schema for skills and agents. Authoring follows
this spec; per-runtime adapters in `tools/build/` translate it to each runtime's
native format.

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
| `argument-hint` | string | Placeholder text when user-invoked |
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
| `compatibility` | string | Min Claude Code version |
| `license` | string | SPDX identifier |

**`runtimes.cursor`** — fields the Cursor MDC writer reads:

| Field | Type | Description |
|-------|------|-------------|
| `globs` | string[] | File patterns that auto-attach this skill |
| `alwaysApply` | boolean | Apply on every prompt |

### Legacy fields (Phase A and B only)

The following are accepted at the top level for backward compatibility with the
current `.claude/skills/` source, but the validator warns on them and Phase C
migration moves them under `runtimes.claude`:

- `user-invokable`
- `disable-model-invocation`
- `compatibility`
- `license`

### Example (neutral, post-migration)

```yaml
---
name: ship
description: Kick off the full ship flow for a feature or objective.
id: S-ORG-08
category: orchestration
argument-hint: "describe what you want to build"
tools_used:
  - tools/artifact/validate.sh
  - tools/artifact/check-gate.sh
runtimes:
  claude:
    user-invokable: true
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
