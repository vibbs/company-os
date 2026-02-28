---
name: ux-research
description: Designs lean user research plans with method selection, interview scripts, usability testing protocols, and journey mapping. Use when validating user needs, testing usability, or building personas before PRD creation.
allowed-tools: Read, Grep, Glob, Bash, Write
---

# UX Research

## Reference
- **ID**: S-PROD-06
- **Category**: Product / Research
- **Inputs**: product context (company.config.yaml), existing PRDs, user feedback themes (from feedback-synthesizer), analytics data
- **Outputs**: research plan → artifacts/product/, research findings → artifacts/product/
- **Used by**: Product Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose

Design lean, sprint-friendly user research that bridges the gap between raw feedback and validated understanding. Not every product decision needs a six-week study -- but shipping blindly when user behavior is unclear is how teams build the wrong thing. This skill provides structured methods to understand user needs, test usability, map journeys, and develop data-driven personas, all within practical time constraints that respect a small team's capacity.

This skill links upstream to discovery-validation (which identifies novel concepts that need deeper investigation) and downstream to prd-writer (which consumes research findings as evidence for requirements). When feedback-synthesizer surfaces conflicting or ambiguous themes, UX research provides the methods to resolve them with direct user evidence rather than assumptions.

## When to Use

- Before creating a PRD for a novel feature (complements discovery-validation)
- After feedback-synthesizer surfaces unclear or conflicting themes
- When existing usability data is thin or outdated
- When the team disagrees about user needs or behavior
- When entering a new market segment or user persona
- When a shipped feature has unexpectedly low adoption

## UX Research Procedure

### Step 1: Load Context

Before designing any research:

1. **Read `company.config.yaml`** -- understand product, domain, stage, platforms
2. **Read existing feedback synthesis** in `artifacts/product/` -- what themes are already identified?
3. **Read existing PRDs** -- what assumptions need validation?
4. **Read analytics data** if available -- what does behavior tell us?

### Step 2: Classify Research Need

Determine the research type to select appropriate methods:

| Type | Goal | When | Duration |
|------|------|------|----------|
| **Exploratory** | Discover unknown needs, map problem space | Pre-PRD, new domain, unclear user behavior | 3-5 days |
| **Evaluative** | Test existing designs or prototypes | Pre-launch, redesign, usability issues | 2-3 days |
| **Generative** | Inspire new solutions, understand mental models | Innovation phase, competitive differentiation | 3-5 days |

### Step 3: Select Research Methods

Based on research type, time budget, and access to users, select 1-3 methods:

**Quick Methods (1-2 days)**:

| Method | Best For | Participants | Output |
|--------|----------|-------------|--------|
| 5-Second Test | First impression, clarity | 20-50 (remote) | Comprehension score, first impressions |
| Card Sorting | Information architecture, navigation | 15-30 (remote) | Category groupings, labels |
| Micro-Survey | Quick validation, preference | 50-200 (in-app) | Quantitative validation |
| Heuristic Evaluation | Usability audit, quick wins | 1 (expert review) | Severity-rated issue list |

**Standard Methods (2-5 days)**:

| Method | Best For | Participants | Output |
|--------|----------|-------------|--------|
| Usability Testing | Task success, friction points | 5-8 per round | Task completion rates, friction map |
| User Interviews | Deep understanding, motivation | 5-8 | Themes, quotes, journey insights |
| Journey Mapping | End-to-end experience, pain points | Workshop (3-5) | Current/future state journey map |
| Tree Testing | Navigation structure validation | 20-50 (remote) | Findability scores |

**Advanced Methods (5+ days)**:

| Method | Best For | Participants | Output |
|--------|----------|-------------|--------|
| Diary Study | Longitudinal behavior, habits | 10-15 over 1-2 weeks | Behavior patterns, context |
| A/B Testing | Causal validation of design changes | 100+ per variant | Statistical comparison |
| Session Recordings | Real usage patterns, edge cases | 50-100 sessions | Behavioral heat maps |
| Competitive Usability | Benchmarking against alternatives | 5-8 per competitor | Comparative strengths/weaknesses |

### Step 4: Produce Research Plan

Create a research plan artifact with:

1. **Research Question**: The specific question we need answered (e.g., "Do users understand our pricing page?")
2. **Method(s)**: Selected from Step 3 with justification
3. **Participants**:
   - Recruitment criteria (demographics, behavior, segment)
   - Sample size and rationale
   - Recruitment channels (existing users, user testing platforms, social media)
4. **Session Script / Protocol**:
   - For interviews: 5-7 open-ended questions, warm-up > core > wrap-up structure
   - For usability tests: 3-5 task scenarios with success criteria
   - For surveys: question set with response types
5. **Timeline**: Start date, fieldwork duration, analysis period
6. **Success Criteria**: What constitutes a clear finding vs. inconclusive

Template for interview script:

```
Warm-up (2 min): "Tell me about your role and how you currently [relevant activity]"
Context (3 min): "Walk me through the last time you [relevant task]"
Core Questions (15 min):
  1. [Open-ended question about the problem space]
  2. [Open-ended question about current solutions/workarounds]
  3. [Open-ended question about ideal outcome]
  4. [Specific question about the feature/concept being explored]
  5. [Question about priorities/tradeoffs]
Reaction (5 min): [Show prototype/mockup if available] "What are your first thoughts?"
Wrap-up (2 min): "Anything else you'd like to share? Anyone you'd recommend I speak with?"
```

