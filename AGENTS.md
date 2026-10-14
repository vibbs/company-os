# AGENTS.md

<!-- GENERATED FILE — do not edit by hand. Source: .claude/ + CLAUDE.md -->
<!-- Regenerate with: bash tools/build/build-agents-md.sh -->

This file is the runtime-neutral instruction layer for **Company OS** v1.12.0.
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

Staff Engineer. Designs the architecture, splits work, delegates to the Backend, Frontend and DevOps agents, and reviews the result. Use for any technical design, coding or infrastructure task.

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

Writes server-side code: API endpoints, data models, business logic, background jobs and database work. Usually invoked by the Engineering Agent or /ship, so you rarely call it directly.

**Recommended model tier:** `sonnet`

**Skills:** 
- `api-contract-designer`
- `background-jobs`
- `multi-tenancy`
- `seed-data`

Full persona: [`os/agents/engineering-backend.md`](os/agents/engineering-backend.md)

### `engineering-devops`

Sets up deployment pipelines, monitoring, feature flags, CI/CD and environments. Usually invoked by the Engineering Agent or /ship, so you rarely call it directly.

**Recommended model tier:** `sonnet`

**Skills:** 
- `deployment-strategy`
- `observability-baseline`
- `feature-flags`
- `dev-environment`
- `resilience-testing`

Full persona: [`os/agents/engineering-devops.md`](os/agents/engineering-devops.md)

### `engineering-frontend`

Builds user interface code: components, responsive layouts, analytics events, user docs and guided tours. Usually invoked by the Engineering Agent or /ship, so you rarely call it directly.

**Recommended model tier:** `sonnet`

**Skills:** 
- `design-system`
- `mobile-readiness`
- `instrumentation`
- `user-docs`

Full persona: [`os/agents/engineering-frontend.md`](os/agents/engineering-frontend.md)

### `growth`

Plans launches and growth: positioning, landing pages, channels, SEO and content, and onboarding experiments. Use for marketing, launch planning or improving user acquisition.

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

Covers security, privacy, compliance, pricing and cost checks, and legal document drafts. Use for security reviews, compliance checks, cost analysis or Terms of Service and Privacy Policy drafts.

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

Routes an objective to the right agents, enforces stage gates (checks before the next stage) and approves releases. Usually invoked by /ship; use directly for multi-step work across several agents.

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

Turns ideas and feedback into product requirements: discovery, PRDs, prioritization and scope control. Use when defining what to build, analyzing user feedback or ranking features.

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

Plans and runs quality checks: test plans, QA reports and the final release readiness verdict. Use when testing a feature, writing a test plan or deciding whether it is ready to release.

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

- **`activation-onboarding`** — Designs the first-run flow and experiments that get new users to their first moment of value. Use when sign-ups are not turning into active users. 
  → [`os/skills/activation-onboarding/SKILL.md`](os/skills/activation-onboarding/SKILL.md)
- **`ai-engineering`** — Designs AI features: LLM integration, retrieval-augmented generation (RAG) over your own data, prompts, and AI cost control. Use when building a feature that calls an AI model. 
  → [`os/skills/ai-engineering/SKILL.md`](os/skills/ai-engineering/SKILL.md)
- **`api-contract-designer`** — Designs REST or GraphQL API contracts with consistent errors, pagination, auth and translations. Use when adding or changing API endpoints. 
  → [`os/skills/api-contract-designer/SKILL.md`](os/skills/api-contract-designer/SKILL.md)
- **`api-tester-playbook`** — Writes an API test playbook covering contracts, authentication, pagination and error handling. Use when building or reviewing API tests. 
  → [`os/skills/api-tester-playbook/SKILL.md`](os/skills/api-tester-playbook/SKILL.md)
- **`architecture-draft`** — Writes a technical design doc (RFC) covering system boundaries, modules, data model and integrations. Use when turning a PRD into a design or making an architecture decision. 
  → [`os/skills/architecture-draft/SKILL.md`](os/skills/architecture-draft/SKILL.md)
