---
name: test-intelligence
description: Analyzes test suite health including flaky test detection, coverage scoring, test pyramid balance, and mutation testing guidance. Use when assessing test quality or diagnosing test reliability issues.
allowed-tools: Read, Grep, Glob, Bash, Write
---

# Test Intelligence

## Reference
- **ID**: S-QA-09
- **Category**: QA / Release
- **Inputs**: test runner output, coverage reports, CI logs
- **Outputs**: test health report → artifacts/qa-reports/test-health-*.md
- **Used by**: QA & Release Agent
- **Tool scripts**: ./tools/artifact/validate.sh, ./tools/qa/test-health.sh

## Purpose

Assess test suite quality beyond pass/fail. A green CI badge tells you tests pass -- it says nothing about whether the tests are meaningful, stable, or well-distributed. This skill detects flaky tests that erode developer trust, scores coverage in ways that actually matter (not just line coverage), verifies the test pyramid is balanced, and recommends mutation testing for critical business logic.

Test suites decay silently. Flaky tests get ignored. Coverage numbers plateau while meaningful coverage drops. Integration tests multiply while unit tests stagnate. This skill provides periodic health checks to catch these problems before they undermine confidence in the entire test suite.

## When to Use

- After the test suite grows past initial setup and needs quality assessment
- When flaky tests cause CI unreliability or developer frustration
- During release readiness evaluation (feeds into release-readiness-gate)
- Quarterly health audits to maintain test suite quality
- When onboarding a new codebase and need to understand test suite maturity

## Test Intelligence Procedure

### Step 1: Load Context

Before analyzing test health:

1. **Read `company.config.yaml`** -- extract `tech_stack.test_framework`, CI configuration, and language/framework
2. **Scan test directories** -- identify test file locations based on project conventions:
   - `tests/`, `test/`, `__tests__/`, `spec/`, `*.test.*`, `*.spec.*`
   - Subdirectories: `unit/`, `integration/`, `e2e/`, `functional/`
3. **Read CI configuration** -- `.github/workflows/`, `.circleci/`, `Jenkinsfile`, `.gitlab-ci.yml`
4. **Read existing test health reports** in `artifacts/qa-reports/` for trend comparison

### Step 2: Flaky Test Detection

Analyze CI logs and test results for inconsistent behavior:

1. **Identify non-deterministic tests** -- tests that pass and fail across runs without code changes
2. **Common flaky patterns to scan for**:
   - Time-dependent assertions (`Date.now()`, `setTimeout`, `sleep`, timestamp comparisons)
   - Race conditions in async tests (missing `await`, unhandled promises)
   - Shared mutable state between tests (global variables, database state leaking)
   - Network-dependent tests (external API calls without mocks)
   - Order-dependent tests (pass in isolation, fail in suite or vice versa)
   - Filesystem-dependent tests (hardcoded paths, temp files not cleaned up)
3. **Produce quarantine recommendations**:
   - Quarantine file: list tests to move to a separate, non-blocking CI step
   - Re-run strategy: configure test runner retry (e.g., `jest --bail`, `pytest --lf`)
   - Fix-or-delete SLA: flaky tests get 2 sprints to fix, then delete -- no exceptions

### Step 3: Test Coverage Scoring

Go beyond line coverage to measure meaningful coverage:

1. **Line coverage** -- baseline metric, but insufficient alone (target: >80%)
2. **Branch coverage** -- measures decision paths taken (target: >70%)
3. **Assertion density** -- assertions per test function (target: >1.5 avg; tests with 0 assertions are smoke, not tests)
4. **Coverage delta** -- coverage of new/changed code vs overall (new code should be at or above overall average)
5. **Meaningful coverage assessment**:
   - Are critical paths (auth, payments, data mutations) covered?
   - Are error handlers tested, not just happy paths?
   - Are boundary conditions (empty input, max values, null) exercised?
6. **Coverage blind spots** -- files with 0% coverage that contain business logic (not config/boilerplate)

### Step 4: Test Pyramid Balance

Calculate the ratio of test types and compare against the ideal pyramid:

1. **Count tests by type**:
   - **Unit tests**: test individual functions/classes in isolation (fast, no I/O)
   - **Integration tests**: test component interactions (database, API calls, service boundaries)
   - **E2E tests**: test full user flows (browser, API chain, multi-service)
