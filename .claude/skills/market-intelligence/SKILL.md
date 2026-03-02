---
name: market-intelligence
description: Produces competitive landscape scans, technology radar assessments, and trend timing analysis. Use when monitoring competitors, evaluating new technologies, or identifying market opportunities.
---

# Market Intelligence

## Reference
- **ID**: S-PROD-07
- **Category**: Product / Strategy
- **Inputs**: company.config.yaml, existing PRDs, competitor list, industry context
- **Outputs**: market intelligence brief → artifacts/product/, technology radar → artifacts/product/
- **Used by**: Product Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose

Provide structured, ongoing market intelligence that moves beyond reactive discovery (validating a single idea) to proactive opportunity detection. Produces competitive landscape scans, technology radar assessments (ADOPT/TRIAL/ASSESS/HOLD), and trend timing analysis.

This skill turns "I think our competitors are doing X" into structured, evidence-based market awareness that feeds into PRD priorities and architecture decisions.

## When to Use

- Quarterly competitive landscape refresh
- Before major product pivots or new market entry
- When evaluating whether to adopt a new technology, library, or framework
- When competitors launch notable features
- When the Product Agent needs market context for prioritization
- When the Engineering Agent needs technology evaluation for architecture decisions

## Market Intelligence Procedure

### Step 1: Load Context

1. Read `company.config.yaml` -- understand product, domain, stage, tech stack
2. Read existing market intelligence in `artifacts/product/` -- avoid duplicate analysis
3. Read existing PRDs -- what competitive pressure do they reference?
4. Identify the monitoring scope:
   - Direct competitors (same problem, same audience)
   - Adjacent competitors (different approach, overlapping audience)
   - Emerging threats (new entrants, tangential products expanding)

### Step 2: Competitive Landscape Scan

Produce a structured competitive analysis:

#### Competitor Profile Template

For each competitor (3-5 direct, 2-3 adjacent):

| Dimension | Analysis |
|-----------|----------|
| **Product** | Core features, unique differentiators, pricing model |
| **Positioning** | Target audience, messaging, value proposition |
| **Strengths** | What they do better than us |
| **Weaknesses** | Gaps, complaints (from reviews, social, forums) |
| **Recent Moves** | Last 90 days: launches, pricing changes, funding, pivots |
| **Threat Level** | Low / Medium / High -- with justification |

#### Feature Parity Matrix

Map key features across competitors:

```
| Feature | Us | Competitor A | Competitor B | Competitor C |
|---------|-----|-------------|-------------|-------------|
| Feature 1 | Yes | Yes | No | Yes |
| Feature 2 | No | Yes | Yes | No |
| Feature 3 | In Progress | Yes | Yes | Yes |
```
Legend: Yes = has it, No = doesn't have it, In Progress = building, Partial = incomplete

Identify: parity gaps (they all have it, we don't), differentiation opportunities (we have it, they don't), table stakes (everyone needs this).

### Step 3: Technology Radar

Evaluate technologies relevant to the product using the ThoughtWorks radar model:

#### Classification

| Ring | Definition | Action |
|------|-----------|--------|
| **ADOPT** | Proven, low risk, clear value -- use it now | Include in tech stack |
| **TRIAL** | Worth trying on a non-critical project | Spike or proof-of-concept |
| **ASSESS** | Interesting, worth understanding -- not ready to try | Monitor, read docs |
| **HOLD** | Proceed with caution -- issues identified | Avoid new adoption |

#### Evaluation Criteria

For each technology being assessed:
1. **Fitness**: Does it solve a real problem we have?
2. **Maturity**: Production-ready? Community size? Documentation quality?
3. **Ecosystem**: Integrates with our stack? Active maintenance? Breaking changes frequency?
4. **Cost**: Licensing, infrastructure, team ramp-up time
5. **Risk**: Vendor lock-in? Single maintainer? Regulatory concerns?

#### Technology Radar Template

