# AI Agentic Company OS

A template system for building SaaS products with Claude Code. Fork this repo, describe what you're building, and let specialized AI agents take you from idea to shipped product — with structured artifacts, enforced quality gates, and full audit trails at every stage.

---

## Why This Exists

Claude Code is powerful, but out of the box it's a blank canvas. You prompt, it responds, and the quality depends entirely on what you remember to ask for.

Company OS adds structure:

- **6 specialized agents** that know their domain (product, engineering, QA, growth, ops, orchestration)
- **44 skills** with procedures, templates, and checklists agents follow
- **23 tool scripts** that enforce rules deterministically (artifact validation, stage gates, lifecycle management)
- **Artifact lineage** tracking every decision from PRD to release with parent/child relationships
- **Stage gates** that block progression until prerequisites are met

The overhead? **~1,900 extra tokens per session** for the system prompt. That's it. See [TOKEN_COSTS.md](TOKEN_COSTS.md) for the full breakdown.

---

## Quick Start

Company OS is an **overlay** — it works with new projects, existing repos, and mono repos. It never touches your source code.

### Option A — Claude Code (Recommended)

```bash
cd my-project    # new or existing repo
claude
> /setup
```

The `/setup` wizard walks you through tech stack selection (with presets), fills in `company.config.yaml`, generates `.claude/settings.json` with permissions for your stack, and scaffolds directories.

### Option B — Script + Claude Code

```bash
cd my-project
bash setup.sh    # scaffolds directories + template config
claude
> /setup         # customize interactively
```

### Option C — GitHub Template

Click "Use this template" on GitHub, clone, then run `/setup`.

See [SETUP_COMPANY_OS.md](SETUP_COMPANY_OS.md) for the full configuration walkthrough.

---

## Architecture

### Three-Layer System

```
┌─────────────────────────────────────────────┐
│  Agents (Authority Layer)                    │
│  .claude/agents/                             │
│  Route, decide, delegate. Never build.       │
├─────────────────────────────────────────────┤
│  Skills (Procedural Layer)                   │
│  .claude/skills/                             │
│  Advise, produce artifacts. Templates &      │
│  checklists agents follow.                   │
├─────────────────────────────────────────────┤
│  Tools (Execution Layer)                     │
│  tools/                                      │
│  Execute deterministic actions. Shell scripts │
│  that validate, promote, link, gate.         │
└─────────────────────────────────────────────┘
```

### Ship Flow

Every feature follows this enforced path:

```
Objective → Orchestrator → Product Agent (PRD)
                              │
                    ── prd-to-rfc gate ──
                              │
                        Engineering Agent (RFC + API Contract)
                              │
                    ── rfc-to-impl gate ──
                              │
                    ┌─────────┴─────────┐
              Ops & Risk Agent     Engineering Agent
              (Threat Model)       (Implementation)
                    │                    │
                    └─────────┬─────────┘
                    ── impl-to-qa gate ──
                              │
                        QA Agent (Test Plan + QA Report)
                              │
                    ── release gate ──
                              │
                    Growth Agent (Launch Brief)
                              │
                    Orchestrator Approves Release
```

Gates are enforced by `tools/artifact/check-gate.sh` — you can't skip stages.

---

## What's Included

### Agents

| Agent | Role |
|-------|------|
| **Orchestrator** | Routes tasks, enforces gates, approves releases |
| **Product** | Discovery, PRDs, prioritization, scope control |
| **Engineering** | Architecture, API design, implementation |
| **QA & Release** | Test plans, quality gates, release readiness |
| **Growth** | Launch strategy, SEO, activation, content |
| **Ops & Risk** | Security, compliance, legal, finance |

### Skills (44)

| Category | Skills |
|----------|--------|
| Orchestration | workflow-router, ship, status, decision-memo-writer, conflict-resolver, ingest, system-maintenance, artifact-import, setup |
| Product | icp-positioning, prd-writer, sprint-prioritizer, feedback-synthesizer, discovery-validation |
| Engineering | architecture-draft, api-contract-designer, background-jobs, multi-tenancy, implementation-decomposer, observability-baseline, code-review, seed-data, deployment-strategy, instrumentation, feature-flags, user-docs, mobile-readiness |
| QA / Release | test-plan-generator, api-tester-playbook, release-readiness-gate, perf-benchmark-checklist, seed-data, code-review, dogfood |
| Growth | positioning-messaging, landing-page-copy, seo-topic-map, channel-playbook, activation-onboarding, email-lifecycle |
| Risk / Legal / Finance | threat-modeling, privacy-data-handling, compliance-readiness, pricing-unit-economics, tos-privacy-drafting, incident-response |

