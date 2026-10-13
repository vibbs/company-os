# Changelog

All notable changes to Company OS are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

**Version rules:**
- **MAJOR** — Breaking changes requiring user action (agent restructures, changed tool interfaces, new required config fields)
- **MINOR** — New agents, skills, tools, or non-breaking improvements
- **PATCH** — Bug fixes to existing scripts, typo corrections, documentation fixes

---

## [Unreleased]

---

## [1.12.0] - 2026-10-14

**Upgrade notes:** Edit skills and agents in `os/` from now on, then run `bash tools/build/build.sh`. Hand edits to `.claude/skills/` or `.claude/agents/` are overwritten by the build. Installing with `--runtime` for anything other than `claude` needs 1.12.0 or later; older releases ship only the Claude Code adapter. Existing installs keep their current `.company-os/docs/` files; the installer only adds docs that are missing.

### Added
- **Multi-runtime support.** Company OS now runs in Claude Code, Cursor, Codex CLI, Gemini CLI and Aider.
  - Generated adapters `AGENTS.md` (Codex, Aider, other AGENTS.md runtimes), `GEMINI.md`, `.cursor/rules/*.mdc` plus legacy `.cursorrules`, and `.codex/config.md`
  - A runtime-neutral skill and agent schema (`tools/build/schema/`) with `validate-skill.sh` and `validate-agent.sh`, run by `build.sh --check`
  - `os/` is the single authoring source (`os/skills/`, `os/agents/`, `os/playbooks/`, `os/hooks/`); `tools/build/build.sh` regenerates every adapter, including `.claude/`
  - `install.sh --runtime auto|all|core|claude|cursor|codex|gemini|aider` (comma-separated lists allowed; `auto` detects installed runtimes), plus `tools/registry/list-runtimes.sh` and `tools/registry/install-runtime.sh` to inspect and add adapters after install
- **New user docs** in `.company-os/docs/`: `CONCEPTS.md` (glossary, layers, artifacts, stage-aware gates, ship flow with your job at each gate), `CONFIG_REFERENCE.md` (every config section marked required or optional), `CUSTOMIZING.md` (edit `os/`, then build) and `TROUBLESHOOTING.md`
- **SVG diagrams** in `.company-os/docs/diagrams/` (system overview, agent org chart, ship flow, stage gates, artifact lineage, multi-runtime build, install and upgrade, workflow paths), embedded in the docs and installed with them
- **FAQ "Getting started" block**: cost, choosing a runtime, use without Claude Code, manual uninstall, customizing, upgrading, stages, troubleshooting
- **Tool hardening**: every tool script answers `-h` / `--help`; `validate.sh --all` checks every artifact; config is read through one helper (`tools/lib/config.sh`, `cfg_get`); `setup.sh --help`

### Changed
- `SETUP.md` is now a short quickstart (prerequisites, install, pick your runtime, `/setup`, verify, first `/ship`); reference material moved to the new docs above
- Skill and agent descriptions rewritten in plain language; key user-facing skills gained an overview and sample output
- Claude-only skill fields (`user-invokable`, `disable-model-invocation`, `argument-hint`) now live under `runtimes.claude:` in `os/skills/`; the build lifts them to the top level of the generated `.claude/` copy
- Authoring schema moved from `docs/superpowers/SCHEMA.md` to `.company-os/docs/SKILL_SCHEMA.md` (installed with the docs); the portability design spec moved to `docs/design/` and is marked Implemented
- `TOKEN_COSTS.md` re-measured for this release, with always-on cost per runtime; `ROADMAP.md` refreshed with a collapsed Shipped list
- `install.sh --help` lists `--runtime` in its header, adds examples and the docs link

