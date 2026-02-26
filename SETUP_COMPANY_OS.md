# Setup Guide — AI Agentic Company OS

This guide walks you through installing and configuring Company OS. Two phases: **install** (get the files) then **configure** (customize for your project).

---

## Phase 1: Install

Company OS is an **overlay** — it adds its own files alongside your code and never touches your source.

### Existing Project (recommended)

```bash
cd my-project
curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh | bash
```

This downloads the Company OS overlay files (`.claude/`, `tools/`, `company.config.yaml`, `CLAUDE.md`) and scaffolds working directories. Your existing code is untouched.

### New Project (GitHub template)

```bash
# GitHub CLI
gh repo create my-app --template vibbs/company-os --clone
cd my-app

# Or click "Use this template" on the GitHub repo page
```

### What Gets Installed

| Item | Purpose |
|------|---------|
| `.claude/agents/` | 6 specialized AI agents |
| `.claude/skills/` | 44 procedural skills with templates and checklists |
| `.claude/hooks/` | Automatic artifact validation hooks |
| `tools/` | 23 enforcement scripts (validation, gates, lifecycle) |
| `company.config.yaml` | Central config file (empty template — you fill it in Phase 2) |
| `CLAUDE.md` | Agent instructions (auto-loaded every session) |
| `artifacts/`, `standards/`, `tasks/`, `imports/` | Working directories |

### Mono/Multi Repo

- **Mono repo**: Install at the repo root. `company.config.yaml` describes the shared stack. Agents work across all packages.
- **Multi repo**: Each repo gets its own Company OS install with independent config and artifacts.

---

## Phase 2: Configure

Open Claude Code and run the setup wizard:

```bash
claude
> /setup
```

The wizard fills in `company.config.yaml`, generates `.claude/settings.json` with permissions for your tech stack, and verifies everything works.

### Three ways to configure — pick your speed:

**Interactive** — guided step-by-step (best for first-timers):
```
> /setup
```

**Express** — paste a config block (best for power users):
```
> /setup

## Company
- Name: Acme Corp
- Product: InvoiceFlow
- Description: B2B SaaS invoicing for small businesses
- Domain: invoiceflow.com
- Stage: mvp

## Tech Stack
- Preset: nextjs
- Cache: Redis
- Queue: BullMQ

## Architecture
- Multi-tenant: true
- Tenant Isolation: RLS
- Deployment: serverless

## Platforms
- Targets: [web, mobile-web]

## Analytics
- Provider: PostHog

## Email
- Provider: Resend

## Options
- Clean Up Templates: yes
```

**Auto-extract** — paste a URL or unstructured text (fastest):
```
> /setup https://yourproduct.com
```

Or paste a pitch deck summary, product brief, or Notion dump alongside `/setup` — the wizard extracts what it can and only asks about what it couldn't determine.

See the full express mode template in `.claude/skills/setup/SKILL.md`.

**Or configure manually** — the sections below walk through each step.

---

## 1. Configure `company.config.yaml`

This is the central configuration file. Every agent, skill, and tool reads from it.

**Ask an agent**: "Fill in company.config.yaml — we're building [describe your product and stack]"

The agent will read the file, ask clarifying questions for fields it can't infer, and fill in the values.

### Required Fields (minimum to start)

```yaml
company:
  name: "Your Company"          # Used in artifact headers and docs
  product: "Your Product"       # Product name
  description: "One-liner"      # Agents use this for context
  stage: "mvp"                  # idea | mvp | growth | scale

tech_stack:
  language: "TypeScript"        # Agents tailor code and architecture to this
  framework: "Next.js"          # Architecture decisions depend on this
  database: "PostgreSQL"        # Data model design adapts to this
```

### Recommended Fields (fill as your project matures)

