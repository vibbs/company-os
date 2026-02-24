---
name: positioning-messaging
description: Crafts a crisp product narrative and competitive differentiators for go-to-market materials. Use when defining or refreshing the product story for marketing and sales.
---

# Positioning & Messaging

## Reference
- **ID**: S-GROW-01
- **Category**: Growth
- **Inputs**: ICP document, competitive landscape, product capabilities, customer testimonials
- **Outputs**: messaging framework document → artifacts/growth/
- **Used by**: Growth Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose
Produces a messaging framework that articulates the product narrative, value propositions, and competitive differentiators in language that resonates with the target audience across all go-to-market channels.

## Procedure
1. Review the ICP document and positioning statement from Product.
2. Identify the top 3 value propositions the product delivers to the ICP.
3. For each value proposition, write a headline, supporting statement, and proof point.
4. Define the competitive differentiators: what the product does that alternatives cannot.
5. Craft the product narrative arc: problem → failed alternatives → our approach → outcome.
6. Write messaging variants for different channels: website, email, sales deck, social.
7. Define tone and voice guidelines specific to the brand.
8. Test messaging against common buyer objections and refine.
9. Save the messaging framework to `artifacts/growth/`.
10. Validate the artifact using `./tools/artifact/validate.sh`.

## Quality Checklist
- [ ] Value propositions are specific and benefit-oriented, not feature-focused
- [ ] Differentiators are defensible and evidence-backed
- [ ] Narrative arc follows problem → solution → outcome structure
- [ ] Channel-specific variants are provided
- [ ] Tone and voice are consistent throughout
- [ ] Common objections are addressed in the messaging
- [ ] Messaging aligns with the ICP document
- [ ] Artifact passes validation