### Fixed
- Docs used command names that do not exist: `/prototype` is `/rapid-prototype` and `/token-cost` is `/token-cost-ledger`
- Tool scripts no longer abort silently on an unmatched `grep`, reject missing flag values and unknown flags, and send errors to stderr
- `check-gate.sh` exits 2 when the artifact path does not exist
- Stale counts in the docs (now 64 skills, 9 agents, 33 tool scripts)
- `install.sh --check` and `--changelog` read the incoming version and changelog from `.company-os/` (they moved in v1.9.0), so they no longer report "unknown"; older template layouts still work
- `/upgrade-company-os rollback` now restores `os/` and tells you to run `bash tools/build/build.sh` to regenerate the other adapters
- `/setup` writes agent models to `os/agents/` and rebuilds, not to the generated `.claude/agents/`
- `/system-maintenance` audits the current docs (`CONCEPTS.md`, `CUSTOMIZING.md`, README) from `os/` and checks count drift
- `setup.sh --cleanup` and the `/setup` cleanup option keep the guides in `.company-os/docs/` (other files link to them) and remove only the example artifacts and standards
- `validate.sh` rejects unknown flags; `version-bump.sh` sends errors to stderr; `--since`, `--dir`, `--prd`, `--journey`, `--timeout` and `--expected-status` report a missing value

## [1.11.0] - 2026-05-27

### Added
- **Excalidraw skill** (`/excalidraw`, S-ENG-17) — Dual-format diagramming skill that produces architecture diagrams, data flow diagrams, ERDs, and system overviews in both Mermaid (inline) and Excalidraw JSON (standalone). Assigned to the Engineering Staff agent
- **6 architecture diagrams** in `docs/diagrams/` (agent-architecture, ship-flow, engineering-delegation, artifact-lineage, feedback-loop, workflow-router) generated by `docs/diagrams/generate.js`

### Changed
- **Engineering Staff agent**: 5 → 6 skills (added excalidraw)
- **architecture-draft** (Step 3) and **threat-modeling** (Step 2) skills now cross-reference the excalidraw skill for diagram production
- **Install documentation** simplified — README, SETUP.md, and setup skill now show a single `curl` installer path for both new and existing projects. Removed the obsolete `gh repo create --template --clone` instructions
- Skill count: 63 → 64

### Fixed
- Stale skill count in SETUP.md ("What Gets Installed" table) updated from 62 to 64

## [1.10.0] - 2026-03-17

### Added
- **GTM Sprint skill** (`/gtm-sprint`, S-GRO-09) — Time-boxed go-to-market sprint (7/14/21 days) that sequences customer validation, positioning, launch, and distribution with quantified decision gates. Inspired by the 100x GTM Playbook methodology. Includes LOI template, sprint plan/report artifacts, and stage-aware defaults
- **Mom-Test interview methodology** in `customer-conversations` — New `mom-test` conversation type with The Mom Test rules, question bank, anti-patterns, and enhanced debrief fields ($$ quantification, commitment signals)
- **Pain Matrix output** in `feedback-synthesizer` — Step 12 produces a Pain Matrix table (themes x $$ impact x urgency), quadrant classification (Build Now / Build Next / Quick Win / Monitor), and quotable quotes section for landing pages and pitch decks
- **Directory Blitz playbook** in `channel-playbook` — Master list of 19 SaaS directories with submission requirements, hook formulas using interview data, and submission tracking checklist
- **Build-in-Public arc** in `channel-playbook` — Structured 14-day content arc that turns a GTM sprint into a public narrative across Twitter/LinkedIn/communities
- **Competitor Poaching playbook** in `channel-playbook` — How to find competitor reviewers (G2, Capterra, Reddit), value-first outreach templates, and concierge migration offers
- **LOI artifact type** — `loi` added to `validate.sh` VALID_TYPES for Letter of Intent artifacts with structured template (commitment level, pilot terms, prospect context)
- **GTM/Market Validation** workflow type in Workflow Router — New classification that routes to Growth Agent GTM Sprint, skipping Engineering entirely
- **GTM Sprint Flow** section in CLAUDE.md — Documents the GTM Sprint as an alternative to `/ship` for market validation

### Changed
- **Growth Agent**: 8 → 9 skills (added gtm-sprint). New GTM Sprint behavioral rules for pre-product validation and LOI tracking
- **Orchestrator**: New delegation pattern for GTM/market validation ("Go to market", "GTM", "Validate market", "Find customers")
- **Workflow Router**: 9 → 10 classification types (added GTM / Market Validation with shortcut flow)
- Skill count: 62 → 63

## [1.9.0] - 2026-03-02

