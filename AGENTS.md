# AGENTS.md

<!-- GENERATED FILE — do not edit by hand. Source: .claude/ + CLAUDE.md -->
<!-- Regenerate with: bash tools/build/build-agents-md.sh -->

This file is the runtime-neutral instruction layer for **Company OS** v1.11.0.
It is intended for AI coding agents that follow the [AGENTS.md](https://agents.md/)
convention — Codex CLI, Aider, and any agent without its own instruction file.

If you are running in:

- **Claude Code** → read `CLAUDE.md` (it has Claude-specific guidance)
- **Cursor**      → see `.cursor/rules/` (generated from this same source)
- **Gemini CLI**  → see `GEMINI.md` (generated from this same source)
- **Anything else** → read this file from top to bottom

---

## What Is Company OS?

An AI Agentic Company OS — a template project system for building SaaS products
with AI agents, skills, and tools. The system has three layers:

| Layer | Authoring source | Purpose |
|-------|------------------|---------|
| **Agents** (Authority) | `os/agents/` | Choose what happens next. Route, decide, delegate. |
| **Skills** (Procedural) | `os/skills/` | Advise + produce artifacts. Procedures, templates, checklists. |
| **Tools** (Execution) | `tools/` | Execute fixed, deterministic actions. Shell scripts. |

Per-runtime adapters (`.claude/`, `.cursor/`, `.codex/`) are **generated** from
`os/` by `tools/build/build.sh`.

**Dependency rules:**
- Agents depend on Skills for *how to think / what to produce*
- Agents depend on Tools for *how to act / what to run*
- Skills may *recommend* tools but never execute them
- Tools never contain reasoning
- **Artifacts are the handshake** between all components

## Working Conventions

**Before doing anything technical**, read `company.config.yaml` — it defines the
tech stack, conventions, and architecture for this specific project.

**Before recommending any library API**, fetch current docs (e.g., via Context7
in Claude Code, or web search in other runtimes). Training data is often stale.

**Artifact lineage is enforced.** Every artifact in `artifacts/` has YAML
frontmatter with `id`, `type`, `title`, `status`, `created`, `author`. Use:

- `./tools/artifact/validate.sh` — check frontmatter + link integrity
- `./tools/artifact/link.sh` — link parent ↔ child artifacts
- `./tools/artifact/promote.sh` — status transitions (draft → review → approved)
- `./tools/artifact/check-gate.sh` — stage gate checks (prd-to-rfc, rfc-to-impl, impl-to-qa, release)

**Commit discipline:** read `conventions.commit_style` from `company.config.yaml`.
One concern per commit. Commit at logical boundaries.

---

## Agent Catalog

The system ships with these agent personas. In runtimes without native sub-agent
dispatch (Codex, Aider), treat these as **role descriptions** — when a user
asks for product strategy, behave as the Product Agent would; for architecture,
behave as the Engineering Agent.

### `engineering`

Staff Engineer — owns architecture, decomposes work, delegates to Backend/Frontend/DevOps sub-agents, resolves conflicts, and reviews combined output. Use for any technical design, coding, or infrastructure task.

**Recommended model tier:** `opus`

**Skills:** 
- `architecture-draft`
- `implementation-decomposer`
- `code-review`
- `conflict-resolver`
- `ai-engineering`
- `excalidraw`

Full persona: [`os/agents/engineering.md`](os/agents/engineering.md)

### `engineering-backend`

Backend implementation specialist — API endpoints, data models, business logic, background jobs, and database operations. Use for server-side coding tasks delegated by the Engineering Agent.

**Recommended model tier:** `sonnet`

**Skills:** 
- `api-contract-designer`
- `background-jobs`
- `multi-tenancy`
- `seed-data`

Full persona: [`os/agents/engineering-backend.md`](os/agents/engineering-backend.md)

### `engineering-devops`

DevOps and infrastructure specialist — deployment pipelines, observability, feature flags, CI/CD, and environment configuration. Use for infrastructure tasks delegated by the Engineering Agent.

**Recommended model tier:** `sonnet`

**Skills:** 
- `deployment-strategy`
- `observability-baseline`
- `feature-flags`
- `dev-environment`
- `resilience-testing`

Full persona: [`os/agents/engineering-devops.md`](os/agents/engineering-devops.md)

### `engineering-frontend`

Frontend implementation specialist — UI components, responsive design, instrumentation, user docs, and guided tours. Use for client-side coding tasks delegated by the Engineering Agent.

**Recommended model tier:** `sonnet`

**Skills:** 
- `design-system`
- `mobile-readiness`
- `instrumentation`
- `user-docs`

Full persona: [`os/agents/engineering-frontend.md`](os/agents/engineering-frontend.md)

### `growth`

Handles launch strategy, acquisition loops, SEO/content, and activation experiments. Use for marketing, launch planning, or growth optimization tasks.

**Recommended model tier:** `sonnet`

**Skills:** 
- `positioning-messaging`
- `landing-page-copy`
- `seo-topic-map`
- `channel-playbook`
- `activation-onboarding`
- `email-lifecycle`
- `content-engine`
- `product-led-growth`
- `gtm-sprint`

Full persona: [`os/agents/growth.md`](os/agents/growth.md)

### `ops-risk`

Manages security baseline, privacy/compliance, finance sanity, and legal drafts. Use for security reviews, compliance checks, cost analysis, or legal document preparation.

**Recommended model tier:** `sonnet`

**Skills:** 
- `threat-modeling`
- `privacy-data-handling`
- `compliance-readiness`
- `pricing-unit-economics`
- `tos-privacy-drafting`
- `incident-response`
- `support-operations`
- `token-cost-ledger`
- `security-posture`

Full persona: [`os/agents/ops-risk.md`](os/agents/ops-risk.md)

### `orchestrator`

Routes tasks, enforces stage gates, arbitrates conflicts, approves releases. Use proactively for any multi-step objective or when coordinating work across multiple agents.

**Recommended model tier:** `opus`

**Skills:** 
- `workflow-router`
- `ship`
- `status`
- `decision-memo-writer`
- `release-readiness-gate`
- `ingest`
- `system-maintenance`
- `artifact-import`
- `setup`
- `upgrade-company-os`
- `rapid-prototype`
- `token-cost-ledger`
- `conflict-resolver`
- `weekly-review`
- `retrospective`

Full persona: [`os/agents/orchestrator.md`](os/agents/orchestrator.md)

### `product`

Handles discovery, PRD creation, prioritization, and scope control. Use when defining what to build, analyzing user feedback, or prioritizing features.

**Recommended model tier:** `sonnet`

**Skills:** 
- `icp-positioning`
- `prd-writer`
- `sprint-prioritizer`
- `feedback-synthesizer`
- `discovery-validation`
- `ux-research`
- `market-intelligence`
- `customer-conversations`

Full persona: [`os/agents/product.md`](os/agents/product.md)

### `qa-release`

Manages quality gates, test planning, regression confidence, and release readiness. Use when testing, creating test plans, or evaluating release readiness.

**Recommended model tier:** `sonnet`

**Skills:** 
- `test-plan-generator`
- `api-tester-playbook`
- `release-readiness-gate`
- `perf-benchmark-checklist`
- `code-review`
- `seed-data`
- `dogfood`
- `experiment-framework`
- `test-intelligence`

Full persona: [`os/agents/qa-release.md`](os/agents/qa-release.md)

---

## Skill Catalog

Skills are procedural playbooks. In Claude Code they are loaded just-in-time via
the `Skill` tool; in other runtimes, **read the skill file directly when its
description matches the task**. Each skill ends with a procedure section — follow
the steps in order.

- **`activation-onboarding`** — Designs "aha moment" flows and activation experiments to improve new user onboarding. Use when optimizing the path from sign-up to first value realization. 
  → [`os/skills/activation-onboarding/SKILL.md`](os/skills/activation-onboarding/SKILL.md)
- **`ai-engineering`** — Designs AI/ML feature architectures including LLM integration, RAG pipelines, prompt engineering, and AI cost optimization. Use when building features that involve AI/ML components. 
  → [`os/skills/ai-engineering/SKILL.md`](os/skills/ai-engineering/SKILL.md)
- **`api-contract-designer`** — Designs REST/GraphQL API contracts with consistent error handling, pagination, auth, and i18n. Use when designing new API endpoints, modifying existing APIs, or creating service interfaces. 
  → [`os/skills/api-contract-designer/SKILL.md`](os/skills/api-contract-designer/SKILL.md)
- **`api-tester-playbook`** — Generates API testing playbooks covering contract tests, authentication testing, pagination validation, and error handling. Use when building or reviewing API test suites. 
  → [`os/skills/api-tester-playbook/SKILL.md`](os/skills/api-tester-playbook/SKILL.md)
- **`architecture-draft`** — Produces RFC/ADR defining system boundaries, modules, data model, and integration points. Use when translating a PRD into technical design, making architectural decisions, or designing new system components. 
  → [`os/skills/architecture-draft/SKILL.md`](os/skills/architecture-draft/SKILL.md)
- **`artifact-import`** — Imports existing documents (PRDs, RFCs, API specs, test plans) into Company OS with proper frontmatter, type classification, and artifact linking. Use when bringing external documents into the artifact system. 
  → [`os/skills/artifact-import/SKILL.md`](os/skills/artifact-import/SKILL.md)
- **`background-jobs`** — Design patterns for background job processing including retries, idempotency, and queue management. Use when designing or reviewing async task infrastructure. 
  → [`os/skills/background-jobs/SKILL.md`](os/skills/background-jobs/SKILL.md)
- **`channel-playbook`** — Creates platform-specific marketing playbooks for acquisition channels. Use when launching or optimizing a specific growth channel (e.g., LinkedIn, Twitter, email, Product Hunt). 
  → [`os/skills/channel-playbook/SKILL.md`](os/skills/channel-playbook/SKILL.md)
- **`code-review`** — Structured multi-section code review with interactive feedback — architecture, quality, tests, performance. Use for PR reviews, pre-merge quality checks, or self-review before handoff. 
  → [`os/skills/code-review/SKILL.md`](os/skills/code-review/SKILL.md)
- **`compliance-readiness`** — Performs SOC2-lite checklist assessment and compliance gap analysis. Use when preparing for audits, assessing compliance posture, or building toward SOC2 certification. 
  → [`os/skills/compliance-readiness/SKILL.md`](os/skills/compliance-readiness/SKILL.md)
- **`conflict-resolver`** — Resolves disagreements between agents using structured tradeoff analysis. Use when two or more agents propose conflicting approaches and a principled resolution is needed. 
  → [`os/skills/conflict-resolver/SKILL.md`](os/skills/conflict-resolver/SKILL.md)
- **`content-engine`** — Produces multi-format content strategies with editorial calendars, content briefs, and multiplication workflows. Use when building a content marketing engine, planning blog/newsletter cadence, or creating content briefs. 
  → [`os/skills/content-engine/SKILL.md`](os/skills/content-engine/SKILL.md)
- **`customer-conversations`** — Prepares pre-call briefings, captures post-call debriefs, and routes insights to ICP refinement and PRD evidence. Stores conversation logs as CONV- artifacts in artifacts/decision-memos/. 
  → [`os/skills/customer-conversations/SKILL.md`](os/skills/customer-conversations/SKILL.md)
- **`decision-memo-writer`** — Produces structured decision records with rationale, alternatives considered, and consequences. Use when recording non-trivial decisions that future team members need to understand. 
  → [`os/skills/decision-memo-writer/SKILL.md`](os/skills/decision-memo-writer/SKILL.md)
- **`deployment-strategy`** — Designs deployment pipelines, rollout strategies, and environment configurations. Use when establishing deployment procedures, planning a feature rollout, or setting up CI/CD pipelines. 
  → [`os/skills/deployment-strategy/SKILL.md`](os/skills/deployment-strategy/SKILL.md)
- **`design-system`** — Reads configured design archetype and UX baseline to produce project-specific design tokens, component guidance, and UX patterns. Use when building UI components, reviewing design consistency, or configuring design preferences for the first time. 
  → [`os/skills/design-system/SKILL.md`](os/skills/design-system/SKILL.md)
- **`dev-environment`** — Generates Docker Compose files and dev scripts from tech stack config. Creates environment-specific infrastructure for local development, QA, and production. 
  → [`os/skills/dev-environment/SKILL.md`](os/skills/dev-environment/SKILL.md)
- **`discovery-validation`** — Smart pre-build discovery that validates novel feature ideas before committing to a full PRD. Classifies objectives as common patterns (skip) or novel concepts (full validation with lean canvas, competitive scan, and risk assessment). 
  → [`os/skills/discovery-validation/SKILL.md`](os/skills/discovery-validation/SKILL.md)
- **`dogfood`** — Autonomous dogfooding — tests the product by using it as real users would, capturing issues with severity ratings. Supports web apps (via agent-browser) and API-only products. 
  → [`os/skills/dogfood/SKILL.md`](os/skills/dogfood/SKILL.md)
- **`email-lifecycle`** — Designs email sequences, templates, and send triggers for SaaS lifecycle marketing and transactional emails. Use when planning onboarding drips, transactional notifications, activation campaigns, or retention email flows. 
  → [`os/skills/email-lifecycle/SKILL.md`](os/skills/email-lifecycle/SKILL.md)
- **`excalidraw`** — Produces architecture diagrams, data flow diagrams, ERDs, and system overviews in Mermaid (inline) and Excalidraw JSON (standalone). Use when an RFC, threat model, or documentation needs visual diagrams. 
  → [`os/skills/excalidraw/SKILL.md`](os/skills/excalidraw/SKILL.md)
- **`experiment-framework`** — Designs statistically rigorous A/B experiments with sample size calculation, guardrail metrics, and results analysis. Use when planning experiments, validating feature impact, or analyzing test results. 
  → [`os/skills/experiment-framework/SKILL.md`](os/skills/experiment-framework/SKILL.md)
- **`feature-flags`** — Designs feature flag strategy, progressive discovery patterns, and per-feature flag specifications for safe rollouts and organic product learning. 
  → [`os/skills/feature-flags/SKILL.md`](os/skills/feature-flags/SKILL.md)
- **`feedback-synthesizer`** — Turns messy, unstructured customer and user feedback into actionable themes with supporting evidence. Use when consolidating feedback from multiple sources into product insights. 
  → [`os/skills/feedback-synthesizer/SKILL.md`](os/skills/feedback-synthesizer/SKILL.md)
- **`gtm-sprint`** — Time-boxed go-to-market sprint that sequences customer validation, positioning, launch, and distribution over 7-21 days. Use when validating market demand, launching an MVP, or running a structured GTM push. 
  → [`os/skills/gtm-sprint/SKILL.md`](os/skills/gtm-sprint/SKILL.md)
- **`icp-positioning`** — Defines ideal customer profile and product positioning. Use when establishing or refining who the product serves and how it is differentiated in the market. 
  → [`os/skills/icp-positioning/SKILL.md`](os/skills/icp-positioning/SKILL.md)
- **`implementation-decomposer`** — Breaks a PRD or RFC into small, well-scoped implementation tasks suitable for individual pull requests. Use when translating product requirements into engineering work items. 
  → [`os/skills/implementation-decomposer/SKILL.md`](os/skills/implementation-decomposer/SKILL.md)
- **`incident-response`** — Generates incident runbooks, post-mortem templates, and incident response records. Use when establishing incident response procedures, handling a live incident, or conducting post-incident reviews. 
  → [`os/skills/incident-response/SKILL.md`](os/skills/incident-response/SKILL.md)
- **`ingest`** — Scans standards/ and artifacts/ for new or changed content and suggests updates to skills, agents, and configuration. Use after adding new standards documents, API specs, or artifacts to synchronize the system. 
  → [`os/skills/ingest/SKILL.md`](os/skills/ingest/SKILL.md)
- **`instrumentation`** — Defines analytics instrumentation standards including event taxonomy, tracker ID conventions, and per-feature instrumentation plans for measurable product development. 
  → [`os/skills/instrumentation/SKILL.md`](os/skills/instrumentation/SKILL.md)
- **`landing-page-copy`** — Generates conversion-focused landing page copy organized by sections. Use when creating or optimizing landing pages for product launches, features, or campaigns. 
  → [`os/skills/landing-page-copy/SKILL.md`](os/skills/landing-page-copy/SKILL.md)
- **`market-intelligence`** — Produces competitive landscape scans, technology radar assessments, and trend timing analysis. Use when monitoring competitors, evaluating new technologies, or identifying market opportunities. 
  → [`os/skills/market-intelligence/SKILL.md`](os/skills/market-intelligence/SKILL.md)
- **`mobile-readiness`** — Defines responsive web design patterns and React Native/Expo mobile architecture ensuring all products work on every screen size. Use when building mobile-first web UIs, planning native mobile apps, or adding PWA support. 
  → [`os/skills/mobile-readiness/SKILL.md`](os/skills/mobile-readiness/SKILL.md)
- **`multi-tenancy`** — Design patterns for multi-tenant architecture including org scoping, row-level security, and tenant data isolation. Use when designing or auditing tenant isolation boundaries. 
  → [`os/skills/multi-tenancy/SKILL.md`](os/skills/multi-tenancy/SKILL.md)
- **`observability-baseline`** — Establishes logging, metrics, and tracing conventions for the codebase. Use when setting up or auditing the observability stack and standards. 
  → [`os/skills/observability-baseline/SKILL.md`](os/skills/observability-baseline/SKILL.md)
- **`perf-benchmark-checklist`** — Establishes baseline performance metrics and regression detection criteria. Use when setting up performance benchmarks or investigating performance regressions. 
  → [`os/skills/perf-benchmark-checklist/SKILL.md`](os/skills/perf-benchmark-checklist/SKILL.md)
- **`positioning-messaging`** — Crafts a crisp product narrative and competitive differentiators for go-to-market materials. Use when defining or refreshing the product story for marketing and sales. 
  → [`os/skills/positioning-messaging/SKILL.md`](os/skills/positioning-messaging/SKILL.md)
- **`prd-writer`** — Generates consistent PRDs with problem statements, acceptance criteria, success metrics, and scope boundaries. Use when creating or updating product requirements for any feature. 
  → [`os/skills/prd-writer/SKILL.md`](os/skills/prd-writer/SKILL.md)
- **`pricing-unit-economics`** — Performs CAC/LTV analysis and pricing model validation. Use when setting initial pricing, evaluating pricing changes, or assessing unit economics health. 
  → [`os/skills/pricing-unit-economics/SKILL.md`](os/skills/pricing-unit-economics/SKILL.md)
- **`privacy-data-handling`** — Defines data retention policies, access controls, and deletion procedures. Use when establishing or auditing how personal and sensitive data is stored, accessed, and removed. 
  → [`os/skills/privacy-data-handling/SKILL.md`](os/skills/privacy-data-handling/SKILL.md)
- **`product-led-growth`** — Designs product-led growth mechanics — free tier structure, viral loops, referral programs, and in-product growth moments. Use when building self-serve acquisition and expansion. 
  → [`os/skills/product-led-growth/SKILL.md`](os/skills/product-led-growth/SKILL.md)
- **`rapid-prototype`** — Time-boxed MVP prototyping methodology for proof-of-concept and investor demos. Skips RFC, security review, and full QA for speed. Use when validating ideas quickly or preparing demos. 
  → [`os/skills/rapid-prototype/SKILL.md`](os/skills/rapid-prototype/SKILL.md)
- **`release-readiness-gate`** — Final quality gate checklist with pass/fail evaluation and release verdict. Run this before approving any release. 
  → [`os/skills/release-readiness-gate/SKILL.md`](os/skills/release-readiness-gate/SKILL.md)
- **`resilience-testing`** — Designs failure mode catalogs, circuit breaker tests, latency injection plans, and blast radius analysis for system resilience verification. Use when validating system behavior under failure conditions. 
  → [`os/skills/resilience-testing/SKILL.md`](os/skills/resilience-testing/SKILL.md)
- **`retrospective`** — Post-ship retrospective — traces artifact lineage from PRD to launch, evaluates success metrics, captures lessons learned, and produces a structured retro document. 
  → [`os/skills/retrospective/SKILL.md`](os/skills/retrospective/SKILL.md)
- **`security-posture`** — Aggregates open threats, scan status, compliance gaps, and human checkpoint audit into a unified security posture snapshot. Use when reviewing overall security health or before major releases. 
  → [`os/skills/security-posture/SKILL.md`](os/skills/security-posture/SKILL.md)
- **`seed-data`** — Generates test seed data, fixtures, and factory definitions for all data scenarios. Produces tech-stack-appropriate seed files and a seed-data catalog artifact. 
  → [`os/skills/seed-data/SKILL.md`](os/skills/seed-data/SKILL.md)
- **`seo-topic-map`** — Builds keyword clusters and internal linking strategy for content-led SEO growth. Use when planning content strategy or optimizing site architecture for organic search. 
  → [`os/skills/seo-topic-map/SKILL.md`](os/skills/seo-topic-map/SKILL.md)
- **`setup`** — Interactive setup wizard for Company OS. Configures company.config.yaml, generates .claude/settings.json with tech-stack-specific permissions, and scaffolds directories. Supports three modes — interactive wizard, express config block, or auto-extract from a URL/unstructured text. 
  → [`os/skills/setup/SKILL.md`](os/skills/setup/SKILL.md)
- **`ship`** — Kick off the full ship flow for a feature or objective. Routes through the Orchestrator to produce PRD, RFC, implementation, QA, and launch artifacts with gate checks at every stage. 
  → [`os/skills/ship/SKILL.md`](os/skills/ship/SKILL.md)
- **`sprint-prioritizer`** — Prioritizes features and work items using impact, effort, and risk scoring. Use when planning sprints or deciding what to build next. 
  → [`os/skills/sprint-prioritizer/SKILL.md`](os/skills/sprint-prioritizer/SKILL.md)
- **`status`** — Shows project artifact status summary — counts, statuses, broken links, and gate readiness across all artifact types. 
  → [`os/skills/status/SKILL.md`](os/skills/status/SKILL.md)
- **`support-operations`** — Designs customer support infrastructure including FAQ generation, SLA tiers, escalation paths, and support-to-product feedback pipelines. Use when establishing support operations or improving customer service. 
  → [`os/skills/support-operations/SKILL.md`](os/skills/support-operations/SKILL.md)
- **`system-maintenance`** — Audits and syncs all Company OS documentation after structural changes. Use when skills, agents, tools, artifact types, or stage gates are added, removed, or modified. 
  → [`os/skills/system-maintenance/SKILL.md`](os/skills/system-maintenance/SKILL.md)
- **`test-intelligence`** — Analyzes test suite health including flaky test detection, coverage scoring, test pyramid balance, and mutation testing guidance. Use when assessing test quality or diagnosing test reliability issues. 
  → [`os/skills/test-intelligence/SKILL.md`](os/skills/test-intelligence/SKILL.md)
- **`test-plan-generator`** — Generates comprehensive test plans from PRD acceptance criteria. Use when a new feature needs a structured testing strategy before implementation begins. 
  → [`os/skills/test-plan-generator/SKILL.md`](os/skills/test-plan-generator/SKILL.md)
- **`threat-modeling`** — Performs data flow threat analysis with structured mitigations. Use when assessing security threats for new features, architecture changes, or compliance reviews. 
  → [`os/skills/threat-modeling/SKILL.md`](os/skills/threat-modeling/SKILL.md)
- **`token-cost-ledger`** — Tracks AI token usage and costs as COGS. Logs entries, generates reports, monitors budget, shows per-feature cost. Use when reviewing AI spend, logging session costs, or checking budget status. 
  → [`os/skills/token-cost-ledger/SKILL.md`](os/skills/token-cost-ledger/SKILL.md)
- **`tos-privacy-drafting`** — Drafts Terms of Service and Privacy Policy outlines tailored to the product. Use when creating initial legal documents or reviewing existing TOS/Privacy Policy for completeness. 
  → [`os/skills/tos-privacy-drafting/SKILL.md`](os/skills/tos-privacy-drafting/SKILL.md)
- **`upgrade-company-os`** — Check for Company OS updates, preview changes, and upgrade to the latest version. Shows changelog, migration notes, and handles breaking changes safely. 
  → [`os/skills/upgrade-company-os/SKILL.md`](os/skills/upgrade-company-os/SKILL.md)
- **`user-docs`** — Produces user-facing documentation, guided tour specifications, and changelog entries for every shipped feature. Ensures users can discover, learn, and adopt new functionality. 
  → [`os/skills/user-docs/SKILL.md`](os/skills/user-docs/SKILL.md)
- **`ux-research`** — Designs lean user research plans with method selection, interview scripts, usability testing protocols, and journey mapping. Use when validating user needs, testing usability, or building personas before PRD creation. 
  → [`os/skills/ux-research/SKILL.md`](os/skills/ux-research/SKILL.md)
- **`weekly-review`** — Weekly operating rhythm — summarizes what shipped, AI spend, support themes, security health, and surfaces next priorities. Use at the end of each week to maintain operating cadence. 
  → [`os/skills/weekly-review/SKILL.md`](os/skills/weekly-review/SKILL.md)
- **`workflow-router`** — Maps objectives to required artifacts, stages, and responsible agents. Use when routing any objective, deciding what happens next, or determining which agents need to be involved in a task. 
  → [`os/skills/workflow-router/SKILL.md`](os/skills/workflow-router/SKILL.md)

---

## Tool Catalog

Deterministic shell scripts. Safe to invoke directly. All live under `tools/`.

- `tools/analytics/publish-content.sh` — Tool: T-MKT-01 Publish Draft Content
- `tools/analytics/query-metrics.sh` — Tool: T-ANA-01 Query Metrics
- `tools/artifact/check-gate.sh` — Tool: Stage Gate Checker
- `tools/artifact/link.sh` — Tool: Artifact Linker
- `tools/artifact/promote.sh` — Tool: Artifact Promote
- `tools/artifact/validate.sh` — Tool: Artifact Validate
- `tools/build/build-agents-md.sh` — Reads CLAUDE.md, skills, agents, and config and emits AGENTS.md at the
- `tools/build/build-claude.sh` — Claude Code is now treated as one runtime adapter among several. This script
- `tools/build/build-codex.sh` — Codex CLI reads AGENTS.md natively. This script ensures AGENTS.md is fresh
- `tools/build/build-cursor.sh` — Emits:
- `tools/build/build-gemini.sh` — Gemini CLI reads GEMINI.md (its own convention) — same payload as AGENTS.md
- `tools/build/build.sh` — Regenerates every runtime adapter (Claude Code, Cursor, Codex, Gemini,
- `tools/build/lib-agent-index.sh` — Source this file. Provides:
- `tools/build/lib-frontmatter.sh` — Source this file; do not execute directly.
- `tools/build/lib-skill-index.sh` — Source this file. Provides:
- `tools/build/validate-agent.sh` — Usage:
- `tools/build/validate-skill.sh` — Usage:
- `tools/ci/lint-format.sh` — Tool: T-CI-02 Lint/Format
- `tools/ci/openapi-lint.sh` — Tool: T-API-01 OpenAPI Lint/Validate
- `tools/ci/run-tests.sh` — Tool: T-CI-01 Run Tests
- `tools/db/migration-check.sh` — Tool: T-DB-01 Migration Check
- `tools/db/seed.sh` — Tool: Seed Data Runner
- `tools/deploy/pre-deploy.sh` — Tool: T-DEPLOY-01 Pre-Deploy Validation
- `tools/lib/config.sh` — Shared helper (sourced, not run): read values from company.config.yaml.
- `tools/lib/usage.sh` — Shared helper (sourced, not run): print a script's header comment as --help text.
- `tools/ops/dashboard.sh` — Tool: T-OPS-04 Static Dashboard Generator
- `tools/ops/status-check.sh` — Tool: T-OPS-01 Status Check
- `tools/ops/support-faq-check.sh` — Tool: T-OPS-02 Support FAQ Coverage Check
- `tools/ops/token-ledger.sh` — Tool: T-OPS-03 Token Cost Ledger
- `tools/qa/contract-test.sh` — Tool: T-QA-01 Contract Test Runner
- `tools/qa/dogfood.sh` — Tool: Dogfood Pre-flight
- `tools/qa/experiment-report.sh` — Tool: T-QA-08 Experiment Report Generator
- `tools/qa/perf-benchmark.sh` — Tool: T-QA-02 Perf Benchmark Runner
- `tools/qa/resilience-test.sh` — Tool: T-QA-07 Resilience Test Runner
- `tools/qa/smoke-test.sh` — Tool: T-QA-03 Smoke Test Runner
- `tools/qa/test-health.sh` — Tool: T-QA-06 Test Health Analyzer
- `tools/registry/detect-changes.sh` — Tool: Detect Changes
- `tools/registry/health-check.sh` — Tool: Skill Health Check
- `tools/registry/install-runtime.sh` — When you set up the project with --runtime=claude and later want to also
- `tools/registry/list-runtimes.sh` — OS adapters are installed for them.
- `tools/registry/search-skill.sh` — Tool: Skill Search
- `tools/security/dependency-scan.sh` — Tool: T-SEC-01 Dependency Scan
- `tools/security/posture-check.sh` — Tool: T-SEC-04 Security Posture Check
- `tools/security/sast.sh` — Tool: T-SEC-03 Basic SAST (Static Application Security Testing)
- `tools/security/secrets-scan.sh` — Tool: T-SEC-02 Secrets Scan
- `tools/versioning/version-bump.sh` — Detects the app version file, bumps it by the specified type, updates CHANGELOG.md,

---

## Common Workflows

Claude Code exposes these as slash commands. In other runtimes, ask the agent to
"run the ship skill" / "run the setup skill" — it will read the corresponding
skill file and follow the procedure.

| Intent | Skill | What it does |
|--------|-------|--------------|
| Build a feature end-to-end | `ship` | PRD → RFC → impl → QA → launch with gates |
| First-time project setup | `setup` | Interactive config wizard + scaffolding |
| Import an existing doc | `artifact-import` | Classify + add frontmatter + link |
| Quick prototype (skip gates) | `rapid-prototype` | Time-boxed MVP for PoC/demos |
| GTM validation sprint | `gtm-sprint` | 7/14/21-day market validation |
| Status snapshot | `status` | Counts, broken links, gate readiness |
| Upgrade Company OS | `upgrade-company-os` | Pull latest template safely |

---

## Re-generating This File

This file is generated from `.claude/skills/`, `.claude/agents/`, and
`CLAUDE.md`. To regenerate after changes:

```bash
bash tools/build/build.sh
```

Or just the AGENTS.md file:

```bash
bash tools/build/build-agents-md.sh
```
