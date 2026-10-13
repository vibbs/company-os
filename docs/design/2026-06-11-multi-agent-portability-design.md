# Multi-Agent Portability — Design

**Date:** 2026-06-11
**Status:** Implemented (Phases A–D shipped; see the `[Unreleased]` section of `.company-os/docs/CHANGELOG.md`)
**Owner:** Engineering
**Stages:** A → B → C → Distribution

> This is the original design record, kept for history. For how to author skills and agents today, read [`docs/contributing/SKILL_SCHEMA.md`](../contributing/SKILL_SCHEMA.md).

## Problem

Company OS is methodology + tooling, but its delivery surface is 100% Claude Code:
`.claude/skills/`, `.claude/agents/`, `.claude/hooks/`, `CLAUDE.md`, `settings.json`, slash commands.
The actual IP (artifacts, standards, tools, lineage, gates, ship flow) is runtime-agnostic — only the chassis isn't.

**Goal:** Make Company OS usable from Cursor, Codex, Gemini CLI, Aider, Copilot CLI, and any future agent that adopts `AGENTS.md` — without forcing users to install Claude Code.

## Non-Goals

- Building a runtime ourselves
- Reproducing Claude Code's `Skill` tool semantics in other runtimes
- Maintaining feature parity across every runtime — best-effort per runtime
- Plugin packaging (that's the *next* phase after distribution)

## Strategy: Staged decoupling (A → B → C)

### Phase A — Adapter generation from current source (~1-2 days)

Keep `.claude/skills/` and `.claude/agents/` as authoring source-of-truth (they're already in clean Markdown).
Add a build layer that **compiles** to other runtime targets:

```
tools/build/
  build.sh               # orchestrator
  build-agents-md.sh     # → AGENTS.md (Codex, Aider, generic)
  build-gemini.sh        # → GEMINI.md (Gemini CLI)
  build-cursor.sh        # → .cursor/rules/*.mdc + .cursorrules (legacy)
  lib-skill-index.sh     # shared: enumerate skills with frontmatter
  lib-agent-index.sh     # shared: enumerate agents with frontmatter
```

Outputs are committed (so non-Claude users can `git clone` and go) and regenerated whenever `.claude/` changes (post-tool hook or manual `make build`).

**Acceptance:** A user cloning the repo without Claude Code installed sees a working `AGENTS.md` that points to skills, agents, tools, and config. Cursor users get `.cursor/rules/`. Gemini users get `GEMINI.md`.

### Phase B — Skill/agent format normalization + transpilers (~1-2 days)

Define the **neutral skill schema** (a documented superset of what's authored):

- Required: `name`, `description`, `body` (Markdown)
- Optional: `category`, `id`, `inputs`, `outputs`, `tools_used`, `tags`
- Runtime-specific extensions in `runtimes:` map (e.g., `runtimes.claude.user-invokable`)

Build transpilers:
- For runtimes with skill systems (Claude Code) → native skill file
- For runtimes without (Codex/Aider) → flat playbook reference in `AGENTS.md` skill catalog

`tools/build/normalize-skill.sh` validates any skill file against the schema.

**Acceptance:** A skill written in the neutral schema produces correct outputs for all targets. Existing `.claude/skills/` are validated by the same script.

### Phase C — Runtime-agnostic core (~2-3 days)

Promote `os/` as the authoring source-of-truth. `.claude/` becomes the **flagship adapter** — generated.

```
os/
  skills/<name>/SKILL.md     # neutral skill schema
  agents/<name>.md           # neutral agent persona schema
  playbooks/                 # workflows referenced by skills
  hooks/                     # neutral hook scripts (bash); runtimes wire them in their own way
  schema/
    skill.schema.json
    agent.schema.json
```

Build step:
- `os/` → `.claude/`, `.cursor/`, `.gemini/`, `AGENTS.md` (all generated)
- Generated dirs committed for friction-free clone-and-go
- `install.sh` fetches `os/` + generated outputs + tools/standards/config

Migration path:
- `tools/build/migrate-claude-to-os.sh` — one-shot script to move `.claude/skills/` → `os/skills/` and rewrite frontmatter to neutral schema
- Existing user installs detect old structure via `.company-os/version` and offer migration

**Acceptance:** Authoring happens in `os/`; all runtime dirs regenerate from one command; existing installs upgrade cleanly.

### Distribution layer (~1-2 days, after C)

Refactor `install.sh` to support runtime selection:

```
curl … | bash                          # detect runtimes, install all detected
curl … | bash -s -- --runtime=claude   # install only Claude Code adapter
curl … | bash -s -- --runtime=cursor   # install only Cursor adapter
curl … | bash -s -- --runtime=all      # install everything
curl … | bash -s -- --runtime=none     # install core + AGENTS.md only
```

New commands:
- `tools/registry/list-runtimes.sh` — show what's installed
- `tools/registry/install-runtime.sh <runtime>` — add a runtime post-install

Runtime detection heuristics:
- Claude Code: `command -v claude` or `~/.claude/` exists
- Cursor: `~/.cursor/` or `cursor` in PATH
- Codex: `~/.codex/` or `codex` in PATH
- Gemini CLI: `command -v gemini` or `~/.gemini/`
- Otherwise: only ship neutral `AGENTS.md`

## Architecture

```
                  ┌─────────────────┐
                  │      os/        │   ← authoring source-of-truth (Phase C)
                  │  skills/        │
                  │  agents/        │
                  │  playbooks/     │
                  │  hooks/         │
                  │  schema/        │
                  └────────┬────────┘
                           │
                  ┌────────▼────────┐
                  │  tools/build/   │   ← deterministic build step
                  └────────┬────────┘
                           │
        ┌──────────┬───────┼──────────┬──────────┐
        ▼          ▼       ▼          ▼          ▼
   .claude/    .cursor/  AGENTS.md  GEMINI.md  .codex/
   (Claude    (Cursor   (Codex,    (Gemini    (when
    Code)     IDE)      Aider)     CLI)       available)

   ─── shared, untouched by adapters ───
   artifacts/   standards/   tools/   seeds/   cogs/   company.config.yaml
```

## Compatibility / migration

- Phase A is **purely additive** — nothing in `.claude/` moves, no existing installs break
- Phase B introduces the schema and a validator but doesn't move files
- Phase C is the breaking change. Migration is one-shot and idempotent.
- The migration script is gated by a version check (`.company-os/version >= 1.12.0`) and emits a backup

## Risks

| Risk | Mitigation |
|---|---|
| Slash commands don't exist in Cursor/Codex | Adapter generates an `AGENTS.md` *catalog* — user types "use the ship skill" instead of `/ship` |
| Skill JIT-loading is Claude-specific | For other runtimes, all skill bodies are concatenated into a skill catalog file; agents load on demand by reading the file |
| Hook lifecycle is Claude-specific | Phase A doesn't address hooks. Phase C documents portable bash entrypoints; per-runtime adapters wire them up where possible |
| Build outputs drift from source | CI check + post-tool hook validation; clear "regenerate" instructions in CLAUDE.md / AGENTS.md |

## Testing

After each phase:
1. `bash tools/build/build.sh` succeeds
2. Generated `AGENTS.md` references a real skill and a real agent
3. Generated runtime files validate against their schemas (where checkable)
4. Existing `.claude/` setup still loads in Claude Code (no regression)
5. `git diff` is sane — no junk in generated files

End-to-end: clone fresh repo, run install with `--runtime=cursor`, confirm `.cursor/` exists and `.claude/` does not.

## Out of scope (post-distribution)

- Claude Code plugin marketplace packaging
- Cursor extension packaging
- Per-runtime feature parity beyond skill catalog and instruction files
- Hook portability beyond what each runtime natively supports
