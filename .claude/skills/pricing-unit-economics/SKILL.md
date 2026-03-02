---
name: pricing-unit-economics
description: Performs CAC/LTV analysis and pricing model validation. Use when setting initial pricing, evaluating pricing changes, or assessing unit economics health.
---

# Pricing & Unit Economics

## Reference
- **ID**: S-RISK-05
- **Category**: Ops & Risk
- **Inputs**: revenue data, cost structure, acquisition spend, churn rates, customer segmentation
- **Outputs**: unit economics report + financial forecast → artifacts/finance/
- **Used by**: Ops & Risk Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose
Analyzes customer acquisition cost (CAC), lifetime value (LTV), and related unit economics to validate that the pricing model is sustainable and identify levers for improving profitability.

## Procedure

### Step 0: Revenue Stage Check

Read `company.stage` from `company.config.yaml`.

**Pre-Revenue Mode** (idea/mvp, 0-10 customers):
1. Value metric selection — what unit of value does the customer pay for?
2. Willingness-to-pay hypothesis via customer conversations
3. Competitive pricing teardown — 3-5 comparable products
4. Initial price range (floor = cost x 3, ceiling = competitor median)
5. Price sensitivity test script for first 10 sales conversations

Skip CAC/LTV/NRR calculations until sufficient data exists. Proceed to full unit economics when monthly revenue exceeds $1K or customer count exceeds 20.

1. Calculate **CAC**: total acquisition spend / number of new customers acquired, by channel.
2. Calculate **LTV**: average revenue per user (ARPU) * gross margin % * average customer lifetime.
3. Compute the **LTV:CAC ratio** and assess health (target: 3:1 or higher).
4. Calculate **CAC payback period**: CAC / (ARPU * gross margin %).
5. Segment the analysis by customer tier, plan, or cohort to find variation.
6. Review the current pricing model: per-seat, usage-based, flat-rate, freemium.
7. Stress-test pricing assumptions: what happens if churn increases 20%? If ARPU drops 15%?
8. Identify pricing optimization opportunities: upsell paths, plan restructuring, value metric alignment.
9. Produce recommendations with projected financial impact.
10. **MRR/ARR Tracking Framework**:
    - Define MRR components: new MRR, expansion MRR, contraction MRR, churned MRR, reactivation MRR.
    - Produce cohort table template: signup month x months-since-signup, tracking retained revenue %.
    - Calculate Net Revenue Retention (NRR): (Starting MRR + Expansion - Contraction - Churn) / Starting MRR.
    - Benchmark: NRR > 100% = healthy growth (expansion > churn), > 120% = excellent.
11. **Financial Forecasting**:
    - Build 3/6/12 month revenue projections using current MRR growth rate.
    - Model three scenarios: Optimistic (1.5x current growth), Base (current growth), Pessimistic (0.5x current growth).
    - Include key assumptions and sensitivity ranges.
    - For each scenario: projected MRR, ARR, customer count, ARPU.
12. **Runway Monitoring**:
    - Calculate monthly burn rate: total monthly expenses (engineering, marketing, infrastructure, operations).
    - Calculate months of runway: current cash / monthly burn rate.
    - Define trigger thresholds:
      - Green: > 18 months runway.
      - Yellow: 12-18 months (start exploring funding).
      - Orange: 6-12 months (actively fundraise).
      - Red: < 6 months (emergency mode: cut costs or close round).
    - Cash-out date projection based on current burn and revenue growth.
13. **Budget Allocation Framework**:
    - Define spending ratios by company stage:
      - **idea/mvp**: 70% engineering, 15% marketing, 10% infra, 5% ops.
      - **growth**: 50% engineering, 25% marketing, 15% infra, 10% ops.
      - **scale**: 40% engineering, 30% marketing, 15% infra, 15% ops.
    - Compare current allocation vs recommended ratios.
    - Flag significant deviations with recommendations.
14. **Investor Reporting Template**:
    - Produce monthly investor update outline:
      1. Key metrics (MRR, growth %, NRR, CAC, LTV:CAC, runway).
      2. Product highlights (shipped features, user feedback themes).
      3. Growth highlights (acquisition channels, activation rate).
      4. Challenges & risks (what's not working, market shifts).
      5. Asks (specific help needed from investors: intros, hiring, advice).
    - Reference the template at `standards/ops/investor-reporting-template.md`.
15. Save the unit economics report to `artifacts/finance/`.
16. Validate the artifact using `./tools/artifact/validate.sh`.

## Quality Checklist
- [ ] CAC is calculated by channel, not just blended
- [ ] LTV calculation uses gross margin, not revenue
- [ ] LTV:CAC ratio is computed and benchmarked
- [ ] CAC payback period is calculated
- [ ] Analysis is segmented by meaningful cohorts
- [ ] Sensitivity analysis covers key risk scenarios
- [ ] Pricing recommendations are tied to data
- [ ] MRR decomposition (new, expansion, contraction, churn) is present
- [ ] NRR is calculated and benchmarked
- [ ] Financial forecast covers at least 3 scenarios
- [ ] Runway is calculated with traffic-light classification
- [ ] Budget allocation compared to stage-appropriate ratios
- [ ] Investor update template is referenced
- [ ] Artifact passes validation
