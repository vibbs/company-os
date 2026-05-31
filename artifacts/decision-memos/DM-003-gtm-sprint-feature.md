---
id: DM-003-gtm-sprint-feature
type: decision-memo
title: "Decision: Add GTM Sprint Feature to Company OS"
status: approved
created: 2026-03-17
author: Claude
---

# Decision: Add GTM Sprint Feature to Company OS

## Context

Company OS had strong individual GTM building blocks (ICP positioning, customer conversations, feedback synthesis, positioning, landing page copy, channel playbooks) but lacked a **coordinating workflow** that sequences them into a time-boxed go-to-market push. Users at the `idea` stage had no clear starting point — `/ship` builds software, `/prototype` proves technical feasibility, but neither validates market demand.

## Trigger

Analysis of the 100x 14-Day GTM Roadmap (a go-to-market playbook from a recent webinar) revealed structural gaps in Company OS's growth capabilities. The playbook's power comes from three things Company OS didn't have:

1. **Time-boxed orchestration** — daily task cadence with specific deliverables
2. **Quantified decision gates** — hard metrics thresholds that trigger corrective action
3. **Commitment artifacts** — Letters of Intent as a validation signal stronger than interviews

## Decision

Add a comprehensive GTM Sprint feature (v1.10.0) consisting of:

| Component | Type | Description |
|-----------|------|-------------|
| `/gtm-sprint` (S-GRO-09) | New skill | Time-boxed GTM sprint orchestrator (7/14/21 days) |
| Mom-Test methodology | Enhancement | Added to `customer-conversations` as new conversation type |
| Pain Matrix | Enhancement | Added to `feedback-synthesizer` as Step 12 output |
| Directory Blitz | Enhancement | Added to `channel-playbook` with 19 SaaS directories |
| Build-in-Public arc | Enhancement | Added to `channel-playbook` with 14-day content schedule |
| Competitor Poaching | Enhancement | Added to `channel-playbook` with outreach templates |
| LOI artifact type | Enhancement | Added to `validate.sh` VALID_TYPES |
| GTM/Market Validation | Enhancement | New Workflow Router classification type |

## Alternatives Considered

1. **New standalone skills only** (no orchestrator) — Rejected because the value is in the sequencing, not the individual tactics. Users would still need to figure out the order themselves.

2. **Embed GTM into `/ship` flow** — Rejected because `/ship` is software-focused. GTM validation should be possible without writing any code. Different workflow, different artifacts, different gates.

3. **External playbook document** (not a skill) — Rejected because it wouldn't integrate with existing skill cross-references, artifact tracking, or decision gates.

## Consequences

- Growth Agent now has 9 skills (was 8)
- Workflow Router has 10 classification types (was 9)
- New `loi` artifact type in validate.sh
- Company OS now has a clear answer for "I have an idea but haven't validated it yet" — run `/gtm-sprint` first, then `/ship` to build
- The three workflow entry points are now: `/gtm-sprint` (validate market) → `/prototype` (prove technical feasibility) → `/ship` (build and launch)

## Success Criteria

- Users at `idea` stage can run `/gtm-sprint` and produce: ICP artifact, 20+ CONV- artifacts, feedback report with Pain Matrix, 5 LOI artifacts, positioning artifact, landing page copy, and a GTM Sprint Report — all within 14 days
- Decision gates catch underperformance early and trigger corrective actions