```yaml
api:
  style: "REST"                 # REST | GraphQL | gRPC | tRPC
  error_format: "RFC7807"       # How API errors are structured
  auth: "JWT"                   # Authentication method
  pagination: "cursor"          # cursor | offset | none

conventions:
  test_framework: "Vitest"      # Tools auto-detect and run tests
  linter: "ESLint"              # Lint tool auto-runs the right command
  commit_style: "conventional"  # Guides commit message format
```

### Additional Config Sections (fill as needed)

```yaml
platforms:
  targets: [web, mobile-web]    # web | mobile-web | ios | android
  responsive: true              # Enable mobile-readiness checks
  pwa: false                    # Progressive Web App support

analytics:
  provider: "PostHog"           # Analytics provider (PostHog, Mixpanel, Amplitude, etc.)
  events_style: "noun_verb"     # Event naming convention
  consent_required: true        # Whether consent is needed before tracking

feature_flags:
  provider: "LaunchDarkly"      # Feature flag provider (LaunchDarkly, Flagsmith, custom, etc.)
  discovery_levels: [core, foundations, power, expert]  # Progressive discovery tiers
  default_rollout: "percentage" # percentage | user-segment | environment

email:
  provider: "Resend"            # Email service provider (Resend, SendGrid, Postmark, etc.)
  transactional: true           # Transactional emails (receipts, password resets)
  marketing: false              # Marketing/lifecycle email campaigns
  templates_dir: "standards/email/"  # Where email templates live
```

These sections are read by the corresponding skills: `mobile-readiness` reads `platforms`, `instrumentation` reads `analytics`, `feature-flags` reads `feature_flags`, and `email-lifecycle` reads `email`.

### What Happens If Fields Are Empty

- Agents will ask you to decide before proceeding with affected recommendations
- Tools will attempt auto-detection (e.g., checking for `package.json` to detect Node.js)
- Skills will use generic patterns instead of stack-specific ones

### Tech Stack Recommendations

Agents flag concerns if your configured stack isn't ideal for a specific use case:
- MongoDB configured but feature needs complex joins → suggests PostgreSQL
- REST configured but need real-time updates → suggests WebSocket additions
- These are recommendations, not blockers — agents respect your final decision

### Why config stays at the root (not in artifacts/)

`company.config.yaml` is user-authored **input** configuration. Artifacts are agent-produced **outputs** with lifecycle tracking (draft→approved). Config has no lifecycle — it's a living document that changes when you decide. See `artifacts/decision-memos/DM-001-config-location.md` for the full rationale.

---

## 2. The Three-Layer Architecture

### Agents (Authority Layer) — `.claude/agents/`

Agents are Claude Code subagents that make decisions and delegate work.

| Agent | File | Responsibility |
|-------|------|---------------|
| **Orchestrator** | `orchestrator.md` | Routes tasks, enforces gates, approves releases |
| **Product** | `product.md` | Discovery, PRDs, prioritization, scope control |
| **Engineering** | `engineering.md` | Architecture, API design, implementation |
| **QA & Release** | `qa-release.md` | Test plans, quality gates, release readiness |
| **Growth** | `growth.md` | Launch strategy, SEO, activation, content |
| **Ops & Risk** | `ops-risk.md` | Security, compliance, legal, finance |

**How to use**: Claude Code discovers agents automatically. You can invoke them by name or just describe your objective — the Orchestrator routes it.

### Skills (Procedural Layer) — `.claude/skills/`

Skills are directory-based knowledge documents. Each contains a `SKILL.md` entrypoint plus optional supporting files.

