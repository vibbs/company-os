---
name: release-readiness-gate
description: Final quality gate checklist with pass/fail evaluation and release verdict. Run this before approving any release.
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash
---

# Release Readiness Gate

## Reference
- **ID**: S-QA-03
- **Category**: QA / Release
- **Inputs**: PRD (approved), RFC (approved), QA report, security review, tool logs
- **Outputs**: release readiness verdict (pass/fail with reasons)
- **Used by**: Orchestrator Agent, QA & Release Agent
- **Tool scripts**: ./tools/artifact/validate.sh, ./tools/artifact/promote.sh, ./tools/artifact/link.sh, ./tools/artifact/check-gate.sh

## Purpose

Evaluate whether a feature/release meets all minimum quality bars. This is the final checkpoint before the Orchestrator approves a release. The gate produces a clear pass/fail verdict with specific reasons for any failures.

## When to Use

- Engineering has completed implementation
- QA has run tests and produced a QA report
- Ops & Risk has completed security review
- Orchestrator asks "Is this ready to ship?"

## Release Readiness Procedure

### Step 1: Gather Required Artifacts

Collect and verify the existence of all required artifacts:

| # | Artifact | Location | Required |
|---|----------|----------|----------|
| 1 | PRD | artifacts/prds/ | YES |
| 2 | RFC/ADR | artifacts/rfcs/ | YES |
| 3 | API Contract | (in RFC or separate) | YES (if API changes) |
| 4 | Threat Model | artifacts/security-reviews/ | YES |
| 5 | Test Plan | artifacts/test-plans/ | YES |
| 6 | QA Report | artifacts/qa-reports/ | YES |
| 7 | Launch Brief | artifacts/launch-briefs/ | NO (recommended) |

Run `./tools/artifact/check-gate.sh release <prd-path>` to verify all required artifacts exist and are approved, then run `./tools/artifact/validate.sh` on each artifact for structural correctness.

**If any REQUIRED artifact is missing or check-gate fails: FAIL immediately.**

### Step 2: Evaluate Minimum Bars

Each bar is pass/fail. ALL must pass for release approval.

#### Bar 1: PRD Completeness
- [ ] PRD has status `approved`
- [ ] All acceptance criteria are present and testable
- [ ] Success metrics are defined with baselines and targets
- [ ] Scope boundaries are explicit

#### Bar 2: Technical Design
- [ ] RFC/ADR exists and is approved
- [ ] API contract exists (if feature has API changes)
- [ ] Data model changes documented
- [ ] Migration strategy defined (if applicable)

#### Bar 3: Security & Risk
- [ ] Threat model exists (even minimal)
- [ ] No unresolved CRITICAL or HIGH severity findings
- [ ] Dependency scan has been run (logs exist)
- [ ] Secrets scan has been run (logs exist)
- [ ] Auth model reviewed

#### Bar 4: Testing
- [ ] Test plan exists linked to PRD acceptance criteria
- [ ] Unit/integration tests pass
- [ ] API contract tests pass (if applicable)
- [ ] No critical test failures

#### Bar 5: Code Quality
- [ ] Lint passes
- [ ] No TODO/FIXME/HACK in new code (or explicitly tracked)
- [ ] Code follows conventions from `standards/coding/`

#### Bar 6: Operational Readiness
- [ ] Logging covers key operations
- [ ] Error handling doesn't leak internal details
- [ ] Performance baselines met (if applicable)
- [ ] Rollback strategy documented in RFC

### Step 3: Calculate Overall Verdict

```markdown
## Release Readiness Verdict

### Summary
| Bar | Status |
|-----|--------|
| PRD Completeness | PASS / FAIL |
| Technical Design | PASS / FAIL |
| Security & Risk | PASS / FAIL |
| Testing | PASS / FAIL |
| Code Quality | PASS / FAIL |
| Operational Readiness | PASS / FAIL |

### Overall: APPROVED FOR RELEASE / NOT READY

### Blocking Issues (if any)
1. [Specific issue] — assigned to [agent] — must resolve before re-evaluation

### Recommendations (non-blocking)
1. [Nice-to-have improvement]
```

### Step 4: Handle Verdict

**If APPROVED:**
1. Run `./tools/artifact/promote.sh` to promote all artifacts to `approved`
2. Run `./tools/artifact/link.sh` to ensure lineage links are complete
3. Produce the release readiness report in `artifacts/qa-reports/`
4. Notify Orchestrator: "Release approved — all minimum bars passed"

**If NOT READY:**
1. List every blocking issue with what's wrong, who fixes it, and what "fixed" looks like
2. Do NOT promote any artifacts
3. Notify Orchestrator: "Release blocked — [N] issues must be resolved"

## Edge Cases

### Expedited Release (Hotfix)
Reduced bars: bug documented, fix tested, no new security vulnerabilities. Skip full PRD, RFC, threat model.

### Partial Release (Feature Flag)
All bars still apply, plus: flag is configured, kill switch works, monitoring covers flagged behavior.

## Quality Checklist

- [ ] All required artifacts inventoried
- [ ] Each minimum bar evaluated with evidence
- [ ] Blocking issues are specific and assigned
- [ ] Verdict is binary (approved or not — no "mostly ready")
- [ ] Report stored with proper artifact frontmatter
- [ ] Artifact lineage links are complete