### Added
- **Weekly Review skill** (`/weekly-review`, S-ORG-13) — Weekly operating rhythm summarizing what shipped, AI spend, support themes, security health, and next priorities
- **Retrospective skill** (`/retrospective`, S-ORG-14) — Post-ship retrospective tracing artifact lineage, evaluating success metrics, and capturing structured lessons
- **Product-Led Growth skill** (`/product-led-growth`, S-GRO-08) — Free tier design, viral loops, referral programs, and in-product growth moments
- **Security Posture skill** (`/security-posture`, S-RISK-04) — Aggregated security health snapshot with tiered tool assessment and compliance gap tracking
- **Customer Conversations skill** (`/customer-conversations`, S-PROD-08) — Pre-call briefings, post-call debriefs, and insight routing to ICP/PRD evidence
- **Static Dashboard tool** (`tools/ops/dashboard.sh`, T-OPS-04) — Markdown/HTML output with Mermaid graph, gate readiness, and cost snapshot
- **Security Posture Check tool** (`tools/security/posture-check.sh`, T-SEC-04) — Tiered security scan aggregation
- **Growth Agent memory** (`.claude/agent-memory/growth/MEMORY.md`) — Persistent cross-session memory for Growth agent
- **Inbound Loop SOP** (`standards/ops/inbound-loop-sop.md`) — Customer signal → feedback → sprint → ship pipeline
- **Security Posture standard** (`standards/security/security-posture.md`) — Security posture assessment framework
- **Self-Improvement Loop enhancements** — Broader lesson triggers (self-noticed friction, not just corrections), lessons hygiene with ~20 entry cap and Archive section

### Changed
- **Orchestrator**: 12 → 15 skills (added conflict-resolver, weekly-review, retrospective)
- **Product Agent**: 7 → 8 skills (added customer-conversations)
- **Growth Agent**: 7 → 8 skills (added product-led-growth), added `memory: project`
- **Ops & Risk Agent**: 8 → 9 skills (added security-posture)
- **QA & Release Agent**: Added Write tool
- Skill count: 56 → 62
- Tool count: 28 → 31

### Fixed
- 49 system gap findings fixed across agents, skills, tools, and documentation (see REVIEW-SYSTEM-GAPS-2026-03-02.md)
- Missing `artifacts/product/`, `seeds/`, `standards/mobile/` directories created
- 3 decision memo artifacts missing required `author` field
- `pre-deploy.sh` Bash 4+ syntax (`${var,,}`) replaced with `tr` for macOS compat
- `link.sh` silent no-op when `parent:` field absent from frontmatter
- `post-write-artifact-check.sh` glob pattern now matches artifact subdirectories
- `search-skill.sh` GNU `-printf` replaced with portable alternative
- `jq` availability guard added to both PreToolUse and PostToolUse hooks
- `health-check.sh` now validates agent files
- `allowed-tools` removed from 31 skill frontmatters (invalid field for skills)
- Ingest skill mapping expanded from 4 to 12 standards directories
- CLAUDE.md, README.md, SETUP.md factual corrections

## [1.8.0] - 2026-03-01

### Added
- **COGS Token Cost Ledger** — Track AI token costs as Cost of Goods Sold. New `cogs/ai-ledger/` directory with JSONL append-only ledger, git-trackable cost history, and per-feature cost attribution
- **Token Ledger tool** (`tools/ops/token-ledger.sh`, T-OPS-03) — 5 subcommands: `log` (append entry with auto-cost calculation), `summary` (daily/weekly/monthly totals by category/model/agent), `feature-cost` (total cost to build a feature by PRD ID), `export` (JSONL→CSV), `budget` (spend vs budget with projected EOM)
- **Token Cost Ledger skill** (`/token-cost-ledger`, S-OPS-08) — User-invokable with `log | report | budget-check | feature-cost` argument hints. Routes to tool, adds optimization suggestions and unit economics cross-references
- **Token Cost Tracking standard** (`standards/ops/token-cost-tracking.md`) — Model cost rates (Claude, GPT, Gemini), cost categories, budget framework by stage, feature cost attribution rules, alert thresholds, optimization playbook, COGS expansion guide
- **Ship flow Step 7.5: Token Cost Logging** — Advisory (non-blocking) step after release summary. Suggests logging session cost with auto-populated `--feature` flag from the ship flow's PRD ID
- **Context Optimization section** in CLAUDE.md — Behavioral guidance to avoid reading `.company-os/`, `standards/brand/archetypes/`, and `cogs/*/entries.jsonl` during normal operations (loaded-on-demand by specific skills only)
- **`ai.cost_tracking_enabled`** and **`ai.cost_alert_threshold_percent`** config fields under `ai:` section
- `.gitignore` entries for COGS generated artifacts (`summary.md`, `export.csv` — regenerated from source data)

