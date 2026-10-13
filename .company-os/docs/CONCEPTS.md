# Concepts

How Company OS is organized and how work moves through it. Read this once after [SETUP.md](SETUP.md); the other docs link back here for definitions.

![System overview: you and company.config.yaml at the top; agents decide, skills advise, tools execute; every step writes artifacts; os/ is built into runtime adapters](diagrams/system-overview.svg)

---

## Glossary

| Term | Meaning |
|------|---------|
| **Agent** | An AI role with authority to decide what happens next, such as Product, Engineering, or QA & Release. Agents delegate work and run tools. |
| **Sub-agent** | An agent that another agent delegates to. Engineering has three: Backend, Frontend and DevOps. |
| **Skill** | A written procedure with templates and checklists, for example "write a PRD". In Claude Code you run a skill as `/name` (such as `/ship`); in other runtimes you ask the agent to "run the *name* skill". |
| **Tool** | A shell script in `tools/` that performs one fixed action, such as validating a file. Tools contain no AI reasoning. |
| **Artifact** | A document an agent produces, saved under `artifacts/` with a YAML header (frontmatter) that records its ID, type, status and links. |
| **Lineage** | The parent and child links between artifacts, for example PRD to RFC to QA report. |
| **Gate** | A scripted check that must pass before work moves to the next stage, for example "the PRD is approved before design starts". |
| **Stage** | Your company's maturity (`idea`, `mvp`, `growth`, `scale`), set in `company.config.yaml`. It decides which gates block and which only warn. |
| **Runtime** | The AI coding tool you work in: Claude Code, Cursor, Codex CLI, Gemini CLI or Aider. |
| **Adapter** | The runtime-specific files generated from `os/`: `.claude/`, `.cursor/`, `.codex/`, `AGENTS.md`, `GEMINI.md`. Never edit them by hand. |

Abbreviations: **PRD** is a product requirements document. **RFC** is a technical design doc ("request for comments"). **QA** is quality assurance. **COGS** is cost of goods sold; Company OS tracks AI token spend as COGS in `cogs/ai-ledger/`.

---

## The three layers

| Layer | Role | Where it is authored | Example |
|-------|------|----------------------|---------|
| **Agents** (authority) | Choose what happens next. Route, decide, delegate. | `os/agents/` | The Orchestrator sends a new feature to the Product agent |
| **Skills** (procedure) | Advise and produce artifacts using templates and checklists | `os/skills/` | `prd-writer` gives the PRD structure |
| **Tools** (execution) | Run fixed, deterministic actions | `tools/` | `validate.sh` checks an artifact's header |

Dependency rules:

- Agents use skills to know *what to produce* and run tools to *act*.
- Skills may recommend a tool, but never run one.
- Tools never contain reasoning.
- **Artifacts are the handshake.** Every hand-off between agents is a file in `artifacts/`, not a chat message.

---

## Agents and delegation

![Agent org chart: the Orchestrator routes to Product, Engineering, QA & Release, Growth and Ops & Risk; Engineering delegates to Backend, Frontend and DevOps sub-agents](diagrams/agent-org.svg)

| Agent | Responsibility |
|-------|----------------|
| **Orchestrator** | Routes objectives, enforces gates, approves releases |
| **Product** | Discovery, PRDs, prioritization, scope control |
| **Engineering** | Staff engineer: architecture, splitting work, delegation, code review |
| **Engineering: Backend** (sub-agent) | API endpoints, data models, business logic, background jobs |
| **Engineering: Frontend** (sub-agent) | UI components, responsive design, analytics events, user docs |
| **Engineering: DevOps** (sub-agent) | Deployment pipelines, monitoring, feature flags, CI/CD |
| **QA & Release** | Test plans, quality checks, release readiness |
| **Growth** | Launch strategy, positioning, SEO, activation, content |
| **Ops & Risk** | Security, privacy, compliance, pricing, legal drafts |

You do not have to name an agent. Describe your objective and the Orchestrator routes it. In Claude Code you can also call an agent by name. Engineering designs and reviews the work and delegates the build: Backend and DevOps start in parallel, and Frontend waits for the API contract.

In Claude Code, four agents (Engineering, QA & Release, Product, Growth) keep notes across sessions in `.claude/agent-memory/<agent>/MEMORY.md`. That memory is yours: upgrades never touch it.

