---
name: observability-baseline
description: Establishes logging, metrics, and tracing conventions for the codebase. Use when setting up or auditing the observability stack and standards.
user-invokable: false
---

# Observability Baseline

## Reference
- **ID**: S-ENG-15
- **Category**: Engineering
- **Inputs**: service architecture, SLOs, existing logging/metrics setup
- **Outputs**: observability standards document → artifacts/engineering/
- **Used by**: Engineering Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose
Defines the baseline conventions for structured logging, application metrics, and distributed tracing so that every service produces consistent, queryable telemetry data from day one.

## Procedure

### Step 0: Tech Stack Detection

Read `observability.*` from `company.config.yaml` to determine logging, metrics, and tracing providers.

**Provider-specific patterns:**

| Provider | Logging | Metrics | Tracing |
|----------|---------|---------|---------|
| Datadog | Pino → `dd-trace` auto-inject | StatsD via `hot-shots` | `dd-trace` auto-instrumentation |
| Sentry | `@sentry/node` breadcrumbs | Sentry performance metrics | Sentry transactions |
| OpenTelemetry | OTLP exporter | OTLP metrics | OTLP spans |
| CloudWatch | `winston` + CloudWatch transport | CloudWatch embedded metrics | X-Ray SDK |

**Structured log required fields:**
```json
{
  "timestamp": "ISO-8601",
  "level": "info|warn|error|debug",
  "message": "Human-readable description",
  "request_id": "uuid",
  "user_id": "optional",
  "tenant_id": "optional (if multi-tenant)",
  "duration_ms": "optional (for timed operations)",
  "error": { "code": "string", "stack": "string" }
}
```

**Cross-references:** See deployment-strategy for infrastructure setup, incident-response for alert routing.

1. Audit the current observability setup: what logging, metrics, and tracing exist today.
2. Define structured logging conventions: log levels, required fields (request_id, tenant_id, user_id), format (JSON).
3. Define application metrics conventions: naming scheme, label cardinality limits, standard metrics (request duration, error rate, queue depth).
4. Define distributed tracing conventions: span naming, context propagation, sampling strategy.
5. Establish SLO-aligned alerting: map each SLO to a metric and define alert thresholds.
6. Document correlation strategy: how to go from an alert to logs to traces.
7. Define sensitive data handling in telemetry: what must never be logged (PII, secrets).
8. Create example code snippets for each convention.
9. Save the standards document to `artifacts/engineering/`.
10. Validate the artifact using `./tools/artifact/validate.sh`.

## Quality Checklist
- [ ] Structured logging format is defined with required fields
- [ ] Metric naming conventions follow a consistent scheme
- [ ] Distributed tracing spans are named consistently
- [ ] SLO-to-alert mapping is documented
- [ ] Correlation path (alert → logs → traces) is clear
- [ ] PII/secret exclusion rules are specified
- [ ] Example code snippets are provided
- [ ] Artifact passes validation
