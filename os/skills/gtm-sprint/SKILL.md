---
name: gtm-sprint
description: "Runs a 7, 14 or 21 day go-to-market (GTM) sprint: customer interviews, positioning, landing page and distribution, with go/no-go checkpoints. Use to test demand or launch an MVP."
runtimes:
  claude:
    user-invocable: true
    argument-hint: "[plan | status | gate-check] [7 | 14 | 21]"
---

# GTM Sprint

## Reference
- **ID**: S-GRO-09
- **Category**: Growth
- **Inputs**: company.config.yaml, ICP artifact (or triggers creation), objective description
- **Outputs**: GTM Sprint Plan artifact + GTM Sprint Report artifact -> artifacts/growth/
- **Used by**: Growth Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose

Orchestrates a time-boxed go-to-market sprint that sequences validation, commitment, launch, and distribution into a structured daily cadence with quantified decision gates. Unlike `/ship` (which builds software) or `/rapid-prototype` (which proves technical feasibility), `/gtm-sprint` validates **market demand** and builds **distribution** — no code required.

Inspired by the 100x GTM Playbook methodology: validate with interviews, secure commitments (LOIs), build launch assets, activate distribution channels, and measure traction — all within a fixed sprint window.

## When to Use

- Pre-product validation: "Do people actually want this?"
- MVP launch: "We built it, now how do we get users?"
- New market entry: "We're expanding to a new segment"
- Repositioning: "Our current positioning isn't working"
- Any time the user says: "go to market", "GTM", "launch plan", "validate market", "find customers"

## When NOT to Use

- Building software features -> use `/ship`
- Technical proof-of-concept -> use `/rapid-prototype`
- Single-channel optimization -> use `/channel-playbook` directly
- Post-launch growth optimization -> use individual growth skills directly

## What You Will See

`/gtm-sprint plan 14` produces a plan like this (excerpt). Each day lists tasks, the skill to use and the output.

```text
GTM Sprint Plan: Acme Invoices, 14 days, stage: idea

Day 0  Prep: lock ICP and outreach
  - Finalize ICP (role, company size, budget, current workaround)
  - Build a 100-name prospect list; book 15+ calls for Days 1-2
  - Skill: icp-positioning        Output: ICP artifact, prospect list
Day 1  Pain discovery: Mom-Test interviews (10+, 15 min each)
  - Skill: customer-conversations prep mom-test
  - Output: 10+ CONV- artifacts
Day 2  Insights: synthesize pain data
  - Skill: feedback-synthesizer   Output: Pain Matrix
  Gate: Interview Volume (>= 15 completed)
```

`/gtm-sprint gate-check` evaluates one gate and tells you what to do next:

```text
Gate: Interview Volume (Day 2)   Metric: completed interviews
Threshold: >= 15   Actual: 11   Result: FAIL (advisory at stage idea)
Corrective action: extend Days 1-2 by 1-2 days and increase outreach volume.
Adjust the plan, override the gate, or pause the sprint?
```

Answer with `adjust`, `override` or `pause`. Gates are advisory at `idea` stage and enforced at `growth` and `scale`.

## Modes

### Mode: `plan` (default)

Generates a personalized GTM Sprint Plan with daily tasks, decision gates, and skill sequencing.

### Mode: `status`

Reviews progress against the active GTM Sprint Plan — checks completed tasks, gate metrics, and recommends adjustments.

### Mode: `gate-check`

Evaluates a specific decision gate and recommends corrective action if thresholds are not met.

## Procedure

### Phase 0: Context & Configuration

1. **Load Context**
   - Read `company.config.yaml` for company name, stage, product description
   - Check `artifacts/product/` for existing ICP artifact
   - Check `artifacts/decision-memos/` for existing CONV- artifacts (interview count)
   - Check `artifacts/growth/` for existing positioning, landing page, channel playbooks

2. **Sprint Configuration**

   Ask the user for (with smart defaults):

   | Parameter | Default | Options |
   |-----------|---------|---------|
   | Sprint duration | 14 days | 7 / 14 / 21 days |
   | Start date | Today | Any date |
   | Objective | From product description | Custom |
   | Target LOIs | 5 | 3-10 |
   | Target interviews | 20 | 10-30 |
   | Target wait-list | 50 | 25-200 |

   Stage-aware defaults:
   - `idea`: 14 days, 20 interviews, 5 LOIs, 50 wait-list
   - `mvp`: 7 days (validation done), 10 interviews, 3 LOIs, 100 wait-list
   - `growth`: 7 days (repositioning sprint), 15 interviews, 5 LOIs, 200 wait-list

