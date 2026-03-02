# Company OS

A deterministic governance layer for AI-assisted SaaS delivery — built for Claude Code, with human-in-the-loop quality gates at every stage.

`Claude Code specific` · `Human-in-the-loop` · `Document-first` · `v1.8.0`

You stay in control. The system proposes — PRDs, RFCs, threat models, QA reports, launch briefs — you review and approve before anything advances. Enforced by shell scripts, not prompts.

---

## What It Is / What It Isn't

| Company OS is… | Company OS is not… |
|---|---|
| A structured workflow with enforced quality gates | An autonomous agent that ships code without your review |
| A set of specialized AI team members you direct | A replacement for engineering judgment |
| A document trail (PRDs, RFCs, QA reports) you own | A black box that makes decisions for you |
| Human-in-the-loop by design — you approve every stage | A "give it a goal and walk away" system |
| An overlay on your existing repo — never touches source | A platform you migrate your code into |

Every workflow pauses for your review. The Orchestrator does not advance past a gate until you've seen the artifact and approved the transition. This is enforced by `check-gate.sh` — a shell script that verifies required artifacts exist and are in approved status before proceeding.

---

## Design Philosophy

### Built for Claude Code — not an abstraction layer

Company OS does not try to work with every AI coding tool. It is built specifically for Claude Code's agent, skills, and subagent architecture, and uses those primitives directly.

This specificity is a deliberate tradeoff: you get deep integration (agent memory, skill preloading, hook-based validation, subagent delegation) instead of lowest-common-denominator compatibility. If you use Claude Code, you get the full system. If you don't, this tool is not for you — and that's intentional.

### Every stage is a decision point, not a handoff

The Orchestrator routes and delegates. It does not execute autonomously. After each major stage — PRD, RFC, implementation, QA, launch — artifacts are produced and presented for your review. You decide what happens next.

Gates are enforced by `check-gate.sh`. The tool checks that required artifacts exist in approved status before allowing the next stage to begin. Your approval is the key that unlocks each stage. The system cannot skip stages on your behalf.

### Artifacts are the source of truth, not the byproduct

Most AI coding tools produce code. Company OS produces code AND a full paper trail: PRD → RFC → API contract → threat model → QA report → launch brief. Each artifact has YAML frontmatter with lineage links (parent, children, depends_on, blocks).

For solopreneurs especially: six months from now, you can open `artifacts/rfcs/` and understand exactly what was built, why it was built that way, which tradeoffs were made, and which risks were flagged. The code tells you *what* — the artifacts tell you *why*.

---

## What You Get Out of the Box

### 9 Agents (6 top-level + 3 engineering sub-agents)

| Agent | Role |
|-------|------|
| **Orchestrator** | Routes tasks, enforces gates, approves releases |
| **Product** | Discovery, PRDs, prioritization, scope control |
| **Engineering** | Staff Engineer — architecture, decomposition, delegation, code review |
| **Engineering: Backend** | Sub-agent — API endpoints, data models, business logic, background jobs |
| **Engineering: Frontend** | Sub-agent — UI components, responsive design, instrumentation, user docs |
| **Engineering: DevOps** | Sub-agent — deployment, observability, feature flags, dev environment |
| **QA & Release** | Test plans, quality gates, release readiness |
| **Growth** | Launch strategy, SEO, activation, email lifecycle |
| **Ops & Risk** | Security, compliance, incidents, legal, finance |

### 62 Skills

| Category | Skills |
|----------|--------|
| Orchestration | workflow-router, ship, status, decision-memo-writer, conflict-resolver, ingest, system-maintenance, artifact-import, setup, upgrade-company-os, rapid-prototype, token-cost-ledger, weekly-review, retrospective |
| Product | icp-positioning, prd-writer, sprint-prioritizer, feedback-synthesizer, discovery-validation, ux-research, market-intelligence, customer-conversations |
| Engineering | architecture-draft, api-contract-designer, background-jobs, multi-tenancy, implementation-decomposer, code-review, seed-data, deployment-strategy, instrumentation, feature-flags, user-docs, mobile-readiness, dev-environment, ai-engineering, design-system, observability-baseline, resilience-testing |
| QA / Release | test-plan-generator, api-tester-playbook, release-readiness-gate, perf-benchmark-checklist, dogfood, test-intelligence, experiment-framework |
| Growth | positioning-messaging, landing-page-copy, seo-topic-map, channel-playbook, activation-onboarding, email-lifecycle, content-engine, product-led-growth |
| Risk / Legal | threat-modeling, privacy-data-handling, compliance-readiness, pricing-unit-economics, tos-privacy-drafting, incident-response, support-operations, security-posture |

### 31 Tool Scripts

