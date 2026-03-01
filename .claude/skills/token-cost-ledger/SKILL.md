---
name: token-cost-ledger
description: Tracks AI token usage and costs as COGS. Logs entries, generates reports, monitors budget, shows per-feature cost. Use when reviewing AI spend, logging session costs, or checking budget status.
user-invokable: true
argument-hint: "log | report | budget-check | feature-cost"
---

# Token Cost Ledger

## Reference
- **ID**: S-OPS-08
- **Category**: Ops & Risk
- **Inputs**: token usage data, company.config.yaml (ai.cost_budget_monthly, ai.cost_tracking_enabled, ai.cost_alert_threshold_percent)
- **Outputs**: ledger entries in `cogs/ai-ledger/entries.jsonl`, summary in `cogs/ai-ledger/summary.md`
- **Used by**: Ops & Risk Agent, Orchestrator Agent (post-ship advisory)
- **Tool scripts**: `./tools/ops/token-ledger.sh`

## Purpose

Track AI token consumption and costs as Cost of Goods Sold (COGS). Provides a lightweight, git-trackable cost accounting system for solo developers using AI agents. Supports logging individual entries, generating period summaries, showing per-feature cost breakdowns, monitoring budget health, and exporting data for financial reporting.

## When to Use

- After completing a ship flow or significant AI-assisted work session
- When reviewing monthly AI spend against budget
- When preparing investor updates or financial reports (feeds into pricing-unit-economics)
- When deciding whether to use Opus vs Sonnet for a task (cost awareness)
- When company.stage transitions (budgets should be reassessed)

## Procedure

### Step 1: Check Configuration

Read `company.config.yaml` and extract:
- `ai.cost_budget_monthly` — monthly spend cap
- `ai.cost_tracking_enabled` — whether tracking is active (default: true if budget is set)
- `ai.cost_alert_threshold_percent` — warning threshold (default: 80)

If `ai.cost_budget_monthly` is empty, suggest the user set a budget with guidance by stage:
- **idea**: $25-50/month (exploration, light usage)
- **mvp**: $50-200/month (active development, ship flows)
- **growth**: $200-1000/month (multiple features, more agent usage)
- **scale**: $1000+/month (heavy automation, multiple concurrent flows)

### Step 2: Subcommand Routing

#### Subcommand: `log`

Log a token cost entry:

```bash
./tools/ops/token-ledger.sh log \
  --model "claude-sonnet-4-20250514" \
  --input-tokens 12500 \
  --output-tokens 3200 \
  --cache-read 8000 \
  --cache-write 1500 \
  --agent engineering \
  --category ship-flow \
  --feature PRD-001 \
  --session "ship-user-auth-20260301" \
  --notes "RFC generation for user auth"
```

If the user provides raw numbers from their session, help them fill in the fields. Cost is auto-calculated from the model rates in `standards/ops/token-cost-tracking.md` when not provided via `--cost`.

After logging, the tool shows budget impact:
```
Entry logged: $0.08
  Budget: $13.82 / $100.00 (13.8%)
```

#### Subcommand: `report`

Generate a cost report:

```bash
./tools/ops/token-ledger.sh summary --period monthly
```

Present the results with analysis:
1. Total spend by category (ship-flow, agent-session, research, ad-hoc)
2. Total spend by model (which models are costing the most)
3. Total spend by agent (which agents are most expensive)
4. Budget health with color coding

Also regenerates `cogs/ai-ledger/summary.md` for human review.

If the user has investor reporting set up, note that token costs feed into the infrastructure cost line item in `standards/ops/investor-reporting-template.md`.

#### Subcommand: `budget-check`

Quick budget health check:

```bash
./tools/ops/token-ledger.sh budget
```

Present results:
- Current month spend vs budget
- Projected end-of-month spend (based on daily average)
- Recommendation: stay the course / reduce usage / increase budget

#### Subcommand: `feature-cost`

Show total cost of building a specific feature:

```bash
./tools/ops/token-ledger.sh feature-cost PRD-001
```

Present the feature cost report:
- Total cost with entry count
- Breakdown by agent (who spent what)
- Breakdown by phase (ship-flow, research, etc.)
- Timeline showing each entry chronologically

This is the key command for understanding "how much did this feature cost to build?"

### Step 3: Cost Optimization Suggestions

Based on the report data, suggest optimizations:
- **Model downgrade**: If Opus is used for template-driven tasks, suggest Sonnet
- **Cache utilization**: If cache_read_tokens is consistently 0, suggest enabling prompt caching
- **Category rebalancing**: If research spend exceeds ship-flow spend, suggest more focused sessions
- **Budget adjustment**: If consistently under 50% budget, suggest reducing to free up capital

Refer to the full optimization playbook in `standards/ops/token-cost-tracking.md`.

### Step 4: Cross-Reference with Unit Economics

When generating reports, if artifacts exist in `artifacts/finance/`, note how AI COGS relates to:
- Gross margin (AI costs reduce margin)
- CAC (AI-assisted customer acquisition costs)
- Infrastructure costs in the investor template

## Cross-References

- **pricing-unit-economics** — consumes AI cost data for infrastructure cost calculations
- **ship** — advisory integration at Step 7.5 (suggest logging session cost after release)
- **investor-reporting-template** — AI COGS feeds into burn rate reporting

## Quality Checklist

- [ ] company.config.yaml was read for budget and tracking config
- [ ] Ledger entry has all required fields (timestamp, model, tokens, cost, category)
- [ ] Cost calculation matches model rate table (if auto-calculated)
- [ ] Budget status uses color coding (green/yellow/red)
- [ ] Summary report regenerates `cogs/ai-ledger/summary.md`
- [ ] Empty ledger is handled gracefully
- [ ] Feature ID is tagged when applicable (especially during ship flows)
- [ ] Cross-reference to unit economics noted when applicable