3. **ICP Check**
   - If no ICP artifact exists: inform the user — "No ICP found. The sprint will begin with ICP definition (Day 0). Run `/icp-positioning` now, or we'll include it in the sprint plan."
   - If ICP exists but is `draft`: note it needs validation through interviews

### Phase 1: Generate Sprint Plan (Mode: `plan`)

4. **Build Daily Task Schedule**

   Generate a day-by-day plan adapted to the sprint duration. For a 14-day sprint:

   #### Week 1: Validate & Commit (Days 0-6)

   **Day 0 — Prep: Lock ICP & Outreach**
   - Finalize ICP criteria (role, company size, budget, current workaround)
   - Build prospect list (100 targets) — use LinkedIn, communities, competitor reviews
   - Book 15+ discovery calls for Days 1-2
   - *Skill*: `icp-positioning` (if no ICP exists)
   - *Skill*: `customer-conversations prep cold-outreach`
   - *Output*: ICP artifact (draft or updated), prospect list

   **Day 1 — Pain Discovery: Mom-Test Interviews**
   - Conduct 10+ Mom-Test interviews (15 min each)
   - Record key quotes and $$ impact of each pain point
   - Focus: current behavior, cost of status quo, workarounds tried
   - *Skill*: `customer-conversations prep mom-test`
   - *Skill*: `customer-conversations debrief` (after each call)
   - *Output*: 10+ CONV- artifacts

   **Day 2 — Insights: Synthesize Pain Data**
   - Conduct remaining interviews (target: 20 total)
   - Run feedback synthesis on all CONV- artifacts
   - Produce Pain Matrix: themes clustered by $$ impact + urgency
   - Rank themes, identify top 3 "hair-on-fire" problems
   - *Skill*: `feedback-synthesizer` (with pain-matrix output)
   - *Output*: Feedback report with Pain Matrix

   **Day 3 — Refine: Sharpen MVP Scope**
   - Map current workflow -> desired workflow for top pain
   - Update MVP scope based on Day 2 insights
   - Quantify time saved and cost saved per user
   - Draft value proposition: "We help X do Y, saving Z hours/week"
   - *Skill*: `prd-writer` or update existing PRD
   - *Output*: Updated PRD or mini-PRD (if pre-product)

   **Day 4 — Commit: Secure Letters of Intent**
   - Draft 1-page LOI template (problem, proposed solution, commitment level, timeline)
   - Re-contact top 5 prospects from interviews
   - Show prototype/mockup/demo and request commitment
   - Obtain verbal commitments or e-signatures
   - *Output*: LOI artifacts (target: 5 signed)

   **Day 5 — Narrative: Go Public**
   - Write 1-sentence mission statement
   - Write 2-paragraph vision statement
   - Craft positioning: "We help [X] do [Y] in [Z] seconds"
   - Publish first build-in-public post
   - *Skill*: `positioning-messaging`
   - *Skill*: `channel-playbook` (build-in-public arc)
   - *Output*: Positioning artifact, first public post draft

   **Day 6 — Gate Check: Week 1 Review**
   - Review metrics: interviews completed, LOIs signed, wait-list size
   - **Decision Gate 1**: Evaluate against thresholds (see Decision Gates below)
   - Adjust Week 2 plan based on gate results
   - *Output*: Week 1 status update

   #### Week 2: Launch & Grow (Days 7-13)

   **Day 7 — Launch Pad: Landing Page**
   - Build landing page with top 3 pain quotes above the fold
   - Embed email capture / wait-list form
   - Add Calendly or booking link for demos
   - *Skill*: `landing-page-copy`
   - *Output*: Landing page copy artifact (or deployed page)

   **Day 8 — Lead Magnet: Field Report**
   - Compile interview insights into a downloadable asset
   - Format: "Field Report" PDF, industry brief, or data snapshot
   - Gate the download behind email capture
   - *Skill*: `content-engine` (lead-magnet format)
   - *Output*: Lead magnet content artifact

   **Day 9 — Distribution: Directory Blitz**
   - Submit product to 15+ relevant directories
   - Craft directory-specific hooks using interview data
   - *Skill*: `channel-playbook` (directory-blitz template)
   - *Output*: Directory submission tracker

   **Day 10 — Community: Engagement Strike**
   - Join 3-5 Slack/Discord communities where ICP hangs out
   - Share one fresh insight chart from interview data
   - Offer free office-hours or AMA slot
   - **Decision Gate 2**: Check wait-list size against threshold
   - *Skill*: `channel-playbook` (community tactics)
   - *Output*: Community post drafts

   **Day 11 — Competitor: Poaching Play**
   - Identify 50-100 competitor reviewers (G2, Capterra, Reddit)
   - Send value-first outreach: "What's frustrating about [competitor]?"
   - Offer concierge migration or white-glove onboarding
   - *Skill*: `channel-playbook` (competitor-poaching template)
   - *Output*: Competitor outreach templates

   **Day 12 — Demo Day: Show & Tell**
   - Live demo to LOI signers and top prospects
   - Capture video testimonials (even 30-second clips)
   - Post build-in-public recap with traction metrics
   - *Output*: Demo script, testimonial clips, recap post draft

   **Day 13 — Sprint Retrospective**
   - Review all metrics vs. targets
   - Decide top 3 growth experiments for next 30 days
   - Publish internal retro + public "what's next" post
   - *Skill*: `retrospective` (or standalone retro)
   - *Output*: GTM Sprint Report artifact

   #### Sprint Duration Variants

   **7-Day Sprint** (compressed):
   - Days 0-1: ICP + Interviews (combine Prep + Pain Discovery)
   - Day 2: Synthesize + Refine MVP
   - Day 3: LOIs + Positioning
   - Day 4: Landing Page + Lead Magnet
   - Day 5: Distribution Blitz + Community
   - Day 6: Demo Day + Retrospective
   - Gate Check: Day 3 (mid-sprint)

   **21-Day Sprint** (extended):
   - Week 1: Days 0-6 (same as 14-day)
   - Week 2: Days 7-13 (same as 14-day)
   - Week 3: Days 14-20 — Optimize & Scale
     - Day 14-15: A/B test landing page variants
     - Day 16-17: Double down on best-performing channel
     - Day 18: Pitch deck assembly
     - Day 19: Investor/partner outreach
     - Day 20: Sprint close + 30-day plan
   - Gate Check: Day 6, Day 13, Day 18