| Category | Skills (directory names) |
|----------|------------------------|
| Orchestration | `workflow-router`, `decision-memo-writer`, `conflict-resolver`, `ingest`, `system-maintenance`, `artifact-import`, `setup` |
| Product | `icp-positioning`, `prd-writer`, `sprint-prioritizer`, `feedback-synthesizer`, `discovery-validation` |
| Engineering | `architecture-draft`, `api-contract-designer`, `background-jobs`, `multi-tenancy`, `implementation-decomposer`, `observability-baseline`, `code-review`, `seed-data`, `deployment-strategy`, `instrumentation`, `feature-flags`, `user-docs`, `mobile-readiness` |
| QA / Release | `test-plan-generator`, `api-tester-playbook`, `release-readiness-gate`, `perf-benchmark-checklist`, `seed-data`, `code-review`, `dogfood` |
| Growth | `positioning-messaging`, `landing-page-copy`, `seo-topic-map`, `channel-playbook`, `activation-onboarding`, `email-lifecycle` |
| Risk / Legal / Finance | `threat-modeling`, `privacy-data-handling`, `compliance-readiness`, `pricing-unit-economics`, `tos-privacy-drafting`, `incident-response` |

**Customizing**: Edit any skill's `SKILL.md` to match your processes. Frontmatter uses official Claude Code fields (`name`, `description`, `allowed-tools`, etc.). Supporting files (templates, references) live alongside `SKILL.md`.

### Tools (Execution Layer) — `tools/`

Shell scripts that agents execute via Bash. They perform deterministic actions.

| Category | Directory | Tools |
|----------|-----------|-------|
| Artifact Management | `tools/artifact/` | validate, promote, link, check-gate |
| Skill Registry | `tools/registry/` | search-skill, health-check, detect-changes |
| CI / Engineering | `tools/ci/` | run-tests, lint-format, openapi-lint |
| Database | `tools/db/` | migration-check, seed |
| QA | `tools/qa/` | contract-test, perf-benchmark, smoke-test, dogfood |
| Security | `tools/security/` | dependency-scan, secrets-scan, sast |
| Analytics | `tools/analytics/` | query-metrics, publish-content |
| Ops | `tools/ops/` | status-check |
| Deploy | `tools/deploy/` | pre-deploy |

**Customizing**: Tools read from `company.config.yaml` to auto-detect your stack. Some tools are stubs (analytics, content publishing) — replace them with calls to your actual providers.

---

## 3. Place Your Standards Documents

Drop your existing company standards into `standards/`. Then run `/ingest` to sync them into the system.

**Ask an agent**: "I've placed my API spec in standards/api/. Run /ingest to update the relevant skills."

### `standards/api/`
- OpenAPI specifications
- API style guides
- Error format examples
- Authentication documentation

### `standards/coding/`
- Code style guides
- Linting configuration files
- Architecture decision records
- Naming conventions

### `standards/compliance/`
- SOC2 requirements
- GDPR compliance docs
- HIPAA requirements (if applicable)
- Audit logging requirements

### `standards/templates/`
- Custom artifact templates (overrides defaults in skills)
- Document templates
- PR templates, issue templates

### `standards/brand/`
- Brand guidelines and style guide
- Design tokens (colors, typography, spacing)
- Logo usage rules and asset references
- Component library documentation or Figma links

When brand standards are present, agents reference them for visual requirements and content tone.

### `standards/ops/`
- Operational runbooks and playbooks
- Incident response procedures and severity definitions
- SLO/SLA definitions and escalation policies
- On-call rotation and communication templates

### `standards/analytics/`
- Event taxonomy and naming conventions
- Tracking plans (which events, which properties)
- Dashboard specifications and KPI definitions
- Consent and privacy requirements for analytics

### `standards/docs/`
- Documentation style guides
- API documentation templates
- End-user documentation conventions
- Changelog and release notes formats

### `standards/email/`
- Email template designs and guidelines
- Lifecycle sequence definitions (onboarding, re-engagement, etc.)
- Deliverability best practices
- Transactional vs marketing email rules

### `standards/engineering/`
- Engineering principles and philosophy
- Architecture decision records (ADRs)
- Code ownership and review policies
- Deployment and release procedures

### After Placing Standards: Run Ingest

The `/ingest` command detects new files and recommends updates to skills and agents:

