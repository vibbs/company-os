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

## Pillar Content Strategy Extension

When producing topic maps, extend into pillar content architecture to create a content structure that maximizes SEO authority.

### Step 12: Define Pillar Pages

For each keyword cluster identified in the topic map, define a pillar page:

1. **Pillar page structure**: Long-form (3000-5000 words), comprehensive, regularly updated. Covers the cluster topic broadly with links to detailed cluster pages.

2. **Pillar-cluster linking model**:
```
Pillar Page: "Complete Guide to [Topic]"
├── Cluster Page: "[Subtopic 1] Guide"
├── Cluster Page: "[Subtopic 2] Best Practices"
├── Cluster Page: "How to [Subtopic 3]"
├── Cluster Page: "[Subtopic 4] vs [Alternative]"
└── Cluster Page: "[Subtopic 5] Examples"
```

Each cluster page links back to the pillar. The pillar links to all clusters. This creates a topical authority signal for search engines.

3. **Pillar page requirements**:
   - Target the head keyword for the cluster (highest volume)
   - Include a table of contents with jump links
   - Answer the top 5-10 "People Also Ask" questions
   - Include original data, statistics, or insights where possible
   - Update quarterly to maintain freshness

### Step 13: Content Multiplication Plan

For each pillar page, define derivative content:

| Derivative | Format | Purpose | Cadence |
|-----------|--------|---------|---------|
| Blog summary | 500-800 words | Drive traffic to pillar | On pillar publish |
| Social posts (3-5) | Platform-specific | Drive awareness + traffic | Spread across 1 week |
| Newsletter excerpt | 200-300 words | Drive email traffic | Next newsletter issue |
| Video script | 3-5 min talking points | YouTube/Loom content | Within 2 weeks |
| Community post | Value-first summary | Reddit/HN distribution | 1-2 days after publish |

This table feeds directly into the content-engine skill for editorial calendar planning.

## Quality Checklist
- [ ] At least 4 pillar themes are defined
- [ ] Each pillar has 5+ cluster keywords
- [ ] Keywords have volume, difficulty, and relevance scores
- [ ] Internal linking hierarchy is clearly defined
- [ ] Content gaps are identified and prioritized
- [ ] Topic clusters align with ICP pain points and search intent
- [ ] Content calendar has realistic publishing cadence
- [ ] Each keyword cluster has a defined pillar page
- [ ] Pillar-cluster linking model is documented
- [ ] Content multiplication plan exists for each pillar
- [ ] Artifact passes validation
