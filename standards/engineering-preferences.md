# Engineering Preferences

> This file defines your team's engineering philosophy. The `code-review` skill reads it to calibrate recommendations. Edit these preferences to match your team's values and priorities.
>
> Each preference has a **default** (shown in parentheses) and a **spectrum**. Set your position on the spectrum and optionally add notes explaining exceptions or context.

## DRY (Don't Repeat Yourself)

**Stance**: aggressive
<!-- Options: relaxed | moderate | aggressive -->
<!-- aggressive: Flag any non-trivial logic that appears twice. Recommend extraction immediately. -->
<!-- moderate: Flag logic repeated 3+ times. Allow some duplication for clarity. -->
<!-- relaxed: Only flag large blocks of identical code. Accept duplication when it aids readability. -->

**Notes**: <!-- e.g., "Allow duplication in test setup code" or "Shared utilities go in lib/shared/" -->

## Testing Philosophy

**Stance**: thorough
<!-- Options: minimal | balanced | thorough -->
<!-- thorough: Well-tested code is non-negotiable. Prefer too many tests over too few. Every public function needs tests. Error paths need tests. -->
<!-- balanced: Test critical paths and edge cases. Skip tests for trivial getters/setters. -->
<!-- minimal: Test the happy path and critical failures only. Rely on integration/e2e for coverage. -->

**Notes**: <!-- e.g., "Mocks only for external services, never for internal modules" -->

## Engineering Calibration

**Stance**: engineered-enough
<!-- Options: move-fast | engineered-enough | robust -->
<!-- move-fast: Ship quickly, refactor later. Accept some tech debt for velocity. -->
<!-- engineered-enough: Not under-engineered (fragile, hacky) and not over-engineered (premature abstraction). Right-size the solution. -->
<!-- robust: Build for scale and maintainability from the start. Invest upfront in clean abstractions. -->

**Notes**: <!-- e.g., "For MVP stage, lean toward move-fast. After product-market fit, shift to robust." -->

## Edge Case Handling

**Stance**: thorough
<!-- Options: optimistic | balanced | thorough -->
<!-- thorough: Err on the side of handling more edge cases, not fewer. Thoughtfulness > speed. -->
<!-- balanced: Handle likely edge cases. Document but don't implement rare ones. -->
<!-- optimistic: Handle the happy path well. Add edge case handling when bugs surface. -->

**Notes**: <!-- e.g., "Always handle: empty input, max limits, auth boundaries, concurrent access" -->

## Explicitness vs Cleverness

**Stance**: explicit
<!-- Options: clever-ok | pragmatic | explicit -->
<!-- explicit: Bias toward explicit, readable code. No magic. A new team member should understand it immediately. -->
<!-- pragmatic: Use language idioms and common patterns freely. Be clever only when it significantly reduces complexity. -->
<!-- clever-ok: Optimize for brevity and elegance. Trust the reader to understand common patterns. -->

**Notes**: <!-- e.g., "Avoid operator overloading, magic strings, and implicit type coercion" -->

## Error Handling

**Stance**: strict
<!-- Options: lenient | moderate | strict -->
<!-- strict: Never swallow errors. Use typed/custom error classes. Validate at all system boundaries. Log every error with context. -->
<!-- moderate: Handle errors at API boundaries and critical paths. OK to use generic errors internally. -->
<!-- lenient: Log errors but keep the system running. Prefer resilience over strictness. -->

**Notes**: <!-- e.g., "Use RFC7807 error format for API responses per company.config.yaml" -->

## Performance Awareness

**Stance**: balanced
<!-- Options: not-premature | balanced | performance-first -->
<!-- balanced: Consider performance for hot paths and database queries. Don't micro-optimize cold paths. -->
<!-- not-premature: Don't optimize until profiling shows a problem. Readability trumps performance. -->
<!-- performance-first: Always consider performance. Profile changes that touch hot paths. Budget for p95 latency. -->

**Notes**: <!-- e.g., "Always check for N+1 queries in ORM code. Cache external API responses." -->

---

## How These Preferences Are Used

- **`/code-review`**: Reads this file to calibrate issue severity and recommendations. An "aggressive" DRY stance means 2 occurrences trigger a flag; a "relaxed" stance requires 3+.
- **Engineering Agent**: Reads during implementation for self-review calibration.
- **Release Readiness Gate**: QA Agent reads during Bar 5 (Code Quality) evaluation.

If this file does not exist, the code-review skill uses built-in defaults (see the skill's Appendix A).