### Skills by agent

Skill directory names, grouped by the agent that owns them. Run any user-facing skill as `/name`. `os/skills/` is the complete list.

| Owner | Skills |
|-------|--------|
| Orchestrator | `workflow-router`, `ship`, `status`, `decision-memo-writer`, `release-readiness-gate`, `ingest`, `system-maintenance`, `artifact-import`, `setup`, `upgrade-company-os`, `rapid-prototype`, `token-cost-ledger`, `conflict-resolver`, `weekly-review`, `retrospective` |
| Product | `icp-positioning`, `prd-writer`, `sprint-prioritizer`, `feedback-synthesizer`, `discovery-validation`, `ux-research`, `market-intelligence`, `customer-conversations` |
| Engineering (staff) | `architecture-draft`, `implementation-decomposer`, `code-review`, `conflict-resolver`, `ai-engineering`, `excalidraw` |
| Engineering: Backend | `api-contract-designer`, `background-jobs`, `multi-tenancy`, `seed-data` |
| Engineering: Frontend | `design-system`, `mobile-readiness`, `instrumentation`, `user-docs` |
| Engineering: DevOps | `deployment-strategy`, `observability-baseline`, `feature-flags`, `dev-environment`, `resilience-testing` |
| QA & Release | `test-plan-generator`, `api-tester-playbook`, `release-readiness-gate`, `perf-benchmark-checklist`, `code-review`, `seed-data`, `dogfood`, `experiment-framework`, `test-intelligence` |
| Growth | `positioning-messaging`, `landing-page-copy`, `seo-topic-map`, `channel-playbook`, `activation-onboarding`, `email-lifecycle`, `content-engine`, `product-led-growth`, `gtm-sprint` |
| Ops & Risk | `threat-modeling`, `privacy-data-handling`, `compliance-readiness`, `pricing-unit-economics`, `tos-privacy-drafting`, `incident-response`, `support-operations`, `token-cost-ledger`, `security-posture` |

A few skills are shared (for example `code-review` by Engineering and QA). To change what a skill does, see [CUSTOMIZING.md](CUSTOMIZING.md).

### Tools by category

| Category | Folder | Tools |
|----------|--------|-------|
| Artifacts | `tools/artifact/` | `validate`, `promote`, `link`, `check-gate` |
| Registry | `tools/registry/` | `search-skill`, `health-check`, `detect-changes`, `list-runtimes`, `install-runtime` |
| CI | `tools/ci/` | `run-tests`, `lint-format`, `openapi-lint` |
| Database | `tools/db/` | `migration-check`, `seed` |
| QA | `tools/qa/` | `contract-test`, `perf-benchmark`, `smoke-test`, `dogfood`, `experiment-report`, `resilience-test`, `test-health` |
| Security | `tools/security/` | `dependency-scan`, `secrets-scan`, `sast`, `posture-check` |
| Analytics | `tools/analytics/` | `query-metrics`, `publish-content` |
| Ops | `tools/ops/` | `status-check`, `dashboard`, `support-faq-check`, `token-ledger` |
| Deploy | `tools/deploy/` | `pre-deploy` |
| Versioning | `tools/versioning/` | `version-bump` |

Every tool prints usage with `-h` or `--help`. Tools read `company.config.yaml` to detect your stack. The analytics tools are stubs: replace them with calls to your real provider. Two more folders are not user tools: `tools/build/` regenerates the adapters, and `tools/lib/` holds helpers the tools load.

---

## Artifacts and lineage

![Artifact lineage: PRD to RFC to security review, test plan and QA report, plus launch brief; each moves draft to review to approved, checked by validate, link, promote and check-gate](diagrams/artifact-lineage.svg)

Every artifact starts with a YAML header:

```yaml
---
id: PRD-001               # unique identifier
type: prd                 # see the type list below
title: "Feature Name"
status: draft             # draft → review → approved → archived
created: 2026-02-23
author: product-agent
parent: null              # ID of the parent artifact (must exist)
children: [RFC-001]       # IDs of child artifacts (must exist)
depends_on: []            # IDs this depends on (must exist)
blocks: []                # IDs this blocks (must exist)
tags: [mvp, auth]
---
```