### Changed
- **Ops & Risk Agent**: 7 → 8 skills (added token-cost-ledger). New responsibility #6: Token Cost Tracking with behavioral rules for COGS monitoring, feature tagging, and budget alerts
- **Orchestrator**: 11 → 12 skills (added token-cost-ledger). New delegation pattern for cost queries ("Token costs" / "AI spend" / "COGS")
- **setup.sh** — Added `cogs/` and `cogs/ai-ledger/` directory scaffolding, `ai:` section to heredoc config template

### Removed
- **`Read(./.company-os/**)`** deny rule from both repo settings.json and setup.sh template — was breaking `/upgrade-company-os` which needs to read version, manifest, and changelog. Replaced with CLAUDE.md behavioral guidance (Context Optimization section)

## [1.7.0] - 2026-03-01

### Added
- **SessionStart hook** (`.claude/hooks/session-start.sh`) — Injects company name, stage, tech stack, branch, and recent lessons at every session start. Guards unconfigured projects with "Run /setup" message. ~100-200 tokens per session (fixed ceiling)
- **Persistent Agent Memory** — Engineering, QA & Release, and Product agents now have `memory: project` scope with seed MEMORY.md files at `.claude/agent-memory/<name>/MEMORY.md`. Project-scoped (version-controlled) so institutional knowledge ships with the repo
- **Memory Management sections** in Engineering, QA, and Product agent files with agent-specific guidance and guardrails (150-line cap, 5 topic files max, update-after-work discipline)
- **ROADMAP: Claude Code Platform Features** — Future adoption items: Modular Rules System (trigger: CLAUDE.md > 300 lines), Worktree Isolation for prototypes, Skill Model Selection for cost optimization (15-20% savings)

### Changed
- **CLAUDE.md** — Fixed rule numbering (sequential 1-9), updated Hooks section (2 → 3 hooks), added Key Files entries for SessionStart hook and agent memory
- **ROADMAP** — Updated current state counts (44 → 56 skills, 6 → 9 agents, 23 → 28 tools)
- **.gitignore** — Added `.claude/agent-memory-local/` for developers who prefer private (local-scope) memory
- Hook count: 2 → 3 (added SessionStart)


## [1.6.0] - 2026-02-28

### Added
- **AI Engineering skill** (`ai-engineering`) — LLM integration patterns, RAG architecture, prompt engineering, vector DB selection, AI cost optimization, and ethical AI checklist. New `ai:` config section and `standards/engineering/ai-patterns.md` reference doc
- **Experiment Framework skill** (`experiment-framework`) — Statistically rigorous A/B experiment design with sample size calculation, guardrail metrics, experiment state machine, and results analysis. New `experiments:` config section and `tools/qa/experiment-report.sh`
- **UX Research skill** (`ux-research`) — Lean user research with method selection, guerrilla interview scripts, usability testing protocols, journey mapping, persona development, and heuristic evaluation
- **Market Intelligence skill** (`market-intelligence`) — Competitive landscape scans, technology radar (ADOPT/TRIAL/ASSESS/HOLD), trend timing framework, and app store intelligence
- **Content Engine skill** (`content-engine`) — Multi-format content production, editorial calendars, content multiplication workflows, and performance tracking. New `standards/growth/content-strategy.md` and `standards/growth/platform-playbooks.md`
- **Test Intelligence skill** (`test-intelligence`) — Flaky test detection, coverage scoring, test pyramid balance, mutation testing guidance. New `tools/qa/test-health.sh`
- **Resilience Testing skill** (`resilience-testing`) — Failure mode catalogs, circuit breaker testing, latency injection, blast radius analysis. New `tools/qa/resilience-test.sh`
- **Support Operations skill** (`support-operations`) — FAQ generation, SLA tiers, escalation paths, de-escalation scripts, support-to-product feedback pipeline. New `support:` config section, `standards/ops/support-runbook.md`, `tools/ops/support-faq-check.sh`
- **Rapid Prototype skill** (`/rapid-prototype`) — Time-boxed MVP prototyping (4h/1d/3d sprints) for proof-of-concept and investor demos. Skips RFC, security review, and full QA
- **Release gate Bar 10: AI Safety** — Prompt injection protection, output filtering, cost guardrails, bias assessment. Triggers only when `ai.llm_provider` is set. Advisory in idea/mvp, enforced in growth/scale
- **Ship flow Step 5.95: Experiment Review** — Verifies experiment specs for features behind experiment flags (advisory, does not block)
- **Workflow Router: Prototype/Demo** — New classification type for time-boxed PoCs, routes to rapid-prototype skill
- **Brand Guidelines standard** (`standards/brand/brand-guidelines.md`) — Brand identity reference doc
- **Investor Reporting template** (`standards/ops/investor-reporting-template.md`) — Monthly investor update template

