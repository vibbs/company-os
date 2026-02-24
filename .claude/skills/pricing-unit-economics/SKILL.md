---
name: pricing-unit-economics
description: Performs CAC/LTV analysis and pricing model validation. Use when setting initial pricing, evaluating pricing changes, or assessing unit economics health.
---

# Pricing & Unit Economics

## Reference
- **ID**: S-FIN-01
- **Category**: Finance
- **Inputs**: revenue data, cost structure, acquisition spend, churn rates, customer segmentation
- **Outputs**: unit economics report → artifacts/finance/
- **Used by**: Ops & Risk Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose
Analyzes customer acquisition cost (CAC), lifetime value (LTV), and related unit economics to validate that the pricing model is sustainable and identify levers for improving profitability.

## Procedure
1. Calculate **CAC**: total acquisition spend / number of new customers acquired, by channel.
2. Calculate **LTV**: average revenue per user (ARPU) * gross margin % * average customer lifetime.
3. Compute the **LTV:CAC ratio** and assess health (target: 3:1 or higher).
4. Calculate **CAC payback period**: CAC / (ARPU * gross margin %).
5. Segment the analysis by customer tier, plan, or cohort to find variation.
6. Review the current pricing model: per-seat, usage-based, flat-rate, freemium.
7. Stress-test pricing assumptions: what happens if churn increases 20%? If ARPU drops 15%?
8. Identify pricing optimization opportunities: upsell paths, plan restructuring, value metric alignment.
9. Produce recommendations with projected financial impact.
10. Save the unit economics report to `artifacts/finance/`.
11. Validate the artifact using `./tools/artifact/validate.sh`.

## Quality Checklist
- [ ] CAC is calculated by channel, not just blended
- [ ] LTV calculation uses gross margin, not revenue
- [ ] LTV:CAC ratio is computed and benchmarked
- [ ] CAC payback period is calculated
- [ ] Analysis is segmented by meaningful cohorts
- [ ] Sensitivity analysis covers key risk scenarios
- [ ] Pricing recommendations are tied to data
- [ ] Artifact passes validation
