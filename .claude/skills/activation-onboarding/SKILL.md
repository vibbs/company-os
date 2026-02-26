---
name: activation-onboarding
description: Designs "aha moment" flows and activation experiments to improve new user onboarding. Use when optimizing the path from sign-up to first value realization.
---

# Activation & Onboarding

## Reference
- **ID**: S-GROW-05
- **Category**: Growth
- **Inputs**: user journey data, sign-up funnel metrics, product analytics, ICP document
- **Outputs**: activation playbook → artifacts/growth/
- **Used by**: Growth Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose
Designs the onboarding experience that guides new users to their "aha moment" as quickly as possible, and defines activation experiments to systematically improve conversion from sign-up to active user.

## Procedure
1. Define the "aha moment": the specific action that correlates with long-term retention.
2. Map the current onboarding flow from sign-up to aha moment, step by step.
3. Identify drop-off points in the funnel using product analytics data.
4. For each drop-off point, hypothesize the friction cause.
5. Design interventions: simplify steps, add guidance, remove unnecessary steps, add progress indicators.
6. Define activation metrics: time-to-value, activation rate, Day 1/7/30 retention.
7. Design 2-3 activation experiments with clear hypotheses and success criteria.
8. Define the experiment execution plan: A/B test setup, sample size, duration.
9. Outline the post-experiment analysis framework.
10. Save the activation playbook to `artifacts/growth/`.
11. Validate the artifact using `./tools/artifact/validate.sh`.

## Progressive Discovery Integration

When the `feature_flags.strategy` in `company.config.yaml` includes progressive discovery (`progressive-discovery` or `full`), coordinate with the Feature Flags skill:

- **Map aha moments to discovery levels**: The aha moment from Step 1 should be the trigger that unlocks Level 1 (Foundations) features
- **Align activation experiments with feature reveals**: A/B tests can test different discovery level thresholds
- **Time-to-value acceleration**: Onboarding interventions should guide users toward the triggers that unlock the next discovery level
- **Feature reveal coordination**: When a user unlocks a new discovery level, trigger the corresponding guided tour (from the User Docs skill)

Discovery levels (from feature-flags skill):
- **Level 0 (Core)**: Always visible — essential product value
- **Level 1 (Foundations)**: Unlocked after aha moment / core flow completion
- **Level 2 (Power)**: Unlocked after proficiency demonstrated
- **Level 3 (Expert)**: Unlocked on request or sustained engagement

## Quality Checklist
- [ ] "Aha moment" is data-backed or has a clear hypothesis
- [ ] Current onboarding flow is mapped end-to-end
- [ ] Drop-off points are identified with data
- [ ] Interventions are specific and actionable
- [ ] Activation metrics are defined with baseline values
- [ ] Experiments have clear hypotheses and success criteria
- [ ] Sample size and duration are calculated
- [ ] Artifact passes validation