Save plan to `artifacts/product/research-plan-{feature}.md` with artifact frontmatter.

### Step 5: Conduct Research (Guidance)

Provide guidance for execution:

- **Note-taking**: Use a structured template (participant ID, timestamp, observation, quote, severity)
- **Recording**: Always get consent. Record for team review, not just notes.
- **Bias mitigation**: Don't lead questions. Don't react to answers. Ask "why" and "tell me more."
- **Sample rule**: After 5 participants, you've found ~80% of usability issues. Stop when patterns repeat.
- **Remote tools**: Maze (unmoderated), Hotjar (recordings), Typeform (surveys), Loom (moderated), Miro (workshops)

### Step 6: Analyze and Synthesize Findings

1. **Code observations**: Tag each observation with themes (affinity mapping)
2. **Severity rate issues**:
   - Critical: prevents task completion
   - High: causes significant confusion or delay
   - Medium: noticeable friction but workaround exists
   - Low: minor annoyance, cosmetic
3. **Quantify where possible**: task success rate, time-on-task, error rate, satisfaction score
4. **Extract patterns**: What do 3+ participants struggle with? What delights them?
5. **Collect evidence**: Representative quotes (with participant ID, never names)

### Step 7: Build Personas (Optional)

If research reveals distinct user segments:

1. Define 2-4 personas based on observed behavior (not demographics alone)
2. Use Jobs-to-be-Done framing: "When [situation], I want to [motivation], so I can [outcome]"
3. Include: goals, frustrations, current tools, decision criteria, tech comfort level
4. Anti-stereotyping: base on data patterns, not assumptions about age/gender/role
5. Validate personas against analytics segments if available

### Step 8: Produce Research Findings

Create findings artifact:

```yaml
---
id: RES-XXX
type: research
status: draft
parent: [PRD-XXX or null if pre-PRD]
---
```

Structure:

1. **Research Question** (from plan)
2. **Method & Participants** (what was done, who participated)
3. **Key Findings** (3-7 findings, severity-rated, with evidence)
4. **Quotes** (representative quotes per finding)
5. **Recommendations** (specific actions, linked to findings)
6. **Implications for PRD** (what should change in the product requirements)
7. **Open Questions** (what we still don't know)

### Step 9: Validate and Handoff

1. Save to `artifacts/product/`
2. Run `./tools/artifact/validate.sh`
3. If parent PRD exists, link via `./tools/artifact/link.sh`
4. Findings feed into: `prd-writer` (requirements), `activation-onboarding` (user journey), `design-system` (UX patterns)

## Heuristic Evaluation Framework

When conducting expert review, evaluate against Nielsen's 10 Usability Heuristics:

| # | Heuristic | What to Check |
|---|-----------|---------------|
| 1 | Visibility of system status | Loading indicators, progress bars, feedback on actions |
| 2 | Match between system and real world | Familiar language, logical ordering, real-world conventions |
| 3 | User control and freedom | Undo, back button, cancel, escape hatches |
| 4 | Consistency and standards | Same words mean same things, platform conventions followed |
| 5 | Error prevention | Constraints, confirmations, defaults, clear affordances |
| 6 | Recognition over recall | Visible options, contextual help, recent items |
| 7 | Flexibility and efficiency | Shortcuts, customization, expert paths |
| 8 | Aesthetic and minimalist design | No unnecessary info, clear hierarchy, whitespace |
| 9 | Help users recognize and recover from errors | Clear error messages, suggested fixes, non-destructive |
| 10 | Help and documentation | Searchable, task-oriented, concise, contextual |

Rate each heuristic: Pass / Minor Issue / Major Issue / Critical Issue

## Cross-References

- **discovery-validation**: UX research provides evidence for discovery validation. Run research before or alongside discovery for novel features.
- **feedback-synthesizer**: Feedback themes can identify areas that need deeper research. Research findings enrich future feedback synthesis.
- **prd-writer**: Research findings directly inform PRD requirements, especially acceptance criteria and success metrics.
- **activation-onboarding**: Journey maps and usability findings feed directly into onboarding flow design.
- **design-system**: Usability findings may identify UX patterns that need updating or new patterns to add.

## Quality Checklist

- [ ] Research type correctly classified (exploratory/evaluative/generative)
- [ ] Method selection justified based on time budget and research question
- [ ] Research plan has clear question, method, participants, and timeline
- [ ] Interview/test script follows open-ended, non-leading question principles
- [ ] Sample size is appropriate for the method (5-8 for usability, 20+ for surveys)
- [ ] Findings are severity-rated with supporting evidence
- [ ] Recommendations are specific and actionable (not vague "improve usability")
- [ ] Personas (if built) use Jobs-to-be-Done framing, not demographic stereotypes
- [ ] Research artifacts have valid frontmatter
- [ ] Findings are linked to downstream artifacts (PRD, activation plan)
