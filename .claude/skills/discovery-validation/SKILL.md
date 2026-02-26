---
name: discovery-validation
description: Smart pre-build discovery that validates novel feature ideas before committing to a full PRD. Classifies objectives as common patterns (skip) or novel concepts (full validation with lean canvas, competitive scan, and risk assessment).
allowed-tools: Read, Grep, Glob, Bash, Write, WebSearch
user-invokable: false
---

# Discovery Validation

## Reference
- **ID**: S-PROD-05
- **Category**: Product
- **Inputs**: objective description, company.config.yaml, market context
- **Outputs**: Discovery Validation section (appended to PRD), or "skip" verdict for common patterns
- **Used by**: Product Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose

Not every feature needs discovery. Authentication, CRUD, and notifications are well-understood patterns -- just build them. But novel concepts (new business models, AI-powered interfaces, marketplace dynamics) carry real uncertainty and deserve lightweight validation before committing engineering time. This skill acts as a smart filter: it classifies the objective, skips discovery for common patterns, and runs a focused validation for novel concepts.

## When to Use

- Before writing a PRD for any new feature or product
- When the solopreneur/PM is unsure if an idea has legs
- When the feature involves unfamiliar territory (new market, new UX paradigm, new business model)
- The Product Agent should invoke this skill as a first step before PRD generation

## Discovery Validation Procedure

### Step 1: Classify Objective (Smart Filter)

Determine whether this feature needs discovery by matching it against known patterns.

#### COMMON PATTERNS (skip discovery -- proceed directly to PRD)

These are well-understood, solved problems with established implementation patterns:

- Authentication / login / signup / password reset
- CRUD operations (create, read, update, delete for any entity)
- Notifications (email, push, in-app)
- File uploads / media management
- Search / filtering / sorting
- Pagination
- Settings / preferences pages
- Admin panels / dashboards
- Payment integration (Stripe, PayPal)
- User profiles / account management
- Comments / ratings / reviews
- Tags / categories / labels
- Export / import (CSV, PDF, etc.)
- Webhooks / integrations with known services
- Role-based access control (RBAC)
- Audit logging
- Internationalization (i18n)

If the objective matches a common pattern:

> **Output**: "Discovery skipped -- [feature] matches common pattern: [category]. Proceeding to PRD."

Exit the skill. No further steps needed.

#### NOVEL CONCEPTS (full discovery required)

These involve genuine uncertainty about problem-solution fit:

- New business model or pricing paradigm
- New market segment the product has not served before
- New UX paradigm (AI-powered interface, voice UI, AR/VR)
- Marketplace or multi-sided platform dynamics
- AI/ML-powered features without precedent in the product
- Social/community features with network effects
- Features requiring new data sources or partnerships
- Anything the solopreneur describes as "I have never built something like this"
- Gamification or behavioral mechanics
- Content creation or collaboration tools with novel workflows

If the objective matches a novel concept, proceed to Step 2.

#### UNCERTAIN

If the objective does not clearly fit either category, ask the user:

> "This feature sits between common and novel. Should I run discovery validation or proceed directly to PRD?"

Respect the user's decision.

### Step 2: Lean Canvas (for NOVEL Concepts)

Produce a one-page lean canvas covering all nine boxes. Be specific -- generic answers defeat the purpose.

| Box | Prompt | Output |
|-----|--------|--------|
| **Problem** | What are the top 3 problems this feature solves? | Specific, observable problems with evidence |
| **Customer Segments** | Who specifically has these problems? | Named persona(s) with context (role, company size, behavior) |
| **Unique Value Proposition** | Single clear compelling message | One sentence that would make the target persona stop scrolling |
| **Solution** | Top 3 features that address the problems | Concrete capabilities, not abstract descriptions |
| **Channels** | How will users discover this feature? | Specific channels (in-app prompt, email campaign, blog post, word-of-mouth) |
| **Revenue Streams** | How does this feature contribute to revenue? | Direct (new pricing tier, add-on) or indirect (retention, upsell trigger) |
| **Cost Structure** | What are the build + ongoing costs? | Engineering time estimate, infrastructure costs, third-party service costs |
| **Key Metrics** | What numbers prove this works? | 2-4 specific metrics with target values |
| **Unfair Advantage** | What makes this defensible? | Data, network effects, domain expertise, integrations, brand |