- **`artifact-import`** — Brings existing documents (PRDs, RFCs, API specs, test plans) into Company OS with frontmatter, a type and links. Use when you already have docs outside this repo. 
  → [`os/skills/artifact-import/SKILL.md`](os/skills/artifact-import/SKILL.md)
- **`background-jobs`** — Designs background job processing: retries, idempotency (safe repeats) and queue management. Use when designing or reviewing async task infrastructure. 
  → [`os/skills/background-jobs/SKILL.md`](os/skills/background-jobs/SKILL.md)
- **`channel-playbook`** — Creates a step-by-step marketing playbook for one acquisition channel such as LinkedIn, Twitter, email or Product Hunt. Use when launching or improving a growth channel. 
  → [`os/skills/channel-playbook/SKILL.md`](os/skills/channel-playbook/SKILL.md)
- **`code-review`** — Reviews code in sections (architecture, quality, tests, performance) with interactive feedback. Use for pull request reviews, pre-merge checks or self-review before handoff. 
  → [`os/skills/code-review/SKILL.md`](os/skills/code-review/SKILL.md)
- **`compliance-readiness`** — Checks your readiness for a lightweight SOC 2 security audit and lists the gaps. Use when preparing for an audit or customer security questionnaires. 
  → [`os/skills/compliance-readiness/SKILL.md`](os/skills/compliance-readiness/SKILL.md)
- **`conflict-resolver`** — Resolves disagreements between agents by comparing tradeoffs and recommending one path. Use when two agents propose conflicting approaches. 
  → [`os/skills/conflict-resolver/SKILL.md`](os/skills/conflict-resolver/SKILL.md)
- **`content-engine`** — Plans a content program: editorial calendar, content briefs and ways to reuse one piece across formats. Use when starting or scaling blog, newsletter or social content. 
  → [`os/skills/content-engine/SKILL.md`](os/skills/content-engine/SKILL.md)
- **`customer-conversations`** — Prepares briefings before customer calls and records what you learned afterward. Use before and after customer interviews or sales calls. 
  → [`os/skills/customer-conversations/SKILL.md`](os/skills/customer-conversations/SKILL.md)
- **`decision-memo-writer`** — Writes a decision record with rationale, alternatives considered and consequences. Use when a non-trivial decision needs to be understood later. 
  → [`os/skills/decision-memo-writer/SKILL.md`](os/skills/decision-memo-writer/SKILL.md)
- **`deployment-strategy`** — Designs deployment pipelines, rollout strategies and environment setups. Use when setting up CI/CD (automated build and deploy) or planning a gradual rollout. 
  → [`os/skills/deployment-strategy/SKILL.md`](os/skills/deployment-strategy/SKILL.md)
- **`design-system`** — Sets up and applies your visual design: tokens (colors, type, spacing), component guidance and UX patterns. Use when building UI or choosing a design style for the first time. 
  → [`os/skills/design-system/SKILL.md`](os/skills/design-system/SKILL.md)
- **`dev-environment`** — Generates Docker Compose files, .env.example and dev scripts from your tech stack. Use when setting up local, QA or production environments. 
  → [`os/skills/dev-environment/SKILL.md`](os/skills/dev-environment/SKILL.md)
- **`discovery-validation`** — Checks whether a new feature idea is worth building before you write a PRD. Use for novel features; common patterns are skipped. 
  → [`os/skills/discovery-validation/SKILL.md`](os/skills/discovery-validation/SKILL.md)
- **`dogfood`** — Tests your product the way a real user would and logs issues with severity ratings. Use before launch or after a big change; works for web apps and APIs. 
  → [`os/skills/dogfood/SKILL.md`](os/skills/dogfood/SKILL.md)
- **`email-lifecycle`** — Designs email sequences, templates and send triggers for onboarding, transactional and retention emails. Use when planning product emails. 
  → [`os/skills/email-lifecycle/SKILL.md`](os/skills/email-lifecycle/SKILL.md)
