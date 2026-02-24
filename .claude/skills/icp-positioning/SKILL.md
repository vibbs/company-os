---
name: icp-positioning
description: Defines ideal customer profile and product positioning. Use when establishing or refining who the product serves and how it is differentiated in the market.
---

# ICP & Positioning

## Reference
- **ID**: S-PROD-01
- **Category**: Product
- **Inputs**: market research, user interviews, competitive landscape, product capabilities
- **Outputs**: ICP document and positioning statement → artifacts/product/
- **Used by**: Product Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose
Produces a clear ideal customer profile (ICP) and positioning statement that align the team on who the product is built for, what problem it solves, and why it wins against alternatives.

## Procedure
1. Gather inputs: market research data, user interview summaries, competitor analysis.
2. Define ICP demographics: company size, industry, role/title, budget range.
3. Define ICP psychographics: pain points, goals, buying triggers, objections.
4. Identify the primary job-to-be-done the product addresses for this ICP.
5. Map the competitive landscape — direct competitors, indirect alternatives, status quo.
6. Draft a positioning statement using the format: For [ICP] who [need], [Product] is a [category] that [key benefit] unlike [alternatives] because [differentiator].
7. Validate positioning against known customer feedback and win/loss data.
8. Save ICP document and positioning statement to `artifacts/product/`.
9. Validate the artifact using `./tools/artifact/validate.sh`.

## Quality Checklist
- [ ] ICP is specific enough to disqualify non-ideal customers
- [ ] Pain points are grounded in real user evidence, not assumptions
- [ ] Competitive landscape includes at least the top 3 alternatives
- [ ] Positioning statement follows the standard format
- [ ] Differentiator is defensible and not easily copied
- [ ] Document links to supporting evidence (interviews, data)
- [ ] Artifact passes validation