```
## Technology Radar -- [Quarter Year]

### ADOPT
- **[Tech]**: [Why -- 1 sentence] (evaluated: [date])

### TRIAL
- **[Tech]**: [Why -- 1 sentence, what to try it on] (evaluated: [date])

### ASSESS
- **[Tech]**: [Why watching -- 1 sentence] (evaluated: [date])

### HOLD
- **[Tech]**: [Why cautious -- 1 sentence] (evaluated: [date])
```

Note: This subsumes the "Tool/Technology Evaluation" concept -- technology evaluation happens within the market intelligence context, not in isolation.

### Step 4: Trend Timing Analysis

For identified trends and opportunities, assess timing:

#### Timing Framework

| Window | Signal | Action |
|--------|--------|--------|
| **Too Early** (<5% market adoption) | Only innovators talking about it, no proven business model | ASSESS on radar, monitor monthly |
| **Sweet Spot** (5-25% adoption) | Early majority adopting, clear use cases, competitors starting | TRIAL or BUILD -- this is the window |
| **Mainstream** (25-50% adoption) | Table stakes, user expectations set | ADOPT as parity -- differentiate on execution |
| **Too Late** (>50% adoption) | Saturated, commoditized | Skip unless catching up on parity |

For each trend:
1. Estimate current adoption stage
2. Identify signals that indicate the next transition
3. Recommend action: monitor, prototype, build, or skip
4. If "build": estimate development effort and link to PRD pipeline

### Step 5: App Store Intelligence (Conditional)

Only when `platforms.targets` includes `ios` or `android`:
1. Review competitor app store listings (ratings, review themes, recent updates)
2. Identify keyword trends and category shifts
3. Note: feature requests appearing in competitor reviews but not addressed
4. Track rating trajectories (improving or declining competitors)

### Step 6: Produce Market Intelligence Brief

Create the brief artifact:

```yaml
---
id: MI-XXX
type: market-intelligence
status: draft
---
```

Structure:
1. **Executive Summary** (3-5 bullet points: what matters most right now)
2. **Competitive Landscape** (profiles + feature parity matrix)
3. **Technology Radar** (ADOPT/TRIAL/ASSESS/HOLD)
4. **Trend Analysis** (timing assessments with recommended actions)
5. **Opportunities** (gaps we can exploit, ranked by impact)
6. **Threats** (risks to monitor, ranked by likelihood x impact)
7. **Recommendations** (specific actions for Product, Engineering, Growth)

### Step 7: Validate and Handoff

1. Save to `artifacts/product/`
2. Run `./tools/artifact/validate.sh`
3. Competitive landscape feeds into: `prd-writer` (competitive requirements), `positioning-messaging` (differentiation), `sprint-prioritizer` (priority context)
4. Technology radar feeds into: `architecture-draft` (tech stack decisions), Engineering Agent (library choices)
5. Schedule next refresh: quarterly for full scan, monthly for trend monitoring

## Quality Checklist

- [ ] At least 3 direct competitors profiled
- [ ] Feature parity matrix covers key differentiating features
- [ ] Technology radar uses ADOPT/TRIAL/ASSESS/HOLD classification
- [ ] Each technology assessment has clear evaluation criteria
- [ ] Trend timing uses the timing framework (too early / sweet spot / mainstream / too late)
- [ ] Recommendations are specific and actionable
- [ ] Brief distinguishes facts (observed) from analysis (interpreted)
- [ ] Sources are cited (URLs, dates) for key claims
- [ ] Artifact has valid frontmatter

## Cross-References

- **discovery-validation**: Market intelligence provides context for discovery validation (is this idea already being done? by whom? how?)
- **positioning-messaging**: Competitive landscape directly informs positioning and differentiation strategy
- **architecture-draft**: Technology radar feeds into tech stack fitness evaluation in RFCs
- **sprint-prioritizer**: Competitive pressure and market opportunities feed into priority scoring
