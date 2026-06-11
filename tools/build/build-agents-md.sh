#!/usr/bin/env bash
# ============================================================================
# build-agents-md.sh — Generate AGENTS.md (multi-runtime instruction file)
# ============================================================================
# Reads CLAUDE.md, skills, agents, and config and emits AGENTS.md at the
# repo root. AGENTS.md is the cross-runtime standard adopted by Codex, Aider,
# and a growing list of other agentic tools.
#
# Usage:
#   bash tools/build/build-agents-md.sh
#
# Output:
#   AGENTS.md
# ============================================================================

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

source tools/build/lib-frontmatter.sh
source tools/build/lib-skill-index.sh
source tools/build/lib-agent-index.sh

OUT="AGENTS.md"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

VERSION="$(cat .company-os/version 2>/dev/null || echo "unknown")"

# ----------------------------------------------------------------------------
# Header
# ----------------------------------------------------------------------------
cat > "$TMP" <<EOF
# AGENTS.md

<!-- GENERATED FILE — do not edit by hand. Source: .claude/ + CLAUDE.md -->
<!-- Regenerate with: bash tools/build/build-agents-md.sh -->

This file is the runtime-neutral instruction layer for **Company OS** v${VERSION}.
It is intended for AI coding agents that follow the [AGENTS.md](https://agents.md/)
convention — Codex CLI, Aider, and any agent without its own instruction file.

If you are running in:

- **Claude Code** → read \`CLAUDE.md\` (it has Claude-specific guidance)
- **Cursor**      → see \`.cursor/rules/\` (generated from this same source)
- **Gemini CLI**  → see \`GEMINI.md\` (generated from this same source)
- **Anything else** → read this file from top to bottom

---

EOF

# ----------------------------------------------------------------------------
# Core principles — pulled from CLAUDE.md "Core Principles" + Company OS Overview
# ----------------------------------------------------------------------------
cat >> "$TMP" <<'EOF'
## What Is Company OS?

An AI Agentic Company OS — a template project system for building SaaS products
with AI agents, skills, and tools. The system has three layers:

| Layer | Authoring source | Purpose |
|-------|------------------|---------|
| **Agents** (Authority) | `os/agents/` | Choose what happens next. Route, decide, delegate. |
| **Skills** (Procedural) | `os/skills/` | Advise + produce artifacts. Procedures, templates, checklists. |
| **Tools** (Execution) | `tools/` | Execute fixed, deterministic actions. Shell scripts. |

Per-runtime adapters (`.claude/`, `.cursor/`, `.codex/`) are **generated** from
`os/` by `tools/build/build.sh`.

**Dependency rules:**
- Agents depend on Skills for *how to think / what to produce*
- Agents depend on Tools for *how to act / what to run*
- Skills may *recommend* tools but never execute them
- Tools never contain reasoning
- **Artifacts are the handshake** between all components

## Working Conventions

**Before doing anything technical**, read `company.config.yaml` — it defines the
tech stack, conventions, and architecture for this specific project.

**Before recommending any library API**, fetch current docs (e.g., via Context7
in Claude Code, or web search in other runtimes). Training data is often stale.

**Artifact lineage is enforced.** Every artifact in `artifacts/` has YAML
frontmatter with `id`, `type`, `title`, `status`, `created`, `author`. Use:

- `./tools/artifact/validate.sh` — check frontmatter + link integrity
- `./tools/artifact/link.sh` — link parent ↔ child artifacts
- `./tools/artifact/promote.sh` — status transitions (draft → review → approved)
- `./tools/artifact/check-gate.sh` — stage gate checks (prd-to-rfc, rfc-to-impl, impl-to-qa, release)

**Commit discipline:** read `conventions.commit_style` from `company.config.yaml`.
One concern per commit. Commit at logical boundaries.

EOF

# ----------------------------------------------------------------------------
# Agent catalog
# ----------------------------------------------------------------------------
cat >> "$TMP" <<'EOF'
---

## Agent Catalog

The system ships with these agent personas. In runtimes without native sub-agent
dispatch (Codex, Aider), treat these as **role descriptions** — when a user
asks for product strategy, behave as the Product Agent would; for architecture,
behave as the Engineering Agent.

EOF

while IFS= read -r agent; do
  [ -z "$agent" ] && continue
  file="$(agent_file "$agent")"
  desc="$(fm_field "$file" "description")"
  model="$(fm_field "$file" "model" || true)"
  echo "### \`$agent\`" >> "$TMP"
  echo "" >> "$TMP"
  if [ -n "$desc" ]; then echo "$desc" >> "$TMP"; echo "" >> "$TMP"; fi
  if [ -n "$model" ]; then echo "**Recommended model tier:** \`$model\`" >> "$TMP"; echo "" >> "$TMP"; fi
  # List skills the agent has access to
  skills="$(fm_list "$file" "skills" || true)"
  if [ -n "$skills" ]; then
    echo "**Skills:** " >> "$TMP"
    while IFS= read -r s; do
      [ -z "$s" ] && continue
      echo "- \`$s\`" >> "$TMP"
    done <<< "$skills"
    echo "" >> "$TMP"
  fi
  agent_src_dir="$(agent_source_dir)"
  echo "Full persona: [\`$agent_src_dir/$agent.md\`]($agent_src_dir/$agent.md)" >> "$TMP"
  echo "" >> "$TMP"
done < <(agent_list)

# ----------------------------------------------------------------------------
# Skill catalog
# ----------------------------------------------------------------------------
cat >> "$TMP" <<'EOF'
---

## Skill Catalog

Skills are procedural playbooks. In Claude Code they are loaded just-in-time via
the `Skill` tool; in other runtimes, **read the skill file directly when its
description matches the task**. Each skill ends with a procedure section — follow
the steps in order.

EOF

skill_src_dir="$(skill_source_dir)"
while IFS= read -r skill; do
  [ -z "$skill" ] && continue
  file="$(skill_file "$skill")"
  [ -f "$file" ] || continue
  desc="$(fm_field "$file" "description")"
  echo "- **\`$skill\`** — $desc " >> "$TMP"
  echo "  → [\`$skill_src_dir/$skill/SKILL.md\`]($skill_src_dir/$skill/SKILL.md)" >> "$TMP"
done < <(skill_list)

# ----------------------------------------------------------------------------
# Tool catalog
# ----------------------------------------------------------------------------
cat >> "$TMP" <<'EOF'

---

## Tool Catalog

Deterministic shell scripts. Safe to invoke directly. All live under `tools/`.

EOF

find tools -mindepth 2 -maxdepth 3 -type f -name "*.sh" 2>/dev/null | sort | while read -r tool; do
  # First non-comment description line, falling back to the path
  desc="$(grep -m1 -E '^# [A-Z]' "$tool" 2>/dev/null | sed 's/^# *//' || true)"
  if [ -z "$desc" ]; then desc="(no description)"; fi
  echo "- \`$tool\` — $desc" >> "$TMP"
done

# ----------------------------------------------------------------------------
# Workflow shortcuts
# ----------------------------------------------------------------------------
cat >> "$TMP" <<'EOF'

---

## Common Workflows

Claude Code exposes these as slash commands. In other runtimes, ask the agent to
"run the ship skill" / "run the setup skill" — it will read the corresponding
skill file and follow the procedure.

| Intent | Skill | What it does |
|--------|-------|--------------|
| Build a feature end-to-end | `ship` | PRD → RFC → impl → QA → launch with gates |
| First-time project setup | `setup` | Interactive config wizard + scaffolding |
| Import an existing doc | `artifact-import` | Classify + add frontmatter + link |
| Quick prototype (skip gates) | `rapid-prototype` | Time-boxed MVP for PoC/demos |
| GTM validation sprint | `gtm-sprint` | 7/14/21-day market validation |
| Status snapshot | `status` | Counts, broken links, gate readiness |
| Upgrade Company OS | `upgrade-company-os` | Pull latest template safely |

---

## Re-generating This File

This file is generated from `.claude/skills/`, `.claude/agents/`, and
`CLAUDE.md`. To regenerate after changes:

```bash
bash tools/build/build.sh
```

Or just the AGENTS.md file:

```bash
bash tools/build/build-agents-md.sh
```
EOF

mv "$TMP" "$OUT"
trap - EXIT

# Output summary
SKILL_COUNT=$(skill_list | wc -l | tr -d ' ')
AGENT_COUNT=$(agent_list | wc -l | tr -d ' ')
TOOL_COUNT=$(find tools -mindepth 2 -maxdepth 3 -type f -name "*.sh" 2>/dev/null | wc -l | tr -d ' ')
echo "✓ Wrote $OUT  (${SKILL_COUNT} skills, ${AGENT_COUNT} agents, ${TOOL_COUNT} tools)"
