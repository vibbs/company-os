---
name: deployment-strategy
description: Designs deployment pipelines, rollout strategies, and environment configurations. Use when establishing deployment procedures, planning a feature rollout, or setting up CI/CD pipelines.
allowed-tools: Read, Grep, Glob, Bash, Write
---

# Deployment Strategy

## Reference
- **ID**: S-ENG-07
- **Category**: Engineering
- **Inputs**: company.config.yaml, existing RFCs
- **Outputs**: deployment strategy (standards/ops/), per-feature deployment plan (in RFC)
- **Used by**: Engineering Agent
- **Tool scripts**: ./tools/deploy/pre-deploy.sh, ./tools/qa/smoke-test.sh, ./tools/db/migration-check.sh

## Purpose

Define a repeatable, safe deployment pipeline that moves code from a developer's machine to production with confidence. This skill produces environment configurations, pipeline designs, rollout strategies, and rollback procedures tailored to the configured tech stack.

## Procedure

### Step 1: Load Context

Before designing the deployment strategy:

1. **Read `company.config.yaml`** -- understand hosting provider, CI system, branching conventions, and `architecture.deployment_model`
2. **Read existing RFCs** in `artifacts/rfcs/` -- understand system dependencies and data flow
3. **Check existing standards** in `standards/ops/` -- avoid contradicting existing operational procedures
4. **Identify deployment constraints** -- database migrations, external service dependencies, feature flags

### Step 2: Generate Deployment Strategy

Produce `standards/ops/deployment-strategy.md` with the following sections:

#### Environment Ladder

Define three environments with specific configuration differences:

| Environment | Purpose | Database | Data | Monitoring | Access |
|-------------|---------|----------|------|------------|--------|
| **Local** | Developer machine, hot reload, fast iteration | Local DB instance (SQLite, local Postgres, etc.) | Seed data from `./tools/db/seed.sh` | Console logging only | Developer only |
| **Staging** | Mirror of production for pre-release validation | Staging DB (same engine as production) | Anonymized test data, never real user data | Full monitoring enabled, alerts to staging channel | Developer + QA |
| **Production** | Live users, real data, revenue-generating | Production DB with backups and replication | Real user data, strict access controls | Full monitoring, alerting, on-call notifications | Restricted, deploy via CI only |

Key differences to document:
- Environment variable sets per environment
- Feature flags: which are enabled where
- External service endpoints: sandbox vs. production APIs
- Log levels: debug (local), info (staging), warn+error (production)

#### Deployment Pipeline

Design the pipeline based on the configured CI provider:

```
Push to branch
    |
    v
CI Pipeline Triggered
    |
    +-- Run tests (unit, integration)
    +-- Run linter
    +-- Run security scan (dependency-scan.sh)
    +-- Run migration check (migration-check.sh)
    |
    v
All checks pass?
    |
    +-- No --> Block merge, notify developer
    +-- Yes --> Continue
    |
    v
Merge to main branch
    |
    v
Deploy to Staging
    |
    v
Run smoke tests (smoke-test.sh) against staging
    |
    v
Smoke tests pass?
    |
    +-- No --> Block production deploy, notify
    +-- Yes --> Continue
    |
    v
Manual approval gate (for P0-risk changes) or auto-promote
    |
    v
Deploy to Production
    |
    v
Run smoke tests against production
    |
    v
Monitor error rates for 15 minutes
    |
    +-- Error spike --> Auto-rollback (if configured) or alert
    +-- Stable --> Deploy complete
```

#### Rollout Strategy Per Deployment Model

**Serverless** (Vercel, Netlify, AWS Lambda, Cloudflare Workers):
- Atomic deploys: the entire deployment is swapped at once
- Instant rollback: redeploy the previous version through the platform dashboard or CLI
- No partial rollouts by default; use feature flags for gradual exposure
- Edge functions deploy regionally; verify in multiple regions

**Containers** (Docker, ECS, Kubernetes, Fly.io, Railway):
- **Rolling update** (default): replace instances one at a time; zero downtime if health checks pass
- **Blue-green**: run new version alongside old; switch traffic via load balancer; instant rollback by switching back
- **Canary**: route a small percentage of traffic (5-10%) to the new version; monitor error rates; expand if stable

**VMs** (EC2, DigitalOcean Droplets, traditional hosting):
- Blue-green with load balancer swap: spin up new instances, validate, swap load balancer target
- Rollback: swap load balancer back to old instances (keep them running for 1 hour post-deploy)

**Edge** (Cloudflare Workers, Deno Deploy, edge functions):
- Regional rollout: deploy to one region first, monitor, then expand globally
- Instant rollback: redeploy previous version to all regions

#### Rollback Procedure

Step-by-step, stack-specific rollback:

1. **Detect the issue** -- error rate spike, failing smoke tests, user reports
2. **Decide to rollback** -- if fix is not obvious within 15 minutes, rollback
3. **Execute rollback**:
   - Revert to the previous deployment using the hosting provider's rollback mechanism
   - If database migration was applied: run the rollback migration (see migration safety below)
   - If feature flag was enabled: disable the flag
4. **Verify rollback** -- run `./tools/ops/status-check.sh` and `./tools/qa/smoke-test.sh`
5. **Communicate** -- notify stakeholders that a rollback occurred and why
6. **Investigate** -- determine root cause before re-attempting the deploy

#### Database Migration Safety

These rules apply to every deployment that includes schema or data changes:

1. **Always backwards-compatible migrations** -- the old code must work with the new schema, and the new code must work with the old schema (during the transition window)
2. **Schema changes deployed before code changes** -- deploy the migration first, verify it succeeds, then deploy the code that depends on it
3. **Data migrations in a separate deploy from schema changes** -- never mix `ALTER TABLE` with bulk `UPDATE` in the same deployment
4. **Rollback migration for every forward migration** -- every `up` must have a corresponding `down`; verify the down migration works in staging
5. **Coordinate with `./tools/db/migration-check.sh`** -- run before every deploy to validate migration ordering, syntax, and rollback capability
6. **Large data migrations run as background jobs** -- do not block the deploy pipeline with long-running data transformations

#### Environment Variable Management

1. **Never hardcode secrets** -- no API keys, database URLs, or tokens in source code
2. **Use platform-native secret management** -- Vercel environment variables, AWS Secrets Manager, Railway variables, Fly.io secrets, or equivalent for the configured hosting provider
3. **Validate required env vars before deploy** -- `./tools/deploy/pre-deploy.sh` checks that all required variables are set
4. **Document all environment variables** -- maintain a `.env.example` file with variable names, descriptions, and example values (never real values)
5. **Separate secrets per environment** -- staging and production must use different credentials
6. **Rotate secrets on a schedule** -- document rotation procedure for each secret type

#### Smoke Test Integration

After every deployment to any environment:

1. Run `./tools/qa/smoke-test.sh` against the deployed environment URL
2. Smoke tests verify: health endpoint responds, authentication works, critical user flows complete, external integrations respond
3. If smoke tests fail on staging: block production deploy
4. If smoke tests fail on production: trigger rollback procedure

### Step 3: Per-Feature Deployment Plan

When designing deployment for a specific feature (added to the feature's RFC):

**Migration Order:**
- Does this feature require schema changes? If yes, deploy schema first.
- Are the migrations backwards-compatible? Document compatibility window.
- Is a data migration needed? Schedule it separately.

**Feature Flag Gating:**
- Should this feature be gated behind a flag? (Recommended for any user-facing change.)
- Progressive rollout plan: 0% -> 5% -> 25% -> 50% -> 100%
- Rollout timeline: how long at each percentage before expanding
- Flag cleanup: when to remove the flag after full rollout

**Rollback Trigger:**
- What metrics or errors trigger a rollback? (Error rate >1%, p99 latency >5s, etc.)
- Is automatic rollback configured, or is it manual?
- What is the maximum acceptable time in a degraded state before rollback?

**Canary Criteria** (if using canary deployment):
- What percentage of traffic goes to canary? (Start with 5%)
- How long does the canary run before expanding? (Minimum 15 minutes)
- What metrics are compared between canary and baseline?
- What is the automatic rollback threshold for the canary?

### Step 4: Pre-Deployment Validation

Before every deployment, reference `./tools/deploy/pre-deploy.sh` for automated checks:

1. No uncommitted changes in the working tree
2. On the expected branch (main/master per branching config)
3. All tests pass
4. Linting passes
5. No secrets detected in the codebase
6. Database migrations reviewed and validated
7. Required environment variables are set

If any check fails, the deploy is blocked until the issue is resolved.

### Step 5: Verify

- [ ] All three environments (local, staging, production) are defined with specific configuration differences
- [ ] Deployment pipeline matches the configured CI provider
- [ ] Rollout strategy matches the configured `deployment_model`
- [ ] Rollback procedure is step-by-step and specific to the tech stack
- [ ] Database migration safety rules are explicit and enforced
- [ ] Environment variable management does not permit hardcoded secrets
- [ ] Smoke tests are integrated after every deployment

## Quality Checklist

- [ ] All environments defined with specific config differences
- [ ] Pipeline matches configured CI provider
- [ ] Rollout strategy matches deployment_model
- [ ] Rollback is step-by-step and stack-specific
- [ ] Migration safety rules are explicit
- [ ] Env var management does not hardcode secrets
- [ ] Smoke tests are integrated post-deploy