```
/ingest
```

It will:
1. Scan `standards/` and `artifacts/` for new or modified files
2. Classify which skills and agents are impacted
3. Compare new standards against current skill procedures
4. Generate specific update recommendations
5. Ask you to review or auto-apply the changes

This is how your company-specific standards become embedded in the skill procedures.

---

## 4. Importing Existing Work

> **`imports/` vs `standards/` — what goes where?**
> - **`standards/`** is for **permanent reference docs** (API specs, style guides, brand guidelines). Files stay there and agents read them continuously. Use `/ingest` after adding.
> - **`imports/`** is a **transient staging area** for existing artifacts (PRDs, RFCs, test plans) you want to bring into the lifecycle system. Files are classified, given frontmatter, moved to `artifacts/`, then deleted from `imports/`. Use `/artifact-import` to process.

If you already have PRDs, architecture docs, API specs, test plans, or other artifacts from Google Docs, Notion, Confluence, or local files, you can import them into Company OS to use the stage gates, enforcement tools, and agent workflows.

### Quick Import

1. Export your documents as Markdown or HTML
2. Place them in the `imports/` directory
3. Run `/artifact-import`

**Ask an agent**: "I've placed my existing PRD and architecture doc in imports/. Import them into the system."

The import skill will:
- Classify each document by type (PRD, RFC, test plan, etc.)
- Generate proper frontmatter with unique IDs
- Restructure content to match Company OS templates (best-effort)
- Detect relationships between imported documents and link them
- Move processed files to the correct `artifacts/` subdirectory
- Run validation on each artifact

### Inline Import

You can also paste document content directly:
> "Import this as a PRD: [paste content]"

### Imported Artifact Status

Imported artifacts start at `review` status (not `draft`) because they already exist as complete documents. Review them against Company OS standards, then promote to `approved` when satisfied. Promote parent artifacts first (PRD before RFC).

### After Import

- Stage gates are active immediately -- run `check-gate.sh` to see what's needed
- The Orchestrator can route from imported artifacts forward (e.g., imported PRD -> generate RFC)
- Run `/ingest` after import if the new artifacts should update skill procedures

---

## 5. The Canonical Ship Flow

Every feature follows this flow. Agents and tools enforce it — you can't skip stages.

```
Objective
    │
    ▼
┌─────────────┐
│ Orchestrator │──── Routes to Product Agent
└─────────────┘
    │
    ▼                              Gate: prd-to-rfc
┌─────────────┐                    (PRD must be approved)
│   Product    │──── PRD → artifacts/prds/
└─────────────┘
    │
    ▼                              Gate: rfc-to-impl
┌─────────────┐                    (RFC + parent PRD approved)
│ Engineering  │──── RFC + API Contract → artifacts/rfcs/
└─────────────┘
    │
    ├──────────────────────┐
    ▼                      ▼       Gate: impl-to-qa
┌─────────────┐    ┌─────────────┐ (RFC approved, test plan exists)
│  Ops & Risk │    │     QA      │──── Test Plan → artifacts/test-plans/
│  Threat     │    └─────────────┘
│  Model      │
└─────────────┘
    │                      │
    ▼                      ▼
┌─────────────┐    ┌─────────────┐
│ Engineering  │    │     QA      │──── QA Report → artifacts/qa-reports/
│ Implements   │    │   Tests     │
└─────────────┘    └─────────────┘
    │                      │
    ▼                      ▼       Gate: release
┌─────────────┐    ┌─────────────┐ (ALL artifacts exist + approved)
│   Growth    │    │ Orchestrator│──── Release Readiness Gate
│ Launch Brief│    │  Approves   │
└─────────────┘    └─────────────┘
```

### Stage Gate Enforcement

Gates are checked with `./tools/artifact/check-gate.sh`:

