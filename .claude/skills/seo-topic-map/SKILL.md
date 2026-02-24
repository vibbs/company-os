---
name: seo-topic-map
description: Builds keyword clusters and internal linking strategy for content-led SEO growth. Use when planning content strategy or optimizing site architecture for organic search.
---

# SEO Topic Map

## Reference
- **ID**: S-GROW-03
- **Category**: Growth
- **Inputs**: ICP document, product capabilities, competitor content, keyword research data
- **Outputs**: SEO topic map and linking strategy → artifacts/growth/
- **Used by**: Growth Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose
Creates a structured topic map that organizes target keywords into clusters around pillar pages, defines internal linking relationships, and prioritizes content creation based on search volume, difficulty, and business relevance.

## Procedure
1. Review the ICP document to understand what the target audience searches for.
2. Conduct keyword research: seed keywords from product capabilities and pain points.
3. Group keywords into topic clusters around 4-6 pillar themes.
4. For each pillar, identify: pillar page keyword, cluster page keywords, long-tail variations.
5. Assess each keyword: search volume, keyword difficulty, business relevance (1-5).
6. Prioritize clusters by combined score: volume * relevance / difficulty.
7. Design the internal linking architecture: pillar → cluster → supporting pages.
8. Identify content gaps: high-value keywords with no existing content.
9. Create a content calendar with publishing priorities.
10. Save the topic map to `artifacts/growth/`.
11. Validate the artifact using `./tools/artifact/validate.sh`.

## Quality Checklist
- [ ] At least 4 pillar themes are defined
- [ ] Each pillar has 5+ cluster keywords
- [ ] Keywords have volume, difficulty, and relevance scores
- [ ] Internal linking hierarchy is clearly defined
- [ ] Content gaps are identified and prioritized
- [ ] Topic clusters align with ICP pain points and search intent
- [ ] Content calendar has realistic publishing cadence
- [ ] Artifact passes validation
