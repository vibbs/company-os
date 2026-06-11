---
name: conflict-resolver
description: Resolves disagreements between agents using structured tradeoff analysis. Use when two or more agents propose conflicting approaches and a principled resolution is needed.
---

# Conflict Resolver

## Reference
- **ID**: S-ORG-03
- **Category**: Orchestration
- **Inputs**: conflicting proposals, agent positions, project constraints
- **Outputs**: resolution record with tradeoff matrix → artifacts/decision-memos/
- **Used by**: Orchestrator Agent, Engineering Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose
Provides a structured framework for resolving disagreements between agents by surfacing tradeoffs, aligning on evaluation criteria, and producing a transparent resolution that all parties can reference.

## Procedure
1. Identify the conflicting proposals and the agents involved.
2. Extract the core concern or objective each agent is optimizing for.
3. Define shared evaluation criteria (e.g., user impact, technical cost, timeline, risk).
4. Build a tradeoff matrix scoring each proposal against the criteria.
5. Identify areas of agreement and isolate the true points of contention.
6. Explore hybrid or compromise options that satisfy the highest-priority criteria.
7. Recommend a resolution with explicit rationale tied to the tradeoff matrix.
8. Document dissenting views and conditions under which the resolution should be revisited.
9. Save the resolution record to `artifacts/decision-memos/`.
10. Validate the artifact using `./tools/artifact/validate.sh`.

## Quality Checklist
- [ ] All conflicting proposals are accurately represented
- [ ] Evaluation criteria are explicit and agreed upon
- [ ] Tradeoff matrix is complete and fair
- [ ] Resolution rationale is tied to criteria, not authority
- [ ] Dissenting views are documented respectfully
- [ ] Revisit conditions are specified
- [ ] Artifact passes validation