Required fields: `id`, `type`, `title`, `status`, `created`, `author`. Valid types: `prd`, `rfc`, `test-plan`, `qa-report`, `launch-brief`, `security-review`, `decision-memo`, `test-data`, `icp`, `market-intelligence`, `research`, `sprint-plan`, `feedback-report`, `experiment`, `diagram`, `loi`.

### Status lifecycle

`promote.sh` enforces the order. You cannot skip a step; you can archive from any status.

| Status | Meaning | How to get there |
|--------|---------|------------------|
| `draft` | First version from an agent | Created |
| `review` | Ready for your review | `./tools/artifact/promote.sh <file> review` |
| `approved` | Accepted. The parent and every `depends_on` artifact must already be approved, and validation must pass. | `./tools/artifact/promote.sh <file> approved` |
| `archived` | Superseded or cancelled | `./tools/artifact/promote.sh <file> archived` |

### Artifact tools

| Tool | What it does |
|------|--------------|
| `validate.sh <file>` or `validate.sh --all` | Checks the header and required fields, and that every `parent`, `children`, `depends_on` and `blocks` ID points to a real artifact. `--strict` also checks links in both directions. |
| `promote.sh <file> <status>` | Changes status. Validates first, checks the order, and checks prerequisites for approval. |
| `link.sh <parent> <child>` | Links two artifacts and edits both files: sets `parent` on the child, adds the child to the parent's `children`, and adds the parent to the child's `depends_on`. |
| `check-gate.sh <gate> <file>` | Checks a stage gate (see below). |

Every promotion and link is logged in `artifacts/.audit-log/promotions.log`. You rarely run these yourself: ask "Link the RFC to its PRD" or "Promote the PRD to approved" and the agent runs them.

---

## Stages and gates

![Stage-aware gates: at idea every gate only warns; at mvp the PRD and RFC gates block; at growth and scale every gate blocks](diagrams/stage-gates.svg)

A gate is run with `./tools/artifact/check-gate.sh <gate> <file>`:

| Gate | Run against | Passes when |
|------|-------------|-------------|
| `prd-to-rfc` | the PRD | The PRD is approved and has acceptance criteria |
| `rfc-to-impl` | the RFC | The RFC is approved and its parent PRD is approved |
| `impl-to-qa` | the RFC | The RFC is approved and a test plan exists |
| `release` | the PRD | PRD, RFC, security review and QA report are approved, and the app version was bumped |

How strictly gates apply depends on `company.stage`:

| Stage | Means | Gate behavior |
|-------|-------|---------------|
| `idea` | Exploring; no real users | Every gate only warns |
| `mvp` | First version with early users | `prd-to-rfc` and `rfc-to-impl` block; `impl-to-qa` and `release` warn |
| `growth` | Paying customers, growing | Every gate blocks |
| `scale` | Established product, larger team | Every gate blocks |

If `stage` is empty, gates behave as `growth`. A blocking gate exits with code 1 and lists what is missing; a warning gate prints the same list and exits 0. Exit code 2 means the file you pointed at does not exist.

The stage also sets app versioning: `idea` and `mvp` stay on `0.x.x`; `1.0.0` comes when you move to `growth` or `scale`.

---

## The ship flow

![Ship flow: Orchestrator routes the objective; Product writes the PRD; Engineering writes the RFC while Ops & Risk reviews security and QA plans tests; Engineering builds; QA reports; Growth prepares launch; the Orchestrator approves the release](diagrams/ship-flow.svg)

`/ship <what you want to build>` runs the whole pipeline. It shows a plan first, then pauses after each stage. At each pause you see the artifact, its location, and the gate result. Reply `approve` to continue, describe a change to rerun the stage, or `stop` to resume later.

