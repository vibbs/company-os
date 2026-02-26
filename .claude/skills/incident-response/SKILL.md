---
name: incident-response
description: Generates incident runbooks, post-mortem templates, and incident response records. Use when establishing incident response procedures, handling a live incident, or conducting post-incident reviews.
allowed-tools: Read, Grep, Glob, Bash, Write
---

# Incident Response

## Reference
- **ID**: S-OPS-02
- **Category**: Ops & Risk
- **Inputs**: company.config.yaml, existing RFCs, running service URLs
- **Outputs**: incident runbook (standards/ops/), post-mortem template (standards/ops/), incident records (artifacts/decision-memos/)
- **Used by**: Ops & Risk Agent
- **Tool scripts**: ./tools/ops/status-check.sh, ./tools/artifact/validate.sh

## Purpose

Establish a repeatable incident response process that minimizes downtime and data loss. This skill produces runbooks, post-mortem templates, and per-incident records so that every outage is handled consistently and every failure becomes a learning opportunity.

## Procedure

### Step 1: Load Context

Before generating any incident response artifacts:

1. **Read `company.config.yaml`** -- understand hosting provider, observability stack, error_tracking configuration
2. **Read existing RFCs** in `artifacts/rfcs/` -- understand the system architecture, dependencies, and failure domains
3. **Identify critical services** -- which components, if down, cause user-facing impact
4. **Check existing standards** in `standards/ops/` -- avoid duplicating or contradicting existing operational procedures

### Step 2: Generate Incident Runbook

Produce `standards/ops/incident-runbook.md` with the following sections:

#### Severity Classification

| Severity | Description | Examples | Response Time | Resolution Target |
|----------|-------------|----------|---------------|-------------------|
| **P0 (Critical)** | Complete service outage, data loss, security breach | Production database down, authentication broken for all users, confirmed data exfiltration | Immediate, all hands | 1 hour |
| **P1 (High)** | Major feature broken, significant performance degradation, data integrity risk | Payment processing failing, API response times >10s, primary replica out of sync | Within 30 minutes | 4 hours |
| **P2 (Medium)** | Minor feature broken, workaround exists, non-critical performance issue | Export feature timing out (manual workaround available), dashboard loading slowly, non-critical background job stalled | Next business day | 24 hours |
| **P3 (Low)** | Cosmetic issue, minor inconvenience, improvement opportunity | UI alignment off on one browser, tooltip text incorrect, non-blocking deprecation warning in logs | Next sprint | 1 week |

#### Triage Procedure Per Severity

**P0 Triage:**
1. Acknowledge the incident within 5 minutes of detection
2. Open a dedicated incident channel or document
3. Run `./tools/ops/status-check.sh` against all critical service URLs
4. Determine blast radius: which users/features are affected
5. Decide: rollback immediately or apply hotfix
6. Execute rollback checklist (below) if rolling back
7. Communicate status within 15 minutes of detection
8. Continue updates every 30 minutes until resolved

**P1 Triage:**
1. Acknowledge within 30 minutes
2. Run `./tools/ops/status-check.sh` to assess scope
3. Identify the failing component from logs/error tracking
4. Determine if rollback is needed or if a targeted fix is faster
5. Communicate initial assessment within 1 hour
6. Update every 2 hours until resolved

**P2 Triage:**
1. Acknowledge within 4 hours (business hours)
2. Document the issue and known workaround
3. Schedule investigation for next available work session
4. Communicate workaround to affected users if applicable

**P3 Triage:**
1. Log the issue in the backlog
2. Prioritize during next sprint planning
3. No immediate action required

#### Rollback Checklist

**Deployment Rollback** (per hosting provider from config):
- Identify the last known good deployment
- Execute platform-specific rollback command (Vercel: redeploy previous, AWS: roll back CloudFormation/ECS task, Railway: redeploy previous, Fly.io: `fly releases rollback`)
- Verify the rollback deployed successfully via status check
- Confirm user-facing functionality restored

**Database Rollback** (per ORM from config):
- Identify the migration that caused the issue
- Run the corresponding down/rollback migration (Prisma: `prisma migrate resolve`, Drizzle: rollback script, Django: `python manage.py migrate <app> <previous_migration>`)
- Verify data integrity after rollback
- Confirm application still functions with the rolled-back schema

**Feature Flag Disable:**
- Identify the feature flag associated with the change
- Disable the flag in the feature flag management system
- Verify the feature is no longer active for users
- Monitor for side effects from the flag change

**DNS Failover:**
- Switch DNS to the failover/maintenance page if primary is unrecoverable
- Set a low TTL before planned risky deployments
- Revert DNS after primary is restored

**Cache Invalidation:**
- Identify if stale cache is contributing to the issue
- Flush the relevant cache keys or entire cache
- Verify fresh data is being served

#### Communication Templates

**Status Page Update Template:**
```
Title: [Service Name] - [Investigating/Identified/Monitoring/Resolved]
Impact: [Brief description of user impact]
Current Status: We are aware of [description]. [Action being taken].
Next Update: We will provide an update by [time].
```

**User Notification Email Template:**
```
Subject: [Service Name] Service Disruption - [Date]

We experienced [brief description of the issue] starting at [time UTC].

Impact: [What users experienced]
Duration: [Start time] to [End time / ongoing]
Current Status: [Resolved / Under investigation]

What we are doing: [Actions taken or in progress]

We apologize for the inconvenience. If you have questions, contact [support channel].
```

