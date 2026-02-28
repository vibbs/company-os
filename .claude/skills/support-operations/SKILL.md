---
name: support-operations
description: Designs customer support infrastructure including FAQ generation, SLA tiers, escalation paths, and support-to-product feedback pipelines. Use when establishing support operations or improving customer service.
allowed-tools: Read, Grep, Glob, Bash, Write
---

# Support Operations

## Reference
- **ID**: S-OPS-07
- **Category**: Ops & Risk
- **Inputs**: PRDs in `artifacts/prds/`, feature list, support channel config from `company.config.yaml` (`support.*`)
- **Outputs**: FAQ docs in `artifacts/support/faq-*.md`, SLA definitions in `artifacts/support/sla-*.md`
- **Used by**: Ops & Risk Agent
- **Tool scripts**: `./tools/ops/support-faq-check.sh`, `./tools/artifact/validate.sh`

## Purpose

Build and maintain customer support infrastructure that scales with the product. Generate FAQs from product features, define SLA tiers, design escalation paths, and create a feedback pipeline back to product. Support is not an afterthought -- it is a core operational function that directly impacts retention and product quality.

## When to Use

- After shipping a new feature (update FAQ to cover it)
- When establishing support for the first time
- When scaling support channels (adding chat, phone, or self-serve)
- When support ticket volume indicates process issues
- During periodic support infrastructure reviews

## Procedure

### Step 1: Load Context

Before generating any support artifacts:

1. **Read `company.config.yaml`** -- extract `support.*` section (channels, sla_tier, escalation_email), `company.stage`, and `company.product`
2. **Read PRDs** in `artifacts/prds/` -- build a feature inventory from shipped/approved PRDs
3. **Check existing support artifacts** in `artifacts/support/` -- understand current FAQ coverage, SLA definitions, and any existing escalation documentation
4. **Check `standards/ops/support-runbook.md`** -- load the operational support runbook for procedural alignment

### Step 2: FAQ Generation

For each shipped feature (PRDs with status `approved` or linked to completed implementations):

1. **Extract user-facing behaviors** from the PRD's acceptance criteria
2. **Anticipate common questions** for each behavior:
   - **How to**: How do I use this feature?
   - **What if**: What happens if I do X incorrectly?
   - **Why**: Why does the feature work this way?
   - **Troubleshooting**: The feature is not working -- what should I check?
3. **Produce FAQ entries** with the following structure for each entry:
   - **Question**: The user's question in natural language
   - **Answer**: Clear, step-by-step answer
   - **Category**: Getting Started | Account | Features | Billing | Troubleshooting
   - **Related Feature**: Link to the PRD or feature name
   - **Last Updated**: Date of last review
4. **Group entries by category**:
   - **Getting Started** -- onboarding, first-time setup, quick start
   - **Account** -- login, password, profile, permissions
   - **Features** -- feature-specific how-to and configuration
   - **Billing** -- pricing, invoices, plan changes, cancellation
   - **Troubleshooting** -- error resolution, performance issues, workarounds
5. **Validate coverage** -- run `./tools/ops/support-faq-check.sh` to verify FAQ entries exist for all PRD acceptance criteria

### Step 3: SLA Tier Definitions

Define SLA tiers based on `company.stage` and the `support.sla_tier` config value:

| Tier | Default Stage | Channels | Response Time | Resolution Time | Availability |
|------|---------------|----------|---------------|-----------------|--------------|
| **Basic** | idea / mvp | Email only | 48 hours | 5 business days | Business hours (9am-5pm local) |
| **Standard** | growth | Email + Chat | 24 hours | 2 business days | Extended hours (8am-8pm local) |
| **Premium** | scale | Email + Chat + Phone | 4 hours | 24 hours | 24/7 |

For each tier, define:

- **Response time**: Maximum time to first human response
- **Resolution time**: Maximum time to resolve or provide a workaround
- **Escalation triggers**: Conditions that auto-escalate (e.g., response SLA breach, P0 severity)
- **Availability hours**: When support is staffed
- **Included channels**: Which contact methods are available
- **Priority handling**: How priority levels map to response/resolution targets within the tier

### Step 4: Escalation Path Design

Define escalation levels with clear boundaries:

| Level | Name | Handles | % of Queries | Max Time Before Escalation |
|-------|------|---------|--------------|----------------------------|
| **L1** | Self-serve | FAQ, docs, knowledge base | 60-70% | N/A (user-initiated escalation) |
| **L2** | Email/Chat support | First human contact, standard issues | 20-25% | Based on SLA tier resolution time |
| **L3** | Engineering escalation | Bugs, data issues, security concerns | 5-10% | 4 hours at L3 before L4 review |
| **L4** | Executive escalation | Critical business impact, legal, data loss | <1% | Immediate resolution track |

For each level, document:

- **Trigger criteria**: What conditions cause escalation to this level
- **Maximum time at level**: How long before auto-escalation to the next level
- **Notification recipients**: Who gets notified when an issue reaches this level
- **Required information**: What must be documented before escalating
- **De-escalation criteria**: When an issue can be moved back down

### Step 5: Multi-Channel Support Strategy

Based on `support.channels` config, for each configured channel:

**Email Support:**
- Setup: dedicated support inbox, auto-responder with ticket confirmation
- Response templates for common categories
- Automation: auto-categorize by keywords, auto-assign by category
- Recommended for: all stages (baseline channel)

**Chat Support:**
- Setup: chat widget integration, canned responses, operating hours display
- Response templates for real-time conversations
- Automation: chatbot for L1 deflection, human handoff triggers
- Recommended for: growth stage and above

