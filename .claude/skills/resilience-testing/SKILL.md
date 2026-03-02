---
name: resilience-testing
description: Designs failure mode catalogs, circuit breaker tests, latency injection plans, and blast radius analysis for system resilience verification. Use when validating system behavior under failure conditions.
---

# Resilience Testing

## Reference
- **ID**: S-ENG-14
- **Category**: Engineering / DevOps
- **Inputs**: RFC/architecture docs, deployment topology, dependency map
- **Outputs**: resilience test plan → `artifacts/test-plans/resilience-*.md`
- **Used by**: Engineering DevOps Agent
- **Tool scripts**: `./tools/qa/resilience-test.sh`, `./tools/artifact/validate.sh`

## Purpose

Verify that systems degrade gracefully under failure. Catalog failure modes for every external dependency, design tests for each, and verify recovery behavior. The goal is to ensure that no single dependency failure causes a total system outage, and that users receive clear feedback when functionality is degraded.

## When to Use

- Before production launch of features with external dependencies
- After adding new infrastructure components (databases, caches, queues, third-party APIs)
- During incident post-mortem follow-up to prevent recurrence
- Quarterly resilience audits of critical paths

## Stage-Aware Behavior

| Stage | Behavior |
|-------|----------|
| `idea` | Advisory — resilience testing is recommended but not enforced |
| `mvp` | Advisory — produce a failure mode catalog, testing is optional |
| `growth` | Recommended — failure mode catalog and circuit breaker tests expected |
| `scale` | Required — full resilience test plan must be produced and executed |

Read `company.stage` from `company.config.yaml` to determine the current stage.

## Procedure

### Step 1: Load Context

Before designing resilience tests:

1. **Read `company.config.yaml`** — understand `architecture.*`, `tech_stack.hosting`, `observability.*` configuration
2. **Read the RFC** for deployment topology — identify services, databases, caches, queues, and external APIs
3. **Identify all external dependencies** — anything the system calls that is not under your direct control (third-party APIs, managed databases, CDNs, DNS providers, certificate authorities, payment processors, etc.)
4. **Read `standards/ops/`** for existing operational procedures and runbooks
5. **Check feature flag configuration** — identify flags that can be used for graceful degradation

### Step 2: Failure Mode Catalog

Enumerate failure modes for each dependency. For every external dependency, assess the following failure scenarios:

| Failure Mode | Description |
|--------------|-------------|
| Database unavailability | Primary database is unreachable or rejecting connections |
| Cache miss/failure | Cache layer (Redis, Memcached) is down or returning errors |
| External API timeout | Third-party API responds but exceeds timeout threshold |
| External API error (4xx/5xx) | Third-party API returns client or server errors |
| Message queue backpressure | Queue is full or consumer is unable to keep up |
| DNS resolution failure | DNS lookup for an external service fails |
| Certificate expiry | TLS certificate for an external endpoint has expired |
| Disk space exhaustion | Local or attached storage is full |
| Memory pressure | Application or host is running out of available memory |
| Network partition | Network connectivity between services is interrupted |

For each failure mode, document:

- **Severity**: critical / high / medium / low
- **Likelihood**: frequent / occasional / rare
- **Detection method**: How is this failure detected? (health check, metric alert, error log, user report)
- **Expected behavior**: What should the system do when this failure occurs? (fallback, retry, degrade, fail fast)

### Step 3: Circuit Breaker Testing

For each dependency that has a circuit breaker configured:

1. **Verify CLOSED to OPEN transition** — confirm the failure threshold triggers the breaker to open
2. **Verify OPEN state behavior** — confirm fast-fail responses with no cascading failures to upstream callers
3. **Verify OPEN to HALF-OPEN transition** — confirm the recovery probe fires after the configured timeout
4. **Verify HALF-OPEN to CLOSED transition** — confirm successful recovery probes restore normal operation

Document for each circuit breaker:

| Field | Value |
|-------|-------|
| Breaker name | [identifier] |
| Failure threshold | [count or percentage] |
| Timeout (open duration) | [seconds] |
| Half-open probe count | [number of test requests] |
| Fallback behavior | [what happens when open] |

### Step 4: Latency Injection Testing

Introduce artificial delays to verify timeout and retry behavior:

1. **Timeout handling** — verify that timeout fires at the configured threshold, not earlier or later
2. **Retry logic** — verify exponential backoff with jitter (not fixed-interval retries that cause thundering herd)
3. **User-facing messages** — verify that timeout errors produce clear, actionable messages (not stack traces)
4. **Monitoring alerts** — verify that latency spike alerts fire when injected delays exceed SLO thresholds

Test at the following latency levels:

| Level | Description | Purpose |
|-------|-------------|---------|
| P50 latency | Typical response time | Baseline — system should behave normally |
| P99 latency | High-end normal response time | System should handle without degradation |
| Timeout boundary | Just below configured timeout | Verify timeout does not fire prematurely |
| 2x timeout | Well beyond configured timeout | Verify timeout fires, retry/fallback activates |

### Step 5: Graceful Degradation Verification

#### Feature Flag Degradation

For each feature flag in the system:

1. Disable the flag — verify the feature is hidden (not broken or throwing errors)
2. Verify fallback behavior renders correctly (empty state, alternative UI, or feature removal)
3. Verify no error logs are generated from the disabled feature path
4. Verify monitoring still tracks the degraded state (metric counters, flag status dashboards)

#### Dependency Degradation

For each external dependency:

1. Simulate unavailability — verify the application continues running with reduced functionality
2. Verify error messages guide users clearly (not generic "something went wrong")
3. Verify no data corruption occurs during degraded operation
4. Verify that recovery is automatic when the dependency comes back online

### Step 6: Blast Radius Analysis

For each failure mode identified in Step 2:

1. **Map cascading effects** — if dependency X fails, what other features or services also break?
2. **Identify single points of failure** — dependencies with no redundancy or fallback
3. **Document maximum blast radius** — the worst-case scope of impact for each failure
4. **Recommend isolation strategies**:
   - **Bulkheading** — isolate failure domains so one failure does not consume all resources
   - **Timeouts** — prevent slow dependencies from blocking fast paths
   - **Circuit breakers** — stop cascading failures by failing fast
   - **Retry budgets** — limit total retry attempts across the system to prevent amplification

### Step 7: Produce Resilience Test Plan

Create the resilience test plan artifact at `artifacts/test-plans/resilience-{feature}-{date}.md` with the following structure:

```yaml
---
id: TP-RES-{feature}-{number}
type: test-plan
status: draft
parent: RFC-{id}
created: {date}
---
```

Include the following sections in the artifact:
- Summary of dependencies and failure modes
- Circuit breaker test cases with expected outcomes
- Latency injection test matrix
- Graceful degradation test cases
- Blast radius map with isolation recommendations
- Priority ordering (test critical paths first)

### Step 8: Validate

Run `./tools/artifact/validate.sh` on the produced artifact to verify:
- YAML frontmatter is complete and well-formed
- Parent RFC reference exists
- Status is set to `draft`
- All required fields are present

## Cross-References

- **deployment-strategy** — resilience tests should align with the deployment topology and rollback procedures
- **observability-baseline** — failure detection depends on metrics, logging, and alerting being configured
- **feature-flags** — graceful degradation often relies on feature flags as kill switches
- **threat-modeling** — failure modes overlap with threat scenarios (denial of service, dependency compromise)

**Tool Limitation Note:** `resilience-test.sh` performs basic HTTP health and timeout checks only. The circuit breaker, latency injection, and blast radius tests described in this skill require manual execution or Claude-driven testing against a running application. The tool provides a smoke-test baseline, not full resilience verification. For production-grade resilience testing, consider dedicated chaos engineering tools (Litmus, Gremlin, or Chaos Monkey).

## Quality Checklist

- [ ] Every external dependency has a failure mode entry in the catalog
- [ ] Severity and likelihood are assessed for each failure mode
- [ ] Circuit breaker tests cover all four state transitions (CLOSED, OPEN, HALF-OPEN, CLOSED)
- [ ] Latency injection tests cover P50, P99, timeout boundary, and 2x timeout levels
- [ ] Graceful degradation verified for every feature flag and critical dependency
- [ ] Blast radius is mapped for every critical failure mode
- [ ] Single points of failure are identified with isolation recommendations
- [ ] Stage-awareness is respected (advisory in idea/mvp, required in scale)
- [ ] Artifact frontmatter is complete and passes validation
- [ ] Resilience test plan is linked to its parent RFC
