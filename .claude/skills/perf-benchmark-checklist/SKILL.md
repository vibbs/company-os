---
name: perf-benchmark-checklist
description: Establishes baseline performance metrics and regression detection criteria. Use when setting up performance benchmarks or investigating performance regressions.
---

# Performance Benchmark Checklist

## Reference
- **ID**: S-QA-04
- **Category**: QA
- **Inputs**: SLOs, critical user journeys, infrastructure specs, current performance data
- **Outputs**: performance benchmark report → artifacts/qa/
- **Used by**: QA Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose
Defines baseline performance metrics for critical paths, establishes regression detection thresholds, and provides a repeatable checklist for running performance benchmarks before and after significant changes.

## Procedure
1. Identify critical user journeys and API endpoints that need performance baselines.
2. Define the metrics to capture: p50/p95/p99 latency, throughput (RPS), error rate, memory/CPU usage.
3. Establish the test environment spec: infrastructure, data volume, concurrency level.
   - **Load seed data** — run `./tools/db/seed.sh --reset high-volume` before running benchmarks. This ensures realistic data distribution and volume. Record the exact record counts used in the benchmark report.
4. Run baseline benchmarks under realistic load and record results.
   - **Verify seed data loaded** — confirm `high-volume` scenario data exists by running `./tools/db/seed.sh --list`. Benchmarks against an empty database produce misleading results.
5. Set regression thresholds: e.g., p95 latency must not increase by more than 10%.
6. Define the benchmark execution procedure: warm-up, steady-state duration, cool-down.
7. Document load profiles: ramp-up pattern, sustained load, spike test parameters.
8. Create a comparison template for before/after results.
9. Define the escalation process when a regression is detected.
10. Save the benchmark report and checklist to `artifacts/qa/`.
11. Validate the artifact using `./tools/artifact/validate.sh`.

## Quality Checklist
- [ ] Critical paths are identified and prioritized
- [ ] Metrics include latency percentiles (p50, p95, p99), throughput, and error rate
- [ ] Test environment is documented and reproducible
- [ ] Baseline numbers are recorded with timestamps
- [ ] Regression thresholds are explicitly defined
- [ ] Load profiles cover normal, peak, and spike scenarios
- [ ] Escalation process for regressions is documented
- [ ] `high-volume` seed scenario loaded before benchmarks
- [ ] Record counts documented in benchmark report
- [ ] Artifact passes validation
