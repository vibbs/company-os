---
name: prd-writer
description: Generates consistent PRDs with problem statements, acceptance criteria, success metrics, and scope boundaries. Use when creating or updating product requirements for any feature.
allowed-tools: Read, Grep, Glob, Bash, Write
---

# PRD Writer

## Reference
- **ID**: S-PROD-02
- **Category**: Product
- **Inputs**: objective, ICP doc, user feedback, market signals, company.config.yaml
- **Outputs**: PRD artifact → artifacts/prds/
- **Used by**: Product Agent
- **Tool scripts**: ./tools/artifact/validate.sh, ./tools/analytics/query-metrics.sh

For the PRD artifact template, see [prd-template.md](prd-template.md).

## Purpose

Produce a structured, actionable Product Requirements Document that clearly communicates the "what" and "why" of a feature. The PRD is the entry point for the entire delivery pipeline — Engineering, QA, Growth, and Ops all consume it.

## When to Use

- New feature request from user or stakeholder
- Significant enhancement to existing functionality
- Any work that requires Engineering to produce an RFC

## PRD Writing Procedure

### Step 1: Understand the Problem

Before writing anything, answer these questions:

1. **Who has this problem?** — Reference ICP or describe the target user
2. **What is the problem?** — Specific pain, not vague dissatisfaction
3. **How do they solve it today?** — Current workaround or competitor solution
4. **Why solve it now?** — What's changed that makes this urgent
5. **What happens if we don't?** — Cost of inaction

If you can't answer all 5, the problem isn't well-defined enough. Go back to discovery.

### Step 2: Define Success

Define 2-4 measurable success metrics. Each metric must have:
- **Metric name**: what you're measuring
- **Current baseline**: where it is today (or "N/A - new")
- **Target**: where it should be after launch
- **Measurement method**: how you'll know (analytics event, query, manual check)

Examples:
- "Activation rate increases from 30% to 45% within 30 days of launch"
- "Support tickets for X decrease by 50% within 2 weeks"
- "Feature adoption: 60% of active users try the feature within first week"

### Step 3: Write Acceptance Criteria

Acceptance criteria are the contract between Product and Engineering. They define "done."

Rules for good acceptance criteria:
- **Specific**: "User can filter by date range" not "User can filter"
- **Testable**: QA must be able to write a test case from it
- **Independent**: Each criterion stands alone
- **Boundary-aware**: Include edge cases ("Works with 0 items", "Handles 10,000 items")

Format each criterion as:
```
AC-[number]: [Given/When/Then or imperative statement]
```

### Step 4: Define Scope Boundaries

Explicitly state what's IN and OUT. Scope boundaries prevent creep. Be aggressive about "out of scope."

### Step 5: Consider Dependencies and Risks

- **Technical dependencies**: APIs, services, data that must exist
- **Business dependencies**: Pricing decisions, legal approval, partnerships
- **Risks**: What could go wrong, likelihood, mitigation
- **Tech stack fit**: Does this work well with the configured stack in `company.config.yaml`? Flag concerns.

### Step 6: Assemble the PRD

Use the template in [prd-template.md](prd-template.md).

### Step 7: Validate

Before marking the PRD as ready for review:

- [ ] Problem statement is specific (not "users want better UX")
- [ ] Success metrics are measurable with baselines and targets
- [ ] Every acceptance criterion is testable by QA
- [ ] Scope boundaries are explicit (IN and OUT listed)
- [ ] Open questions have owners and deadlines
- [ ] Dependencies are identified
- [ ] Tech stack compatibility considered (checked company.config.yaml)
- [ ] Run `./tools/artifact/validate.sh` on the artifact

### Step 8: Handoff

1. Set status to `review`
2. Store in `artifacts/prds/`
3. Notify Orchestrator that PRD is ready for Engineering to consume
4. Engineering Agent will use this PRD as input for architecture-draft

## Anti-Patterns to Avoid

- **Solution masquerading as a problem**: "We need a dropdown" is a solution. The problem is "users can't find items quickly."
- **Vague success metrics**: "Improve user experience" is not measurable. Pick a specific metric.
- **Missing edge cases in AC**: Always consider: empty state, max limits, error states, unauthorized access
- **Scope creep in "In Scope"**: If the in-scope list has more than 5-7 items, it's too big. Cut.
- **No "Out of Scope"**: If nothing is out of scope, you haven't made hard decisions yet.

## Quality Checklist

- [ ] Problem is validated (not assumed)
- [ ] Success metrics are SMART (Specific, Measurable, Achievable, Relevant, Time-bound)
- [ ] Acceptance criteria are testable
- [ ] Scope is bounded with explicit cuts
- [ ] Dependencies and risks documented
- [ ] Artifact frontmatter is complete and valid
- [ ] Ready for Engineering handoff
