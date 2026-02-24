# Token Cost Reference

This document details the token overhead of running Company OS with Claude Code. Use it to estimate costs before adopting the system.

All estimates use the approximation: **~4 characters = 1 token** (for mixed markdown/YAML content).

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
| `CLAUDE.md` | 5,537 | ~1,400 |
| **Company OS delta** | | **~1,400** |

`company.config.yaml` (~457 tokens) is read on-demand by agents, not auto-loaded.

### Per-Agent Context (loaded when an agent is spawned)

Each agent gets its own context window with the agent definition + all preloaded skills from its `skills:` list.

| Agent | Agent File | Skills Preloaded | Total Tokens |
|-------|-----------|-----------------|-------------|
| **Orchestrator** | 794 | workflow-router (1,198), decision-memo-writer (356), release-readiness-gate (1,159), ingest (1,296), system-maintenance (962) | **5,765** |
| **Engineering** | 723 | architecture-draft (1,370), api-contract-designer (1,208), background-jobs (370), multi-tenancy (406), implementation-decomposer (470), observability-baseline (484) | **5,031** |
| **QA & Release** | 545 | test-plan-generator (454), api-tester-playbook (469), release-readiness-gate (1,159), perf-benchmark-checklist (437) | **3,064** |
| **Ops & Risk** | 612 | threat-modeling (439), privacy-data-handling (486), compliance-readiness (481), pricing-unit-economics (487), tos-privacy-drafting (616) | **3,121** |
| **Growth** | 571 | positioning-messaging (408), landing-page-copy (514), seo-topic-map (484), channel-playbook (507), activation-onboarding (472) | **2,956** |
| **Product** | 544 | icp-positioning (366), prd-writer (1,126), sprint-prioritizer (439), feedback-synthesizer (380) | **2,855** |

Each spawned agent also receives a smaller Claude Code system prompt (~6,000-8,000 tokens).

---

## Realistic Scenario: "Build a Feature End-to-End"

User sends a 15,000-token goal message describing a feature with detailed requirements.

### First API call (main session)

| Component | Tokens |
|-----------|--------|
| Claude Code platform baseline | ~11,000 |
| CLAUDE.md (auto-loaded) | ~1,400 |
| Your message | ~15,000 |
| **Total first call** | **~27,000** |

### Agent delegation chain

| Step | Input Tokens | Output Tokens |
|------|-------------|--------------|
| Orchestrator routes the goal | ~20,000 | ~2,000-3,000 |
| Product Agent produces PRD | ~18,000 | ~5,000-10,000 |
| Engineering Agent produces RFC | ~20,000 | ~5,000-10,000 |
| Ops & Risk Agent reviews | ~16,000 | ~2,000-4,000 |
| QA Agent produces test plan | ~18,000 | ~3,000-5,000 |
| Tool calls, file reads/writes | ~10,000-30,000 | ~5,000-10,000 |

### Estimated total for one feature through the full ship flow

**~150,000-200,000 tokens** (input + output combined)

For a 10-feature milestone: **~1.5M-2M tokens** (with some efficiency from context reuse within sessions).

---

## Company OS vs Plain Claude Code

| Metric | Plain Claude Code | With Company OS | Delta |
|--------|------------------|-----------------|-------|
| Main session overhead | ~11,000 (platform) | ~12,400 (+CLAUDE.md) | **+1,400** |
| Agent spawn overhead | ~6,000-8,000 (platform) | ~9,000-14,000 (+skills) | **+3,000-6,000** |
| Structure and enforcement | None — you prompt manually | 6 agents, 29 skills, 20+ tools, stage gates, artifact validation | Included in delta |

The cost of Company OS is ~1,400 tokens per session + ~3,000-6,000 tokens per agent spawn. In exchange, you get structured workflows, enforced quality gates, and consistent artifact production.

---

## How to Reduce Costs

1. **Trim unused skills**: Remove skills from agent `skills:` lists that you don't use. Each skill saves 350-1,300 tokens per agent spawn.

2. **Use `model: haiku` for lightweight agents**: Set `model: haiku` in agent frontmatter for agents doing simple routing or review. Haiku is significantly cheaper per token.

3. **Reduce orchestrator hops**: For simple tasks, invoke the target agent directly instead of routing through the Orchestrator (saves one agent spawn).

4. **Consolidate small skills**: If you only use parts of a skill, merge the relevant procedures into the agent body and remove the skill reference.

5. **Skip unnecessary gates**: For prototyping (stage: `idea` or `mvp`), you can simplify the ship flow by skipping intermediate agents. The system is designed to scale up as your project matures.
