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

## Visual Content Guidance

When producing landing page copy, include guidance for visual elements that complement the text.

### Hero Section Visuals
- **Product screenshot**: Show the product in action (not a generic stock photo). Annotate key features.
- **Video**: 30-60 second demo showing the core value proposition. Autoplay muted with play button.
- **Animation**: Subtle motion showing the product's primary workflow (e.g., drag-and-drop, form submission, dashboard loading).
- Choose ONE primary visual -- don't combine. Screenshot is safest, video converts highest, animation is most engaging.

### Data Visualization
When the landing page includes metrics, social proof, or comparisons:
- **Comparison tables**: Feature comparison with competitors (checkmarks, not paragraphs). Keep to 5-7 rows.
- **Metric callouts**: Large numbers (e.g., "50% faster", "10K+ users") with supporting context. Use 3 metrics max.
- **Before/after**: Side-by-side showing the problem state vs. with-product state.
- **Charts**: Only if data is compelling. Bar charts for comparisons, line charts for growth. Keep simple.

### Presentation & Pitch Deck Guidance
When landing page content is adapted for presentations:
- **Slide framework**: Problem (1-2 slides) -> Solution (1-2 slides) -> Demo (2-3 slides) -> Social Proof (1 slide) -> CTA (1 slide)
- **One idea per slide**: Don't crowd. Large text, minimal bullets.
- **Visual consistency**: Use brand colors, consistent fonts, company logo on every slide.

## Quality Checklist
- [ ] Single clear CTA is consistent throughout the page
- [ ] Hero headline communicates the core value in under 10 words
- [ ] Benefits are outcome-focused, not feature-focused
- [ ] Social proof section has specific, credible proof points
- [ ] FAQ addresses real buyer objections
- [ ] Copy reads at an 8th-grade level or below for clarity
- [ ] SEO metadata is included
- [ ] Hero visual recommendation included (screenshot, video, or animation)
- [ ] Data visualization guidance provided for any metrics/social proof
- [ ] Artifact passes validation