| Gate | Command | What it checks |
|------|---------|---------------|
| PRD → RFC | `check-gate.sh prd-to-rfc <prd-path>` | PRD approved, has acceptance criteria |
| RFC → Implementation | `check-gate.sh rfc-to-impl <rfc-path>` | RFC approved, parent PRD approved |
| Implementation → QA | `check-gate.sh impl-to-qa <rfc-path>` | RFC approved, test plan exists |
| Release | `check-gate.sh release <prd-path>` | PRD + RFC + security review + QA report all approved |

**Ask an agent**: "Is the auth feature ready to ship?" → The Orchestrator runs `check-gate.sh release` and tells you exactly what's missing.

### Minimum Bars for Release

The Orchestrator will not approve a release unless all gates pass:
- PRD exists and is approved
- RFC/API contract exists and is approved
- Threat model / security review exists (even minimal)
- QA report exists with approved status

---

## 6. Artifacts and Lineage

Every agent-produced document is an **artifact** with YAML frontmatter:

```yaml
---
id: PRD-001               # Unique identifier
type: prd                  # prd | rfc | test-plan | qa-report | launch-brief | security-review | decision-memo | test-data
title: "Feature Name"
status: draft              # draft → review → approved → archived
created: 2026-02-23
author: product-agent
parent: null               # ID of parent artifact (validated — must exist)
children: [RFC-001]        # IDs of child artifacts (validated — must exist)
depends_on: []             # IDs of artifacts this depends on (validated)
blocks: []                 # IDs of artifacts this blocks (validated)
tags: [mvp, auth]
---
```

### Artifact Lifecycle (Enforced)

Transitions are enforced by `promote.sh` — you cannot skip stages:

```
draft → review → approved → archived
                              ↑
                    (archival allowed from any state)
```

- **Draft**: Agent creates initial version
- **Review**: Ready for review (`promote.sh artifact.md review`)
- **Approved**: Passes all checks (`promote.sh artifact.md approved`)
  - Parent artifact must already be approved
  - All `depends_on` artifacts must already be approved
  - Validation must pass (all references resolve to real files)
- **Archived**: Superseded or cancelled

### Artifact Tools

| Tool | What it does |
|------|-------------|
| `validate.sh <path>` | Checks frontmatter, required fields, **verifies all references resolve** (parent, depends_on, children, blocks point to real artifacts). Use `--strict` for bidirectional consistency checks. |
| `promote.sh <path> <status>` | Status transition with enforcement. Runs validate first, checks lifecycle ordering, verifies prerequisites for approval. |
| `link.sh <parent> <child>` | Links two artifacts — **edits both files**: sets parent on child, adds child to parent's children array, adds to depends_on. Validates and logs. |
| `check-gate.sh <gate> <path>` | Checks stage gate preconditions. Gates: `prd-to-rfc`, `rfc-to-impl`, `impl-to-qa`, `release`. |

**Ask an agent**: "Link the RFC to its parent PRD" → runs `link.sh`, edits both files, validates.

**Ask an agent**: "Promote the PRD to approved" → runs `promote.sh`, checks lifecycle ordering and prerequisites.

### Audit Log

All promotions and linkages are logged in `artifacts/.audit-log/promotions.log`.

---

## 7. Customization Guide

### Adding a New Skill

**Ask an agent**: "Create a new skill called `my-custom-skill` that handles [your use case]"

Or manually:

1. Create directory: `.claude/skills/<skill-name>/`
2. Create `SKILL.md` with official frontmatter:
   ```yaml
   ---
   name: skill-name          # lowercase-hyphens, max 64 chars
   description: What this skill does. Use when [trigger phrase].
   allowed-tools: Read, Grep, Glob, Bash   # optional: restrict available tools
   ---
   ```
3. Write the procedure in the markdown body (include a Reference section for custom metadata)
4. Add supporting files (templates, examples) alongside `SKILL.md`
5. Update the relevant agent in `.claude/agents/` to list the new skill name in `skills:`
6. Verify: `./tools/registry/health-check.sh`

