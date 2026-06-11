---
name: positioning-messaging
description: Crafts a crisp product narrative and competitive differentiators for go-to-market materials. Use when defining or refreshing the product story for marketing and sales.
---

# Positioning & Messaging

## Reference
- **ID**: S-GRO-01
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

## Brand Identity Extension

When producing positioning and messaging, extend into full brand identity to ensure consistent brand expression across all touchpoints.

**Brand Identity Extension** — Steps 8-11 below are Growth/Scale deliverables. At idea/mvp stage, complete Steps 1-7 (core positioning) and run `/design-system` for visual tokens. Skip brand guidelines, voice documentation, and style guide until you have a designer or reach growth stage.

### Step 8: Brand Voice Matrix

Define the brand voice on 4 dimensions with specific examples:

| Dimension | Our Position | Do | Don't |
|-----------|-------------|-----|-------|
| **Formal <-> Casual** | [e.g., "Professional but approachable"] | [Example phrase] | [Counter-example] |
| **Serious <-> Playful** | [e.g., "Confident with occasional wit"] | [Example phrase] | [Counter-example] |
| **Respectful <-> Irreverent** | [e.g., "Respectful of user time"] | [Example phrase] | [Counter-example] |
| **Matter-of-fact <-> Enthusiastic** | [e.g., "Understated confidence"] | [Example phrase] | [Counter-example] |

### Step 9: Brand Personality Traits

Define 3-5 personality adjectives with behavioral examples:

For each trait, define how the product "acts" across states:
- **Success states**: How we celebrate with the user
- **Error states**: How we communicate problems
- **Empty states**: How we guide toward first action
- **Onboarding**: How we introduce ourselves
- **Loading/waiting**: How we fill time

Example:
> **Trait: Confident** — Success: "Done. Your changes are live." (not "Yay! We did it!"). Error: "Something went wrong. Here's what to do." (not "Oops!"). Empty: "Start here." (not "Looks like there's nothing here yet :(").

### Step 10: Cross-Platform Brand Harmonization

Define how brand voice adapts (not changes) across touchpoints:

| Touchpoint | Voice Adaptation | Formality | Personality Dial |
|-----------|-----------------|-----------|-----------------|
| **Product UI** | Concise, action-oriented | Medium | Trait emphasis: helpful, clear |
| **Marketing site** | Benefit-focused, persuasive | Medium-low | Trait emphasis: confident, aspirational |
| **Email** | Personal, direct | Low-medium | Trait emphasis: helpful, warm |
| **Social media** | Platform-native, conversational | Low | Trait emphasis: witty, engaging |
| **Documentation** | Precise, educational | Medium-high | Trait emphasis: clear, thorough |
| **Support** | Empathetic, solution-focused | Medium | Trait emphasis: helpful, patient |

### Step 11: Brand Asset Guidelines

Document brand asset usage rules:
1. **Logo usage**: Primary mark, icon-only, wordmark-only, minimum size, clear space
2. **Color application**: Primary, secondary, accent colors + when each is used
3. **Typography hierarchy**: Display, heading, body, caption with specific fonts/sizes
4. **Imagery style**: Photography vs illustration vs abstract, mood/tone guidelines
5. **Iconography**: Style (outlined, filled, duotone), consistent stroke weight, grid alignment

## Quality Checklist
- [ ] Value propositions are specific and benefit-oriented, not feature-focused
- [ ] Differentiators are defensible and evidence-backed
- [ ] Narrative arc follows problem → solution → outcome structure
- [ ] Channel-specific variants are provided
- [ ] Tone and voice are consistent throughout
- [ ] Common objections are addressed in the messaging
- [ ] Messaging aligns with the ICP document
- [ ] Brand voice matrix defines 4 dimensions with do/don't examples
- [ ] Brand personality traits have behavioral examples across product states
- [ ] Cross-platform harmonization table covers all touchpoints
- [ ] Brand asset guidelines cover logo, color, typography, imagery
- [ ] Artifact passes validation
