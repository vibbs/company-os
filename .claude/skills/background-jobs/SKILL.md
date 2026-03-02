---
name: background-jobs
description: Design patterns for background job processing including retries, idempotency, and queue management. Use when designing or reviewing async task infrastructure.
---

# Background Jobs

## Reference
- **ID**: S-ENG-03
- **Category**: Engineering
- **Inputs**: job requirements, retry semantics, throughput targets, failure modes
- **Outputs**: background job design document → artifacts/engineering/
- **Used by**: Engineering Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose
Provides design patterns and conventions for building reliable background job systems with proper retry logic, idempotency guarantees, and queue management to prevent data corruption and ensure at-least-once processing.

## Procedure

### Step 0: Tech Stack Detection

Read `tech_stack.queue` from `company.config.yaml` to determine the job processing framework.

**Framework-specific patterns:**

| Framework | Language | Job Structure | Retry Config | Dead-Letter |
|-----------|----------|---------------|--------------|-------------|
| BullMQ | TypeScript | `Queue` + `Worker` classes, job data as typed interface | `attempts` + `backoff` in job options | Failed jobs move to `__failed__` queue |
| Celery | Python | `@app.task` decorator, `bind=True` for self-reference | `max_retries` + `default_retry_delay` on task | `task_reject_on_worker_lost=True` |
| Sidekiq | Ruby | `include Sidekiq::Worker`, `perform` method | `sidekiq_options retry: N` | Dead set after max retries |

If `tech_stack.queue` is not configured, present recommendations based on `tech_stack.language`.

**Cross-references:** See deployment-strategy for queue infrastructure, observability-baseline for job metrics.

1. Identify the jobs to be processed asynchronously and their triggers.
2. Classify each job by priority, expected duration, and failure tolerance.
3. Design the queue topology: which queues, routing rules, concurrency limits.
4. Define retry strategy for each job type: max retries, backoff algorithm (exponential, linear), dead-letter handling.
5. Ensure idempotency: define idempotency keys and deduplication windows.
6. Design failure handling: what happens on permanent failure, alerting, manual retry paths.
7. Define observability: job start/end logging, duration metrics, failure rate dashboards.
8. Document rate limiting and backpressure mechanisms.
9. Save the design document to `artifacts/engineering/`.
10. Validate the artifact using `./tools/artifact/validate.sh`.

## Quality Checklist
- [ ] Every job type has a defined retry strategy
- [ ] Idempotency keys are specified for all state-mutating jobs
- [ ] Dead-letter queue handling is defined
- [ ] Concurrency limits prevent resource exhaustion
- [ ] Failure alerting thresholds are specified
- [ ] Backpressure mechanism is documented
- [ ] Observability hooks (logs, metrics, traces) are included
- [ ] Artifact passes validation