### Changed
- **Product Agent**: 5 → 7 skills (added ux-research, market-intelligence). New responsibilities for user research and market monitoring
- **Engineering Agent (Staff)**: 5 → 6 skills (added ai-engineering). Phase 1 architecture now includes AI/ML evaluation. Removed design-system from staff scope (frontend sub-agent only)
- **QA & Release Agent**: 7 → 9 skills (added experiment-framework, test-intelligence). New responsibilities for experimentation and test health
- **Engineering DevOps**: 4 → 5 skills (added resilience-testing). Stage-aware resilience verification before production launch
- **Growth Agent**: 6 → 7 skills (added content-engine). Content production as a formal responsibility
- **Ops & Risk Agent**: 6 → 7 skills (added support-operations). Customer support as 5th responsibility
- **Orchestrator**: 10 → 11 skills (added rapid-prototype). New delegation pattern for prototype/demo/PoC work
- **Pricing & Unit Economics**: Extended with MRR/ARR tracking, financial forecasting, runway monitoring, budget allocation, and investor reporting
- **Channel Playbook**: Platform deep-dives for Twitter/X, LinkedIn, Reddit, TikTok, Instagram, Product Hunt, Hacker News
- **Positioning & Messaging**: Brand identity section with voice matrix, personality traits, cross-platform harmonization
- **SEO Topic Map**: Pillar content strategy with content multiplication plans
- **Landing Page Copy**: Visual content guidance (hero specs, data visualization, presentation frameworks)
- **Design System**: Delight patterns — celebration moments, micro-interactions, easter eggs, shareable moments, sound design (mapped to archetype personality)
- **Mobile Readiness**: App Store Optimization — keyword research, metadata optimization, screenshot strategy, review management, A/B testing
- **Feature Flags**: Cross-reference to experiment-framework for experiment-type flags
- Tool count: 24 → 28 (added test-health.sh, resilience-test.sh, experiment-report.sh, support-faq-check.sh)
- Skill count: 47 → 56 (9 new skills)
- Config sections: 14 → 17 (added ai, experiments, support)
- Standards docs: ~15 → ~21 (6 new reference docs)

## [1.5.0] - 2026-02-28

### Added
- **Design Archetype System** — 6 design archetypes (Linear, Attio, Notion, Figma, Things 3, Framer) with comprehensive visual tokens, UX patterns, and ASCII wireframe previews in `standards/brand/archetypes/`
- **Universal UX Baseline** (`standards/brand/ux-baseline.md`) — Non-negotiable UX patterns every product must implement: empty states, loading skeletons, error handling, form validation, keyboard navigation, accessible contrast, responsive behavior
- **Design System skill** (`/design-system`) — User-invokable skill that runs archetype selection wizard on first use, generates project-specific design tokens, reviews code for design consistency violations
- **Setup wizard Step 5.7: Design & Brand** — 3-question matchmaking flow (product type, user priority, density) that scores and recommends archetypes with trait-led presentation and ASCII previews for users who may not know the reference products
- **Release gate Bar 9: Design Quality** — Checks UX baseline compliance, design token usage, responsive behavior, touch targets. Advisory in idea/mvp stages, enforced in growth/scale.
- **Config section**: `design:` in company.config.yaml — archetype, dark_mode, density, overrides

