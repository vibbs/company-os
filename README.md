# Company OS

An AI-powered operating system for building SaaS products with Claude Code. Company OS gives your AI assistant a complete team of specialized agents, structured workflows, and quality gates — taking you from idea to shipped product with full audit trails.

## Install

Company OS is an **overlay** — it adds its own files alongside your code and never touches your source. Works with new projects, existing repos, and mono repos.

### Existing Project (one command)

```bash
cd my-project
curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh | bash
```

This downloads the Company OS overlay (`.claude/`, `tools/`, `company.config.yaml`, `CLAUDE.md`) and scaffolds working directories. Your existing code is untouched.

### New Project (GitHub template)

```bash
# Option A — GitHub CLI
gh repo create my-app --template vibbs/company-os --clone
cd my-app

# Option B — GitHub UI
# Click "Use this template" on the repo page, then clone your new repo
```

### After Install

Open Claude Code and run the setup wizard:

```bash
claude
> /setup
```

The wizard configures `company.config.yaml` for your company, tech stack, and conventions, then generates permissions and scaffolds directories. Three input modes:

| Mode | How | Best for |
|------|-----|----------|
| **Interactive** | `/setup` | First-timers — guided step-by-step |
| **Express** | `/setup` + config block | Power users — paste everything at once |
| **Auto-Extract** | `/setup https://yoursite.com` | Fastest — extracts from your website or unstructured text |

Then build your first feature:

```
> Build [feature] for [product]
```

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

Run `/ship` to kick off the full pipeline. Gates are enforced by `tools/artifact/check-gate.sh` — you can't skip stages.

---

## What's Included

### 6 Agents

| Agent | Role |
|-------|------|
| **Orchestrator** | Routes tasks, enforces gates, approves releases |
| **Product** | Discovery, PRDs, prioritization, scope control |
| **Engineering** | Architecture, API design, implementation, deployment |
| **QA & Release** | Test plans, quality gates, release readiness |
| **Growth** | Launch strategy, SEO, activation, email lifecycle |
| **Ops & Risk** | Security, compliance, incidents, legal, finance |

### 44 Skills

| Category | Skills |
|----------|--------|
| Orchestration | workflow-router, ship, status, decision-memo-writer, conflict-resolver, ingest, system-maintenance, artifact-import, setup |
| Product | icp-positioning, prd-writer, sprint-prioritizer, feedback-synthesizer, discovery-validation |
| Engineering | architecture-draft, api-contract-designer, background-jobs, multi-tenancy, implementation-decomposer, observability-baseline, code-review, seed-data, deployment-strategy, instrumentation, feature-flags, user-docs, mobile-readiness |
| QA / Release | test-plan-generator, api-tester-playbook, release-readiness-gate, perf-benchmark-checklist, dogfood |
| Growth | positioning-messaging, landing-page-copy, seo-topic-map, channel-playbook, activation-onboarding, email-lifecycle |
| Risk / Legal | threat-modeling, privacy-data-handling, compliance-readiness, pricing-unit-economics, tos-privacy-drafting, incident-response |

### 23 Tool Scripts

| Tool | Purpose |
|------|---------|
| `validate.sh` | Checks artifact frontmatter + reference integrity |
| `promote.sh` | Enforces lifecycle ordering (draft → review → approved) |
| `link.sh` | Links parent/child artifacts bidirectionally |
| `check-gate.sh` | Stage gate checks (prd-to-rfc, rfc-to-impl, impl-to-qa, release) |
| `status-check.sh` | HTTP health checks for production services |
| `pre-deploy.sh` | Pre-deployment validation gate |
| `health-check.sh` | Validates all skills are discoverable |

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

---

## Content Model

| Category | Location | Author | Purpose |
|----------|----------|--------|---------|
| Configuration | `company.config.yaml` | User | Tech stack, API standards, conventions |
| Imports | `imports/` | User | Transient staging for `/artifact-import` |
| Standards | `standards/` | User | Permanent reference docs agents read continuously |
| Session Work | `tasks/` | Agent | Task tracking + accumulated learning |
| Deliverables | `artifacts/` | Agent | Lifecycle-managed outputs with audit trail |

---

## Token Costs

Company OS adds minimal overhead to Claude Code usage:

| What | Additional Tokens |
|------|------------------|
| Per session (CLAUDE.md auto-loaded) | ~1,900 |
| Per agent spawn (skills preloaded) | ~3,000–16,000 |
| Full feature (idea → shipped) | ~160,000–220,000 total |

See [TOKEN_COSTS.md](TOKEN_COSTS.md) for detailed breakdowns.

---

## Customization

- **Add skills**: Create `.claude/skills/<name>/SKILL.md`
- **Add agents**: Create `.claude/agents/<name>.md`
- **Add tools**: Create `tools/<category>/<name>.sh`
- **Modify artifact types**: Update `tools/artifact/validate.sh`
- **Change stage gates**: Update `tools/artifact/check-gate.sh`

After structural changes, run `/system-maintenance` to keep documentation in sync.

Full reference: [SETUP_COMPANY_OS.md](SETUP_COMPANY_OS.md) | [FAQ](FAQ.md) | [Roadmap](ROADMAP.md)

---

## Updating

To update Company OS to the latest version in an existing project:

```bash
curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh | bash -s -- --force
```

The `--force` flag overwrites existing Company OS files while preserving your `company.config.yaml` configuration.

---

## License

MIT