- **`excalidraw`** — Draws architecture, data flow, database (ERD) and system diagrams as Mermaid text and Excalidraw files. Use when a design doc or threat model needs a diagram. 
  → [`os/skills/excalidraw/SKILL.md`](os/skills/excalidraw/SKILL.md)
- **`experiment-framework`** — Designs A/B experiments with sample size, guardrail metrics and results analysis. Use when planning a test or judging whether a feature moved the numbers. 
  → [`os/skills/experiment-framework/SKILL.md`](os/skills/experiment-framework/SKILL.md)
- **`feature-flags`** — Designs a feature flag strategy and per-feature flag specs for safe rollouts. Use when releasing a feature gradually or planning flag cleanup. 
  → [`os/skills/feature-flags/SKILL.md`](os/skills/feature-flags/SKILL.md)
- **`feedback-synthesizer`** — Turns messy customer feedback into themes with supporting evidence and a ranked pain matrix. Use when consolidating feedback from several sources. 
  → [`os/skills/feedback-synthesizer/SKILL.md`](os/skills/feedback-synthesizer/SKILL.md)
- **`gtm-sprint`** — Runs a 7, 14 or 21 day go-to-market (GTM) sprint: customer interviews, positioning, landing page and distribution, with go/no-go checkpoints. Use to test demand or launch an MVP. 
  → [`os/skills/gtm-sprint/SKILL.md`](os/skills/gtm-sprint/SKILL.md)
- **`icp-positioning`** — Defines your ideal customer profile (ICP) and how your product is positioned against alternatives. Use when deciding who the product serves and how it differs. 
  → [`os/skills/icp-positioning/SKILL.md`](os/skills/icp-positioning/SKILL.md)
- **`implementation-decomposer`** — Breaks a PRD or RFC into small tasks that each fit one pull request. Use when turning requirements into engineering work items. 
  → [`os/skills/implementation-decomposer/SKILL.md`](os/skills/implementation-decomposer/SKILL.md)
- **`incident-response`** — Creates incident runbooks, post-mortem templates and incident records. Use when preparing for incidents, handling a live one or reviewing one afterward. 
  → [`os/skills/incident-response/SKILL.md`](os/skills/incident-response/SKILL.md)
- **`ingest`** — Scans standards/ and artifacts/ for new or changed files and suggests updates to skills and config. Use after adding standards docs, API specs or artifacts. 
  → [`os/skills/ingest/SKILL.md`](os/skills/ingest/SKILL.md)
- **`instrumentation`** — Defines analytics events and tracking plans for a feature. Use when adding product analytics or reviewing event naming. 
  → [`os/skills/instrumentation/SKILL.md`](os/skills/instrumentation/SKILL.md)
- **`landing-page-copy`** — Writes conversion-focused landing page copy, section by section. Use when creating or improving a landing page for a launch, feature or campaign. 
  → [`os/skills/landing-page-copy/SKILL.md`](os/skills/landing-page-copy/SKILL.md)
- **`market-intelligence`** — Scans competitors, emerging technologies and market timing. Use when tracking competitors, evaluating a new technology or looking for opportunities. 
  → [`os/skills/market-intelligence/SKILL.md`](os/skills/market-intelligence/SKILL.md)
- **`mobile-readiness`** — Defines responsive web patterns and a React Native/Expo plan so the product works on every screen. Use when building mobile-first UI or planning a native or PWA app. 
  → [`os/skills/mobile-readiness/SKILL.md`](os/skills/mobile-readiness/SKILL.md)
- **`multi-tenancy`** — Designs multi-tenant architecture: org scoping, row-level security and tenant data isolation. Use when designing or auditing how customers' data is kept separate. 
  → [`os/skills/multi-tenancy/SKILL.md`](os/skills/multi-tenancy/SKILL.md)
- **`observability-baseline`** — Sets logging, metrics and tracing conventions for the codebase. Use when setting up or auditing monitoring. 
  → [`os/skills/observability-baseline/SKILL.md`](os/skills/observability-baseline/SKILL.md)