### Adding a New Tool

1. Create a `.sh` file in the appropriate `tools/` subdirectory
2. Add the header comment (Description, Usage, Inputs, Outputs)
3. Make executable: `chmod +x tools/category/tool-name.sh`
4. If it reads company config, use the grep pattern from existing tools
5. Reference the tool in relevant skill files

### Adding a New Agent

**Ask an agent**: "Create a new agent for [responsibility] that uses [these skills]"

Or manually:

1. Create `.md` file in `.claude/agents/`
2. Official frontmatter:
   ```yaml
   ---
   name: agent-name           # lowercase-hyphens, max 64 chars
   description: What this agent does. Use proactively for [trigger phrase].
   tools: Read, Write, Edit, Bash, Grep, Glob    # Claude Code tool names
   model: inherit             # inherit | sonnet | opus | haiku
   skills:
     - skill-directory-name   # preloads skill content into agent context
   ---
   ```
3. Write behavioral instructions in the body (include Reference Metadata section)
4. Update the Orchestrator's routing logic if needed

### Modifying Artifact Types

1. Update `tools/artifact/validate.sh` to recognize the new type
2. Create a corresponding directory in `artifacts/`
3. Update relevant skills to produce the new artifact type

---

## 8. Common Agent Workflows

These are things you can ask Claude Code to do. The agents handle the rest.

### Setting up a new project

**Interactive mode** — step-by-step guided wizard:
> Run `/setup` — the wizard asks questions one section at a time with smart defaults.

**Express mode** — paste everything at once:
> Run `/setup` with a config block — no round-trips. Example:

```
/setup

## Company
- Name: Acme Corp
- Product: InvoiceFlow
- Description: B2B SaaS invoicing for small businesses
- Domain: invoiceflow.com
- Stage: mvp

## Tech Stack
- Preset: nextjs
- Cache: Redis
- Queue: BullMQ

## Architecture
- Multi-tenant: true
- Tenant Isolation: RLS
- Deployment: serverless

## Platforms
- Targets: [web, mobile-web]

## Analytics
- Provider: PostHog

## Email
- Provider: Resend

## Options
- Clean Up Templates: yes
```

The wizard parses your block, applies preset defaults for anything not specified, shows a summary for confirmation, then configures everything in one shot.

**Auto-extract mode** — just give it a URL or dump unstructured text:
> `/setup https://yourproduct.com` — fetches the site, extracts company name, product description, infers stage, detects tech stack from the codebase, and presents a pre-filled config for confirmation.

You can also paste a pitch deck summary, product brief, investor memo, or Notion dump alongside `/setup` — the wizard extracts what it can and only asks about what it couldn't determine.

See the full template and all three modes in `.claude/skills/setup/SKILL.md`.

### Importing existing artifacts
> "I have our PRD and architecture doc from Notion. I've exported them to imports/. Bring them into the system."

Runs `/artifact-import` -> classifies documents -> adds frontmatter -> links related artifacts -> validates. Imported artifacts start at `review` status.

### Ingesting new standards
> "I've added our API specification to standards/api/. Sync the system."

Runs `/ingest` → detects the new file → recommends skill updates → applies with your approval.

### Building a feature end-to-end
> "Build a team management feature where org admins can invite, remove, and manage team members with role-based access."

The Orchestrator routes through the full ship flow: PRD → RFC → threat model → implementation → QA → release.

### Checking release readiness
> "Is the auth feature ready to ship?"

Runs `check-gate.sh release` → reports exactly which artifacts exist, which are missing, and what status they're in.

### Reviewing current state
> "What artifacts do we have? What's the current state of the project?"

Runs `detect-changes.sh` → shows all artifacts with their types and statuses.

---

## 9. Directory Reference

