---
name: rapid-prototype
description: Time-boxed MVP prototyping methodology for proof-of-concept and investor demos. Skips RFC, security review, and full QA for speed. Use when validating ideas quickly or preparing demos.
user-invokable: true
argument-hint: "describe what you want to prototype"
---

# Rapid Prototype

## Reference

- **ID**: S-ORG-11
- **Category**: Orchestration
- **Inputs**: objective description, company.config.yaml
- **Outputs**: mini-PRD, working prototype, demo script
- **Used by**: User (directly via /prototype), Orchestrator Agent
- **Tool scripts**: ./tools/artifact/validate.sh, ./tools/db/seed.sh

## Purpose

Build the smallest thing that proves a hypothesis -- fast. This is an alternative to `/ship` for time-boxed proof-of-concept work. It deliberately skips RFC, security review, full QA, and growth assets to maximize speed.

## When to Use

- Proof of concept for a new idea
- Investor demo preparation
- Hackathon project
- Validating a UX approach before committing to full build
- "Can we even build this?" technical spikes

## When NOT to Use

- Production features (use `/ship`)
- Anything touching user data in production
- Features that need security review
- Anything that will be deployed to real users without further hardening

## Procedure

### Step 1: Load Configuration

Read `company.config.yaml` and extract:

- `tech_stack.*` -- language, framework, runtime, database
- `company.stage` -- affects whether prototype approach is appropriate
- `conventions.*` -- commit style, branching

### Step 2: Select Time-Box

Ask the user which time-box applies:

| Time-Box | Scope | Data | Tradeoffs |
|----------|-------|------|-----------|
| **4-hour sprint** | 1-2 features, single screen | Hardcoded data OK | Fastest feedback, throwaway quality, proves a single interaction |
| **1-day build** | 3-4 features, 2-3 screens | Real data shape but mocked backends OK | Enough polish to show stakeholders, still disposable |
| **3-day build** | 5-6 features, full flow | Real backend with shortcuts (no auth, no edge cases) | Demo-ready, can evolve into production with significant rework |

Present tradeoffs for each and let user choose.

### Step 3: Define What to Prove

Ask: "What hypothesis does this prototype validate?"

Force a single sentence hypothesis. If user gives multiple, force them to pick ONE. The prototype exists to validate one thing -- not to be a mini product.

### Step 4: Scope Ruthlessly

Maximum 3 acceptance criteria. If user proposes more, cut. Use this template:

```markdown
## Mini-PRD: {Prototype Name}

**Hypothesis**: {single sentence}
**Time-box**: {4h | 1d | 3d}
**Date**: {today}

### Acceptance Criteria (max 3)
1. {AC-1}
2. {AC-2}
3. {AC-3}

### Explicitly Out of Scope
- Authentication / authorization
- Error handling beyond basic try/catch
- Responsive design (pick ONE viewport)
- Automated tests
- Security review
- Performance optimization
- Documentation

### Demo Script
1. {Step 1: what to show}
2. {Step 2: what to show}
3. {Step 3: what to show}
```

Save as `artifacts/prds/prototype-{name}-{date}.md` with status `draft` and type `prd` frontmatter.

### Step 5: Build with Prototype Rules

Delegate to Engineering Agent with these constraints:

- **Skip RFC** -- go straight to implementation
- **Skip security review**
- **Skip test plan generation**
- Use the simplest possible architecture (monolith, SQLite, in-memory, static data)
- Hardcode what you can, mock what you must
- Focus on the happy path ONLY
- Use seed data for realistic demo state

### Step 6: Prepare Demo

After build is complete:

1. Load seed data (run `./tools/db/seed.sh nominal` if available)
2. Verify all 3 acceptance criteria work in sequence
3. Write the demo script (talking points for each step)
4. Take screenshots of key states if applicable

### Step 7: Demo Readiness Checklist

- [ ] Happy path works end-to-end for all 3 AC
- [ ] Seed data is loaded and looks realistic
- [ ] Demo script has talking points for each step
- [ ] Known limitations are documented
- [ ] No error states visible during demo flow

### Step 8: Graduation Criteria

Document what is needed to graduate this prototype to a production feature:

- [ ] Full PRD with comprehensive acceptance criteria
- [ ] RFC with architecture decisions
- [ ] Security review / threat model
- [ ] Full test plan and QA
- [ ] Error handling and edge cases
- [ ] Responsive design
- [ ] Performance optimization
- [ ] Documentation

Mark these as a checklist in the mini-PRD artifact under a `## Graduation to Production` section.

## Quality Checklist

- [ ] Hypothesis is a single, testable sentence
- [ ] Acceptance criteria capped at 3
- [ ] Time-box selected and communicated
- [ ] Out-of-scope list is explicit
- [ ] Demo script covers all acceptance criteria
- [ ] Graduation criteria documented for production path
- [ ] Mini-PRD saved with proper artifact frontmatter