- **`perf-benchmark-checklist`** — Sets baseline performance metrics and criteria for catching regressions. Use when setting up benchmarks or investigating a slowdown. 
  → [`os/skills/perf-benchmark-checklist/SKILL.md`](os/skills/perf-benchmark-checklist/SKILL.md)
- **`positioning-messaging`** — Writes the product narrative and competitive differentiators for marketing and sales. Use when defining or refreshing your product story. 
  → [`os/skills/positioning-messaging/SKILL.md`](os/skills/positioning-messaging/SKILL.md)
- **`prd-writer`** — Writes a product requirements document (PRD) with problem statement, acceptance criteria, success metrics and scope. Use when creating or updating requirements for a feature. 
  → [`os/skills/prd-writer/SKILL.md`](os/skills/prd-writer/SKILL.md)
- **`pricing-unit-economics`** — Analyzes pricing and unit economics: customer acquisition cost (CAC) versus lifetime value (LTV). Use when setting prices, changing them or checking financial health. 
  → [`os/skills/pricing-unit-economics/SKILL.md`](os/skills/pricing-unit-economics/SKILL.md)
- **`privacy-data-handling`** — Defines how personal data is retained, accessed and deleted. Use when setting up or auditing data handling. 
  → [`os/skills/privacy-data-handling/SKILL.md`](os/skills/privacy-data-handling/SKILL.md)
- **`product-led-growth`** — Designs self-serve growth: free tier, viral loops, referrals and in-product growth moments. Use when building acquisition and expansion into the product itself. 
  → [`os/skills/product-led-growth/SKILL.md`](os/skills/product-led-growth/SKILL.md)
- **`rapid-prototype`** — Builds a time-boxed MVP (4 hours, 1 day or 3 days) for a proof of concept or demo, skipping the RFC, security review and full QA. Use to validate an idea fast. 
  → [`os/skills/rapid-prototype/SKILL.md`](os/skills/rapid-prototype/SKILL.md)
- **`release-readiness-gate`** — Runs the final pass/fail checklist and gives a release verdict. Use before approving any release. 
  → [`os/skills/release-readiness-gate/SKILL.md`](os/skills/release-readiness-gate/SKILL.md)
- **`resilience-testing`** — Plans failure tests: failure mode lists, circuit breaker tests, latency injection and how far a failure spreads. Use when checking behavior under failure. 
  → [`os/skills/resilience-testing/SKILL.md`](os/skills/resilience-testing/SKILL.md)
- **`retrospective`** — Reviews a shipped feature: traces it from PRD to launch, compares results to goals and records lessons. Use after a release. 
  → [`os/skills/retrospective/SKILL.md`](os/skills/retrospective/SKILL.md)
- **`security-posture`** — Summarizes open threats, scan status, compliance gaps and manual checkpoints into one security snapshot. Use to review security health or before a major release. 
  → [`os/skills/security-posture/SKILL.md`](os/skills/security-posture/SKILL.md)
- **`seed-data`** — Generates test seed data, fixtures and factories for normal, edge and empty scenarios. Use when you need data to try out or test a feature. 
  → [`os/skills/seed-data/SKILL.md`](os/skills/seed-data/SKILL.md)
- **`seo-topic-map`** — Builds keyword clusters and an internal linking plan for search-driven content. Use when planning content or site structure for organic search. 
  → [`os/skills/seo-topic-map/SKILL.md`](os/skills/seo-topic-map/SKILL.md)
- **`setup`** — Configures Company OS for your project: company.config.yaml, permissions and folders. Use the first time you open a repo; accepts a preset, a pasted config block, or a URL to auto-fill. 
  → [`os/skills/setup/SKILL.md`](os/skills/setup/SKILL.md)
- **`ship`** — Takes a feature from idea to release (PRD, RFC, code, QA, launch assets), pausing at each quality gate for your review. Use to build and ship something end to end. 
  → [`os/skills/ship/SKILL.md`](os/skills/ship/SKILL.md)
