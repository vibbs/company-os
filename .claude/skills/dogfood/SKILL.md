---
name: dogfood
description: Autonomous dogfooding — tests the product by using it as real users would, capturing issues with severity ratings. Supports web apps (via agent-browser) and API-only products.
user-invokable: true
argument-hint: "<app-url> [--prd <prd-id>]"
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Dogfood

## Reference
- **ID**: S-QA-06
- **Category**: QA / Testing
- **Inputs**: App URL, PRD (acceptance criteria), test plan (optional), company.config.yaml
- **Outputs**: Dogfood report artifact in `artifacts/qa-reports/` with journey results and severity-rated issues
- **Used by**: QA & Release Agent, User (directly)
- **Tool scripts**: `./tools/qa/dogfood.sh`, `./tools/artifact/validate.sh`
- **Dependencies**: `agent-browser` skill (for web apps), `seed-data` skill (recommended, for realistic data)

## Purpose

Autonomously exercise the product the way real users do. Instead of checking artifacts or running unit tests, dogfooding navigates the actual running application, performs user actions, and reports what breaks. This catches issues that artifact-level QA misses: broken flows, confusing UX, console errors, missing error handling, and integration failures.

## When to Use

- After implementation is complete and the app is running (locally or staging)
- Before release, as a complement to unit/integration/contract tests
- After deploying to staging to verify the deployment works end-to-end
- When a user reports "it doesn't work" and you need to reproduce their experience
- As a periodic health check on a running environment

## Prerequisites

1. **The app must be running** at an accessible URL (localhost, staging, or production)
2. **Seed data must be loaded** — run `./tools/db/seed.sh nominal` before dogfooding. If the `seeds/` directory does not exist, run `/seed-data` first to generate seed files. Dogfooding against an empty database produces unreliable results and should be treated as a prerequisite failure.
3. **For web apps**: `agent-browser` skill must be available (for browser automation)
4. **For API-only products**: `curl` must be available (always present)

## Dogfood Procedure

### Step 1: Load Context

1. **Read `company.config.yaml`** — extract tech stack, especially `tech_stack.framework` to determine product type
2. **Classify product type**:
   - **Web app** — if framework is Next.js, React, Vue, Svelte, Angular, Astro, Django templates, Rails, etc.
   - **API-only** — if framework is Express, FastAPI, Gin, Echo, Hono, or no frontend framework configured
   - **Hybrid** — web app with separate API (run both modes)
3. **Read PRD** — if `--prd <prd-id>` argument provided, read the specific PRD from `artifacts/prds/`. Otherwise, scan for the most recent approved PRD.
4. **Read test plan** — if one exists in `artifacts/test-plans/` linked to the PRD, use it to inform journey definitions

### Step 2: Extract User Journeys

From the PRD's acceptance criteria and user stories, extract concrete user journeys. Each journey is a sequence of user actions with expected outcomes.

**Journey categories**:

| Category | Description | Priority |
|----------|-------------|----------|
| **Happy paths** | Core workflows end-to-end (the "aha moments") | P0 — always test |
| **Error paths** | What happens when things go wrong (invalid input, network failure, unauthorized) | P1 — test if time permits |
| **Edge cases** | Boundary inputs, rapid actions, empty states, long content | P2 — test if time permits |
| **Onboarding** | First-time user experience, empty state → first action | P0 — always test |

For each journey, define:

```markdown
### Journey: [Name]
- **Category**: [happy-path | error-path | edge-case | onboarding]
- **Priority**: [P0 | P1 | P2]
- **Preconditions**: [what state the app must be in]
- **Entry point**: [URL or API endpoint]
- **Steps**:
  1. [Action] → Expected: [outcome]
  2. [Action] → Expected: [outcome]
  ...
- **Success criteria**: [what "pass" looks like]
- **Checks**: [console errors, response codes, visual elements]
```

### Step 3: Pre-flight Validation

Before executing journeys:

1. Run `./tools/qa/dogfood.sh <url>` to verify the app is reachable
2. Check for required authentication (if the app requires login, define auth credentials or tokens)
3. **Verify seed data is loaded**:
   - Run `./tools/db/seed.sh --list` to confirm seed files exist
   - If `seeds/` directory is missing: **STOP** — run `/seed-data` first, then retry dogfooding
   - Check a known endpoint or page for expected data (e.g., list endpoint returns records)
   - If seed data is absent or `seeds/` is missing: report as **PREFLIGHT FAILURE** — do not proceed with dogfooding
4. Create output directory for screenshots and report

### Step 4: Execute Journeys (Web App Mode)

For web applications, use the `agent-browser` skill to automate browser interactions:

For each journey (ordered by priority P0 → P1 → P2):

1. **Navigate** to the entry point URL
2. **Execute each step**:
   - Perform the user action (click, type, navigate, scroll, submit)
   - Wait for the expected outcome (page load, element appears, redirect)
   - **Capture screenshot** at each key checkpoint
   - **Check browser console** for errors or warnings
   - **Check network tab** for failed requests (4xx, 5xx)
   - **Measure load time** for each page transition
