---
name: experiment-framework
description: Designs statistically rigorous A/B experiments with sample size calculation, guardrail metrics, and results analysis. Use when planning experiments, validating feature impact, or analyzing test results.
---

# Experiment Framework

## Reference
- **ID**: S-QA-08
- **Category**: QA / Experimentation
- **Inputs**: PRD (success metrics), feature flag spec, analytics config, baseline conversion rates
- **Outputs**: experiment spec → artifacts/experiments/, experiment results → artifacts/experiments/
- **Used by**: QA & Release Agent
- **Tool scripts**: ./tools/artifact/validate.sh, ./tools/qa/experiment-report.sh

## Purpose

Bring statistical rigor to product experiments. Most teams "ship and see" -- they launch a feature, watch a dashboard, and declare victory if a metric goes up. This leads to false conclusions, wasted engineering time, and product decisions driven by noise rather than signal. The experiment framework ensures every test has a clear hypothesis, proper sample size, controlled execution, and structured analysis.

Move beyond intuition-driven development to hypothesis-driven development. Every experiment answers a specific question with a quantified answer. When a feature "wins," you know the effect size, the confidence level, and whether it came at the cost of degrading something else. When a feature "loses," you learn something concrete rather than wondering if you just didn't run the test long enough.

## When to Use

- Planning an A/B test for a new feature
- Validating whether a change actually improves metrics
- Feature flag strategy is `full` or feature uses experiment-type flags
- Product Agent defines success metrics that need causal validation
- Activation experiments from activation-onboarding skill need statistical design

## Experiment Framework Procedure

### Step 0.5: Traffic Feasibility Check

Before designing any experiment:
1. If `analytics.provider` is configured, estimate current DAU from available data
2. Calculate minimum feasible MDE (Minimum Detectable Effect) given traffic and 90-day max duration
3. If DAU < 1,000: recommend qualitative validation (user interviews via discovery-validation, customer-conversations) over quantitative experiments
4. Flag explicitly: "Quantitative experiments require N users over M days for statistical significance. Current traffic may not support this."
5. For low-traffic products, suggest: fake door tests, concierge tests, or Wizard of Oz experiments as alternatives

### Step 1: Load Context

Before designing any experiment:

1. **Read `company.config.yaml`** -- extract `experiments.*`, `analytics.*`, `feature_flags.*`
2. **Read the PRD success metrics** -- these become the primary metrics for experiments
3. **Read existing experiment specs** in `artifacts/experiments/` for naming conventions and precedent
4. **Read the feature flag spec** if one exists (experiment flags from feature-flags skill)

### Step 2: Define Hypothesis

1. State the hypothesis clearly: "We believe [change] will [improve/reduce] [metric] because [reason]"
2. Define the null hypothesis: "The change has no effect on [metric]"
3. Define primary metric (one metric to make the ship/no-ship decision)
4. Define secondary metrics (additional metrics to understand the full picture)
5. Define guardrail metrics (metrics that must NOT degrade -- e.g., error rate, page load time, revenue)

### Step 3: Calculate Sample Size

1. Determine baseline conversion rate (from analytics or estimation)
2. Set minimum detectable effect (MDE) -- the smallest improvement worth detecting (typically 5-20% relative)
3. Set statistical significance level (alpha) -- default from `experiments.default_significance` or 0.95
4. Set statistical power (1-beta) -- typically 0.80
5. Calculate required sample size per variant using the formula:
   - For proportions: n = (Z_alpha/2 + Z_beta)^2 x (p1(1-p1) + p2(1-p2)) / (p1 - p2)^2
   - Provide a simplified lookup table for common scenarios
6. Account for multiple variants (Bonferroni correction if >2 variants)

**Sample Size Lookup Table** (two-sided test, alpha=0.05, power=0.80):

| Baseline Rate | MDE (relative) | Sample Size per Variant |
|--------------|-----------------|------------------------|
| 1% | 20% | ~130,000 |
| 5% | 10% | ~30,000 |
| 10% | 10% | ~14,000 |
| 20% | 10% | ~6,400 |
| 50% | 5% | ~6,400 |

For custom calculations, use the full formula or reference an online sample size calculator. Always round UP to the nearest hundred.

### Step 4: Estimate Duration

