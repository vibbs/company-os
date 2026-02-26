---
name: code-review
description: Structured multi-section code review with interactive feedback — architecture, quality, tests, performance. Use for PR reviews, pre-merge quality checks, or self-review before handoff.
user-invokable: true
argument-hint: "[pr-number or file-paths]"
allowed-tools: Read, Grep, Glob, Bash
---

# Code Review

## Reference
- **ID**: S-ENG-06
- **Category**: Engineering / QA
- **Inputs**: PR diff or file paths, company.config.yaml, standards/coding/, standards/engineering-preferences.md
- **Outputs**: Interactive review with decisions, review summary artifact in `artifacts/qa-reports/`
- **Used by**: Engineering Agent (self-review), QA & Release Agent (release quality), User (ad-hoc)
- **Tool scripts**: `./tools/artifact/validate.sh`

## Purpose

Conduct a structured, multi-section code review that systematically evaluates architecture, code quality, test coverage, and performance. The review is interactive — issues are presented one section at a time, the user provides feedback on each, and decisions are recorded in a review summary artifact.

## When to Use

- Before merging a PR (user invokes `/code-review 42` or `/code-review <file-paths>`)
- Engineering Agent self-review before handing off to QA
- QA Agent code quality evaluation during release readiness
- Ad-hoc review of any code area

## Code Review Procedure

### Step 0: Load Context

Before reviewing any code:

1. **Read `company.config.yaml`** — extract tech stack, conventions, API standards
2. **Read `standards/coding/`** — load project-specific coding conventions
3. **Read `standards/engineering-preferences.md`** — load the team's engineering philosophy:
   - DRY stance (relaxed / moderate / aggressive)
   - Testing philosophy (minimal / balanced / thorough)
   - Engineering calibration (move-fast / engineered-enough / robust)
   - Edge case handling (optimistic / balanced / thorough)
   - Explicitness preference (clever-ok / pragmatic / explicit)
   - Error handling strictness (lenient / moderate / strict)
   - Performance awareness (not-premature / balanced / performance-first)
4. If `standards/engineering-preferences.md` does not exist, use the built-in defaults (see Appendix A) and note this to the user

### Step 1: Determine Review Scope

Determine what code to review based on the argument:

| Argument | Scope | Method |
|----------|-------|--------|
| PR number (e.g., `42`) | PR diff only | Run `gh pr diff 42` (fallback: `git diff origin/main...HEAD`) |
| File paths (e.g., `src/auth/`) | Specific files/directories | Read files directly |
| No argument | Uncommitted changes | Run `git diff HEAD` for staged+unstaged |
| Branch name (e.g., `feature/auth`) | Branch diff from base | Run `git diff main...feature/auth` |

After determining scope, report:
- Number of files changed
- Approximate lines added/removed
- File types involved (e.g., "12 TypeScript files, 3 test files, 1 migration")

**Large PR heuristic**: If more than 30 files changed, recommend narrowing scope (review by module or directory) rather than attempting to review everything at once.

### Step 2: Ask Review Mode

**BEFORE YOU START:** Ask whether the user wants:

**1/ BIG CHANGE** — Work through interactively, one section at a time (Architecture → Code Quality → Tests → Performance) with at most 4 top issues in each section.

**2/ SMALL CHANGE** — Work through interactively, ONE question per review section.

Wait for user response before proceeding. The user may also specify a focus mode: "focus on [section]" to run only one section with full BIG CHANGE depth.

---

### Section 1: Architecture Review

Evaluate the changed code against architectural concerns. In BIG CHANGE mode, raise up to 4 issues. In SMALL CHANGE mode, raise only the single most important issue (or state "No architectural concerns").

**What to evaluate:**
- Overall system design and component boundaries
- Dependency graph and coupling concerns (are new dependencies introduced? justified?)
- Data flow patterns and potential bottlenecks
- Scaling characteristics and single points of failure
- Security architecture (auth boundaries, data access patterns, API exposure)
- Consistency with existing architecture in `artifacts/rfcs/`
- Tech stack fitness (per `company.config.yaml`)

