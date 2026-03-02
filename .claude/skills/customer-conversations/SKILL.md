---
name: customer-conversations
description: Prepares pre-call briefings, captures post-call debriefs, and routes insights to ICP refinement and PRD evidence. Stores conversation logs as CONV- artifacts in artifacts/decision-memos/.
user-invokable: true
argument-hint: "prep <type> | debrief | patterns"
---

# Customer Conversations

## Reference
- **ID**: S-PROD-08
- **Category**: Product
- **Inputs**: company.config.yaml, existing CONV- artifacts, ICP artifacts, PRDs
- **Outputs**: conversation log artifacts → artifacts/decision-memos/CONV-{date}-{type}-{company}.md
- **Used by**: Product Agent (primary), Ops & Risk Agent (churn signals)
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose

Structures the process of talking to customers. Provides pre-call preparation (what to ask, what to listen for), captures post-call debriefs in a structured format, and routes insights to the right downstream skills (ICP refinement, PRD evidence, churn detection).

## When to Use

- Before a customer call, demo, or interview — run `prep <type>` for a tailored briefing
- After any customer interaction — run `debrief` to capture structured insights
- When you have 3+ conversation logs — run `patterns` to surface cross-conversation themes

## Conversation Types

| Type | Purpose | Key Signals |
|------|---------|-------------|
| `discovery` | Understand user problems, validate hypotheses | Pain intensity, current workarounds, willingness to pay |
| `demo` | Show the product, gauge interest | Feature reactions, objections, comparison mentions |
| `churn-save` | Understand why a user is leaving | Root cause, what would change their mind, competitor mentions |
| `upsell` | Explore expansion opportunities | Usage patterns, feature gaps, budget signals |
| `check-in` | Relationship maintenance, satisfaction pulse | NPS proxy, feature requests, referral willingness |
| `cold-outreach` | Reaching out to potential customers who haven't expressed interest yet | Pain points, willingness to pay signals, competitive mentions |

## Procedure

### Cold Outreach Conversation Type

**Cold Outreach** conversation type:
- **When**: Reaching out to potential customers who haven't expressed interest yet
- **Prep**: Research the prospect, prepare problem-led opening, have 3 discovery questions ready
- **During**: Listen 80%, talk 20%. Goal is learning, not selling.
- **Debrief**: Capture pain points, willingness to pay signals, competitive mentions

**Starting from Scratch Detection**: If no ICP artifact exists in `artifacts/product/` and no CONV- artifacts exist in `artifacts/decision-memos/`, present a "Starting from scratch" briefing:
- Guidance on finding first 10 targets (LinkedIn search, community lurking, competitor reviews)
- Starter interview script focused on problem discovery
- Link to icp-positioning skill to formalize learnings after 5+ conversations

### Mode: `prep <type>`