3. **Record result** for each step: pass / fail / partial
4. If a step fails:
   - Capture screenshot of the failure state
   - Record the error details (console error, HTTP status, missing element)
   - Attempt to continue the journey if possible (some steps may be independent)
   - If the journey is completely blocked, record and move to next journey

### Step 5: Execute Journeys (API-Only Mode)

For API-only products, execute journeys as sequential API calls:

For each journey:

1. **Set up auth** — obtain token via login endpoint or use configured API key
2. **Execute each step** as an API call:
   - Make the HTTP request (method, URL, headers, body)
   - Validate response status code matches expected
   - Validate response body structure and key fields
   - Check response headers (auth, rate-limit, cache)
   - Measure response time
3. **Chain responses** — use IDs/tokens from previous responses in subsequent requests (simulating real user flow)
4. **Record result** for each step: pass / fail / partial

### Step 6: Classify and Rate Issues

For every issue discovered during execution, classify by severity:

| Severity | Criteria | Examples |
|----------|----------|---------|
| **Critical** | Core flow is completely broken, data loss, security vulnerability | Login fails, payment processes twice, XSS in user input |
| **High** | Major feature doesn't work, significant UX problem | Form submission fails silently, page crashes on valid input |
| **Medium** | Feature partially works, minor UX issue, non-critical error, design inconsistency | Console warning, slow load time (>3s), layout broken on edge case, colors don't match design tokens, missing empty state, spinner instead of skeleton, hardcoded spacing |
| **Low** | Minor cosmetic issue, trivial improvement opportunity | Typo in error message, slightly different icon weight, minor alignment offset |

### Step 7: Produce Dogfood Report

Create an artifact in `artifacts/qa-reports/` with the following structure:

```markdown
---
id: DF-[feature]-[date]
type: qa-report
title: "Dogfood Report: [Feature/URL]"
status: draft
created: [YYYY-MM-DD]
author: qa-release-agent
parent: [PRD-XXX if scoped to a PRD]
children: []
depends_on: []
blocks: []
tags: [dogfood, qa]
---

# Dogfood Report: [Feature/URL]

## Summary
- **URL tested**: [url]
- **Product type**: [web-app | api-only | hybrid]
- **Seed data**: [scenario used or "none"]
- **Journeys executed**: [N total, N passed, N failed, N partial]
- **Issues found**: [N total: N critical, N high, N medium, N low]

## Journey Results

### Journey 1: [Name] — [PASS / FAIL / PARTIAL]
| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 1 | [action] | [expected] | [actual] | ✅/❌ |
| 2 | [action] | [expected] | [actual] | ✅/❌ |

**Screenshots**: [paths to captured screenshots]
**Console errors**: [list or "none"]

### Journey 2: [Name] — [PASS / FAIL / PARTIAL]
...

## Issues

### Issue 1: [Title] — [CRITICAL / HIGH / MEDIUM / LOW]
- **Journey**: [which journey]
- **Step**: [which step]
- **Description**: [what went wrong]
- **Expected**: [what should have happened]
- **Actual**: [what did happen]
- **Evidence**: [screenshot path, console error, HTTP response]
- **Recommendation**: [suggested fix]

### Issue 2: ...

## Recommendations
1. [Prioritized list of fixes]
2. ...

## Environment
- **Browser**: [if web app]
- **Seed data scenario**: [which scenario was loaded]
- **Date/time**: [when the test ran]
```

Run `./tools/artifact/validate.sh` on the produced artifact.

### Step 8: Present Results

Summarize the dogfood results to the user:

1. **Headline verdict**: "X of Y journeys passed. N issues found (C critical, H high, M medium, L low)."
2. **Critical/High issues**: list each with a one-line description
3. **Recommendation**: whether the feature is ready to ship based on dogfood results
4. **Link to full report**: artifact path

## Fallback Mode

If `agent-browser` is not available:

1. **API-only mode**: automatically switch to API-sequence dogfooding
2. **Manual checklist mode**: produce a detailed manual test checklist that a human can follow step-by-step, with checkboxes and expected outcomes. Save as an artifact for the user to execute.

## Integration Points

- **seed-data**: Run `/seed-data nominal` before dogfooding to ensure realistic app state
- **release-readiness-gate**: Bar 7 (optional) checks for dogfood report existence and severity counts
- **ship**: Optional dogfooding step between implementation and release gate
- **test-plan-generator**: Dogfood journeys complement (not replace) the structured test plan

## Quality Checklist

- [ ] App URL verified as reachable before starting
- [ ] PRD acceptance criteria used to derive journeys (not arbitrary exploration)
- [ ] All P0 journeys executed
- [ ] Screenshots captured at key checkpoints (web mode)
- [ ] Console/network errors checked at every step
- [ ] Every issue has severity rating with evidence
- [ ] Dogfood report artifact produced with valid frontmatter
- [ ] Results summarized to user with clear verdict
