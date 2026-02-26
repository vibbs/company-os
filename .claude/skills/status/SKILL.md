---
name: status
description: Shows project artifact status summary — counts, statuses, broken links, and gate readiness across all artifact types.
user-invokable: true
argument-hint: "[optional: prd|rfc|qa|all]"
allowed-tools: Read, Grep, Glob, Bash
---

# Status Dashboard

## Reference
- **ID**: S-ORG-09
- **Category**: Orchestration
- **Inputs**: artifacts/ directory contents, company.config.yaml
- **Outputs**: Formatted status dashboard
- **Used by**: User (directly)
- **Tool scripts**: ./tools/artifact/validate.sh, ./tools/artifact/check-gate.sh

## Purpose

Show a project health dashboard at a glance: how many artifacts exist, their statuses, whether references between them are intact, and whether stage gates are ready to pass.

## When to Use

- User wants to see project health at a glance
- Before starting a new feature (check what exists)
- Before a release (check all gates)
- After a session to verify artifact integrity

## Procedure

### Step 1: Scan Artifact Directories

Scan all 7 artifact directories:
- `artifacts/prds/`
- `artifacts/rfcs/`
- `artifacts/test-plans/`
- `artifacts/qa-reports/`
- `artifacts/security-reviews/`
- `artifacts/launch-briefs/`
- `artifacts/decision-memos/`

For each `.md` file found, extract YAML frontmatter:
- `id`
- `type`
- `status` (draft | review | approved | archived)
- `parent`
- `children`
- `depends_on`
- `blocks`

### Step 2: Build Summary Table

Present a summary by category:

```
## Artifact Status Dashboard

| Category         | Total | Draft | Review | Approved | Archived |
|------------------|-------|-------|--------|----------|----------|
| PRDs             | X     | X     | X      | X        | X        |
| RFCs             | X     | X     | X      | X        | X        |
| Test Plans       | X     | X     | X      | X        | X        |
| QA Reports       | X     | X     | X      | X        | X        |
| Security Reviews | X     | X     | X      | X        | X        |
| Launch Briefs    | X     | X     | X      | X        | X        |
| Decision Memos   | X     | X     | X      | X        | X        |
```

### Step 3: Check Reference Integrity

For each artifact, verify:
- If `parent` is set, the referenced artifact file exists
- If `children` are set, each referenced artifact file exists
- If `depends_on` are set, each referenced artifact file exists
- If `blocks` are set, each referenced artifact file exists

Report any broken references:
```
## Broken References
- RFC-001 references parent PRD-001 but file not found
- PRD-002 lists child RFC-003 but file not found
```

If no broken references: "All artifact references verified."

### Step 4: Gate Readiness (Optional)

If the user passes a specific artifact or says "all":

For each PRD that has status `approved`, check gate readiness:
- Run `./tools/artifact/check-gate.sh prd-to-rfc <prd>`
- If RFC exists: run `./tools/artifact/check-gate.sh rfc-to-impl <rfc>`
- If implementation exists: run `./tools/artifact/check-gate.sh impl-to-qa <rfc>`
- If QA exists: run `./tools/artifact/check-gate.sh release <prd>`

Present gate status:
```
## Gate Readiness

### PRD-001: User Authentication
- [x] prd-to-rfc: PASS
- [x] rfc-to-impl: PASS
- [ ] impl-to-qa: NOT READY (test plan missing)
- [ ] release: NOT READY (QA report missing, security review missing)
```

### Step 5: Recent Activity

Show the 5 most recently modified artifacts (by file modification time) to give context on what has been worked on.

### Step 6: Recommendations

Based on the scan, suggest next actions:
- If there are `draft` artifacts: "Consider promoting X to review"
- If there are broken references: "Fix broken references with ./tools/artifact/link.sh"
- If gates are failing: "Complete missing artifacts to unblock gates"
- If everything is clean: "All artifacts validated and linked. Ready to ship."

## Filtering

If the user provides an argument:
- `prd` -- only show PRD status + gates
- `rfc` -- only show RFC status + gates
- `qa` -- only show QA-related artifacts (test plans, QA reports)
- `all` -- full dashboard with gate checks (default if no argument)

## Quality Checklist

- [ ] All artifact directories scanned
- [ ] Frontmatter extracted from every .md file
- [ ] Summary table is accurate
- [ ] Broken references detected and reported
- [ ] Gate readiness checked (if requested)
- [ ] Recommendations are actionable