1. **Load Context**
   - Read `company.config.yaml` for product name, stage, ICP
   - Check `artifacts/product/` for the most recent ICP positioning artifact
   - Check `artifacts/prds/` for in-progress features (gives context on what's being built)
   - Check recent CONV- artifacts for patterns from this company/segment

2. **Generate Pre-Call Briefing**

   Produce a briefing document with:

   **Do Ask** (5 open-ended questions tailored to conversation type):
   - Discovery: "What's the hardest part of [workflow] for you right now?"
   - Demo: "Which of these capabilities matters most to your day-to-day?"
   - Churn-save: "What changed since you first signed up?"
   - Upsell: "If you could wave a magic wand and add one capability, what would it be?"
   - Check-in: "What's working well? What's frustrating?"

   **Don't Ask** (anti-patterns to avoid):
   - Leading questions ("Don't you think our feature X is great?")
   - Binary questions when you need depth ("Do you like it?" → "What's your experience with it?")
   - Feature-first questions before understanding the problem

   **Listen For** (signals specific to conversation type):
   - ICP fit signals: role, company size, tech stack, budget authority
   - Competitor mentions: who else they're evaluating or using
   - Churn risk indicators: frustration level, timeline pressure, alternative mentions
   - Willingness-to-pay signals: asking about pricing, comparing to current spend

   **Context from Recent Conversations** (if CONV- artifacts exist for this company):
   - Previous pain points mentioned
   - Commitments made
   - Open questions from last call

3. **Present Briefing** — show the briefing to the user before the call. Do not save as an artifact (ephemeral output).

### Mode: `debrief`

4. **Capture Structured Debrief**

   Prompt the user to provide (or extract from conversation notes):

   | Field | Description |
   |-------|-------------|
   | **Date** | When the conversation happened |
   | **Participant** | Name, role, company, segment |
   | **Conversation type** | discovery / demo / churn-save / upsell / check-in |
   | **Pain level** | 1 (minor inconvenience) to 5 (hair-on-fire) |
   | **Key quotes** | 2-3 verbatim quotes that capture the essence |
   | **Willingness to pay** | Strong signal / Weak signal / No signal / Price sensitive |
   | **Competitor mentions** | Any alternatives mentioned (by name) |
   | **Churn signals** | None / Low / Medium / High |
   | **Upsell signals** | None / Low / Medium / High |
   | **Feature requests** | Specific capabilities mentioned |
   | **ICP fit** | Strong / Partial / Weak — with reasoning |
   | **Recommended next action** | Follow-up call, send proposal, route to support, etc. |

5. **Classify and Tag**

   Based on the debrief, assign tags:
   - `prd_evidence: true` — if the conversation surfaced a clear product need
   - `icp_signal: true` — if the conversation provided ICP refinement data
   - `churn_signal: true` — if churn risk was detected (Medium or High)
   - `upsell_signal: true` — if expansion opportunity was identified

6. **Save Artifact**

   Write to `artifacts/decision-memos/CONV-{date}-{type}-{company}.md`:

   ```yaml
   ---
   id: CONV-{date}-{type}-{company}
   type: decision-memo
   title: "{Type} Conversation — {Company}"
   status: review
   created: {date}
   tags: [customer-conversation, {type}]
   prd_evidence: true|false
   icp_signal: true|false
   churn_signal: true|false
   ---
   ```

   Body contains the structured debrief fields above.

7. **Route Signals**

   After saving:
   - If `churn_signal: true` → inform the user: "Churn signal detected. Consider running `/support-operations` to review escalation paths, or `/activation-onboarding` to design a re-engagement flow."
   - If `icp_signal: true` → inform the user: "ICP data captured. Run `/icp-positioning` to update your ideal customer profile with this evidence."
   - If `prd_evidence: true` → inform the user: "Product evidence captured. This will be consumed by `/feedback-synthesizer` in the next synthesis cycle."

8. **Validate** — run `./tools/artifact/validate.sh` on the saved artifact.

### Mode: `patterns`

9. **Cross-Conversation Analysis**

   Scan all CONV- artifacts in `artifacts/decision-memos/`:
   - Count by conversation type
   - Extract all `Key quotes` fields
   - Tally pain levels by segment
   - List all competitor mentions with frequency
   - Identify recurring feature requests (3+ mentions = pattern)
   - Aggregate churn signals by segment

10. **Surface Patterns**

    Present a summary:
    - **Top pain points**: ranked by frequency × pain level
    - **Competitor landscape**: who's mentioned most, in what context
    - **ICP signals**: which segments show strongest fit
    - **Emerging feature requests**: requests that appear 3+ times
    - **Churn risk segments**: segments with concentrated churn signals

    This output is ephemeral (presented to user, not saved as artifact). The user can then feed specific findings into `/feedback-synthesizer` or `/icp-positioning`.

## Quality Checklist
- [ ] Pre-call briefings include 5 open-ended questions (no leading questions)
- [ ] Debriefs capture all structured fields
- [ ] Artifact frontmatter uses type `decision-memo` (passes validate.sh)
- [ ] Signal routing recommendations are provided
- [ ] Pattern analysis only runs with 3+ CONV- artifacts
- [ ] Artifact passes validation

## Cross-References
- **feedback-synthesizer** (S-PROD-04) — consumes CONV- artifacts as input during synthesis
- **icp-positioning** (S-PROD-01) — CONV- artifacts provide ICP evidence
- **prd-writer** (S-PROD-02) — CONV- artifacts populate PRD evidence sections
- **support-operations** (S-OPS-07) — churn signals feed support escalation review
- **inbound-loop-sop** — `standards/ops/inbound-loop-sop.md` documents the full pipeline
