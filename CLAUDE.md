# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Company OS Overview

This is an **AI Agentic Company OS** — a template project system for building SaaS products with AI-assisted agents, skills, and tools. Users fork this repo, configure `company.config.yaml`, and use the agent system to go from idea → PRD → architecture → implementation → release.

### Three-Layer Architecture

| Layer | Location | Purpose |
|-------|----------|---------|
| **Agents** (Authority) | `.claude/agents/` | Choose what happens next. Route, decide, delegate. |
| **Skills** (Procedural) | `.claude/skills/` | Advise + produce artifacts. Procedures, templates, checklists. |
| **Tools** (Execution) | `tools/` | Execute fixed, deterministic actions. Shell scripts. |

### Dependency Rules
- Agents depend on Skills for *how to think / what to produce*
- Agents depend on Tools for *how to act / what to run*
- Skills may *recommend* tools but never execute them
- Tools never contain reasoning
- **Artifacts are the handshake** between all components

### Canonical Ship Flow
1. **Orchestrator** routes objective → asks Product Agent for PRD
2. **Product Agent** produces PRD → `artifacts/prds/`
3. **Engineering Agent** produces RFC/API contract → `artifacts/rfcs/`
4. **Ops & Risk Agent** reviews RFC for security/privacy
5. **Engineering Agent** implements → runs CI tools
6. **QA & Release Agent** produces test plan + QA report → `artifacts/qa-reports/`
7. **Growth Agent** produces launch assets → `artifacts/launch-briefs/`
8. **Orchestrator** checks all gates → approves release

### Key Files
- `company.config.yaml` — company-specific tech stack, API standards, conventions. **Read this first in every session.**
- `standards/` — user-provided reference docs (API specs, style guides, compliance)
- `artifacts/` — agent-produced outputs with YAML frontmatter and lineage tracking
- `tasks/todo.md` — current session task tracking
- `tasks/lessons.md` — accumulated corrections and patterns

### Artifact Lineage & Enforcement
Every artifact has YAML frontmatter with: `id`, `type`, `status` (draft/review/approved/archived), `parent`, `children`, `depends_on`, `blocks`. Always maintain these links when creating or updating artifacts.

**Enforcement tools** (use these — don't skip them):
- `./tools/artifact/validate.sh` — checks frontmatter + verifies parent/depends_on/children references exist
- `./tools/artifact/link.sh` — links parent↔child artifacts (edits both files)
- `./tools/artifact/promote.sh` — status transitions with ordering enforcement (draft→review→approved)
- `./tools/artifact/check-gate.sh` — stage gate checks (prd-to-rfc, rfc-to-impl, impl-to-qa, release)

### Ingest Command
After placing new files in `standards/` or `artifacts/`, run `/ingest` to detect changes and update relevant skills/agents.

### Tech Stack Awareness
Always read `company.config.yaml` before making technical recommendations. If the configured tech stack is suboptimal for the task at hand, **flag it explicitly** with a recommendation and rationale — but respect the user's final decision.

---

## Workflow Orchestration

### 1. Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately — don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes — don't over-engineer
- Challenge your own work before presenting it

### 7. System Maintenance
- After ANY change to the Company OS structure (skills, agents, tools, artifact types, stage gates):
  run the `system-maintenance` skill to audit and update all documentation
- Trigger conditions: new/deleted/renamed skill, agent, or tool; modified validate.sh or check-gate.sh
- Documentation files that must stay in sync: CLAUDE.md, SETUP_COMPANY_OS.md, all agent .md files
- This is not optional — stale docs cause cascading confusion for agents and users

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests — then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Task Management

1. **Plan First**: Write plan to `tasks/todo.md` with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section to `tasks/todo.md`
6. **Capture Lessons**: Update `tasks/lessons.md` after corrections

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.
