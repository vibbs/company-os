---
name: implementation-decomposer
description: Breaks a PRD or RFC into small, well-scoped implementation tasks suitable for individual pull requests. Use when translating product requirements into engineering work items.
---

# Implementation Decomposer

## Reference
- **ID**: S-ENG-05
- **Category**: Engineering
- **Inputs**: PRD or RFC document, architecture context, team capacity
- **Outputs**: implementation task list with dependencies → artifacts/engineering/
- **Used by**: Engineering Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose
Translates high-level product requirements (PRD) or technical designs (RFC) into a sequence of small, independently reviewable implementation tasks, each scoped to roughly one pull request, with explicit dependencies and acceptance criteria.

## Procedure
1. Read and understand the source PRD or RFC in full.
2. Identify the major functional areas or modules affected.
3. For each area, list the discrete changes needed (schema, API, UI, tests, migrations).
4. Scope each task to be completable in 1-2 days and reviewable in a single PR.
5. Define dependencies between tasks — which must be merged before others can start.
6. Write acceptance criteria for each task, derived from the PRD requirements.
7. Identify tasks that can be parallelized across team members.
8. Flag any tasks that require spikes or unknowns to be resolved first.
9. For tasks introducing new dependencies, add "Fetch current docs via Context7 (`resolve-library-id` → `query-docs`)" as a pre-implementation step to ensure up-to-date API usage.
10. Arrange tasks in a recommended execution order (topological sort by dependencies).
11. Save the task list to `artifacts/engineering/`.
12. Validate the artifact using `./tools/artifact/validate.sh`.

## Quality Checklist
- [ ] Every PRD requirement maps to at least one implementation task
- [ ] No task is larger than ~2 days of effort
- [ ] Dependencies between tasks are explicit
- [ ] Each task has clear acceptance criteria
- [ ] Parallelizable tasks are identified
- [ ] Spike/research tasks are called out separately
- [ ] Task list covers tests and documentation, not just code
- [ ] Artifact passes validation