### Changed
- **Frontend Agent**: Now loads design context (archetype + UX baseline) before building any UI component. Design-system added as 4th skill (was 3 skills).
- **Engineering Agent**: Phase 6 (Self-Review) now includes design consistency check — verifies archetype token usage, UX baseline compliance
- **Dogfood skill**: Design inconsistencies (missing empty states, hardcoded colors, spinner instead of skeleton) elevated from LOW to MEDIUM severity
- **install.sh**: Scaffolds `standards/brand/archetypes/` directory on fresh install


## [1.4.0] - 2026-02-27

### Added
- **`.company-os/` directory consolidation** — All Company OS system files moved under `.company-os/`:
  - `.company-os/version` (was `.company-os-version`)
  - `.company-os/manifest` (was `.company-os-manifest`)
  - `.company-os/migrations/` (was `migrations/` — frees the name for app database migrations)
  - `.company-os/backup/` (was `.company-os-backup/`)
  - `.company-os/conflicts/` (was `.company-os-conflicts/`)
  - `.company-os/docs/` (template-only: CHANGELOG, SETUP, FAQ, TOKEN_COSTS, ROADMAP)
- **Read deny rule** for `.company-os/**` in settings.json — agents cannot read internal system files
- **Contextual post-upgrade output** — upgrade summary now shows conflict resolution steps, verification command, and a ready-to-run commit command

### Changed
- `install.sh` reads/writes all system files to `.company-os/` paths (backward-compatible with old paths during transition)
- Tool scripts (`pre-deploy.sh`, `version-bump.sh`, `check-gate.sh`) check `.company-os/version` first, fall back to `.company-os-version`
- `setup.sh --cleanup` handles both old and new doc paths
- `.gitignore` updated: `.company-os/backup/` and `.company-os/conflicts/` replace old entries
- Upgrade skill documentation updated with new path references

### Migration
- Automatic: v1.4.0 migration script moves all old-path files to `.company-os/` during upgrade
- No user action needed — backward-compatible readers handle both paths during transition

## [1.3.0] - 2026-02-27

### Added
- **Ship flow Step 5.8: Seed & Verify** — after implementation, presents start commands, per-service URLs, seed data commands, and key acceptance criteria as manual test flows. Reads ports from `.env`/`.env.example`
- **Framework Defaults Table** in dev-environment skill — 12 frameworks mapped to type, default port, start command, health path. Drives `.env.example` port generation and tool URL fallbacks
- **Multi-service port convention** — `SERVICE_PORT` pattern in `.env.example` (`API_PORT`, `WEB_PORT`, `EXPO_PORT`, `WORKER_PORT`). Service list derived from `tech_stack.framework` + `platforms.targets`
- **`seeds/` directory scaffolding** — created by `/setup` and `setup.sh` with `.gitkeep`
- **`artifacts/test-data/` scaffolding** — created by `/setup` and `setup.sh`
- **Seed scenarios in test plan generator** — Step 4.5 maps test types to seed scenarios with Test Data Requirements table
- **Seed data in perf benchmarks** — requires `high-volume` scenario before benchmarks
- **Advisory seed catalog check** in `impl-to-qa` gate — warns when no seed catalog found (never blocks)
- **Seed data required in dogfood** — promoted from "strongly recommended" to prerequisite failure

### Changed
- `contract-test.sh` reads port from `.env` → `.env.example` → framework defaults (was hardcoded `localhost:3000`)
- `dogfood.sh` falls back to env-derived URL when no URL argument provided
- `smoke-test.sh` falls back to env-derived URL when no URL argument provided
- `dev-environment` skill generates `SERVICE_PORT` vars in `.env.example` based on detected services
- Setup Next Steps expanded: dependency install, `/dev-environment`, seed data generation
- 4 agent files updated with port convention rules (backend, frontend, devops, qa-release)

## [1.2.0] - 2026-02-27