**Self-Serve:**
- Setup: knowledge base / help center, search functionality, feedback widget
- Content: FAQ articles, how-to guides, video tutorials
- Automation: AI-powered search suggestions, related article recommendations
- Recommended for: all stages (reduces ticket volume by 30-50%)

Recommend channel priority based on `company.stage`:
- **idea/mvp**: Self-serve + Email (minimal overhead)
- **growth**: Self-serve + Email + Chat (balanced coverage)
- **scale**: Self-serve + Email + Chat + Phone (full coverage)

### Step 6: De-escalation Scripts

Produce scripts for common high-emotion scenarios. Each script includes:

**Billing Dispute:**
- Opening: Acknowledge the concern, confirm you understand the billing issue
- Investigation: Review account billing history, identify the discrepancy
- Resolution options: Refund, credit, plan adjustment, explanation
- Follow-up: Confirm resolution, document for future reference

**Feature Not Working:**
- Opening: Acknowledge frustration, confirm the expected behavior
- Investigation: Reproduce the issue, check known issues list, gather environment details
- Resolution options: Workaround, bug report escalation, timeline for fix
- Follow-up: Notify when fixed, verify resolution

**Data Loss Concern:**
- Opening: Take the concern seriously immediately, escalate urgency internally
- Investigation: Check backup systems, audit logs, data recovery options
- Resolution options: Data restoration, export assistance, compensation
- Follow-up: Root cause report, prevention measures implemented

**Slow Response Complaint:**
- Opening: Apologize for the delay, validate their experience
- Investigation: Review ticket history, identify where the delay occurred
- Resolution options: Immediate attention to original issue, SLA review
- Follow-up: Process improvement commitment, direct contact for future issues

### Step 7: Support Ticket Classification

Define a taxonomy for incoming support tickets:

| Category | Priority Rules | Routing | Expected Resolution |
|----------|---------------|---------|---------------------|
| **Bug Report** | P0 if data loss/security, P1 if blocking, P2 if workaround exists, P3 if cosmetic | L2 triage, L3 if confirmed bug | Fix or workaround per severity |
| **Feature Request** | P3 (backlog) | L2 documents, routes to product | Acknowledgment + roadmap context |
| **How-To Question** | P3 | L1 self-serve, L2 if complex | FAQ link or guided answer |
| **Billing Issue** | P1 if overcharge, P2 otherwise | L2 with billing access | Same-day for overcharges |
| **Account Issue** | P1 if locked out, P2 otherwise | L2 with account access | Same-day for lockouts |
| **Security Concern** | P0 always | L3 immediate, L4 if confirmed breach | Immediate investigation |
| **Performance Issue** | P1 if widespread, P2 if isolated | L2 triage, L3 if infrastructure | Investigation within SLA |

### Step 8: Support-to-Product Feedback Pipeline

Define how support insights feed back to product development:

1. **Weekly aggregation**: Aggregate ticket categories and volumes weekly
2. **Top-5 pain points**: Identify the top 5 most frequent or most severe support themes
3. **Feedback formatting**: Format insights for the feedback-synthesizer skill:
   - Theme name and description
   - Ticket count and trend (increasing/decreasing/stable)
   - Representative user quotes (anonymized)
   - Suggested product action (fix, improve, document, deprioritize)
4. **Support themes artifact**: Create `artifacts/support/support-themes-{date}.md` summarizing:
   - Period covered
   - Total ticket volume and breakdown by category
   - Top pain points with severity and frequency
   - Recommended product actions
   - Comparison to previous period (if available)
5. **Feedback loop closure**: Track which support themes resulted in product changes, and update FAQ/docs when fixes ship

### Step 9: Save Artifacts

1. Save FAQ documents to `artifacts/support/faq-{feature-name}.md` with proper artifact frontmatter:
   ```yaml
   ---
   id: FAQ-{feature}
   type: support-faq
   status: draft
   parent: PRD-XXX  # link to source PRD
   ---
   ```
2. Save SLA definitions to `artifacts/support/sla-{date}.md` with frontmatter:
   ```yaml
   ---
   id: SLA-{date}
   type: support-sla
   status: draft
   ---
   ```
3. Save support themes to `artifacts/support/support-themes-{date}.md` with frontmatter:
   ```yaml
   ---
   id: THEMES-{date}
   type: support-themes
   status: draft
   ---
   ```

### Step 10: Validate

Run `./tools/artifact/validate.sh` on all produced artifacts to verify:
- YAML frontmatter is complete and well-formed
- Parent references resolve to existing artifacts
- Status field is valid

## Cross-References

- **feedback-synthesizer** -- consumes support themes to inform product prioritization
- **prd-writer** -- source of feature definitions used to generate FAQs
- **incident-response** -- handles P0/P1 escalations that originate from support tickets
- **privacy-data-handling** -- governs what customer data support agents can access

## Quality Checklist

- [ ] FAQ entries cover all acceptance criteria from shipped PRDs
- [ ] FAQ coverage validated with `./tools/ops/support-faq-check.sh`
- [ ] SLA tiers defined with response time, resolution time, escalation triggers, and availability
- [ ] SLA tier selection is appropriate for the configured `company.stage`
- [ ] Escalation paths defined for L1 through L4 with trigger criteria and time limits
- [ ] Channel strategy aligns with configured `support.channels` and stage
- [ ] De-escalation scripts cover billing, feature, data loss, and response time scenarios
- [ ] Ticket classification taxonomy includes priority rules and routing for all categories
- [ ] Support-to-product feedback pipeline is defined with weekly cadence
- [ ] All artifacts have proper YAML frontmatter and pass validation
