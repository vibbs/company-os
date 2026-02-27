# Token Cost Reference

This document details the token overhead of running Company OS with Claude Code. Use it to estimate costs before adopting the system.

All estimates use the approximation: **~4 characters = 1 token** (for mixed markdown/YAML content).

> **Note**: This is template documentation — a reference for evaluating Company OS before adoption. After setup, you can safely remove this file with `bash setup.sh --cleanup` or during `/setup`.

---

## Baseline: What Claude Code Always Sends

Every Claude Code session — with or without Company OS — includes a system prompt with tool schemas, behavioral rules, and environment info. This is **not** Company OS overhead; it's the platform cost.

| Component | Estimated Tokens |
|-----------|-----------------|
| Claude Code system prompt (tool schemas, rules, environment) | ~10,000-12,000 |
| MCP tool definitions (if configured) | ~500 |
| Installed skill registry descriptions | ~800-1,000 |
| **Platform baseline** | **~11,000-13,000** |

This baseline exists whether you use Company OS or a blank project.

---

## Company OS Overhead

### Main Session (auto-loaded every session)

| File | Characters | Tokens |
|------|-----------|--------|
| `CLAUDE.md` | 7,586 | ~1,897 |
| **Company OS delta** | | **~1,897** |

`company.config.yaml` (~457 tokens) is read on-demand by agents, not auto-loaded.

### Per-Agent Context (loaded when an agent is spawned)

Each agent gets its own context window with the agent definition + all preloaded skills from its `skills:` list.

| Agent | Agent File | Skills Preloaded | Total Tokens |
|-------|-----------|-----------------|-------------|
| **Orchestrator** | 907 | workflow-router (1,198), decision-memo-writer (356), release-readiness-gate (1,430), ingest (1,296), system-maintenance (962), artifact-import (1,888), setup (2,826) | **10,863** |
| **Engineering** | 723 | architecture-draft (1,366), api-contract-designer (1,208), background-jobs (370), multi-tenancy (406), implementation-decomposer (470), observability-baseline (484), code-review (~2,800), seed-data (~1,800), deployment-strategy (~500), instrumentation (~500), feature-flags (~500), user-docs (~500), mobile-readiness (~500) | **~12,127** |
| **QA & Release** | 545 | test-plan-generator (454), api-tester-playbook (469), release-readiness-gate (1,430), perf-benchmark-checklist (437), code-review (~2,800), seed-data (~1,800), dogfood (~2,200) | **~10,135** |
| **Ops & Risk** | 612 | threat-modeling (439), privacy-data-handling (486), compliance-readiness (481), pricing-unit-economics (487), tos-privacy-drafting (616), incident-response (~500) | **~3,621** |
| **Growth** | 571 | positioning-messaging (408), landing-page-copy (514), seo-topic-map (484), channel-playbook (507), activation-onboarding (472), email-lifecycle (~500) | **~3,456** |
| **Product** | 544 | icp-positioning (366), prd-writer (1,380), sprint-prioritizer (439), feedback-synthesizer (380), discovery-validation (~470) | **~3,579** |

Each spawned agent also receives a smaller Claude Code system prompt (~6,000-8,000 tokens).

**Note**: Engineering is now the heaviest agent (~12,127 tokens) due to its 13 preloaded skills, followed by the Orchestrator (~10,863) and QA & Release (~10,135). The Engineering agent's weight reflects its broad scope: architecture, API design, deployment, instrumentation, feature flags, mobile readiness, and documentation. The Orchestrator includes large setup and artifact-import procedures (rarely needed after initial setup). The QA agent includes code-review, seed-data, and dogfood skills for comprehensive quality assurance. For day-to-day feature work, consider trimming skills from agent `skills:` lists that aren't needed for the current flow — each skill saves 350-2,800 tokens per agent spawn.

---

## Realistic Scenario: "Build a Feature End-to-End"

User sends a 15,000-token goal message describing a feature with detailed requirements.

### First API call (main session)

| Component | Tokens |
|-----------|--------|
| Claude Code platform baseline | ~11,000 |
| CLAUDE.md (auto-loaded) | ~1,897 |
| Your message | ~15,000 |
| **Total first call** | **~27,897** |

### Agent delegation chain

| Step | Input Tokens | Output Tokens |
|------|-------------|--------------|
| Orchestrator routes the goal | ~24,000 | ~2,000-3,000 |
| Product Agent produces PRD | ~18,000 | ~5,000-10,000 |
| Engineering Agent produces RFC | ~20,000 | ~5,000-10,000 |
| Ops & Risk Agent reviews | ~16,000 | ~2,000-4,000 |
| QA Agent produces test plan | ~18,000 | ~3,000-5,000 |
| Tool calls, file reads/writes | ~10,000-30,000 | ~5,000-10,000 |

### Estimated total for one feature through the full ship flow

**~160,000-220,000 tokens** (input + output combined)

For a 10-feature milestone: **~1.6M-2.2M tokens** (with some efficiency from context reuse within sessions).

---

## Company OS vs Plain Claude Code

| Metric | Plain Claude Code | With Company OS | Delta |
|--------|------------------|-----------------|-------|
| Main session overhead | ~11,000 (platform) | ~12,897 (+CLAUDE.md) | **+1,897** |
| Agent spawn overhead | ~6,000-8,000 (platform) | ~9,000-24,000 (+skills) | **+3,000-16,000** |
| Structure and enforcement | None — you prompt manually | 6 agents, 44 skills, 23 tools, stage gates, artifact validation | Included in delta |

The cost of Company OS is ~1,897 tokens per session + ~3,000-16,000 tokens per agent spawn. In exchange, you get structured workflows, enforced quality gates, and consistent artifact production.

---

## How to Reduce Costs

1. **Trim unused skills**: Remove skills from agent `skills:` lists that you don't use. Each skill saves 350-2,800 tokens per agent spawn.

2. **Trim phase-specific Engineering skills**: The Engineering agent now loads 13 skills (~12,127 tokens) — the heaviest agent. Several skills are phase-specific and can be removed when not needed: `deployment-strategy` (only needed at deploy time), `mobile-readiness` (only needed if targeting mobile platforms), `user-docs` (only needed when producing end-user documentation), `instrumentation` (only needed when adding telemetry). Removing all four saves ~2,000 tokens per Engineering spawn.

3. **Use `model: haiku` for lightweight agents**: Set `model: haiku` in agent frontmatter for agents doing simple routing or review. Haiku is significantly cheaper per token.

4. **Reduce orchestrator hops**: For simple tasks, invoke the target agent directly instead of routing through the Orchestrator (saves one agent spawn).

5. **Slim the Orchestrator after setup**: Remove `setup` and `artifact-import` from the Orchestrator's skills list after initial project setup — saves ~4,700 tokens per Orchestrator spawn.

6. **Consolidate small skills**: If you only use parts of a skill, merge the relevant procedures into the agent body and remove the skill reference.

7. **Skip unnecessary gates**: For prototyping (stage: `idea` or `mvp`), you can simplify the ship flow by skipping intermediate agents. The system is designed to scale up as your project matures.