| Tool | Purpose |
|------|---------|
| `validate.sh` | Checks artifact frontmatter + reference integrity |
| `promote.sh` | Enforces lifecycle ordering (draft → review → approved) |
| `link.sh` | Links parent/child artifacts bidirectionally |
| `check-gate.sh` | Stage gate checks (prd-to-rfc, rfc-to-impl, impl-to-qa, release) |
| `version-bump.sh` | Stage-aware app version bumping with changelog + git tags |
| `smoke-test.sh` | Smoke tests against deployed environment (auto-resolves URL) |
| `pre-deploy.sh` | Pre-deployment validation gate (8 checks incl. version) |
| `secrets-scan.sh` | Secret detection in codebase |
| `token-ledger.sh` | AI token cost logging to COGS ledger |
| `posture-check.sh` | Security posture health check (findings, scan freshness, policy) |
| `dashboard.sh` | Project dashboard with artifact graph, gate readiness, open risks, cost snapshot |

See [SETUP.md](.company-os/docs/SETUP.md) for the full list across all 10 tool categories.

### Stage-Aware Gates

Company OS reads `company.stage` from `company.config.yaml` and adjusts enforcement:

| Stage | Gate Behavior |
|-------|--------------|
| `idea` | All gates advisory — warnings only, move fast |
| `mvp` | Core gates enforced (prd-to-rfc, rfc-to-impl) |
| `growth` | All gates enforced |
| `scale` | All gates enforced + stricter release bars |

Start permissive, tighten as you scale. The system adapts without reconfiguration.

---

## How It Works

### Three-Layer Architecture

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

The dependency rule is strict: Agents depend on Skills for reasoning, Skills depend on Tools for execution. Tools never contain AI reasoning — they are deterministic shell scripts. This separation means enforcement cannot be soft-talked out of.

### Multi-Agent Orchestration

Company OS agents are **Claude Code subagents** — each one is a specialized AI with its own system prompt, skills, and tools. When you give an objective, the Orchestrator spawns the right agent for each stage:

```
You: "Build Stripe billing for Acme"
 │
 ├─→ Orchestrator reads objective, spawns Product Agent
 │     └─→ Product Agent writes PRD using prd-writer skill
 │
 ├─→ Orchestrator checks prd-to-rfc gate, spawns Engineering Agent
 │     └─→ Engineering Agent writes RFC + API contract
 │
 ├─→ Orchestrator spawns Ops & Risk Agent (in parallel with Engineering)
 │     └─→ Ops & Risk runs threat model on the RFC
 │
 ├─→ Engineering Agent implements code, runs tests
 │
 ├─→ Orchestrator checks impl-to-qa gate, spawns QA Agent
 │     └─→ QA Agent writes test plan, runs validation
 │
 └─→ Orchestrator checks release gate, spawns Growth Agent
       └─→ Growth Agent writes launch brief
```

Each agent only sees the skills relevant to its role. The Orchestrator never writes code — it only routes, delegates, and enforces gates. Artifacts produced by one agent become inputs to the next, creating a full audit trail from idea to shipped product.

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

Run `/ship` to kick off the full pipeline. Gates are enforced by `tools/artifact/check-gate.sh` — you can't skip stages. After implementation, a **Seed & Verify** step presents start commands, service URLs, and seed data so you can test what was built before handing off to QA.

---

## Why Company OS

### 1. Deterministic enforcement, not prompts
Rules are shell scripts, not instructions. `check-gate.sh`, `validate.sh`, and `promote.sh` cannot be argued with, hallucinated around, or accidentally skipped.

### 2. Artifact lineage as source of truth
Every artifact carries YAML frontmatter with `id`, `parent`, `children`, `depends_on`, and `blocks`. The Orchestrator traces this graph to verify prerequisites before advancing — no manual tracking required.

### 3. Stage-aware progressive gates
At `idea` stage, gates are advisory. At `growth` stage, they're enforced. The same `company.config.yaml` drives this — you set `company.stage` once, the system adjusts.

### 4. Overlay model — never touches your source
Company OS installs into `.claude/`, `tools/`, and `company.config.yaml`. It does not modify your source directories, existing CI, or git history. Uninstall is a directory removal.

### 5. Config-driven adaptation
`company.config.yaml` drives agent behavior: tech stack, API conventions, branching strategy, model selection per agent, COGS budget, design archetype, experiment settings. No prompt editing required to adapt the system to your project.

### 6. Cost consciousness built in
The COGS ledger (`cogs/ai-ledger/`) tracks AI token spend as a first-class business cost. Token costs are published transparently in [TOKEN_COSTS.md](.company-os/docs/TOKEN_COSTS.md). The system uses model routing (opus for reasoning, sonnet for templates) to minimize spend.

---

## Install

