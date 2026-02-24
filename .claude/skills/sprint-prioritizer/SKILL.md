---
name: sprint-prioritizer
description: Prioritizes features and work items using impact, effort, and risk scoring. Use when planning sprints or deciding what to build next.
---

# Sprint Prioritizer

## Reference
- **ID**: S-PROD-03
- **Category**: Product
- **Inputs**: feature backlog, impact estimates, effort estimates, risk assessments, strategic goals
- **Outputs**: prioritized sprint plan → artifacts/product/
- **Used by**: Product Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose
Takes a backlog of features and work items and produces a prioritized sprint plan by scoring each item on impact, effort, and risk, ensuring the team works on the highest-value items first.

## Procedure
1. Collect the candidate feature/work-item backlog for the upcoming sprint.
2. For each item, score **impact** (1-5): user value, revenue potential, strategic alignment.
3. For each item, score **effort** (1-5): engineering complexity, dependencies, unknowns.
4. For each item, score **risk** (1-5): technical risk, market risk, dependency risk.
5. Calculate a priority score: `(Impact * weight) / (Effort + Risk)` using agreed weights.
6. Rank items by priority score, highest first.
7. Apply capacity constraints — fit items into available sprint capacity.
8. Flag items with high risk that may need spikes or de-risking work first.
9. Produce the prioritized sprint plan with rationale for top selections.
10. Save to `artifacts/product/` and validate using `./tools/artifact/validate.sh`.

## Quality Checklist
- [ ] All candidate items have impact, effort, and risk scores
- [ ] Scoring criteria are consistent across items
- [ ] Sprint capacity constraints are applied realistically
- [ ] High-risk items have mitigation plans or spike tasks
- [ ] Top priorities align with current strategic goals
- [ ] Rationale is documented for any overrides of the calculated ranking
- [ ] Artifact passes validation
