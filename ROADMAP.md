# Company OS Roadmap

A living roadmap for Company OS capabilities. Organized by priority tier with estimated complexity. Each item describes what it would add to the solopreneur's "AI company" and why it matters.

**Current state**: 44 skills, 6 agents, 23 tool scripts. Covers the full Build → Ship axis (idea → PRD → RFC → implementation → QA → release) plus operational maturity (incidents, deployment, instrumentation), growth infrastructure (feature flags, email lifecycle, analytics), and mobile readiness.

---

## Tier 1 — High Impact (Next Up)

These close the biggest remaining gaps for a solopreneur running a live product.

### Support Triage & Feedback Loop

**Problem**: Users report bugs, request features, and ask questions. Without a structured intake, feedback gets lost in email, Discord, and Twitter DMs. The solopreneur is the entire support team.

**What it adds**:
- Skill that classifies inbound support requests (bug, feature request, question, churn signal)
- Severity assignment with SLA guidance (P0 bug → same day, feature request → backlog)
- Auto-routes to the right artifact: bugs → engineering tasks, feature requests → PRD candidates, churn signals → activation experiments
- Feedback aggregation: groups similar requests to surface patterns ("12 users asked for dark mode")
- Integrates with `feedback-synthesizer` skill (already exists) for periodic theme extraction

**Complexity**: Medium — 1 new skill + modifications to feedback-synthesizer and prd-writer
**Agent**: Product
**Dependencies**: None

### Customer Conversation Framework

**Problem**: The solopreneur talks to users (sales calls, support chats, user interviews) but has no structured way to capture insights and feed them back into the product process.

**What it adds**:
- Pre-call prep templates: what to ask, what to listen for, what not to lead with
- Post-call debrief template: key quotes, pain points, willingness to pay, competitive mentions
- Pattern library: common conversation types (discovery interview, demo call, churn save, upsell)
- Output feeds into ICP refinement (existing `icp-positioning` skill) and PRD evidence sections
- Conversation log stored in `artifacts/decision-memos/` with `CONV-` prefix for traceability

**Complexity**: Medium — 1 new skill + modifications to icp-positioning and prd-writer
**Agent**: Product
**Dependencies**: None

---

## Tier 2 — Medium-High Impact (Near-Term)

Important for sustainable growth. Not urgent for launch but critical within the first 6 months of a live product.

### Financial Forecasting & Runway

**Problem**: The solopreneur needs to know: Can I afford to keep building? When do I run out of money? What revenue targets do I need to hit? Currently no financial modeling capability exists.

**What it adds**:
- Runway calculator: monthly burn, revenue, months remaining
- Revenue projection models: linear, cohort-based, bottoms-up (users × conversion × ARPU)
- Break-even analysis: when does revenue cover costs
- Scenario planning: best case / expected / worst case with different growth assumptions
- Pricing sensitivity: how changes in pricing affect runway and revenue targets
- Integrates with `pricing-unit-economics` skill (already exists) for CAC/LTV inputs
- Output: financial snapshot artifact in `artifacts/decision-memos/` with `FIN-` prefix

**Complexity**: Medium — 1 new skill
**Agent**: Product or Ops & Risk
**Dependencies**: pricing-unit-economics (exists)

### Performance Optimization Playbook

**Problem**: The product is live and getting slower. The solopreneur needs to diagnose bottlenecks and optimize without deep performance engineering expertise.

**What it adds**:
- Performance audit procedure: identify N+1 queries, missing indexes, unoptimized images, bundle size
- Database optimization patterns: query analysis, indexing strategy, connection pooling
- Frontend performance: Core Web Vitals (LCP, FID, CLS), bundle analysis, lazy loading, caching strategy
- API performance: response time budgets, caching headers, pagination efficiency
- Performance budget definition and regression detection
- Integrates with `perf-benchmark-checklist` skill (already exists) for baseline metrics
- Integrates with `observability-baseline` skill (already exists) for metrics/tracing

**Complexity**: Medium — 1 new skill
**Agent**: Engineering
**Dependencies**: perf-benchmark-checklist, observability-baseline (both exist)

---

## Tier 3 — Medium Impact (Mid-Term)

Valuable capabilities that become important as the product gains traction and the solopreneur considers scaling.

### Community & Founder Visibility

**Problem**: For solopreneurs, personal brand and community ARE the marketing team. Building in public, engaging with communities, and maintaining founder visibility drives organic growth. No skill currently guides this.

**What it adds**:
- Build-in-public content calendar: what to share, where, how often
- Community platform strategy: which platforms matter for your ICP (Discord, Twitter/X, Reddit, Indie Hackers, HN)
- Engagement playbook: how to contribute value without pure self-promotion
- Launch event planning: Product Hunt, HN Show, Reddit launches (extends existing `channel-playbook`)
- Developer relations patterns (if B2D product): docs, examples, tutorials, office hours
- Content repurposing: one insight → tweet thread → blog post → newsletter → changelog

**Complexity**: Low-Medium — 1 new skill, modifications to channel-playbook
**Agent**: Growth
**Dependencies**: channel-playbook (exists)

