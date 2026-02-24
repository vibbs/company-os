# AI Agentic Company OS

A template system for building SaaS products with Claude Code. Fork this repo, describe what you're building, and let specialized AI agents take you from idea to shipped product — with structured artifacts, enforced quality gates, and full audit trails at every stage.

---

## Why This Exists

Claude Code is powerful, but out of the box it's a blank canvas. You prompt, it responds, and the quality depends entirely on what you remember to ask for.

Company OS adds structure:

- **6 specialized agents** that know their domain (product, engineering, QA, growth, ops, orchestration)
- **29 skills** with procedures, templates, and checklists agents follow
- **20+ tool scripts** that enforce rules deterministically (artifact validation, stage gates, lifecycle management)
- **Artifact lineage** tracking every decision from PRD to release with parent/child relationships
- **Stage gates** that block progression until prerequisites are met

The overhead? **~1,400 extra tokens per session** for the system prompt. That's it. See [TOKEN_COSTS.md](TOKEN_COSTS.md) for the full breakdown.

---

## Quick Start

```bash
# 1. Fork or clone
git clone <your-fork-url> my-product
cd my-product

# 2. Open Claude Code
claude

# 3. Tell it what you're building
```

> "Set up Company OS for Acme Corp. We're building a B2B invoicing tool using Next.js, PostgreSQL, and Prisma. We use REST APIs with JWT auth."

The Orchestrator agent fills in `company.config.yaml`, tells you what standards docs to provide, and you're ready to ship features.

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

### Skills (29)

| Category | Skills |
|----------|--------|
| Orchestration | workflow-router, decision-memo-writer, conflict-resolver, ingest, system-maintenance |
| Product | icp-positioning, prd-writer, sprint-prioritizer, feedback-synthesizer |
| Engineering | architecture-draft, api-contract-designer, background-jobs, multi-tenancy, implementation-decomposer, observability-baseline |
| QA / Release | test-plan-generator, api-tester-playbook, release-readiness-gate, perf-benchmark-checklist |
| Growth | positioning-messaging, landing-page-copy, seo-topic-map, channel-playbook, activation-onboarding |
| Risk / Legal / Finance | threat-modeling, privacy-data-handling, compliance-readiness, pricing-unit-economics, tos-privacy-drafting |

### Enforcement Tools

| Tool | What It Does |
|------|-------------|
| `validate.sh` | Checks artifact frontmatter + verifies all references (parent, children, depends_on) resolve to real files |
| `promote.sh` | Enforces lifecycle ordering (draft → review → approved), checks prerequisites before approval |
| `link.sh` | Links parent/child artifacts — edits both files, validates, logs to audit trail |
| `check-gate.sh` | Stage gate checks with specific preconditions per gate |

---

## Token Costs

Company OS adds minimal overhead to your Claude Code usage:

| What | Additional Tokens |
|------|------------------|
| Per session (CLAUDE.md auto-loaded) | ~1,400 |
| Per agent spawn (skills preloaded) | ~3,000-6,000 |
| Full feature (idea → shipped) | ~150,000-200,000 total |

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

The repo uses four distinct content categories:

| Category | Location | Author | Purpose |
|----------|----------|--------|---------|
| Configuration | `company.config.yaml` | User | Tech stack, API standards, conventions |
| Standards | `standards/` | User | Reference docs (API specs, style guides, compliance) |
| Session Work | `tasks/` | Agent | Ephemeral task tracking + accumulated learning |
| Deliverables | `artifacts/` | Agent | Lifecycle-managed outputs (PRDs, RFCs, QA reports) with full audit trail |

Design decisions are documented in `artifacts/decision-memos/`:
- [DM-001](artifacts/decision-memos/DM-001-config-location.md) — Why config stays at root
- [DM-002](artifacts/decision-memos/DM-002-tasks-folder-location.md) — Why tasks/ stays separate from artifacts/

---

## Key Commands

| Command | What It Does |
|---------|-------------|
| `/ingest` | Syncs new standards/artifacts into skills and agents |
| `/system-maintenance` | Audits all documentation after structural changes |
| `./tools/registry/health-check.sh` | Validates all skills have correct format |
| `./tools/artifact/check-gate.sh release <prd>` | Checks if a feature is ready to ship |

---

## License

MIT
