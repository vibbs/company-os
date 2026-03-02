---
name: feedback-synthesizer
description: Turns messy, unstructured customer and user feedback into actionable themes with supporting evidence. Use when consolidating feedback from multiple sources into product insights.
---

# Feedback Synthesizer

## Reference
- **ID**: S-PROD-04
- **Category**: Product
- **Inputs**: raw feedback (support tickets, CONV- artifacts, interviews, surveys, reviews, Slack messages)
- **Outputs**: themed feedback report with actionable insights → artifacts/product/
- **Used by**: Product Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose
Consolidates raw, unstructured feedback from multiple channels into a structured report of themes, each backed by evidence and linked to actionable product recommendations.

## Procedure
1. Collect raw feedback from all available sources (support tickets, interviews, surveys, app reviews, internal notes).
2. Normalize feedback: strip duplicates, tag source channel, note user segment.
3. Perform open coding — assign initial labels to each piece of feedback.
4. Group labels into higher-level themes (e.g., "onboarding friction", "pricing confusion").
5. For each theme, count frequency and assess severity (blocker / pain / annoyance).
6. Rank themes by frequency * severity to surface the highest-impact issues.
7. For each top theme, provide 2-3 representative quotes as evidence.
8. Draft actionable recommendations tied to each theme.
9. Save the themed feedback report to `artifacts/product/`.
10. Validate the artifact using `./tools/artifact/validate.sh`.

### Small-Data Path

If fewer than 10 feedback items across all sources:
- Skip frequency scoring — insufficient sample size for statistical patterns
- Produce a **Signal Log** format: chronological list with severity ratings and direct action suggestions
- Do not generate PRD candidates from fewer than 5 items in the same theme
- Note the data limitation explicitly in the output
- Recommend: "Collect more feedback before synthesizing themes. Use customer-conversations skill to generate structured input."

Resume standard synthesis procedure when 10+ items are available.

### Step 11: Produce PRD Candidates Section

After ranking themes (Step 6), for the top 3 themes by frequency × severity score:

1. Draft a PRD candidate entry for each:
   - **Theme name**: from Step 4
   - **Problem statement draft**: 2-sentence articulation of the user pain
   - **Target ICP**: which user segment reported this most
   - **Evidence sources**: CONV- artifact IDs + support theme artifact IDs
   - **Priority score**: frequency × severity (1-25 scale)
   - **Suggested next action**: `/ship` (score >15), validate first with `/discovery-validation` (8-15), monitor (<8)

2. Append a `## PRD Candidates` section to the themed feedback report.

3. Do NOT auto-create PRD artifacts — present candidates for human review only.

4. Inform the user: "Run `/ship '[theme name]'` to initiate the PRD pipeline for any candidate you'd like to pursue."

## Quality Checklist
- [ ] Feedback from at least 2 distinct sources is included
- [ ] Themes are mutually exclusive and collectively exhaustive
- [ ] Each theme has frequency count and severity rating
- [ ] Representative quotes are included as evidence
- [ ] Recommendations are specific and actionable, not vague
- [ ] User segments are noted where relevant
- [ ] Artifact passes validation