### Enforcement Tools

| Tool | What It Does |
|------|-------------|
| `validate.sh` | Checks artifact frontmatter + verifies all references (parent, children, depends_on) resolve to real files |
| `promote.sh` | Enforces lifecycle ordering (draft → review → approved), checks prerequisites before approval |
| `link.sh` | Links parent/child artifacts — edits both files, validates, logs to audit trail |
| `check-gate.sh` | Stage gate checks with specific preconditions per gate |
| `status-check.sh` | Quick health checks for production services (ops) |
| `pre-deploy.sh` | Validates deployment readiness before every deploy |

---

## Token Costs

Company OS adds minimal overhead to your Claude Code usage:

| What | Additional Tokens |
|------|------------------|
| Per session (CLAUDE.md auto-loaded) | ~1,900 |
| Per agent spawn (skills preloaded) | ~3,000-16,000 |
| Full feature (idea → shipped) | ~160,000-220,000 total |

See [TOKEN_COSTS.md](TOKEN_COSTS.md) for detailed per-agent breakdowns and cost reduction strategies.

---

## Customization

- **Add skills**: Create a directory in `.claude/skills/` with a `SKILL.md` file
- **Add agents**: Create a `.md` file in `.claude/agents/` with the right frontmatter
- **Add tools**: Create a `.sh` script in the appropriate `tools/` subdirectory
- **Modify artifact types**: Update `tools/artifact/validate.sh`
- **Change stage gates**: Update `tools/artifact/check-gate.sh`

After any structural change, run `/system-maintenance` to keep all documentation in sync.

Full customization guide: [SETUP_COMPANY_OS.md](SETUP_COMPANY_OS.md)

---

## Content Model

Company OS works as an overlay on any repo. For **mono repos**, it sits at the root and agents work across all packages. For **multi repos**, each repo gets its own instance.

The repo uses five distinct content categories:

| Category | Location | Author | Purpose |
|----------|----------|--------|---------|
| Configuration | `company.config.yaml` | User | Tech stack, API standards, conventions |
| Imports | `imports/` | User | **Transient** staging — files are classified, moved to `artifacts/`, then deleted via `/artifact-import` |
| Standards | `standards/` | User | **Permanent** reference docs agents read continuously (API specs, style guides, brand, compliance) |
| Session Work | `tasks/` | Agent | Ephemeral task tracking + accumulated learning |
| Deliverables | `artifacts/` | Agent | Lifecycle-managed outputs (PRDs, RFCs, QA reports) with full audit trail |

Design decisions are documented in `artifacts/decision-memos/`:
- [DM-001](artifacts/decision-memos/DM-001-config-location.md) — Why config stays at root
- [DM-002](artifacts/decision-memos/DM-002-tasks-folder-location.md) — Why tasks/ stays separate from artifacts/

---

## Key Commands

| Command | What It Does |
|---------|-------------|
| `/ship` | Kick off the full ship flow — PRD, RFC, implementation, QA, release with gate checks |
| `/status` | Project health dashboard — artifact counts, statuses, broken links, gate readiness |
| `/setup` | Interactive setup wizard — configures config, permissions, and directories |
| `/artifact-import` | Imports existing PRDs, RFCs, specs from external sources |
| `/ingest` | Syncs new standards/artifacts into skills and agents |
| `/system-maintenance` | Audits all documentation after structural changes |
| `./tools/registry/health-check.sh` | Validates all skills have correct format |
| `./tools/artifact/check-gate.sh release <prd>` | Checks if a feature is ready to ship |

---

## FAQ

Honest answers about i18n, design systems, AI content quality, observability, proof of work, and agent coordination. See [FAQ.md](FAQ.md).

---

## License

MIT