5. **Adapt for Existing Progress**

   Skip steps where artifacts already exist:
   - ICP artifact exists and is approved -> skip Day 0 ICP work
   - 10+ CONV- artifacts exist -> reduce Day 1-2 interview targets
   - Positioning artifact exists -> skip Day 5 positioning (just do build-in-public)
   - Landing page copy exists -> skip Day 7 copy work (focus on deployment)

### Phase 2: Decision Gates

6. **Define Quantified Gates**

   Each gate has a metric, threshold, and corrective action:

   | Gate | Day | Metric | Threshold | If Below |
   |------|-----|--------|-----------|----------|
   | Interview Volume | 2 | Completed interviews | >= 15 (of 20 target) | Extend Days 1-2 by 1-2 days, increase outreach volume |
   | Pain Clarity | 3 | Distinct pain themes with $$ quantification | >= 3 themes | Broaden interview scope to adjacent ICP segments |
   | LOI Commitment | 6 | Signed/verbal LOIs | >= 60% of target | Double interview volume in Week 2, revisit ICP criteria |
   | Wait-list Traction | 10 | Wait-list sign-ups | >= 50% of target | Rerun positioning, test different channels, check landing page conversion |
   | Distribution Reach | 12 | Directory submissions + community posts | >= 10 combined | Focus remaining days on single highest-ROI channel |

   **Gate Severity by Stage:**
   - `idea`: All gates are advisory (warnings) — learning is the goal
   - `mvp`: LOI and Wait-list gates are enforced — market signal is critical
   - `growth`/`scale`: All gates enforced — must hit thresholds to continue

7. **Gate Check Procedure** (Mode: `gate-check`)

   When a gate is triggered:
   1. Count the relevant metric from artifacts (CONV- count, LOI count, etc.)
   2. Compare against threshold
   3. If PASS: congratulate, move to next phase
   4. If FAIL: present corrective action with specific steps
   5. Ask user: "Adjust the plan, override the gate, or pause the sprint?"

### Phase 3: Sprint Artifacts

8. **GTM Sprint Plan Artifact**

   Save to `artifacts/growth/GTM-SPRINT-{date}.md`:

   ```yaml
   ---
   id: GTM-SPRINT-{date}
   type: launch-brief
   title: "GTM Sprint Plan — {objective}"
   status: draft
   created: {date}
   author: Growth Agent
   sprint_duration: 14
   sprint_start: {date}
   sprint_end: {date+duration}
   target_interviews: 20
   target_lois: 5
   target_waitlist: 50
   ---
   ```

   Body contains the full daily task schedule with checkboxes.