```
company-os/
├── CLAUDE.md                   # Master prompt for Claude Code sessions
├── SETUP_COMPANY_OS.md         # This file
├── setup.sh                    # Bash setup fallback (scaffolds dirs + template config)
├── company.config.yaml         # Your company configuration (stays at root)
├── .claude/
│   ├── agents/                 # 6 agent definitions (Claude Code subagents)
│   │   ├── orchestrator.md
│   │   ├── product.md
│   │   ├── engineering.md
│   │   ├── qa-release.md
│   │   ├── growth.md
│   │   └── ops-risk.md
│   └── skills/                 # 44 skill directories (SKILL.md + supporting files)
│       ├── workflow-router/
│       │   └── SKILL.md
│       ├── prd-writer/
│       │   ├── SKILL.md
│       │   └── prd-template.md
│       ├── architecture-draft/
│       │   ├── SKILL.md
│       │   └── rfc-template.md
│       ├── api-contract-designer/
│       │   ├── SKILL.md
│       │   └── error-format-reference.md
│       ├── release-readiness-gate/
│       │   └── SKILL.md
│       ├── ingest/
│       │   └── SKILL.md
│       ├── artifact-import/
│       │   └── SKILL.md
│       ├── setup/
│       │   └── SKILL.md
│       ├── seed-data/
│       │   └── SKILL.md
│       ├── dogfood/
│       │   └── SKILL.md
│       ├── code-review/
│       │   ├── SKILL.md
│       │   └── review-report-template.md
│       ├── discovery-validation/
│       │   └── SKILL.md
│       ├── deployment-strategy/
│       │   └── SKILL.md
│       ├── instrumentation/
│       │   └── SKILL.md
│       ├── feature-flags/
│       │   └── SKILL.md
│       ├── user-docs/
│       │   └── SKILL.md
│       ├── mobile-readiness/
│       │   └── SKILL.md
│       ├── incident-response/
│       │   └── SKILL.md
│       ├── email-lifecycle/
│       │   └── SKILL.md
│       └── ... (19 more skill directories)
├── imports/                    # Staging area for importing external documents
│   └── .gitkeep
├── tools/                      # Shell scripts agents execute via Bash
│   ├── artifact/               # validate, promote, link, check-gate
│   ├── registry/               # search-skill, health-check, detect-changes
│   ├── ci/                     # run-tests, lint-format, openapi-lint
│   ├── db/                     # migration-check, seed
│   ├── qa/                     # contract-test, perf-benchmark, smoke-test, dogfood
│   ├── security/               # dependency-scan, secrets-scan, sast
│   ├── analytics/              # query-metrics, publish-content
│   ├── ops/                    # status-check
│   └── deploy/                 # pre-deploy
├── standards/                  # Your company standards (drop files here, then /ingest)
│   ├── api/                    # API specs and style guides
│   ├── brand/                  # Brand guidelines, design tokens, Figma links
│   ├── coding/                 # Code conventions and style guides
│   ├── compliance/             # Compliance requirements
│   ├── ops/                    # Operational runbooks, incident procedures, SLOs
│   ├── analytics/              # Event taxonomy, tracking plans, dashboard specs
│   ├── docs/                   # Documentation standards, style guides, templates
│   ├── email/                  # Email templates, lifecycle sequences, deliverability rules
│   ├── engineering/            # Engineering principles, architecture decision records
│   ├── engineering-preferences.md  # Team engineering philosophy (used by code-review skill)
│   └── templates/              # Custom artifact templates
├── artifacts/                  # Agent-produced outputs with lineage tracking
│   ├── prds/
│   ├── rfcs/
│   ├── test-plans/
│   ├── qa-reports/
│   ├── launch-briefs/
│   ├── security-reviews/
│   ├── decision-memos/
│   ├── test-data/
│   └── .audit-log/            # Promotion and linkage audit trail
└── tasks/                      # Session task management
    ├── todo.md                 # Current task tracking
    └── lessons.md              # Accumulated lessons
```
