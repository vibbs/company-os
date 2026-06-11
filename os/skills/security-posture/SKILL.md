---
name: security-posture
description: Aggregates open threats, scan status, compliance gaps, and human checkpoint audit into a unified security posture snapshot. Use when reviewing overall security health or before major releases.
user-invokable: true
argument-hint: "[--full | --quick | --delta]"
---

# Security Posture

## Reference
- **ID**: S-RISK-04
- **Category**: Ops & Risk
- **Inputs**: artifacts/security-reviews/, standards/security/security-posture.md, company.config.yaml
- **Outputs**: posture snapshot artifact → artifacts/security-reviews/POSTURE-{date}.md
- **Used by**: Ops & Risk Agent
- **Tool scripts**: ./tools/security/posture-check.sh, ./tools/artifact/validate.sh

## Purpose

Produces a cross-cutting security posture snapshot that aggregates findings from all threat models, scans, and compliance checks into a single artifact. Unlike threat-modeling (which analyzes one feature), security-posture evaluates the project's overall security health.

## When to Use

- Before any release — posture snapshot is part of release readiness (Bar 3)
- After resolving a security incident — verify the fix improved posture
- Monthly, if the project is in `growth` or `scale` stage
- When the user asks "how's our security?" or "are we ready to ship?"

## Modes

| Mode | What It Does |
|------|-------------|
| `--full` (default) | Complete posture assessment: findings, scans, compliance, checkpoints |
| `--quick` | Summary only: open finding count, scan freshness, overall verdict |
| `--delta` | Changes since last POSTURE- artifact: new findings, resolved findings, status changes |

## Procedure

### Step 1: Load Standard

Read `standards/security/security-posture.md` for:
- Tool tiering definitions (Tier 0-3)
- Secrets policy requirements
- Mandatory human-review checkpoint definitions
- Safe execution defaults

If the standard does not exist, warn the user: "Security posture standard not found at standards/security/security-posture.md. Create it first or run /ship to generate the full governance layer."

### Step 2: Load Configuration

Read `company.config.yaml` for:
- `company.stage` — determines enforcement level
- `ai.llm_provider` — triggers AI safety checks if set
- `architecture.*` — context for infrastructure security
- `observability.*` — context for logging/monitoring coverage

### Step 3: Scan Threat Models

Find all artifacts in `artifacts/security-reviews/` (exclude POSTURE- artifacts):
- Extract YAML frontmatter: `id`, `status`, `created`
- Scan body for severity markers: `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`
- For each finding, extract: description, severity, status (open/mitigated/accepted), age (days since created)

Categorize:
- **Open CRITICAL**: must be resolved before release
- **Open HIGH**: should be resolved; acceptable with documented mitigation
- **Open MEDIUM**: tracked, resolution timeline recommended
- **Open LOW**: noted, no action required

### Step 4: Check Scan Freshness

Look for evidence of recent security scans:
- Check if `dependency-scan.sh` has been run (look for output in conversation or scan result artifacts)
- Check if `secrets-scan.sh` has been run
- Check if `sast.sh` has been run

Report last-known scan date and result for each. If no evidence of a scan: "UNKNOWN — run `./tools/security/{tool}.sh` to establish baseline."

### Step 5: Compliance Gap Check

For each section of the security posture standard, assess compliance:

| Section | Check |
|---------|-------|
| Tool Tiering | Are all tools classified? Are tier boundaries respected in recent agent actions? |
| Secrets Policy | Does `.env.example` exist? Is `.env` in `.gitignore`? Has `secrets-scan.sh` been run? |
| Human Checkpoints | Have any Tier 3 operations occurred without documented confirmation? |
| Safe Execution Defaults | Are artifacts validated before promotion? Are dry-runs used? |

Rate each: `COMPLIANT` / `PARTIAL` / `GAP` / `NOT ASSESSED`

### Step 6: Human Checkpoint Audit (--full mode only)

Review recent artifacts for Tier 3 operations:
- Check `artifacts/decision-memos/` for INC- (incident) records involving production changes
- Check recent commits for production-impacting changes
- Flag any Tier 3 operations that lack a documented confirmation record

### Step 7: Produce Posture Snapshot

Generate `artifacts/security-reviews/POSTURE-{date}.md`:

```yaml
---
id: POSTURE-{date}
type: security-review
title: "Security Posture Snapshot — {date}"
status: draft
created: {date}
---
```

Body structure:

```markdown
## Executive Summary

**Overall Verdict**: [HEALTHY | CAUTION | AT RISK]

- Open CRITICAL findings: X
- Open HIGH findings: X
- Scan coverage: X/3 tools run in last 30 days
- Compliance gaps: X sections with gaps

## Open Findings

| # | Finding | Severity | Source Artifact | Age (days) | Status |
|---|---------|----------|----------------|------------|--------|
| 1 | ... | CRITICAL | SEC-001 | 14 | Open |

## Scan Coverage

| Tool | Last Run | Result | Freshness |
|------|----------|--------|-----------|
| dependency-scan.sh | {date} | PASS/FAIL | Fresh/Stale/Unknown |
| secrets-scan.sh | {date} | PASS/FAIL | Fresh/Stale/Unknown |
| sast.sh | {date} | PASS/FAIL | Fresh/Stale/Unknown |

## Compliance Status

| Standard Section | Status | Notes |
|-----------------|--------|-------|
| Tool Tiering Policy | COMPLIANT/GAP | |
| Secrets Policy | COMPLIANT/GAP | |
| Human Checkpoints | COMPLIANT/GAP | |
| Safe Execution Defaults | COMPLIANT/GAP | |

## Recommendations

1. [Highest priority action]
2. [Second priority action]
...
```

### Step 8: Run CLI Check

Execute `./tools/security/posture-check.sh` and incorporate its output into the snapshot. If the tool exits non-zero, flag the specific failures in the Recommendations section.

### Step 9: Validate

Run `./tools/artifact/validate.sh` on the saved artifact.

### Step 10: Report to User

Present the Executive Summary and Recommendations. If `--quick` mode, present only the summary line and finding counts. If `--delta` mode, present a diff against the previous POSTURE- artifact.

## Quality Checklist
- [ ] Security posture standard was loaded and referenced
- [ ] All security-review artifacts were scanned (not just the most recent)
- [ ] Scan freshness is accurately reported (not assumed)
- [ ] Compliance gaps are specific, not generic
- [ ] Recommendations are actionable and prioritized
- [ ] Artifact passes validation
- [ ] posture-check.sh was run and its output incorporated

## Cross-References
- **threat-modeling** (S-RISK-01) — produces per-feature threat models that this skill aggregates
- **release-readiness-gate** — posture snapshot is checked at Bar 3 (Security & Risk)
- **security-posture standard** — `standards/security/security-posture.md`
- **posture-check.sh** — `./tools/security/posture-check.sh` (CLI companion)
