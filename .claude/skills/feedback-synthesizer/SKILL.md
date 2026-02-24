---
name: feedback-synthesizer
description: Turns messy, unstructured customer and user feedback into actionable themes with supporting evidence. Use when consolidating feedback from multiple sources into product insights.
---

# Feedback Synthesizer

## Reference
- **ID**: S-PROD-04
- **Category**: Product
- **Inputs**: raw feedback (support tickets, interviews, surveys, reviews, Slack messages)
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

## Quality Checklist
- [ ] Feedback from at least 2 distinct sources is included
- [ ] Themes are mutually exclusive and collectively exhaustive
- [ ] Each theme has frequency count and severity rating
- [ ] Representative quotes are included as evidence
- [ ] Recommendations are specific and actionable, not vague
- [ ] User segments are noted where relevant
- [ ] Artifact passes validation
