# Code Review Report — Artifact Template

Use this template when producing a formal code review artifact. Copy it into `artifacts/qa-reports/` and fill in each section.

```markdown
---
id: CR-[XXX]
type: qa-report
title: "Code Review: [Feature/PR description]"
status: draft
created: [YYYY-MM-DD]
author: [engineering-agent | qa-release-agent | user]
parent: [RFC-XXX or PRD-XXX if known]
children: []
depends_on: []
blocks: []
tags: [code-review]
---

# Code Review: [Feature/PR description]

## Review Metadata
- **Scope**: [PR #N / file paths / branch diff]
- **Mode**: [BIG CHANGE / SMALL CHANGE]
- **Reviewer**: [agent or user]
- **Files reviewed**: [N files, M lines changed]
- **Engineering preferences**: [standards/engineering-preferences.md | built-in defaults]

## Issues Summary

| Section | Issues Found | Resolved | Deferred | Action Items |
|---------|-------------|----------|----------|--------------|
| Architecture | 0 | 0 | 0 | 0 |
| Code Quality | 0 | 0 | 0 | 0 |
| Test | 0 | 0 | 0 | 0 |
| Performance | 0 | 0 | 0 | 0 |
| **Total** | **0** | **0** | **0** | **0** |

## Section 1: Architecture Issues

[Issue details with decisions, or "No issues found."]

## Section 2: Code Quality Issues

[Issue details with decisions, or "No issues found."]

## Section 3: Test Issues

[Issue details with decisions, or "No issues found."]

## Section 4: Performance Issues

[Issue details with decisions, or "No issues found."]

## Decisions Made
1. [Issue title]: [Chosen option] — [Rationale]

## Action Items
- [ ] [Specific action with file reference]

## Deferred Items
- [Issue]: [Reason for deferring]

## Overall Assessment
**Verdict**: [APPROVE / APPROVE WITH CHANGES / REQUEST CHANGES / BLOCK]

[Summary paragraph]
```
