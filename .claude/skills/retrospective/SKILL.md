---
name: retrospective
description: Post-ship retrospective — traces artifact lineage from PRD to launch, evaluates success metrics, captures lessons learned, and produces a structured retro document.
user-invokable: true
argument-hint: "<prd-id or feature name>"
---

# Retrospective

## Reference
- **ID**: S-ORG-14
- **Category**: Orchestration
- **Inputs**: PRD, RFC, QA report, launch brief artifacts; tasks/lessons.md
- **Outputs**: Retrospective document → artifacts/decision-memos/
- **Used by**: Orchestrator Agent, User (directly)
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose

After a feature ships, answer: "Did it work? What did we learn? What should we do differently?" Traces the full artifact lineage and captures structured lessons.

## Procedure

### Step 1: Find the Feature
Accept a PRD ID (e.g., PRD-001) or feature name. If a name is given, search `artifacts/prds/` for matching titles.

### Step 2: Walk Artifact Lineage
Starting from the PRD, trace the full artifact chain:
- PRD → RFC(s) (via children/depends_on links)
- RFC → QA Report(s) (via children links)
- RFC → Security Review (if exists)
- PRD → Launch Brief (if exists)
- Any Decision Memos referencing this PRD

Build a timeline from artifact creation/modification dates.

### Step 3: Evaluate Success Metrics
Read the PRD's success metrics section:
- For each metric: is data available? What's the current value?
- If no data available yet: note as "pending measurement" with recommended check date
- Compare against targets if set

### Step 4: Implementation Analysis
From artifact timestamps:
- Time from PRD creation to RFC completion
- Time from RFC to implementation complete (QA report exists)
- Time from QA to launch
- Total cycle time
- Any stages that took disproportionately long

### Step 5: Quality Analysis
From QA report(s):
- Test pass rate
- Issues found during QA (count and severity)
- Issues found during dogfooding (if dogfood report exists)
- Any post-launch issues reported

### Step 6: Produce Retro Document

```
## Retrospective: [Feature Name]

### Summary
- **PRD**: [ID] — [title]
- **Status**: [shipped/partially shipped/blocked]
- **Cycle Time**: [X days from PRD to launch]

### What Worked
- [things that went well]

### What Didn't Work
- [things that were painful or slow]

### What We Learned
- [key insights]

### Carry Forward
- [ ] [action item for next feature]
- [ ] [process improvement]
- [ ] [technical debt to address]

### Metrics
| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| [metric] | [target] | [actual or pending] | [met/missed/pending] |
```

### Step 7: Save and Link
1. Save to `artifacts/decision-memos/RETRO-{prd-id}.md` with frontmatter
2. Link as child of the original PRD
3. Append key lessons to `tasks/lessons.md`
4. Validate with `./tools/artifact/validate.sh`

## Quality Checklist
- [ ] Full artifact lineage traced
- [ ] Success metrics evaluated (or marked pending)
- [ ] Cycle time calculated
- [ ] Lessons are specific and actionable
- [ ] Document saved and linked to PRD
- [ ] Key lessons appended to tasks/lessons.md