### Paid Acquisition & Ad Management

**Problem**: Organic growth plateaus. The solopreneur needs to experiment with paid channels but has no framework for budget allocation, creative testing, or ROAS tracking.

**What it adds**:
- Channel selection framework: which paid channels match your ICP and budget
- Budget allocation: test budget → learning phase → scale phase
- Creative brief templates: ad copy, visual specs, landing page alignment
- A/B testing framework for ad variants
- ROAS tracking and attribution (ties into instrumentation/analytics)
- Kill criteria: when to stop spending on a channel
- Platform-specific patterns: Google Ads, Meta Ads, LinkedIn Ads, Twitter Ads

**Complexity**: Medium — 1 new skill
**Agent**: Growth
**Dependencies**: instrumentation (exists), channel-playbook (exists)

### Team Scaling Preparation

**Problem**: The solopreneur is ready to hire. First hires are the highest-leverage decisions in a company. No skill helps think through who to hire, how to onboard them, or how to hand off knowledge.

**What it adds**:
- Hiring priority framework: which role unlocks the most growth (first hire: engineer vs marketer vs ops)
- Role definition templates: responsibilities, success metrics, autonomy level
- Onboarding checklist: codebase walkthrough, Company OS orientation, artifact system intro
- Knowledge transfer playbook: what's in the founder's head that needs to be documented
- Access control preparation: which systems, which permissions, which secrets
- Team communication patterns: async-first conventions, decision-making framework
- Contractor vs full-time decision framework

**Complexity**: Medium — 1 new skill
**Agent**: Product or Ops & Risk
**Dependencies**: None

---

## Distant Future — Long-Term Vision

These capabilities are outside the current core scope but represent the full vision of Company OS as a complete operating system for a company. They will become relevant as the product and company mature.

### Tax, Accounting & Entity Formation

**Why distant**: Requires domain-specific legal/financial expertise that varies by jurisdiction. Best served by integrating with specialized tools (Stripe Atlas, Mercury, QuickBooks) rather than building from scratch.

**What it could add**:
- Entity formation decision tree: LLC vs S-Corp vs C-Corp, state selection, registered agent
- Tax calendar: estimated quarterly payments, annual filings, sales tax obligations
- Bookkeeping conventions: chart of accounts, expense categorization, receipt management
- Integration patterns for accounting tools (QuickBooks, Xero, Wave)
- Tax optimization basics: deductible expenses for software businesses, R&D credits
- Financial reporting templates: P&L, balance sheet, cash flow

**Approach**: Start with a lightweight "financial ops checklist" skill that recommends tools and processes, rather than trying to replace accountants.

### CRM & Sales Pipeline

**Why distant**: Most solopreneur SaaS products are self-serve. A full CRM/pipeline is premature until there's a sales-assisted motion. The existing `customer-conversation-framework` (Tier 1) covers the early-stage need.

**What it could add**:
- Lead qualification framework (MQL → SQL → opportunity → close)
- Pipeline stage definitions with exit criteria
- Sales playbook: discovery → demo → proposal → negotiation → close
- CRM data model and integration patterns (HubSpot, Pipedrive, Attio)
- Revenue forecasting from pipeline data
- Win/loss analysis templates

**Approach**: Only build when the product has a clear sales-assisted segment. Start with a simple deal tracker in artifacts before investing in CRM integration.

### Physical Operations & Logistics

**Why distant**: Company OS is optimized for digital/SaaS products. Physical operations (inventory, shipping, warehousing) require fundamentally different workflows and tooling.

**What it could add**:
- Inventory management patterns
- Fulfillment workflow design
- Supplier relationship management
- Shipping and logistics optimization
- Returns and customer service for physical goods

**Approach**: If demand emerges, build as a separate "Company OS for Physical Products" extension rather than bloating the core SaaS-focused system.

### Investor Relations & Fundraising

**Why distant**: Most solopreneurs are bootstrapped. Fundraising is a distinct mode of operation with different artifacts (pitch decks, financial models, cap tables) that only a subset of users need.

**What it could add**:
- Pitch deck framework: problem → solution → market → traction → team → ask
- Financial model templates for fundraising (different from operational forecasting)
- Cap table management basics
- Investor update templates: monthly/quarterly updates for existing investors
- Due diligence preparation checklist
- Term sheet analysis framework

**Approach**: Build as an optional skill pack that can be enabled when a solopreneur decides to raise. The `financial-forecasting` skill (Tier 2) provides the operational foundation this would extend.

---

## How to Contribute

Each roadmap item follows the Company OS ship flow:

1. Create a PRD in `artifacts/prds/` defining the skill's scope and acceptance criteria
2. Design the skill procedure in an RFC in `artifacts/rfcs/`
3. Implement the skill in `.claude/skills/<name>/SKILL.md`
4. Update the relevant agent file in `.claude/agents/`
5. Run `/system-maintenance` to sync all documentation
6. Run `./tools/registry/health-check.sh` to verify

To propose a new roadmap item, open an issue describing the gap, who it helps, and what artifacts the skill would produce.

---

*Last updated: 2026-02-26*
