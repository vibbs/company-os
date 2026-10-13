---
name: feedback-synthesizer
description: Turns messy customer feedback into themes with supporting evidence and a ranked pain matrix. Use when consolidating feedback from several sources.
runtimes:
  claude:
    user-invokable: true
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

### Step 12: Produce Pain Matrix (when invoked by GTM Sprint)

When the feedback-synthesizer is called during a GTM Sprint (or explicitly requested), produce an additional **Pain Matrix** section after Step 6:

1. **Build the Matrix Table**

   For each theme from Step 4, score:

   | Theme | Frequency | $$ Impact / Occurrence | Urgency (1-5) | Total Score |
   |-------|-----------|----------------------|---------------|-------------|
   | {theme} | {count} | {estimated $$ or time cost} | {1=someday, 5=hair-on-fire} | frequency x urgency |

   - **$$ Impact**: Extract from interview quotes. Use time-to-money conversion if needed (e.g., "wastes 3 hours/week" at $50/hr = $150/week = $7,800/year)
   - **Urgency**: How soon prospects need a solution (1 = nice to have, 5 = actively searching right now)

2. **Quadrant Classification**

   Classify each theme into a quadrant:
   - **Build Now** (High $$ + High Urgency): immediate opportunity, prioritize in MVP
   - **Build Next** (High $$ + Low Urgency): strong business case but prospects can wait
   - **Quick Win** (Low $$ + High Urgency): small pain but prospects want it solved now
   - **Monitor** (Low $$ + Low Urgency): track but don't prioritize

3. **Quotable Quotes Section**

   For each "Build Now" theme, extract 2-3 direct quotes suitable for:
   - Landing page social proof (above-the-fold pain quotes)
   - Lead magnet content
   - Pitch deck problem slides
   - Sales outreach templates

   Format: `"[Quote]" — {Role}, {Company Size}` (anonymize company name)

4. Append the Pain Matrix, Quadrant Classification, and Quotable Quotes as a `## Pain Matrix` section in the feedback report artifact.

## Quality Checklist
- [ ] Feedback from at least 2 distinct sources is included
- [ ] Themes are mutually exclusive and collectively exhaustive
- [ ] Each theme has frequency count and severity rating
- [ ] Representative quotes are included as evidence
- [ ] Recommendations are specific and actionable, not vague
- [ ] User segments are noted where relevant
- [ ] Pain Matrix includes $$ quantification (when requested)
- [ ] Quotable quotes are anonymized and landing-page-ready (when requested)
- [ ] Artifact passes validation

## Cross-References
- **gtm-sprint** (S-GRO-09) — invokes Pain Matrix output during Day 2 synthesis
- **customer-conversations** (S-PROD-08) — provides CONV- artifacts as input
- **landing-page-copy** (S-GRO-02) — consumes quotable quotes for above-the-fold social proof
- **prd-writer** (S-PROD-02) — PRD candidates from top themes
