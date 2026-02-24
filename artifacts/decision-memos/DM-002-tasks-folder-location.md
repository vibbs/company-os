---
id: DM-002
type: decision-memo
title: "tasks/ folder stays separate from artifacts/"
status: approved
created: 2026-02-23
author: orchestrator
parent: null
children: []
depends_on: []
blocks: []
tags: [architecture, conventions]
---

# Decision: tasks/ Folder Location

## Question

Should `tasks/todo.md` and `tasks/lessons.md` move into the `artifacts/` directory, since they are AI-generated content?

## Decision

**No. `tasks/` stays as a separate top-level directory.**

## Rationale

### 1. Session Working Files vs Enterprise Deliverables

`tasks/` contains two fundamentally different kinds of content from `artifacts/`:

- **`todo.md`** — Session-ephemeral scratch pad. Rewritten each session with checkable items. No persistence expectation beyond the current work session.
- **`lessons.md`** — Living accumulation of agent corrections and patterns. Grows incrementally over time. Referenced at session start for learning, never "approved" or "archived."

Artifacts are enterprise deliverables (PRDs, RFCs, QA reports) that go through a strict lifecycle with audit trails.

### 2. Lifecycle Does Not Apply

Artifacts have enforced state transitions: `draft → review → approved → archived`. They require YAML frontmatter with `id`, `type`, `status`, `parent`, `children`, `depends_on`, `blocks`.

A todo list that gets rewritten every session has no meaningful lifecycle. A lessons file that agents append to after corrections doesn't go through review/approval cycles — it's a continuously-evolving reference.

### 3. No Tool Enforcement Needed

No tools in `tools/` reference or operate on `tasks/`. Artifact tools (validate, promote, link, check-gate) would add overhead with no benefit — validating frontmatter on a scratch pad or requiring promotion of accumulated lessons doesn't serve any purpose.

### 4. Four-Category Content Model

The Company OS has four distinct content categories:

| Category | Location | Author | Nature |
|----------|----------|--------|--------|
| Configuration | `company.config.yaml` | User | Input — living, no lifecycle |
| Standards | `standards/` | User | Reference — imported, no lifecycle |
| Session Work | `tasks/` | Agent | Operational — ephemeral + learning |
| Deliverables | `artifacts/` | Agent | Output — lifecycle, lineage, audit |

Moving `tasks/` into `artifacts/` would collapse the operational and deliverable categories, creating the same confusion addressed in DM-001.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|------------|------|------|-------------|
| Move `lessons.md` to `standards/patterns/` | Groups institutional knowledge with other references | Lessons are agent-authored, standards are user-authored; conflates input/output | Violates the input vs output principle |
| Move both to `artifacts/` with new "operational" type | All AI content in one place | Requires frontmatter and lifecycle on ephemeral files; artifact tools would enforce meaningless transitions | Overhead with no benefit |
| Create `knowledge/` top-level directory for lessons | Gives lessons more visibility | Adds a new top-level directory for one file; over-engineering | Premature abstraction |

## Consequences

- `tasks/` remains at the repository root as an operational workspace
- `todo.md` continues to be session-scoped with no persistence expectations
- `lessons.md` continues to accumulate patterns, tracked via git history
- Agents reference both files at session start per CLAUDE.md behavioral rules
- No artifact tooling overhead on operational files