2. **Calculate pyramid ratio** -- express as unit:integration:e2e percentage
3. **Compare against ideal**: 70:20:10 (unit:integration:e2e)
4. **Flag pyramid inversions**:
   - Ice cream cone: more E2E than unit (brittle, slow CI)
   - Hourglass: many unit + many E2E, few integration (missing middle layer)
   - Diamond: mostly integration (often masks poor unit test discipline)
5. **Recommend rebalancing** -- specific guidance on which test types to add/reduce

### Step 5: Mutation Testing Guidance

Recommend mutation testing for appropriate codebases:

1. **When to use mutation testing**:
   - Stable codebase with high line coverage (>80%) but uncertain test quality
   - Critical business logic (billing, permissions, data integrity)
   - Code that has had production bugs despite good coverage
2. **Recommended mutators by language**:
   - **JavaScript/TypeScript**: Stryker (`npx stryker run`)
   - **Python**: mutmut (`mutmut run`)
   - **Go**: go-mutesting (`go-mutesting ./...`)
   - **Java/Kotlin**: PIT (`mvn org.pitest:pitest-maven:mutationCoverage`)
   - **Ruby**: mutant (`bundle exec mutant run`)
3. **Interpret mutation score**:
   - >80%: excellent test quality
   - 60-80%: good, investigate surviving mutants
   - <60%: tests are passing but not catching real bugs
4. **Cost-benefit threshold** -- do not mutate everything:
   - Focus on business-critical modules (auth, billing, core domain logic)
   - Skip generated code, configuration, simple getters/setters
   - Run mutation testing weekly or before major releases, not on every PR

### Step 6: Test Execution Performance

Analyze test suite speed and identify optimization opportunities:

1. **Track total suite execution time** by test type (unit, integration, e2e)
2. **Identify slowest tests** -- top 10 by execution time
3. **Set time budgets per test type**:
   - Unit tests: <30 seconds total (or <100ms per test)
   - Integration tests: <5 minutes total
   - E2E tests: <15 minutes total
4. **Recommend parallelization strategies**:
   - Test runner parallelism (Jest workers, pytest-xdist, Go parallel subtests)
   - CI parallelism (split test suites across CI nodes)
   - Database isolation for parallel integration tests

### Step 7: Auto-Triggered Testing Recommendations

Define which tests run on which events for optimal CI feedback speed:

| Event | Tests to Run | Rationale |
|-------|-------------|-----------|
| Pre-commit (local) | Lint + affected unit tests | Fast feedback, <30s |
| Pull request | Unit + integration | Verify correctness, <5min |
| Merge to main | Full suite + E2E | Gate before deploy |
| Nightly | Mutation + performance + full E2E | Expensive, catch decay |
| Pre-release | Full suite + E2E + smoke on staging | Final confidence |

### Step 8: Produce Test Health Report

Generate the test health report artifact:

```yaml
---
id: QA-HEALTH-{date}
type: qa-report
status: draft
parent: [RFC or PRD if applicable]
---
```

Include in the report:
- **Summary**: overall test suite health grade (A-F)
- **Flaky Tests**: count, list, quarantine recommendations
- **Coverage**: line, branch, assertion density, delta, blind spots
- **Pyramid Balance**: current ratio vs ideal, rebalancing recommendations
- **Mutation Testing**: recommended scope, estimated effort
- **Execution Performance**: total time, slowest tests, parallelization opportunities
- **Auto-Trigger Config**: recommended CI trigger matrix
- **Trend**: comparison with previous health reports (if available)

Save to `artifacts/qa-reports/test-health-{date}.md`.

### Step 9: Validate

Run `./tools/artifact/validate.sh` on the produced report to verify frontmatter and artifact references.

## Cross-References

- **test-plan-generator**: Test plans define what to test; test intelligence assesses how well the suite tests it
- **perf-benchmark-checklist**: Performance benchmarks complement test execution performance analysis
- **experiment-framework**: Experiment metrics require reliable test infrastructure; flaky tests undermine experiment confidence

## Quality Checklist

- [ ] CI logs and test output were analyzed for flaky test patterns
- [ ] Coverage scoring goes beyond line coverage (branch, assertion density, delta)
- [ ] Test pyramid ratio is calculated and compared against ideal (70:20:10)
- [ ] Pyramid inversions are flagged with specific rebalancing guidance
- [ ] Mutation testing is recommended with language-appropriate tooling
- [ ] Cost-benefit threshold is applied (focus on business-critical modules)
- [ ] Test execution performance is profiled with optimization recommendations
- [ ] Auto-triggered testing matrix is defined for CI events
- [ ] Report artifact has valid frontmatter and passes validation
- [ ] Trend comparison with previous reports is included (if available)
