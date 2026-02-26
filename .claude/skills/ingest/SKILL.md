---
name: ingest
description: Scans standards/ and artifacts/ for new or changed content and suggests updates to skills, agents, and configuration. Use after adding new standards documents, API specs, or artifacts to synchronize the system.
user-invokable: true
argument-hint: "[optional: standards, artifacts, or both]"
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Ingest

## Reference
- **ID**: S-ORG-04
- **Category**: Orchestration
- **Inputs**: standards/ directory, artifacts/ directory, company.config.yaml
- **Outputs**: update recommendations for skills/agents, optionally applied
- **Used by**: User (directly invokable), Orchestrator Agent
- **Tool scripts**: ./tools/registry/detect-changes.sh, ./tools/registry/health-check.sh

## Purpose

After the user places new standards documents (API specs, style guides, compliance requirements) or new artifacts (PRDs, RFCs) into the repository, this skill detects what changed and reasons about which skills, agents, or configuration should be updated to incorporate the new knowledge.

## When to Use

- After dropping files into `standards/api/`, `standards/coding/`, `standards/compliance/`, or `standards/templates/`
- After a batch of new artifacts has been created or updated
- Periodically, to check if the system is in sync with its standards
- After initial setup, when the user first populates their standards

## Ingest Procedure

### Step 1: Detect Changes

Run `./tools/registry/detect-changes.sh` to get a list of new/modified files.

If the user specifies a date range, pass `--since YYYY-MM-DD`.
If the user only cares about one directory, pass `--dir standards` or `--dir artifacts`.

### Step 2: Classify Each Change

For each detected file, classify its impact area:

| File Location | Impacted Skills | Impacted Agents |
|--------------|-----------------|-----------------|
| `standards/api/*` | api-contract-designer, architecture-draft, api-tester-playbook | engineering |
| `standards/coding/*` | implementation-decomposer, observability-baseline | engineering, qa-release |
| `standards/compliance/*` | compliance-readiness, privacy-data-handling, threat-modeling | ops-risk |
| `standards/templates/*` | prd-writer, architecture-draft, test-plan-generator (match by template type) | product, engineering, qa-release |
| `artifacts/prds/*` | workflow-router (state tracking), sprint-prioritizer | orchestrator, product |
| `artifacts/rfcs/*` | workflow-router, implementation-decomposer, api-tester-playbook | orchestrator, engineering, qa-release |
| `artifacts/security-reviews/*` | release-readiness-gate, threat-modeling | orchestrator, ops-risk |
| `artifacts/qa-reports/*` | release-readiness-gate | orchestrator, qa-release |

### Step 3: Read Each Changed File

For each new/modified file, read its content and extract key information:

- **API specs**: endpoints, error formats, auth patterns, pagination style, versioning
- **Coding standards**: naming conventions, patterns to follow, anti-patterns to avoid
- **Compliance docs**: specific requirements, controls needed, deadlines
- **Templates**: structure, required sections, frontmatter format
- **Artifacts**: current status, lineage links, key decisions

### Step 4: Compare Against Current Skills

For each impacted skill, read its current `SKILL.md` and check:

1. Does the skill reference the relevant `standards/` directory at all?
2. Does the skill incorporate the specific conventions from the new standard?
3. Are there contradictions between the skill's current advice and the new standard?
4. Are there gaps — things the standard requires that the skill doesn't mention?

### Step 5: Generate Update Recommendations

For each needed update, produce a specific recommendation:

```markdown
## Recommended Updates

### 1. [skill-name]/SKILL.md
**Reason**: [What changed and why this skill needs updating]
**Change**: [Specific section and what to add/modify]
**Priority**: High | Medium | Low
  - High = contradicts current advice or fills a critical gap
  - Medium = adds useful context, improves specificity
  - Low = nice-to-have, minor improvement

### 2. [agent-name].md
**Reason**: [What changed and why this agent needs updating]
**Change**: [Specific section to update]
**Priority**: High | Medium | Low
```

### Step 6: Apply or Present

Ask the user: **"Apply these updates now, or review first?"**

- **If apply**: Make the edits using Edit tool, then run `./tools/registry/health-check.sh` to verify all skills still pass
- **If review**: Present the full list of recommendations and wait for user approval on each

### Step 7: Verify

After any changes:

1. Run `./tools/registry/health-check.sh` — all skills must pass (0 errors)
2. Summarize what was updated with file paths and sections changed
3. Note any manual follow-ups needed (e.g., "compliance-readiness may need company-specific SOC2 controls added")

## Edge Cases

### Empty Standards Directory
If `standards/` has only `.gitkeep` files, report: "No standards documents found. Drop your API specs, coding guides, and compliance docs into the appropriate `standards/` subdirectory."

### First-Time Ingest
On first run (no previous ingest), scan everything (don't filter by date). Map all existing standards to skills and report the full picture.

### Conflicting Standards
If a new standard contradicts an existing one in the same directory, flag it explicitly: "standards/api/error-format-v1.md and standards/api/error-format-v2.md may conflict — review before applying."

## Quality Checklist

- [ ] All new/modified files detected and reported
- [ ] Impact classification covers all relevant skills and agents
- [ ] Each recommendation is specific (file path, section, what to change)
- [ ] No contradictions introduced between skills and standards
- [ ] Health check passes after any updates
- [ ] User was given choice to review before applying changes
