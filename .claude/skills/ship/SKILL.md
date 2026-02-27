---
name: ship
description: Kick off the full ship flow for a feature or objective. Routes through the Orchestrator to produce PRD, RFC, implementation, QA, and launch artifacts with gate checks at every stage.
user-invokable: true
argument-hint: "describe what you want to build"
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Ship

The primary entry point for the canonical ship flow. Takes an objective from idea through PRD, RFC, implementation, QA, and release -- with quality gates enforced at every stage transition.

## Reference

- **ID**: S-ORG-08
- **Category**: Orchestration
- **Inputs**: objective description, company.config.yaml, existing artifacts
- **Outputs**: Full artifact chain (PRD -> RFC -> QA Report -> Launch Brief) with stage gate verification
- **Used by**: User (directly), Orchestrator Agent
- **Tool scripts**: ./tools/artifact/validate.sh, ./tools/artifact/check-gate.sh, ./tools/artifact/promote.sh, ./tools/artifact/link.sh, ./tools/ci/run-tests.sh, ./tools/ci/lint-format.sh, ./tools/security/dependency-scan.sh

## When to Use

- User wants to build a new feature end-to-end
- User wants to ship an improvement or enhancement
- User wants the full orchestrated pipeline with quality gates

## Procedure

### Step 1: Load Configuration

Read `company.config.yaml` and extract:

- `company.stage` (idea | mvp | growth | scale) -- affects gate strictness
- `tech_stack.*` -- language, framework, runtime, database, ORM, hosting, CI
- `conventions.*` -- test_framework, linter, formatter, branching, commit_style
- `api.*` -- style, spec_format, error_format, auth, pagination
- `architecture.*` -- multi_tenant, tenant_isolation, deployment_model
- `observability.*` -- logging, metrics, tracing, error_tracking
- `personas.*` -- custom agent names (if configured, use them in delegation messages)

If the config is empty or missing, redirect to `/setup` before proceeding.

### Step 2: Inventory Existing Artifacts

Scan `artifacts/` for any artifacts related to this objective:

- Check `artifacts/prds/` for existing PRDs
- Check `artifacts/rfcs/` for existing RFCs
- Check `artifacts/test-plans/` for existing test plans
- Check `artifacts/qa-reports/` for existing QA reports
- Check `artifacts/security-reviews/` for existing security reviews
- Check `artifacts/launch-briefs/` for existing launch briefs

If related artifacts exist, resume the flow from the next missing stage. Do not re-produce artifacts that already exist and are approved.

### Step 2.5: Discovery Validation (New Features Only)

For objectives classified as **New Feature**, run the Discovery Validation skill (via Product Agent) before proceeding to PRD:

1. The skill's smart filter classifies the objective as COMMON PATTERN or NOVEL CONCEPT
2. **COMMON PATTERN** (auth, CRUD, notifications, file uploads, search, pagination, etc.): Skip discovery, proceed directly to PRD
3. **NOVEL CONCEPT** (new business model, new UX paradigm, AI/ML, marketplace, etc.): Run full validation — lean canvas, competitive scan, risk assessment
4. Discovery output is embedded in the PRD (not a separate artifact)

Skip this step entirely for Bug Fix, Improvement, and Research/Spike types.

### Step 3: Classify Objective

Determine the type of work (reuse workflow-router classification):

| Type | Description | Flow |
|------|-------------|------|
| **New Feature** | Building something that does not exist | Full pipeline (PRD -> RFC -> Build -> Test -> Release) |
| **Bug Fix** | Something is broken | Expedited (Triage -> Fix -> Test -> Release) |
| **Improvement** | Enhancing existing functionality | Mini-PRD -> RFC (optional) -> Build -> Test -> Release |
| **Research/Spike** | Understanding before deciding | Research -> Decision Memo |

For Bug Fix and Research/Spike types, use the abbreviated flows described above rather than the full pipeline.

### Step 4: Build Execution Plan

Based on the objective type and existing artifacts, build a stage-by-stage plan.

For each missing artifact, assign:

| Artifact | Agent | Primary Skill | Tool Dependencies |
|----------|-------|---------------|-------------------|
| PRD | Product Agent | prd-writer | -- |
| RFC | Engineering Agent | architecture-draft | tech_stack.*, architecture.* from config |
| API Contract | Engineering Agent | api-contract-designer | api.* from config |
| Threat Model | Ops & Risk Agent | threat-modeling | -- |
| Implementation | Engineering Agent | implementation-decomposer | conventions.*, tech_stack.* from config |
| Test Plan | QA Agent | test-plan-generator | conventions.test_framework from config |
| QA Report | QA Agent | release-readiness-gate | -- |
| Launch Brief | Growth Agent | positioning-messaging | -- |

Present the execution plan to the user for confirmation before starting. Include:

1. The stages that will be executed (in order)
2. Which stages already have artifacts (will be skipped)
3. Estimated scope of work

Wait for user approval before proceeding.

### Step 5: Execute Stage-by-Stage (Pause at Gates)

For each stage in the execution plan:

**a. Delegate** to the assigned agent with full tech stack context from Step 1. Pass all relevant configuration values so the agent can make informed decisions. If `personas.*` are configured, use persona names when announcing delegation (e.g., "Handing off to Morgan (Engineering) for RFC..." instead of "Handing off to Engineering Agent for RFC...").

**b. Validate the artifact** when the agent produces output:
  - Run `./tools/artifact/validate.sh <artifact>` to verify frontmatter is correct
  - Run `./tools/artifact/link.sh` if parent/child relationships need establishing
  - Promote artifact to review: `./tools/artifact/promote.sh <artifact> review`

**c. Run the appropriate gate check**:
  - After PRD: `./tools/artifact/check-gate.sh prd-to-rfc <prd-file>`
  - After RFC: `./tools/artifact/check-gate.sh rfc-to-impl <rfc-file>`
  - After implementation + test plan: `./tools/artifact/check-gate.sh impl-to-qa <rfc-file>`
  - Before release: `./tools/artifact/check-gate.sh release <prd-file>`

**d. PAUSE** -- Present gate results to the user:
  - Show what was produced (artifact ID, title, location)
  - Show gate pass/fail status with details
  - Ask: "Review the artifact and approve to continue, or request changes?"

**e. On user approval**: promote artifact to approved via `./tools/artifact/promote.sh <artifact> approved`, then proceed to next stage.

**f. On user rejection**: iterate on the current stage. Re-delegate to the agent with the user's feedback incorporated. Repeat validation and gate check.

### Step 5.7: User Documentation & Guided Tours

After implementation is complete, delegate to the Engineering Agent with the User Docs skill to produce:

1. **User-facing feature documentation** — what the feature does, how to use it, step-by-step guide
2. **In-app tour specification** — target elements (using `data-tour-step` attributes), copy, positioning, sequence
3. **Changelog entry** — user-facing description of what changed and why
4. **API documentation updates** — if the feature introduces or modifies API endpoints

This step runs after implementation but before dogfooding/QA, so tours and docs can be validated during testing.

### Step 5.5: Dogfooding (Optional)

After implementation and test execution, optionally dogfood the running product:

1. **Check if the app is running** — if a local or staging URL is available, proceed
2. **Seed realistic data** — run `./tools/db/seed.sh nominal` to populate the app with realistic state
3. **Run pre-flight** — execute `./tools/qa/dogfood.sh <url>` to validate readiness
4. **Execute dogfood procedure** — delegate to the QA Agent with the Dogfood skill to:
   - Extract user journeys from the PRD acceptance criteria
   - Execute each journey against the running app
   - Produce a dogfood report in `artifacts/qa-reports/`
5. **Review results** — present the dogfood summary to the user
   - If CRITICAL issues found: pause and address before proceeding to release gate
   - If no critical issues: proceed to release gate (dogfood report feeds into optional Bar 7)

This step is recommended but not required. Skip it when:
- The product is API-only and contract tests already cover the flows
- No running environment is available
- The user explicitly opts to skip dogfooding

### Step 6: Release Gate (Final Verification)

Before approving release, run the full tool chain:

1. `./tools/ci/run-tests.sh` -- uses `conventions.test_framework` from config
2. `./tools/ci/lint-format.sh` -- uses `conventions.linter` and `conventions.formatter` from config
3. `./tools/security/dependency-scan.sh` -- scans for known vulnerabilities
4. `./tools/deploy/pre-deploy.sh` -- validates deployment readiness (git state, env vars, migrations, version)
5. `./tools/artifact/check-gate.sh release <prd-file>` -- verifies all artifacts exist and are approved
6. **Version bump** -- determine and apply the app version bump:
   a. Read the current app version (auto-detect from `package.json`, `pyproject.toml`, or `VERSION` file)
   b. Determine bump type from shipped artifacts:
      - PRD describes a bug fix or performance improvement → **PATCH**
      - PRD describes a new feature or enhancement → **MINOR**
      - RFC explicitly flags breaking API changes or migration requirements → **MAJOR**
   c. Read `company.stage` — if `idea` or `mvp`, cap version at v0.x.x (MAJOR becomes MINOR per standard v0 semver). If `growth`/`scale` and version is still 0.x.x, recommend transitioning to v1.0.0
   d. Present recommendation to the user: "[current] → [proposed] ([reason])"
   e. On user approval: run `./tools/versioning/version-bump.sh <type>`
   f. If user wants a different bump type, accept their override
   g. Commit the version bump (version file + CHANGELOG.md + .previous-version)

**Recommended**: If an incident runbook exists at `standards/ops/incident-runbook.md`, verify it covers the deployment rollback procedure for this feature.

Report results for each tool. All checks must pass for release approval. If any check fails, report the failure details and work with the user to resolve before retrying.

### Step 7: Release Summary

Present a final summary:

- **Version** -- previous version → new version (git tag: v[new])
- **Artifacts produced** -- list all artifacts with IDs, types, and statuses
- **Gates passed** -- list each gate transition and its result
- **Tool chain results** -- tests, lint, security scan outcomes
- **Recommended next actions** -- deploy, announce, monitor, or any follow-up items

### Step 8: What's Next

After the release summary, surface actionable suggestions for what to build next. This step is **informational only** — no artifacts, no gates, no blocking.

**Sources to scan** (in this order of priority):

1. The PRD's `## Out of Scope` section — features explicitly deferred during planning
2. RFC's `## Future Considerations` / `## Tech Debt` sections — technical follow-ups noted during architecture
3. Decision memos in `artifacts/decision-memos/` linked to this feature — deferred alternatives and open questions
4. `TODO` and `FIXME` comments added during implementation — grep the codebase for recent additions related to this feature
5. `tasks/lessons.md` — patterns that suggest systemic improvements

**Output format** (conversational, not an artifact):

```
## What's Next?

Based on what we just shipped, here are natural next moves:

1. **[Title]** — [one-liner description]
   _Source: PRD out-of-scope_

2. **[Title]** — [one-liner description]
   _Source: RFC tech debt_

3. **[Title]** — [one-liner description]
   _Source: TODO in src/auth/handler.ts:42_

Pick one and say "build that" to kick off a new cycle.
```

**Rules**:
- Maximum 5 suggestions, minimum 1
- Rank by: direct user value > tech debt reduction > nice-to-haves
- If no sources yield suggestions: "No obvious next steps found. Check your roadmap or run `/status` to see what's in progress."
- This output is ephemeral — it lives only in the conversation, not as an artifact

## Parallel Work Optimization

Some stages can run concurrently to reduce total flow time:

```
Sequential (must be in order):
  PRD -> RFC -> Implementation -> QA Report -> Release

Parallel branches (can run alongside the sequential path):
  RFC -> Threat Model (Ops & Risk)       [parallel with implementation planning]
  PRD -> Launch Brief (Growth)            [parallel once PRD is approved]
  RFC -> Test Plan (QA)                   [parallel once RFC is approved]
```

Identify and execute parallel work where possible. When delegating parallel tasks, track each independently and merge results at the appropriate gate.

## Quality Checklist

- [ ] company.config.yaml was read and tech stack context passed to all agents
- [ ] Every artifact was validated with validate.sh before promotion
- [ ] Every stage transition was gated with check-gate.sh
- [ ] User reviewed and approved at each gate pause point
- [ ] Release gate ran full tool chain (tests, lint, security scan)
- [ ] All artifacts are linked with proper parent/children relationships
