---
name: workflow-router
description: Maps objectives to required artifacts, stages, and responsible agents. Use when routing any objective, deciding what happens next, or determining which agents need to be involved in a task.
user-invokable: false
---

# Workflow Router

## Reference
- **ID**: S-ORG-01
- **Category**: Orchestration
- **Inputs**: objective or request, current artifact state (artifacts/), company.config.yaml
- **Outputs**: execution plan with stages, artifacts, and agent assignments
- **Used by**: Orchestrator Agent
- **Tool scripts**: ./tools/artifact/validate.sh, ./tools/artifact/check-gate.sh, ./tools/registry/search-skill.sh

## Purpose

Given any objective, determine the sequence of artifacts, stages, and agents required to deliver it. This is the Orchestrator's primary planning skill.

## When to Use

- User states an objective ("Build feature X", "Launch product Y", "Fix bug Z")
- Orchestrator needs to decide what happens next
- A stage is complete and the next step must be determined

## Routing Procedure

### Step 1: Classify the Objective

Determine the type of work:

| Type | Description | Typical Flow |
|------|-------------|--------------|
| **New Feature** | Building something that doesn't exist | Full pipeline (PRD → RFC → Build → Test → Release) |
| **Bug Fix** | Something is broken | Triage → Fix → Test → Release |
| **Improvement** | Enhancing existing functionality | Mini-PRD → RFC (optional) → Build → Test → Release |
| **Research/Spike** | Understanding before deciding | Research → Decision Memo |
| **Launch** | Taking something live | QA gate → Growth assets → Release |
| **Compliance** | Security/privacy/legal requirement | Risk review → Remediation → Verification |

### Step 2: Check Current State

Inventory what artifacts already exist for this objective:

```
1. Check artifacts/prds/ — does a relevant PRD exist?
2. Check artifacts/rfcs/ — does an RFC exist?
3. Check artifacts/test-plans/ — does a test plan exist?
4. Check artifacts/qa-reports/ — has QA been done?
5. Check artifacts/security-reviews/ — has risk been assessed?
6. Check artifacts/launch-briefs/ — are launch assets ready?
```

Whatever is missing determines what still needs to happen.

### Step 3: Build the Execution Plan

For each missing artifact, assign the responsible agent and required skills:

| Artifact Needed | Agent | Primary Skill | Prerequisite |
|----------------|-------|---------------|--------------|
| PRD | Product Agent | prd-writer | Objective defined |
| RFC / Architecture | Engineering Agent | architecture-draft | PRD approved |
| API Contract | Engineering Agent | api-contract-designer | RFC approved |
| Threat Model | Ops & Risk Agent | threat-modeling | RFC exists |
| Implementation | Engineering Agent | implementation-decomposer | RFC + API contract |
| Test Plan | QA Agent | test-plan-generator | PRD + RFC exist |
| QA Report | QA Agent | release-readiness-gate | Tests executed |
| Launch Brief | Growth Agent | positioning-messaging | PRD + release date |
| Security Review | Ops & Risk Agent | threat-modeling | RFC exists |

### Step 4: Identify Parallelizable Work

Some stages can run concurrently:

```
Sequential (must be in order):
  PRD → RFC → Implementation → QA Report → Release

Parallel branches (can run alongside implementation):
  RFC → Threat Model (Ops & Risk)
  RFC → Test Plan (QA)
  PRD → Launch Brief (Growth)
```

### Step 5: Define Stage Gates

Each stage transition requires validation. Use `./tools/artifact/check-gate.sh` to verify:

| Transition | Gate Command | Checks |
|-----------|-------------|--------|
| PRD → RFC | `check-gate.sh prd-to-rfc <prd>` | PRD approved, acceptance criteria present |
| RFC → Implementation | `check-gate.sh rfc-to-impl <rfc>` | RFC approved, parent PRD approved |
| Implementation → QA | `check-gate.sh impl-to-qa <rfc>` | RFC approved, test plan exists |
| QA → Release | `check-gate.sh release <prd>` | All artifacts exist and approved |

### Step 6: Output the Plan

Produce a structured execution plan:

```markdown
## Execution Plan: [Objective]

### Current State
- [x] PRD: PRD-001 (approved)
- [ ] RFC: not started
- [ ] Threat Model: not started
- [ ] Implementation: not started
- [ ] Test Plan: not started
- [ ] QA Report: not started
- [ ] Launch Brief: not started

### Next Actions
1. **Engineering Agent** → produce RFC using architecture-draft (depends on: PRD-001)
2. **Engineering Agent** → produce API contract using api-contract-designer (depends on: RFC)
3. **Ops & Risk Agent** → produce threat model using threat-modeling (depends on: RFC) [parallel]

### Stage Gates
- RFC must be approved before implementation starts
- Threat model must exist (even minimal) before release
- QA report must pass before release approval
```

## Shortcut Flows

### Bug Fix Flow (Expedited)
1. Engineering Agent triages and fixes
2. QA Agent validates fix (regression check)
3. Orchestrator approves release
- Skip: PRD, RFC, Growth, Ops (unless security-related)

### Research Spike Flow
1. Engineering Agent investigates
2. Orchestrator produces Decision Memo (decision-memo-writer)
- Skip: everything else until decision is made

## Quality Checklist

- [ ] Objective type correctly classified
- [ ] All existing artifacts inventoried
- [ ] Missing artifacts identified with responsible agents
- [ ] Dependencies between stages are explicit
- [ ] Parallel work identified
- [ ] Stage gates defined with specific criteria
- [ ] Plan is actionable (next action is clear)