- **`sprint-prioritizer`** — Ranks features and work items by impact, effort and risk. Use when planning a sprint or deciding what to build next. 
  → [`os/skills/sprint-prioritizer/SKILL.md`](os/skills/sprint-prioritizer/SKILL.md)
- **`status`** — Shows a summary of project artifacts: counts by status, broken links and stage gate readiness. Use to check project health; add --dashboard for an HTML report. 
  → [`os/skills/status/SKILL.md`](os/skills/status/SKILL.md)
- **`support-operations`** — Designs customer support: FAQs, response-time tiers (SLAs), escalation paths and a feedback loop to product. Use when setting up or improving support. 
  → [`os/skills/support-operations/SKILL.md`](os/skills/support-operations/SKILL.md)
- **`system-maintenance`** — Audits and syncs Company OS documentation after structural changes. Use after adding, removing or changing skills, agents, tools, artifact types or stage gates. 
  → [`os/skills/system-maintenance/SKILL.md`](os/skills/system-maintenance/SKILL.md)
- **`test-intelligence`** — Assesses test suite health: flaky tests, coverage, test balance and mutation testing (checking that tests catch real bugs). Use when judging test quality or reliability. 
  → [`os/skills/test-intelligence/SKILL.md`](os/skills/test-intelligence/SKILL.md)
- **`test-plan-generator`** — Generates a test plan from a PRD's acceptance criteria. Use when a feature needs a testing strategy before implementation. 
  → [`os/skills/test-plan-generator/SKILL.md`](os/skills/test-plan-generator/SKILL.md)
- **`threat-modeling`** — Analyzes data flows for security threats and proposes mitigations. Use when assessing a new feature, an architecture change or a compliance review. 
  → [`os/skills/threat-modeling/SKILL.md`](os/skills/threat-modeling/SKILL.md)
- **`token-cost-ledger`** — Tracks AI token usage and spend: logs entries, reports, checks budget and shows cost per feature. Use when reviewing AI spend or logging a session's cost. 
  → [`os/skills/token-cost-ledger/SKILL.md`](os/skills/token-cost-ledger/SKILL.md)
- **`tos-privacy-drafting`** — Drafts outlines of your Terms of Service and Privacy Policy. Use when creating first legal documents or checking existing ones for gaps. 
  → [`os/skills/tos-privacy-drafting/SKILL.md`](os/skills/tos-privacy-drafting/SKILL.md)
- **`upgrade-company-os`** — Checks for, previews, applies or rolls back Company OS updates. Use when you want the latest version or need to undo an upgrade. 
  → [`os/skills/upgrade-company-os/SKILL.md`](os/skills/upgrade-company-os/SKILL.md)
- **`user-docs`** — Writes user-facing docs, guided tours and changelog entries for a shipped feature. Use after a feature ships or before launch. 
  → [`os/skills/user-docs/SKILL.md`](os/skills/user-docs/SKILL.md)
- **`ux-research`** — Plans lean user research: method choice, interview scripts, usability tests and journey maps. Use when validating user needs or building personas before a PRD. 
  → [`os/skills/ux-research/SKILL.md`](os/skills/ux-research/SKILL.md)
- **`weekly-review`** — Summarizes your week: what shipped, AI spend, support themes, security health and next priorities. Use at the end of each week. 
  → [`os/skills/weekly-review/SKILL.md`](os/skills/weekly-review/SKILL.md)
- **`workflow-router`** — Maps an objective to the artifacts, stages and agents it needs. Use when deciding what happens next or which agents to involve. 
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
- `tools/build/lib-markers.sh` — Source this file; do not execute directly.
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
- `tools/versioning/version-bump.sh` — Tool: App Version Bump

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

This file is generated from `os/skills/`, `os/agents/`, and
`CLAUDE.md`. Edit those, not this file. To regenerate after changes:

```bash
bash tools/build/build.sh
```

Or just the AGENTS.md file:

```bash
bash tools/build/build-agents-md.sh
```
