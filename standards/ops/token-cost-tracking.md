# Token Cost Tracking Standard

Defines model rates, cost categories, budgets, and attribution rules for tracking AI token costs as COGS.

---

## 1. Model Cost Rates

Rates are per million tokens (MTok). Update when provider pricing changes.

### Anthropic (Claude)

| Model | Input | Output | Cache Write (5m) | Cache Read | Notes |
|-------|-------|--------|-------------------|------------|-------|
| Claude Opus 4.6 | $5.00 | $25.00 | $6.25 | $0.50 | Architecture, routing, complex reasoning |
| Claude Sonnet 4.6 | $3.00 | $15.00 | $3.75 | $0.30 | Standard agent tasks, templates, checklists |
| Claude Haiku 4.5 | $1.00 | $5.00 | $1.25 | $0.10 | Classification, simple extraction, triage |

### OpenAI

| Model | Input | Output | Cached Input | Notes |
|-------|-------|--------|--------------|-------|
| GPT-4o | $2.50 | $10.00 | $1.25 | General-purpose |
| GPT-4o-mini | $0.15 | $0.60 | $0.075 | Fast, cheap tasks |

### Google (Gemini)

| Model | Input | Output | Notes |
|-------|-------|--------|-------|
| Gemini 2.0 Flash | $0.10 | $0.40 | Fast, cheap tasks |
| Gemini 2.5 Pro | $1.25 | $10.00 | Complex tasks |

**Maintenance**: Review quarterly or when providers announce pricing changes. The tool script (`tools/ops/token-ledger.sh`) has a hardcoded subset for auto-calculation; update both when rates change.

---

## 2. Cost Categories

| Category | Description | Examples |
|----------|-------------|----------|
| `ship-flow` | Full `/ship` pipeline execution | PRD generation, RFC drafting, implementation, QA |
| `agent-session` | Direct agent interaction outside ship flow | Code review, architecture discussion, debugging |
| `research` | Exploratory or investigative AI usage | Market research, technical spike, documentation review |
| `ad-hoc` | One-off queries and manual tasks | Quick questions, formatting help, script generation |

### Category Attribution Rules

- **If `/ship` was running**: `ship-flow`
- **If a specific agent was invoked directly**: `agent-session`
- **If exploring options / gathering information**: `research`
- **Everything else**: `ad-hoc`
- **When in doubt**: default to `ad-hoc`

---

## 3. Budget Allocation Framework

### By Company Stage

| Stage | Suggested Monthly Budget | Rationale |
|-------|-------------------------|-----------|
| **idea** | $25 - $50 | Light exploration, occasional PRDs |
| **mvp** | $50 - $200 | Active development, 2-4 ship flows/month |
| **growth** | $200 - $1,000 | Multiple features, concurrent workstreams |
| **scale** | $1,000+ | Heavy automation, dedicated AI workflows |

### Budget Allocation by Category (Reference)

These are guideline ratios for teams planning budget allocation. Solo developers can ignore this — just track total spend against your monthly budget.

| Category | idea/mvp | growth | scale |
|----------|----------|--------|-------|
| ship-flow | 60% | 50% | 40% |
| agent-session | 20% | 25% | 30% |
| research | 15% | 15% | 15% |
| ad-hoc | 5% | 10% | 15% |

---

## 4. Feature Cost Attribution

Tag every ledger entry with a `feature_id` (PRD or RFC ID) to track cost-to-build per feature.

### Rules

1. **Link to PRD**: Use the PRD ID (e.g., `PRD-001`) as the `feature_id`
2. **Multi-entry features**: A single ship flow may generate 5-10 ledger entries across agents
3. **Shared costs**: Research entries without a `feature_id` are overhead — distribute evenly or track separately
4. **Ship flow auto-tag**: Step 7.5 of the ship flow auto-populates the PRD ID

### Feature Cost Report Template

```
Feature: [PRD-ID] [Feature Name]
Total AI Cost: $X.XX
Breakdown:
  - PRD generation  (Product Agent, Sonnet):     $X.XX
  - RFC drafting     (Engineering Agent, Opus):   $X.XX
  - Implementation   (Sub-agents, Sonnet):        $X.XX
  - QA & Testing     (QA Agent, Sonnet):          $X.XX
  - Security Review  (Ops Agent, Sonnet):         $X.XX
  - Launch Assets    (Growth Agent, Sonnet):      $X.XX
```

---

## 5. Alert Thresholds

| Threshold | % of Budget | Action |
|-----------|-------------|--------|
| **Green** | 0 - 50% | On track. No action needed. |
| **Yellow** | 50 - 80% | Monitor closely. Consider deferring non-essential AI usage. |
| **Red** | 80 - 100% | Warning. Review spend by category, defer research/ad-hoc. |
| **Critical** | >100% | Over budget. Immediate review. Consider model downgrades. |

### Projected Spend Alert

Calculate projected end-of-month spend:
```
projected = (current_spend / days_elapsed) * days_in_month
```

Alert if projected spend exceeds budget even if current spend is under threshold.

---

## 6. Cost Optimization Playbook

### Model Selection Guide

| Task Type | Recommended Model | Why |
|-----------|------------------|-----|
| Routing, architecture, conflict resolution | Opus | Needs strongest reasoning |
| PRDs, test plans, checklists, implementation | Sonnet | Template-driven, structured output |
| Classification, tagging, simple extraction | Haiku | Fast, cheap, sufficient quality |

### Prompt Caching

If `cache_read_tokens` is consistently 0 across entries:
- Ensure system prompts and recurring context are structured for caching
- Claude caching saves up to 90% on input tokens for repeated context

### Session Efficiency

- Batch related tasks in a single session to maximize cache hits
- Avoid starting new sessions for follow-up questions
- Use `/ship` for end-to-end work (better caching) vs ad-hoc agent calls

---

## 7. COGS Expansion Guide

The `cogs/` directory supports multiple cost categories. To add a new one:

1. Create a subdirectory: `cogs/<category-name>/`
2. Add a JSONL ledger: `cogs/<category-name>/entries.jsonl`
3. Add a summary card: `cogs/<category-name>/summary.md`
4. Create a tool script: `tools/ops/<category-name>-costs.sh`
5. The top-level `cogs/summary.md` aggregates across all subdirectories

Future categories: `infrastructure/` (hosting, DB), `tooling/` (Sentry, CI), `services/` (Stripe, email).