| # | Stage | Who | Output | Your job at the pause |
|---|-------|-----|--------|-----------------------|
| 1 | Route the objective | Orchestrator | Execution plan | Confirm the plan, or trim stages you do not need |
| 2 | Requirements | Product | PRD in `artifacts/prds/` | Check the problem, scope and acceptance criteria. This is the cheapest place to change your mind. |
| 3 | Technical design | Engineering | RFC and API contract in `artifacts/rfcs/` | Check the data model, API shape and anything that is hard to undo |
| 4 | Security review | Ops & Risk | Threat model in `artifacts/security-reviews/` | Read the top risks and accept or ask for mitigations |
| 5 | Build | Engineering + sub-agents | Code; CI tools run; test plan in `artifacts/test-plans/` | Try it: the flow gives you start commands, URLs and seed data |
| 6 | Quality check | QA & Release | QA report in `artifacts/qa-reports/` | Read failures and decide fix-now or ship-with-known-issue |
| 7 | Launch prep | Growth | Launch brief in `artifacts/launch-briefs/` | Edit the copy so it sounds like you |
| 8 | Release | Orchestrator | Release readiness verdict | Give the final go. Optionally log the session's AI cost (`/token-cost-ledger`). |

Optional steps run only when they apply: discovery validation for novel features, dogfooding (testing as a real user), and experiment review for features behind an A/B test.

The Orchestrator will not approve a release until the PRD, RFC, security review and QA report exist and are approved (in `growth` and `scale`). Ask "Is the auth feature ready to ship?" and it runs `check-gate.sh release` and tells you exactly what is missing.

The [workflow router](../../os/skills/workflow-router/SKILL.md) picks lighter flows for other objectives, such as bug fixes, refactors, `/rapid-prototype` and `/gtm-sprint`.

---

## Runtimes and adapters

You author once in `os/`; `bash tools/build/build.sh` generates a file set for each runtime. See [CUSTOMIZING.md](CUSTOMIZING.md#how-the-build-works).

| Feature | Claude Code | Cursor, Codex, Gemini, Aider |
|---------|-------------|------------------------------|
| Agents, skills, tools, artifacts, gates | Yes | Yes (skills are read from the catalog in `AGENTS.md`, `GEMINI.md` or `.cursor/rules/`) |
| Slash commands such as `/ship` | Yes | No: ask the agent to "run the ship skill" |
| Automatic hooks (below) | Yes | No |
| Per-agent memory (`.claude/agent-memory/`) | Yes | No |
| Per-agent model choice (`models:` in config) | Yes | No: the runtime uses its own model setting |

The three Claude Code hooks run automatically and cost no tokens:

| Hook | When | What it does |
|------|------|--------------|
| `session-start.sh` | A session starts | Shows company, stage, tech stack, branch and recent lessons |
| `pre-promote-validate.sh` | Before `promote.sh` runs | Validates the artifact and blocks the promotion if it is invalid |
| `post-write-artifact-check.sh` | After a file in `artifacts/` is written | Warns if the YAML header is missing |

---

## Where things live

```text
your-project/
├── company.config.yaml   # Your settings. Input, not an artifact: no status, edit any time.
├── CLAUDE.md             # Instructions loaded every Claude Code session (other runtimes are pointed to it)
├── AGENTS.md             # Generated: catalog for Codex, Aider and other AGENTS.md runtimes
├── GEMINI.md             # Generated: Gemini CLI (if installed)
├── .cursor/ .cursorrules # Generated: Cursor rules (if installed)
├── .codex/               # Generated: Codex pointer (if installed)
├── .claude/
│   ├── agents/ skills/   # Generated from os/. Do not edit.
│   ├── hooks/            # The three hooks above (hand-written, Claude Code only)
│   ├── settings.json     # Permissions and hook wiring
│   └── agent-memory/     # Per-agent notes (yours; upgrades never touch it)
├── os/                   # Source of truth: skills/, agents/, playbooks/, hooks/
├── tools/                # Tool scripts by category, plus build/ and lib/
├── standards/            # Permanent reference docs agents read (api, brand, coding, compliance, docs,
│                         #   email, engineering, ops, analytics, templates). Run /ingest after adding.
├── imports/              # Temporary drop zone for /artifact-import. Emptied after import.
├── artifacts/            # Agent outputs: prds/, rfcs/, test-plans/, qa-reports/, launch-briefs/,
│                         #   security-reviews/, decision-memos/, test-data/, product/, ...
│   └── .audit-log/       # Promotion and link history
├── seeds/                # Test data from /seed-data (nominal, edge-cases, empty, ...)
├── cogs/ai-ledger/       # AI token cost entries
├── tasks/                # todo.md (current work) and lessons.md (corrections agents learn from)
└── .company-os/          # Version, install manifest, migrations, backups, and these docs
```
