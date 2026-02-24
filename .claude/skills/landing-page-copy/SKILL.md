---
name: landing-page-copy
description: Generates conversion-focused landing page copy organized by sections. Use when creating or optimizing landing pages for product launches, features, or campaigns.
---

# Landing Page Copy

## Reference
- **ID**: S-GROW-02
- **Category**: Growth
- **Inputs**: messaging framework, ICP document, campaign goals, CTA targets
- **Outputs**: landing page copy document → artifacts/growth/
- **Used by**: Growth Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose
Produces conversion-optimized landing page copy organized into standard sections (hero, benefits, social proof, CTA) that communicates value clearly and drives the target action.

## Procedure
1. Review the messaging framework and ICP document for voice, value props, and differentiators.
2. Define the page goal: what is the single desired action (sign up, book demo, start trial)?
3. Write the **hero section**: headline, subheadline, primary CTA, and hero image/video guidance.
4. Write the **problem section**: articulate the pain the visitor feels.
5. Write the **solution section**: how the product solves the pain, with key features.
6. Write the **benefits section**: 3-4 benefit blocks with headlines and supporting copy.
7. Write the **social proof section**: testimonial slots, logo bar guidance, metrics.
8. Write the **FAQ section**: 4-6 common objections reframed as questions with answers.
9. Write the **final CTA section**: urgency/scarcity framing and closing CTA.
10. Add SEO metadata: page title, meta description, target keyword.
11. Save the copy document to `artifacts/growth/`.
12. Validate the artifact using `./tools/artifact/validate.sh`.

## Quality Checklist
- [ ] Single clear CTA is consistent throughout the page
- [ ] Hero headline communicates the core value in under 10 words
- [ ] Benefits are outcome-focused, not feature-focused
- [ ] Social proof section has specific, credible proof points
- [ ] FAQ addresses real buyer objections
- [ ] Copy reads at an 8th-grade level or below for clarity
- [ ] SEO metadata is included
- [ ] Artifact passes validation