1. Calculate daily eligible traffic (users who enter the experiment)
2. Duration = (sample_size_per_variant x num_variants) / daily_traffic
3. Add buffer for weekday/weekend variation (multiply by 1.2)
4. Minimum duration: 7 days (to capture weekly cycles)
5. Maximum recommended: 90 days (if longer, the MDE is too small or traffic too low -- reconsider)
6. If duration exceeds `experiments.max_concurrent` capacity, flag scheduling conflict

### Step 5: Design Experiment Spec

Produce an experiment specification artifact:

```yaml
---
id: EXP-XXX
type: experiment
status: draft
parent: PRD-XXX
depends_on: [RFC-XXX]
---
```

Include:
- Hypothesis (from Step 2)
- Primary metric + baseline + MDE
- Secondary metrics
- Guardrail metrics with thresholds
- Sample size per variant
- Estimated duration
- Variant descriptions (control = current, treatment = change)
- Feature flag name (links to feature-flags skill output)
- Assignment method (random, hash-based, segment-based)
- Exclusion criteria (new users only, specific segments, etc.)

### Step 6: Define Experiment State Machine

Every experiment follows this lifecycle:

```
draft -> approved -> running -> analyzing -> concluded -> archived
```

| State | Entry Criteria | Exit Criteria | Who Owns |
|-------|---------------|---------------|----------|
| draft | Hypothesis + metrics defined | Spec reviewed by Product + Engineering | QA |
| approved | Spec reviewed, sample size validated | Feature flag configured, tracking verified | QA |
| running | Flag activated, users being assigned | Duration elapsed OR early termination triggered | QA + Engineering |
| analyzing | Experiment stopped, data collected | Analysis complete, recommendation made | QA |
| concluded | Decision made (ship/no-ship/iterate) | Flag cleaned up, code path removed or made permanent | Engineering |
| archived | Learnings documented | -- | Product |

### Step 7: Define Early Termination Rules

- **Harm detected**: If guardrail metric degrades >20% relative to control, stop immediately
- **Clear winner**: If primary metric shows >99% probability of being better (sequential testing), can stop early
- **No-effect**: If 80% of planned duration has passed and effect size is <0.5x MDE, consider stopping (likely underpowered for this effect)
- **Technical issues**: Assignment imbalance >5%, tracking failures >10%, stop and investigate

### Step 8: Define Analysis Plan

1. When to analyze: only after planned duration OR early termination trigger
2. NEVER peek at results before planned duration (peeking inflates false positive rate)
3. Statistical test:
   - For proportions: two-proportion z-test or chi-squared test
   - For continuous metrics: Welch's t-test or Mann-Whitney U
   - For duration/time metrics: log-transform then t-test
4. Report: effect size, confidence interval, p-value, practical significance
5. Segmentation analysis: check if effect varies by user segment (new vs returning, plan tier, geography)
6. Guardrail check: verify no guardrail metric degraded significantly

### Step 9: Anti-Patterns

Document these to prevent common mistakes:

- **Peeking**: Checking results daily and stopping when "significant" -- inflates false positives to >20%
- **Multiple testing**: Testing 5 metrics without correction -- one will be "significant" by chance
- **Survivorship bias**: Only analyzing users who completed the flow, ignoring drop-offs
- **Underpowered**: Running experiments too short because "we need to move fast"
- **History effects**: External events (holidays, marketing campaigns) contaminating results
- **Novelty effects**: Short-term engagement bump from any change, not real improvement

### Step 10: Validate and Save

1. Save experiment spec to `artifacts/experiments/`
2. Run `./tools/artifact/validate.sh` to verify frontmatter
3. Link to parent PRD and RFC via `./tools/artifact/link.sh`

## Quality Checklist

- [ ] Hypothesis is clear and falsifiable
- [ ] Primary metric is defined with baseline rate
- [ ] MDE is specified and justified
- [ ] Sample size is calculated (not guessed)
- [ ] Duration is estimated with weekly cycle buffer
- [ ] Guardrail metrics are defined with degradation thresholds
- [ ] Early termination rules are documented
- [ ] Analysis plan specifies exact statistical test
- [ ] Anti-patterns section is included
- [ ] Experiment spec has valid artifact frontmatter

## Cross-References

- **feature-flags** skill: Experiment-type flags from the feature-flags skill should have a corresponding experiment spec from this skill. The flag controls assignment; this skill designs the experiment.
- **activation-onboarding** skill: Activation experiments designed in the activation skill should use this framework for statistical rigor.
- **instrumentation** skill: Event tracking must be in place before an experiment can run. Verify tracking with the instrumentation skill's event taxonomy.
