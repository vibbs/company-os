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

## Quality Checklist
- [ ] "Aha moment" is data-backed or has a clear hypothesis
- [ ] Current onboarding flow is mapped end-to-end
- [ ] Drop-off points are identified with data
- [ ] Interventions are specific and actionable
- [ ] Activation metrics are defined with baseline values
- [ ] Experiments have clear hypotheses and success criteria
- [ ] Sample size and duration are calculated
- [ ] Artifact passes validation