9. **GTM Sprint Report Artifact** (end of sprint)

   Save to `artifacts/growth/GTM-SPRINT-REPORT-{date}.md`:

   ```yaml
   ---
   id: GTM-SPRINT-REPORT-{date}
   type: launch-brief
   title: "GTM Sprint Report — {objective}"
   status: review
   created: {sprint_end_date}
   author: Growth Agent
   parent: GTM-SPRINT-{date}
   ---
   ```

   Body contains:
   - **Metrics vs. Targets**: interviews, LOIs, wait-list, directory submissions, community engagement
   - **Top Learnings**: 3-5 key insights from interviews
   - **Pain Matrix Summary**: top 3 validated pain points with $$ impact
   - **Positioning Validation**: what resonated, what didn't
   - **Channel Performance**: which channels drove most traction
   - **Next 30 Days**: top 3 growth experiments recommended
   - **Decision**: proceed to `/ship`, pivot positioning, expand ICP, or pause

### Phase 4: Status Tracking (Mode: `status`)

10. **Progress Dashboard**

    When invoked with `status`:
    1. Find the most recent GTM-SPRINT- artifact in `artifacts/growth/`
    2. Calculate current sprint day based on `sprint_start` date
    3. Count completed metrics:
       - CONV- artifacts created since sprint start
       - LOI artifacts in `artifacts/product/`
       - Landing page / positioning artifacts created
       - Channel playbook artifacts created
    4. Present progress:

    ```
    ## GTM Sprint Status — Day {N} of {duration}

    ### Metrics
    | Metric | Target | Current | Status |
    |--------|--------|---------|--------|
    | Interviews | 20 | 12 | On track |
    | LOIs | 5 | 2 | At risk |
    | Wait-list | 50 | 8 | Behind |

    ### Today's Focus
    - [Day N tasks from the plan]

    ### Upcoming Gate
    - Gate: LOI Commitment (Day 6) — need 3 more LOIs in 2 days
    ```

## LOI (Letter of Intent) Template

When creating LOI artifacts on Day 4, save to `artifacts/product/LOI-{company}-{date}.md` using this structure:

```yaml
---
id: LOI-{company}-{date}
type: loi
title: "Letter of Intent — {Company Name}"
status: draft
created: {date}
author: {user}
parent: {icp-artifact-id}
---
```

### LOI Body Template

```markdown
## Letter of Intent

**From**: {Prospect Name}, {Role} at {Company}
**To**: {Your Company}
**Date**: {date}

### Problem Acknowledged
{1-2 sentences describing the pain point this prospect validated}

### Proposed Solution
{1-2 sentences describing what you plan to build/offer}

### Commitment Level
- [ ] Verbal interest
- [ ] Email confirmation
- [ ] Signed LOI
- [ ] Pilot agreement with timeline

### Terms (if applicable)
- **Pilot Duration**: {e.g., 30 days}
- **Pilot Scope**: {what they'll use}
- **Success Criteria**: {what "working" looks like for them}
- **Pricing Discussion**: {willingness-to-pay signal}

### Prospect Context
- **Company Size**: {employees / revenue range}
- **Current Workaround**: {how they solve this today}
- **$$ Impact**: {estimated cost of current pain per month/year}
- **ICP Fit**: Strong / Partial / Weak
- **Decision Timeline**: {when they need a solution}

### Next Steps
{Agreed follow-up actions}
```

## Cross-References

- **icp-positioning** (S-PROD-01) — Day 0 ICP definition
- **customer-conversations** (S-PROD-08) — Days 1-2 interview prep/debrief, Mom-Test mode
- **feedback-synthesizer** (S-PROD-04) — Day 2 pain synthesis with Pain Matrix
- **prd-writer** (S-PROD-02) — Day 3 MVP refinement
- **positioning-messaging** (S-GRO-01) — Day 5 narrative and positioning
- **landing-page-copy** (S-GRO-02) — Day 7 launch page
- **content-engine** (S-GRO-07) — Day 8 lead magnet
- **channel-playbook** (S-GRO-04) — Days 9-11 distribution (directory blitz, community, competitor poaching)
- **retrospective** (S-ORG-14) — Day 13 sprint retro
- **ship** (S-ORG-08) — post-sprint graduation to full build flow

## Quality Checklist
- [ ] Sprint duration is appropriate for company stage
- [ ] Daily tasks are specific and actionable
- [ ] Decision gates have quantified thresholds
- [ ] Existing artifacts are accounted for (no duplicate work)
- [ ] Skill sequencing follows dependency order
- [ ] LOI template is included for Day 4
- [ ] Sprint plan adapts to 7/14/21 day variants
- [ ] Sprint report captures metrics vs. targets
- [ ] Corrective actions are specific for each failed gate
- [ ] Artifact passes validation