### Step 3: Competitive Quick-Scan

Identify 3-5 closest alternatives and analyze them:

For each alternative:
- **Name**: Product or feature name
- **How they solve the same problem**: Specific approach, not vague description
- **Pricing**: Free, freemium, paid (with price point if known)
- **Key differentiator**: What they do better than others

**Gap Analysis**: What is missing from existing solutions? What do users complain about? Where is there whitespace?

**Positioning**: How will our approach be different or better? What trade-offs are we making? Why would someone switch from an existing solution?

Use WebSearch to find current competitors, recent reviews, and user complaints if needed. Do not fabricate competitor information -- if data is unavailable, state that explicitly.

### Step 4: Risk Assessment

#### Riskiest Assumption

Identify the ONE thing that, if wrong, kills this idea. Be specific:
- Bad: "Users might not want this"
- Good: "Freelance designers earning $50-100K/year will pay $29/month for AI-generated client proposals because they currently spend 5+ hours per proposal"

#### Validation Approach

How to test the riskiest assumption cheaply, before building:
- Landing page with email capture (test demand)
- Concierge MVP (manual delivery of the value proposition)
- Survey of target persona (test willingness to pay)
- Wizard-of-Oz prototype (fake the backend, real the frontend)
- Competitor review mining (do users complain about the gap we would fill?)

#### Problem Validation Questions

| Question | How to Answer |
|----------|---------------|
| Who has this problem? | Specific persona with demographics and behavior |
| How painful is it? (1-10 scale) | Evidence-based: time wasted, money lost, frustration signals |
| How are they solving it today? | Current workarounds, tools, manual processes |
| Will they pay for a better solution? | Willingness-to-pay signals: existing spend, stated intent, market comps |

#### Go/No-Go Recommendation

Based on the lean canvas, competitive scan, and risk assessment, provide one of three recommendations:

- **Proceed to PRD**: Evidence supports building this. Riskiest assumption is testable and the upside justifies the cost.
- **Validate first**: The idea has potential but the riskiest assumption is untested. Run the validation approach before committing to a PRD.
- **Reconsider**: Multiple red flags -- strong competition with no clear differentiator, unclear demand, or high cost with uncertain return.

Include a clear rationale for the recommendation (2-3 sentences).

### Step 5: Output

Append a "Discovery Validation" section to the PRD (this is NOT a separate artifact -- it lives within the PRD):

```markdown
## Discovery Validation

**Classification**: NOVEL -- [reason why this needed discovery]
**Lean Canvas**: [summary of the 9 boxes, or "See full canvas above"]
**Competitive Landscape**: [3-5 alternatives with gap analysis summary]
**Riskiest Assumption**: [the one specific thing that could kill this]
**Validation Status**: Validated / Needs Testing / Risky
**Recommendation**: Proceed to PRD / Validate first / Reconsider
**Rationale**: [2-3 sentences explaining the recommendation]
```

If discovery was skipped (common pattern), the PRD should include a brief note:

```markdown
## Discovery Validation

**Classification**: COMMON PATTERN -- [category name]
**Discovery**: Skipped. This is a well-understood pattern with established implementation approaches.
```

## Quality Checklist

- [ ] Smart filter correctly classified the objective (common vs. novel)
- [ ] If NOVEL: lean canvas is complete (all 9 boxes filled with specifics)
- [ ] Competitive scan has 3-5 real alternatives (not generic or fabricated)
- [ ] Riskiest assumption is specific and testable (not vague)
- [ ] Problem validation questions are answered with evidence (not assumptions)
- [ ] Go/No-Go recommendation is clear with rationale
- [ ] If COMMON: skip is justified with pattern category
- [ ] Output format matches the template (appended to PRD, not separate artifact)
