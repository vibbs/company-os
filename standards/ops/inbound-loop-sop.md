# Inbound Loop SOP

Standard operating procedure for processing all inbound customer signals — support tickets, conversations, feedback — into the product roadmap. This document defines the loop stages, trigger cadences, routing rules, and responsible agents.

---

## Overview

The inbound loop ensures that no customer signal is lost. Every support ticket, conversation, and feedback data point flows through a structured pipeline that produces actionable product insights and, when patterns emerge, PRD candidates.

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Capture    │ ──→ │  Synthesize  │ ──→ │  Prioritize  │ ──→ │     Act      │
│              │     │              │     │              │     │              │
│ Conversations│     │  Feedback    │     │   Sprint     │     │  PRD Writer  │
│ Support Ops  │     │  Synthesizer │     │  Prioritizer │     │  /ship       │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
```

---

## Loop Stages

### Stage 1: Capture

Two skills feed the capture stage:

**Customer Conversations** (`/customer-conversations`)
- Pre-call prep: generates question bank tailored to conversation type
- Post-call debrief: structured capture (pain level, quotes, signals)
- Output: `artifacts/decision-memos/CONV-{date}-{type}-{company}.md`
- Agent: Product Agent

**Support Operations** (`/support-operations`)
- Ticket classification: bug, feature request, how-to, billing, account, security, performance
- Priority assignment with SLA guidance
- Weekly theme aggregation
- Output: `artifacts/support/` (support themes, FAQs)
- Agent: Ops & Risk Agent

### Stage 2: Synthesize

**Feedback Synthesizer** (`/feedback-synthesizer`)
- Consumes: CONV- artifacts, support themes, surveys, app reviews, internal notes
- Normalizes, codes, groups into themes
- Ranks by frequency x severity
- Produces PRD candidate suggestions for top themes
- Output: themed feedback report in `artifacts/product/`
- Agent: Product Agent

### Stage 3: Prioritize

**Sprint Prioritizer** (`/sprint-prioritizer`)
- Evaluates PRD candidates from feedback synthesis
- Scores by impact, effort, and risk
- Sequences into sprint-ready work items
- Agent: Product Agent

### Stage 4: Act

**PRD Writer** (`/prd-writer`) or **Ship** (`/ship`)
- User reviews PRD candidates and selects which to pursue
- `/ship` initiates the full pipeline for selected candidates
- Human decision point — no automatic PRD creation

---

## Trigger Cadences

| Trigger | When | What to Run | Agent |
|---------|------|-------------|-------|
| Post-call | Immediately after any customer call | `/customer-conversations debrief` | Product |
| Weekly | End of each week | `/support-operations` Step 8 (theme aggregation) | Ops & Risk |
| Bi-weekly | Every 2 weeks | `/feedback-synthesizer` with all new CONV- and support theme artifacts | Product |
| Monthly | First week of month | Review PRD candidates with `/sprint-prioritizer` | Product |
| On-demand | When churn signal detected | Alert to Ops & Risk + `/activation-onboarding` review | Ops & Risk |

---

## Routing Rules

| Signal | Condition | Route To |
|--------|-----------|----------|
| **PRD candidate** | 3+ users report the same pain point | `/feedback-synthesizer` → PRD Candidates section → user review |
| **Churn signal** | CONV- artifact flagged as churn | Ops & Risk Agent → activation-onboarding skill |
| **ICP signal** | CONV- artifact tagged with ICP fit data | Product Agent → icp-positioning skill |
| **Feature request** | Support ticket classified as feature request | Feedback Synthesizer (next bi-weekly run) |
| **Bug report** | Support ticket classified as bug (P0/P1) | Engineering Agent directly (bypass synthesis) |
| **Security concern** | Support ticket classified as security | Ops & Risk Agent → threat-modeling or incident-response |

---

## Artifact Flow

```
Customer Call ──→ CONV-{date}-{type}.md (decision-memo)
                        │
Support Ticket ──→ Support Theme Artifact ──┐
                                            │
Survey/Review ──────────────────────────────┤
                                            ▼
                                   Feedback Synthesis Report
                                   (artifacts/product/)
                                            │
                                   ┌────────┴────────┐
                                   │  PRD Candidates  │
                                   │  (human reviews) │
                                   └────────┬────────┘
                                            │
                                     User selects → /ship
```

---

## Responsible Agents

| Stage | Primary Agent | Supporting Agent |
|-------|--------------|-----------------|
| Capture: Conversations | Product Agent | — |
| Capture: Support | Ops & Risk Agent | — |
| Synthesize | Product Agent | Ops & Risk (churn signals) |
| Prioritize | Product Agent | Engineering (feasibility) |
| Act | Product Agent → Orchestrator | All (via /ship flow) |

---

## Cross-References

- **Customer Conversations skill**: `.claude/skills/customer-conversations/SKILL.md`
- **Support Operations skill**: `.claude/skills/support-operations/SKILL.md`
- **Feedback Synthesizer skill**: `.claude/skills/feedback-synthesizer/SKILL.md`
- **Sprint Prioritizer skill**: `.claude/skills/sprint-prioritizer/SKILL.md`
- **Support Runbook**: `standards/ops/support-runbook.md`
