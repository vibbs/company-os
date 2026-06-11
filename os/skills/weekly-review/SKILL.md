---
name: weekly-review
description: Weekly operating rhythm — summarizes what shipped, AI spend, support themes, security health, and surfaces next priorities. Use at the end of each week to maintain operating cadence.
user-invokable: true
argument-hint: "[optional: --save]"
---

# Weekly Review

## Reference
- **ID**: S-ORG-13
- **Category**: Orchestration
- **Inputs**: artifacts/ directory, cogs/ai-ledger/, tasks/lessons.md, company.config.yaml
- **Outputs**: Formatted weekly summary (optionally saved to artifacts/decision-memos/)
- **Used by**: Orchestrator Agent, User (directly)
- **Tool scripts**: ./tools/ops/dashboard.sh, ./tools/security/posture-check.sh, ./tools/ops/token-ledger.sh

## Purpose

Provide a weekly operating rhythm for solopreneurs and small teams. Surfaces what happened, what it cost, what's risky, and what to do next — all in one view.

## Procedure

### Step 1: Load Context
Read `company.config.yaml` for company name, stage, and persona names.

### Step 2: What Shipped This Week
Scan all artifact directories for files modified in the last 7 days:
- List artifacts by type (PRD, RFC, QA report, etc.) with their current status
- Highlight any artifacts that were promoted (status changed to approved)
- Note any new artifacts created

### Step 3: AI Spend
Read `cogs/ai-ledger/entries.jsonl` for entries in the last 7 days:
- Total input/output tokens and estimated cost
- Top 3 flows by cost (e.g., ship, prototype, code-review)
- Week-over-week trend if previous week data exists

### Step 4: Support & Feedback Themes
Scan `artifacts/decision-memos/` for CONV- prefixed artifacts from the last 7 days:
- Count of conversations logged
- Top pain points mentioned
- Any patterns emerging across conversations

### Step 5: Security Health
Run `./tools/security/posture-check.sh --brief` (if available):
- Current posture status (HEALTHY/DEGRADED/AT_RISK)
- Any new findings since last week

### Step 6: Lessons Learned
Read `tasks/lessons.md` for entries added this week:
- New patterns or corrections captured
- Recurring issues to address

### Step 7: Next Week Priorities
Based on the scan:
- Artifacts in draft/review that need attention
- Failing or incomplete gates
- Upcoming deadlines or commitments

### Step 8: Output Format

```
## Weekly Review — [Company Name] — Week of [Date]

### What Shipped
- [list of completed/promoted artifacts]

### AI Spend
- Total: $X.XX (NK input, NK output tokens)
- Top flows: [list]

### Customer Signal
- [conversation count] conversations logged
- Top themes: [list]

### Security
- Posture: [status]
- [any new findings]

### Lessons
- [new lessons this week]

### Next Week
- [ ] [priority 1]
- [ ] [priority 2]
- [ ] [priority 3]
```

### Step 9: Save (Optional)
If user passes `--save`, save to `artifacts/decision-memos/REVIEW-WEEKLY-{YYYY-MM-DD}.md` with appropriate frontmatter.

## Quality Checklist
- [ ] All artifact directories scanned for recent changes
- [ ] AI spend calculated from ledger entries
- [ ] Security posture checked
- [ ] Priorities are actionable and specific
- [ ] Output is concise (fits in one screen)
