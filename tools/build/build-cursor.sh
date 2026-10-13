#!/usr/bin/env bash
# ============================================================================
# build-cursor.sh — Generate Cursor adapter files
# ============================================================================
# Emits:
#   .cursor/rules/00-company-os.mdc   — primary rules file (Cursor MDC format)
#   .cursor/rules/10-skills.mdc       — skill catalog
#   .cursor/rules/20-agents.mdc       — agent personas
#   .cursorrules                      — legacy single-file format
#
# Cursor MDC rules support `globs` and `alwaysApply` frontmatter. The overview
# is always applied; the skill catalog (~3.5k tokens) and agent personas are
# Agent-Requested rules (alwaysApply: false, no globs): Cursor reads their
# description and pulls them in whenever a task needs them, in any folder.
#
# Usage:
#   bash tools/build/build-cursor.sh
# ============================================================================

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

source tools/build/lib-frontmatter.sh
source tools/build/lib-skill-index.sh
source tools/build/lib-agent-index.sh

mkdir -p .cursor/rules

# ----------------------------------------------------------------------------
# 00-company-os.mdc — overview, always applied
# ----------------------------------------------------------------------------
OVERVIEW=".cursor/rules/00-company-os.mdc"
TMP="$(mktemp)"

cat > "$TMP" <<'EOF'
---
description: Company OS — overview and working conventions (always applied)
alwaysApply: true
---

# Company OS

This project follows the Company OS methodology — a three-layer system of
**Agents** (authority), **Skills** (procedures), and **Tools** (deterministic
execution). All work produces **Artifacts** with YAML frontmatter and lineage
links.

## Before doing anything technical

1. Read `company.config.yaml` — defines the tech stack, conventions, and
   architecture for this project.
2. Read `AGENTS.md` for the agent/skill/tool catalog.
3. Read `CLAUDE.md` for full conventions (it includes everything in this rules
   file plus Claude-specific guidance).

## Artifact lineage is enforced

Every file under `artifacts/` must have YAML frontmatter:
`id`, `type`, `title`, `status`, `created`, `author`.

Use these tools when working with artifacts:

- `./tools/artifact/validate.sh` — check frontmatter + link integrity
- `./tools/artifact/link.sh` — link parent ↔ child
- `./tools/artifact/promote.sh` — status transitions
- `./tools/artifact/check-gate.sh` — stage gate checks

## Commit discipline

Read `conventions.commit_style` from `company.config.yaml`. One concern per
commit. Commit at logical boundaries.

## Skills in Cursor

Cursor doesn't have a native skill system. The skill catalog is the
`.cursor/rules/10-skills.mdc` rule, which Cursor attaches on request. When a
task matches a skill there (for example setup, ship, prd-writer,
architecture-draft, test-plan-generator, landing-page-copy), **open
`os/skills/<name>/SKILL.md` and follow its procedure section**.
EOF

mv "$TMP" "$OVERVIEW"

# ----------------------------------------------------------------------------
# 10-skills.mdc — skill catalog (Agent-Requested: pulled in by description)
# ----------------------------------------------------------------------------
SKILLS=".cursor/rules/10-skills.mdc"
TMP="$(mktemp)"

cat > "$TMP" <<'EOF'
---
description: Company OS skill catalog. Use for any product, engineering, QA, growth or operations task (setup, ship, PRD, RFC, API design, test plan, QA, launch copy, pricing, security review, upgrades) to find the matching skill in os/skills/ and follow it.
alwaysApply: false
---

# Skill Catalog

When a task matches one of these skills, open the linked file and follow the
procedure section.

EOF

skill_src_dir="$(skill_source_dir)"
while IFS= read -r skill; do
  [ -z "$skill" ] && continue
  file="$(skill_file "$skill")"
  [ -f "$file" ] || continue
  desc="$(fm_field "$file" "description")"
  echo "- **\`$skill\`** — $desc" >> "$TMP"
  echo "  → \`$skill_src_dir/$skill/SKILL.md\`" >> "$TMP"
done < <(skill_list)

mv "$TMP" "$SKILLS"

# ----------------------------------------------------------------------------
# 20-agents.mdc — agent personas
# ----------------------------------------------------------------------------
AGENTS=".cursor/rules/20-agents.mdc"
TMP="$(mktemp)"

cat > "$TMP" <<'EOF'
---
description: Company OS agent personas — adopt the matching role based on the task
alwaysApply: false
---

# Agent Personas

Cursor doesn't ship native multi-agent dispatch — instead, **adopt the persona
that matches the work**:

- Product strategy / PRDs → behave as `product`
- Architecture / coding → behave as `engineering`
- Testing / release → behave as `qa-release`
- Marketing / launch → behave as `growth`
- Security / compliance → behave as `ops-risk`
- Routing / coordination → behave as `orchestrator`

EOF

agent_src_dir="$(agent_source_dir)"
while IFS= read -r agent; do
  [ -z "$agent" ] && continue
  file="$(agent_file "$agent")"
  desc="$(fm_field "$file" "description")"
  echo "### \`$agent\`" >> "$TMP"
  echo "" >> "$TMP"
  [ -n "$desc" ] && { echo "$desc" >> "$TMP"; echo "" >> "$TMP"; }
  echo "Full persona: \`$agent_src_dir/$agent.md\`" >> "$TMP"
  echo "" >> "$TMP"
done < <(agent_list)

mv "$TMP" "$AGENTS"

# ----------------------------------------------------------------------------
# Legacy .cursorrules — concatenation for older Cursor versions
# ----------------------------------------------------------------------------
TMP="$(mktemp)"
{
  echo "# Company OS — Cursor rules (legacy single-file format)"
  echo ""
  echo "<!-- Generated. Regenerate with: bash tools/build/build-cursor.sh -->"
  echo ""
  awk '!/^---$/ && !/^description:/ && !/^alwaysApply:/ && !/^globs:/' .cursor/rules/00-company-os.mdc
  echo ""
  echo "---"
  echo ""
  awk '!/^---$/ && !/^description:/ && !/^alwaysApply:/ && !/^globs:/' .cursor/rules/10-skills.mdc
  echo ""
  echo "---"
  echo ""
  awk '!/^---$/ && !/^description:/ && !/^alwaysApply:/ && !/^globs:/' .cursor/rules/20-agents.mdc
} > "$TMP"
mv "$TMP" .cursorrules

echo "✓ Wrote .cursor/rules/00-company-os.mdc"
echo "✓ Wrote .cursor/rules/10-skills.mdc"
echo "✓ Wrote .cursor/rules/20-agents.mdc"
echo "✓ Wrote .cursorrules (legacy)"