Company OS is an **overlay** — it adds its own files alongside your code and never touches your source. Works with new projects, existing repos, and monorepos. If you already have Claude Code configured (`.claude/settings.json`, custom agents), the installer smart-merges — your existing permissions, agents, and skills are preserved.

### Prerequisites

- **Git** — Company OS uses git for artifact audit trails (`git init` if you don't have one)
- **Claude Code** — Install from [claude.ai/code](https://claude.ai/code)
- **python3** (optional) — Used by the installer to smart-merge `.claude/settings.json`

### Existing Project (one command)

```bash
cd my-project
curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh | bash
```

### New Project (GitHub template)

```bash
# GitHub CLI
gh repo create my-app --template vibbs/company-os --clone
cd my-app

# Or click "Use this template" on the repo page
```

### After Install

Open Claude Code and run the setup wizard:

```bash
claude
> /setup
```

Three input modes:

| Mode | How | Best for |
|------|-----|----------|
| **Interactive** | `/setup` | First-timers — guided step-by-step |
| **Express** | `/setup` + config block | Power users — paste everything at once |
| **Auto-Extract** | `/setup https://yoursite.com` | Fastest — extracts from your website or text |

Then build your first feature:

```
> Build [feature] for [product]
```

---

## Key Commands

| Command | What It Does |
|---------|-------------|
| `/setup` | Configure Company OS for your project |
| `/ship` | Full ship flow — PRD → RFC → implementation → QA → release |
| `/status` | Project health dashboard — artifacts, statuses, gate readiness |
| `/artifact-import` | Import existing PRDs, RFCs, specs from external sources |
| `/ingest` | Sync new standards/artifacts into the system |
| `/system-maintenance` | Audit and fix documentation after structural changes |
| `/dev-environment` | Generate Docker Compose + dev scripts from tech stack config |
| `/upgrade-company-os` | Check for updates, preview changes, upgrade, or rollback |
| `/rapid-prototype` | Time-boxed PoC (4h/1d/3d) — skips RFC and QA gates |
| `/token-cost` | Log AI token spend to COGS ledger |
| `/design-system` | Configure design archetype and generate visual tokens |
| `/weekly-review` | Weekly operating summary — shipped, spend, risks, priorities |
| `/retrospective` | Post-ship retro — trace lineage, evaluate metrics, capture lessons |

---

## Content Model

| Category | Location | Author | Purpose |
|----------|----------|--------|---------|
| Configuration | `company.config.yaml` | User | Tech stack, API standards, conventions |
| Imports | `imports/` | User | Transient staging for `/artifact-import` |
| Standards | `standards/` | User | Permanent reference docs agents read continuously |
| Session Work | `tasks/` | Agent | Task tracking + accumulated learning |
| Deliverables | `artifacts/` | Agent | Lifecycle-managed outputs with audit trail |
| COGS Ledger | `cogs/ai-ledger/` | Agent | AI token spend tracking as business cost |

---

## Token Costs

Company OS adds minimal overhead to Claude Code usage:

| What | Additional Tokens |
|------|------------------|
| Per session (CLAUDE.md auto-loaded) | ~1,900 |
| Per agent spawn (skills preloaded) | ~3,000–16,000 |
| Full feature (idea → shipped) | ~160,000–220,000 total |

See [TOKEN_COSTS.md](.company-os/docs/TOKEN_COSTS.md) for detailed breakdowns.

---

## Customization

- **Add skills**: Create `.claude/skills/<name>/SKILL.md`
- **Add agents**: Create `.claude/agents/<name>.md`
- **Add tools**: Create `tools/<category>/<name>.sh`
- **Modify artifact types**: Update `tools/artifact/validate.sh`
- **Change stage gates**: Update `tools/artifact/check-gate.sh`

After structural changes, run `/system-maintenance` to keep documentation in sync.

Full reference: [SETUP](.company-os/docs/SETUP.md) | [FAQ](.company-os/docs/FAQ.md) | [Roadmap](.company-os/docs/ROADMAP.md)

---

## Updating

Company OS uses semantic versioning. Check your installed version in `.company-os/version`.

### From Inside Claude Code

```
> /upgrade-company-os            # check for updates
> /upgrade-company-os preview    # preview changes
> /upgrade-company-os apply      # run the upgrade
> /upgrade-company-os rollback   # restore from backup
```

### From Terminal

```bash
# Quick upgrade (preserves your config, permissions, and custom content)
curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh | bash -s -- --force

# Preview first
curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh | bash -s -- --dry-run --force
```

Conflicts (you modified + template changed) are saved to `.company-os/conflicts/` for manual resolution. Major version upgrades automatically create a backup.

See [SETUP.md](.company-os/docs/SETUP.md) for all upgrade flags and options.

---

## License

MIT
