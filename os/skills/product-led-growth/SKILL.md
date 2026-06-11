---
name: product-led-growth
description: Designs product-led growth mechanics — free tier structure, viral loops, referral programs, and in-product growth moments. Use when building self-serve acquisition and expansion.
user-invokable: true
---

# Product-Led Growth

## Reference
- **ID**: S-GRO-08
- **Category**: Growth
- **Inputs**: company.config.yaml, ICP artifact, pricing model
- **Outputs**: PLG strategy document → artifacts/growth/
- **Used by**: Growth Agent, User (directly)
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose

Design the product mechanics that turn users into acquisition channels. Covers free tier design, viral loops, referral programs, and in-product growth moments.

## Procedure

### Step 1: Product Context
Read `company.config.yaml` for:
- Product type (B2B SaaS, B2C, marketplace, developer tool)
- Pricing model (freemium, free trial, open core, usage-based)
- Current stage (idea/mvp/growth/scale)

Read ICP artifact from `artifacts/product/` if available.

### Step 2: Free Tier / Trial Design
Based on product type:

**Freemium Model:**
- What's free forever (must deliver real value — enough to create habit)
- What's gated (features that scale with business value)
- Upgrade trigger (the moment free users hit the ceiling)
- Anti-patterns to avoid: free tier too generous (no upgrade incentive), free tier too stingy (no habit formation)

**Free Trial Model:**
- Trial duration recommendation (7 days for simple products, 14-30 for complex)
- Trial experience (full product vs limited)
- Conversion triggers during trial
- End-of-trial flow (what happens when trial expires)

### Step 3: Viral Loop Design
Identify natural sharing moments in the product:
- **Output sharing**: Can users share what they create? (reports, dashboards, content)
- **Collaboration**: Does the product improve with more users? (team features, shared workspaces)
- **Social proof**: Can usage be visible to non-users? (badges, public profiles, "powered by")
- **Network effects**: Does the product become more valuable as more people use it?

For each loop identified:
- Trigger: What prompts sharing?
- Channel: Where does sharing happen?
- Incentive: Why would someone click the shared link?
- Activation: How does the new user reach value quickly?

### Step 4: Referral Program Design
If appropriate for the product:
1. **Incentive structure**: What does the referrer get? What does the referred get?
   - Two-sided incentives outperform one-sided
   - Match incentive to product value (credits > cash for SaaS)
2. **Mechanics**: Link generation, tracking, reward fulfillment
3. **Placement**: Where in the product to surface referral prompts
   - After positive moments (successful outcome, milestone reached)
   - NOT during onboarding or when user is frustrated
4. **Anti-fraud**: Basic protections (email verification, usage threshold before referral eligibility)

### Step 5: In-Product Growth Moments
Map the user journey and identify growth insertion points:
- **After aha moment**: "Share this with your team?"
- **After milestone**: "You've completed X — invite others to try"
- **During collaboration**: "This works better with teammates"
- **At upgrade boundary**: "Unlock [feature] to continue growing"

Design each moment to feel natural, not interruptive.

### Step 6: PLG Metrics
Define measurement framework:
- **Viral coefficient** (K-factor): invites sent x conversion rate
- **Referral conversion rate**: referred signups / referral links clicked
- **Time-to-invite**: how long before a user invites someone
- **Free-to-paid conversion**: % of free users who upgrade
- **Expansion revenue**: % of revenue from existing customers upgrading

### Step 7: Instrumentation Spec
Produce event tracking requirements for PLG mechanics:
- Referral link generated / clicked / converted
- Share button clicked / share completed
- Viral loop entry / activation / retention
- Upgrade prompt shown / clicked / converted
- Feed these to the instrumentation skill for implementation

### Step 8: Save Artifact
Save PLG strategy to `artifacts/growth/PLG-{feature-or-product}.md` with frontmatter:
- type: launch-brief (or use parent growth artifact type)
- Link to ICP and pricing artifacts if they exist
- Validate with `./tools/artifact/validate.sh`

## Quality Checklist
- [ ] Product context and pricing model analyzed
- [ ] Free tier/trial designed with clear upgrade trigger
- [ ] At least one viral loop identified and designed
- [ ] Referral program designed (if appropriate)
- [ ] Growth moments mapped to user journey
- [ ] PLG metrics defined
- [ ] Instrumentation spec produced
- [ ] Artifact saved and validated