### Added
- **App Versioning System** — Stage-aware semantic versioning for user apps. Ship flow auto-determines bump type (MAJOR/MINOR/PATCH) from PRD and RFC context. New `tools/versioning/version-bump.sh` tool script detects version file (package.json, pyproject.toml, or VERSION), applies stage rules (idea/mvp stay at v0.x.x, growth/scale use v1.x.x+), updates CHANGELOG.md, and creates git tags
- **Version validation in release gate** — `check-gate.sh release` now validates app version exists, follows semver, and was bumped since last release
- **Version check in pre-deploy** — `pre-deploy.sh` adds Check 8 (Version Management) validating version file and bump status
- **Release Versioning bar** — Release-readiness-gate adds Bar 7 checking version file, semver format, bump status, changelog entry, and stage-appropriate version range
- **Setup version initialization** — `/setup` Step 8b initializes app version file (0.1.0 for idea/mvp, 1.0.0 for growth/scale) and creates app CHANGELOG.md

### Changed
- `install.sh` no longer copies `VERSION` or `CHANGELOG.md` to user projects — prevents conflicts with app version files. Company OS version tracking uses `.company-os-version` only
- Tool count: 23 → 24 (added version-bump.sh)
- Pre-deploy checks: 7 → 8 (added version management)
- Release-readiness bars: 7 → 8 (added Release Versioning, renumbered Dogfood to Bar 8)
- DevOps sub-agent: owns `tools/versioning/` directory
- Ship skill Step 6: includes version bump determination and execution
- Ship skill Step 7: includes version transition in release summary
- User-docs skill: changelog entries require version stamps, coordinate with version-bump.sh

## [1.1.0] - 2026-02-27

### Added
- **Post-ship "What's Next" suggestions** — Ship skill Step 8 scans PRD out-of-scope, RFC tech debt, decision memos, TODO/FIXME comments, and lessons to suggest 3-5 natural next builds after a ship cycle completes. Ephemeral output only (no artifact)
- **Dev Environment Generator** (`/dev-environment`) — New skill owned by DevOps sub-agent. Reads `tech_stack` from `company.config.yaml` and generates `infra/docker-compose.dev.yml`, `.env.example`, and `tools/dev/start.sh|stop.sh|reset.sh`. Supports multiple environments (dev, qa, production). Detects existing Docker Compose files and offers to review/merge
- **Agent Personas** — Optional `personas` section in `company.config.yaml` lets users give agents custom names (e.g., "Morgan" instead of "Engineering Agent"). All 9 agents, ship skill, and status skill are persona-aware. Names always display alongside functional role. Gender-neutral defaults suggested

### Changed
- Skill count: 45 → 46 (added dev-environment)
- DevOps sub-agent: 3 → 4 skills (added dev-environment), owns `infra/` and `tools/dev/`
- Ship skill: 7 → 8 steps (added Step 8: What's Next)
- Status skill: persona-aware agent references in recommendations
- All 9 agent files: persona loading in Context Loading section

## [1.0.0] - 2026-02-27

First versioned release. Establishes the baseline for all future upgrades.

### Added
- 45 skills across Product, Engineering, QA, Growth, Ops & Risk, and system management
- 9 agents: 6 top-level (Orchestrator, Product, Engineering, QA & Release, Growth, Ops & Risk) + 3 engineering sub-agents (Backend, Frontend, DevOps)
- 23 tool scripts for artifact validation, CI, QA, security, deployment, and registry
- Smart merge installer (`install.sh`) with `--force` flag for safe upgrades
- Engineering Agent restructured as Staff Engineer orchestrator with Task tool delegation to sub-agents
- Context7 library documentation lookup mandated before implementation
- Git commit standards integrated into CLAUDE.md and engineering agent
- Optimized agent model assignments for cost efficiency (opus for orchestrator/engineering, sonnet for sub-agents, haiku for lightweight tasks)
- Artifact enforcement chain: validate.sh → link.sh → promote.sh → check-gate.sh
- Stage-aware gating: `idea` stage makes gates advisory, `mvp` enforces core gates, `growth`/`scale` enforces all
- Setup wizard with interactive, express, and auto-extract modes
- Versioned upgrade system with dry-run, check, backup, manifest-based conflict detection, and `/upgrade-company-os` skill

### Migration
This is the baseline release. No migration needed.
