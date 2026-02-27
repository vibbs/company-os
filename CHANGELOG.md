# Changelog

All notable changes to Company OS are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

**Version rules:**
- **MAJOR** — Breaking changes requiring user action (agent restructures, changed tool interfaces, new required config fields)
- **MINOR** — New agents, skills, tools, or non-breaking improvements
- **PATCH** — Bug fixes to existing scripts, typo corrections, documentation fixes

---

## [Unreleased]

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