**Post-Mortem Invite Template:**
```
Subject: Post-Mortem: [Incident ID] - [Brief Description]

Incident: [ID and title]
Severity: [P0-P3]
Duration: [X hours/minutes]

We will review this incident to understand root causes and prevent recurrence.
Please review the incident timeline before the session.

Agenda:
1. Timeline review
2. Root cause analysis (5 Whys)
3. Contributing factors
4. Remediation actions
```

#### Solopreneur-Specific Guidance

- **You are always on-call.** Set up alerting through your configured error_tracking tool (Sentry, Bugsnag, or equivalent from config) so you get notified immediately for P0/P1 issues.
- **Mobile notifications are critical.** Configure push alerts for production errors so you can respond even when away from your desk.
- **Escalation path:** Your hosting provider's support channel is your first escalation. Community forums (Stack Overflow, Discord communities for your framework) are your second. For security incidents, consider a security-focused consultancy on retainer.
- **Pre-write your status page updates.** Having templates ready means you spend less time writing and more time fixing.
- **Automate what you can.** Health checks, automatic rollbacks on error rate spikes, and uptime monitoring reduce the burden of solo operations.

### Step 3: Generate Post-Mortem Template

Produce `standards/ops/post-mortem-template.md` with the following structure:

```markdown
# Post-Mortem: [INC-XXX] [Incident Title]

## Incident Metadata
- **Incident ID**: INC-XXX
- **Severity**: P0 / P1 / P2 / P3
- **Date**: YYYY-MM-DD
- **Duration**: X hours Y minutes
- **Impact Summary**: [One sentence describing user-facing impact]
- **Author**: [Name]
- **Status**: Draft / Reviewed / Final

## Timeline (all times UTC)
| Time | Event |
|------|-------|
| HH:MM | Issue first detected by [monitoring/user report/manual check] |
| HH:MM | Incident acknowledged, investigation started |
| HH:MM | Root cause identified |
| HH:MM | Mitigation applied (rollback/hotfix/flag disable) |
| HH:MM | Service confirmed restored |
| HH:MM | Incident marked resolved |

## Root Cause Analysis: 5 Whys
1. **Why** did the service go down? [Answer]
2. **Why** did [answer 1] happen? [Answer]
3. **Why** did [answer 2] happen? [Answer]
4. **Why** did [answer 3] happen? [Answer]
5. **Why** did [answer 4] happen? [Root cause]

## Contributing Factors
- [Factor 1: e.g., missing test coverage for edge case]
- [Factor 2: e.g., no alerting on the affected metric]
- [Factor 3: e.g., deployment happened without staging verification]

## Impact Assessment
- **Users affected**: [Number or percentage]
- **Revenue impact**: [Estimated lost revenue or "none"]
- **Data impact**: [Data lost, corrupted, or "none"]
- **Reputation impact**: [Public visibility, social media mentions, or "minimal"]

## Remediation Actions

### Immediate (completed during incident)
- [ ] [Action taken to restore service]

### Short-term (within 1 week)
- [ ] [Action] -- Owner: [name] -- Due: [date]

### Long-term (within 1 month)
- [ ] [Action] -- Owner: [name] -- Due: [date]

## Follow-Up Items
| Item | Owner | Due Date | Status |
|------|-------|----------|--------|
| [Description] | [Name] | YYYY-MM-DD | Open |

## Lessons Learned
- **What went well**: [e.g., fast detection, clear rollback procedure]
- **What went poorly**: [e.g., slow communication, missing runbook step]
- **Where we got lucky**: [e.g., low traffic period, no data loss despite risk]
```

### Step 4: Per-Incident Response

When an actual incident occurs:

1. **Assess current state** -- run `./tools/ops/status-check.sh` against the affected service URLs
2. **Classify severity** -- use the severity table from the runbook to assign P0-P3
3. **Follow triage procedure** -- execute the severity-specific steps from the runbook
4. **Create incident record** -- produce an artifact in `artifacts/decision-memos/` with:
   - Frontmatter: `id: INC-XXX`, `type: decision-memo`, `status: draft`
   - Content: populated from the post-mortem template
   - Link to any related RFCs or PRDs via `depends_on`
5. **Execute rollback** if needed -- follow the rollback checklist
6. **Communicate** -- use the communication templates
7. **Fill in post-mortem** after resolution -- complete the 5 Whys, impact assessment, and remediation actions
8. **Promote artifact** -- move from draft to review after post-mortem is complete

### Step 5: Verify

- [ ] Runbook covers all severity levels P0 through P3
- [ ] Each severity has specific examples, response times, and resolution targets
- [ ] Rollback steps are specific to the configured hosting provider and database/ORM
- [ ] Communication templates are copy-paste ready with clear placeholders
- [ ] Post-mortem template includes the 5 Whys technique
- [ ] Solopreneur context is acknowledged throughout (no "escalate to team lead" language)
- [ ] If an incident record was produced, it passes `./tools/artifact/validate.sh`

## Quality Checklist

- [ ] All severities P0-P3 defined with examples, response times, and resolution targets
- [ ] Rollback steps are specific to configured hosting/database/ORM
- [ ] Communication templates are copy-paste ready (not vague)
- [ ] Post-mortem template includes 5 Whys
- [ ] Solopreneur context acknowledged (no "escalate to team lead" language)
- [ ] Artifact passes validation if incident record produced