**FOR EACH ISSUE**: Output the explanation and pros and cons, AND your opinionated recommendation and why. Then use AskUserQuestion to present options. Number issues and letter options (Issue 1, Option A/B/C). Recommended option is always listed first.

**Issue format:**

```
### Issue 1: [Concise title]

**Problem**: [Concrete description with file path and line reference]

`path/to/file.ts:42-58` — [what is wrong and why it matters]

**Options**:

**Option A (Recommended): [Action name]**
- Implementation: [what to change]
- Effort: [low/medium/high]
- Risk: [what could go wrong]
- Impact: [how it affects other code]
- Maintenance: [ongoing burden]
- Why recommended: [map to engineering preferences]

**Option B: [Alternative action]**
- Implementation: [what to change]
- Effort: [low/medium/high]
- Risk: [what could go wrong]
- Impact: [how it affects other code]
- Maintenance: [ongoing burden]

**Option C: Do nothing**
- Risk: [what happens if left as-is]
- When acceptable: [under what circumstances this is OK]
```

After presenting all issues for Section 1, ask:

> **Section 1 (Architecture) complete. [N] issues raised.**
> Ready to proceed to Section 2 (Code Quality)? Or want to discuss any issue further?

Wait for user response.

---

### Section 2: Code Quality Review

Evaluate code organization and craftsmanship. Calibrate against `standards/engineering-preferences.md`.

**What to evaluate:**
- Code organization and module structure
- DRY violations — **be aggressive** per engineering preferences; flag any repeated logic, even 2 occurrences if the pattern is non-trivial
- Error handling patterns — are errors caught, typed, and not swallowed?
- Missing edge cases — call these out explicitly with concrete scenarios
- Technical debt hotspots — code that works but will be painful later
- Over-engineering vs under-engineering (calibrate against the "engineered enough" preference)
- Naming clarity — is the code self-documenting?
- Consistency with `standards/coding/` conventions
- Areas that are over-engineered or under-engineered relative to preferences
- **Feature flag debt**: stale flags past cleanup SLA, flags missing cleanup dates, dead flag branches in code (check `feature_flags.cleanup_sla_days` from config)
- **Mobile compatibility**: if `platforms.responsive` is true, check for hardcoded widths, missing viewport considerations, touch targets < 44x44px, non-responsive layouts

Same issue format as Section 1. Pause for user feedback after completing.

---

### Section 3: Test Review

Evaluate test coverage and quality.

**What to evaluate:**
- Test coverage gaps — which new/changed code paths have no tests?
- Test quality and assertion strength — are assertions specific or just "does not throw"?
- Missing edge case coverage — enumerate specific edge cases that should be tested
- Untested failure modes and error paths — errors that could happen but are not exercised
- Test isolation — do tests depend on external state or ordering?
- Mock appropriateness — per coding standards: mock external services only, never your own code
- Test naming — do test names describe behavior (`should X when Y`)?

Same issue format. Pause for user feedback after completing.

---

### Section 4: Performance Review

Evaluate performance characteristics. Skip issues that are clearly irrelevant to the change scope.

**What to evaluate:**
- N+1 queries and database access patterns (if applicable)
- Memory-usage concerns (large allocations, unbounded growth, leaks)
- Caching opportunities (repeated expensive computation or data fetch)
- Algorithmic complexity — O(n²) or worse where O(n) or O(n log n) is achievable
- Unnecessary re-renders (React/frontend specific, if applicable)
- Bundle size impact (if frontend changes)
- I/O patterns — unnecessary sequential operations that could be parallel
- Slow or high-complexity code paths

Same issue format. Pause for user feedback after completing.

---

### Step 3: Review Summary

After all four sections are complete (or the focused section if user requested a single one), produce a review summary:

```markdown
## Code Review Summary

### Scope
- **Reviewed**: [PR #42 / files / branch diff]
- **Mode**: [BIG CHANGE / SMALL CHANGE]
- **Files**: [N files, M lines changed]
- **Engineering preferences**: [standards/engineering-preferences.md | built-in defaults]

### Issues by Section

| Section | Issues Found | Resolved | Deferred | Action Items |
|---------|-------------|----------|----------|--------------|
| Architecture | N | N | N | N |
| Code Quality | N | N | N | N |
| Test | N | N | N | N |
| Performance | N | N | N | N |
| **Total** | **N** | **N** | **N** | **N** |

### Decisions Made
1. **Issue 1** ([section]): [chosen option] — [rationale]
2. **Issue 2** ([section]): [chosen option] — [rationale]
...

### Action Items
- [ ] [Specific action with file reference]
- [ ] [Specific action with file reference]

### Deferred Items
- [Issue N]: [reason for deferring, conditions for revisiting]

### Overall Assessment
[APPROVE / APPROVE WITH CHANGES / REQUEST CHANGES / BLOCK]

[1-2 sentence summary of the overall code quality and readiness]
```

### Step 4: Produce Review Artifact

If the review was part of a formal workflow (not an ad-hoc quick check), save the summary as an artifact:

1. Use the review report template (see `review-report-template.md` in this skill directory)
2. Store in `artifacts/qa-reports/`
3. Set appropriate lineage:
   - `parent`: the RFC or PRD this code implements (if known)
   - `depends_on`: any related artifacts
4. Set status to `review`
5. Run `./tools/artifact/validate.sh` on the artifact

Ask the user: "Save this review as a formal artifact in `artifacts/qa-reports/`? (y/n)"

## Focus Mode

If the user specifies a single section (e.g., `/code-review src/auth/ --focus performance`), run only that section with the full BIG CHANGE depth (up to 4 issues), skip the others, and still produce a summary.

## Agent Integration Modes

### Engineering Self-Review (Pre-Handoff)

When invoked by the Engineering Agent as a pre-handoff self-review:
1. Run all four sections in SMALL CHANGE mode (one issue per section) automatically
2. Do not pause between sections (non-interactive)
3. If any issue is rated as blocking: stop and address before handoff
4. Produce the summary artifact automatically and link to the RFC

### QA Release Review

When invoked by the QA & Release Agent:
1. Run Code Quality and Test sections in BIG CHANGE mode
2. Run Architecture and Performance in SMALL CHANGE mode
3. Results feed into the release-readiness-gate Bar 5 (Code Quality) evaluation

## Appendix A: Default Engineering Preferences

If `standards/engineering-preferences.md` does not exist, use these defaults:

- **DRY**: aggressive — flag any non-trivial logic that appears twice
- **Testing**: thorough — well-tested code is non-negotiable; err on the side of more tests
- **Engineering calibration**: engineered-enough — not under-engineered (fragile, hacky) and not over-engineered (premature abstraction)
- **Edge cases**: thorough — err on the side of handling more edge cases, not fewer; thoughtfulness > speed
- **Explicitness**: explicit — bias toward explicit, readable code; no magic
- **Error handling**: strict — never swallow errors; use typed errors at system boundaries
- **Performance**: balanced — consider performance for hot paths and database queries; don't micro-optimize cold paths

## Quality Checklist

- [ ] `company.config.yaml` was read for tech stack context
- [ ] `standards/coding/` was read for project conventions
- [ ] `standards/engineering-preferences.md` was read (or defaults noted)
- [ ] Review scope was clearly determined and reported
- [ ] Review mode (BIG/SMALL) was confirmed with user
- [ ] Each section paused for user feedback (in interactive mode)
- [ ] Issues are numbered and options are lettered
- [ ] Recommended option is always listed first (Option A)
- [ ] Every issue references concrete file paths and line numbers
- [ ] Summary includes all decisions made during the review
- [ ] Action items are specific and actionable
- [ ] Review artifact was offered/produced if part of formal workflow
