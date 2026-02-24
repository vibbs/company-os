---
name: decision-memo-writer
description: Produces structured decision records with rationale, alternatives considered, and consequences. Use when recording non-trivial decisions that future team members need to understand.
---

# Decision Memo Writer

## Reference
- **ID**: S-ORG-02
- **Category**: Orchestration
- **Inputs**: decision context, alternatives, stakeholder positions
- **Outputs**: decision memo artifact → artifacts/decision-memos/
- **Used by**: Orchestrator Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose
Records non-trivial decisions with full rationale, alternatives evaluated, and anticipated consequences so that future team members can understand why a particular path was chosen without re-litigating the discussion.

## Procedure
1. Gather the decision context: what problem or question triggered this decision.
2. List all alternatives considered, including the status-quo option.
3. For each alternative, document pros, cons, risks, and estimated effort.
4. Identify stakeholder positions and any dissenting opinions.
5. State the chosen alternative and the primary rationale for selection.
6. Document expected consequences (positive and negative) of the decision.
7. Define revisit criteria — conditions under which this decision should be reconsidered.
8. Write the memo in the standard template and save to `artifacts/decision-memos/`.
9. Validate the artifact using `./tools/artifact/validate.sh`.

## Quality Checklist
- [ ] Decision context is clearly stated and specific
- [ ] At least two alternatives (including status-quo) are documented
- [ ] Each alternative has pros, cons, and risk assessment
- [ ] Stakeholder positions are captured accurately
- [ ] Chosen alternative has explicit rationale
- [ ] Consequences section covers both upside and downside
- [ ] Revisit criteria are defined with measurable triggers
- [ ] Artifact passes validation
