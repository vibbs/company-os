# Token Cost Reference

What Company OS adds to your AI token usage, and how to reduce it. Use it to estimate cost before you adopt the system.

All figures are measured from the files in this release at **about 4 characters per token** (typical for Markdown and YAML). Platform figures (what your runtime sends anyway) are estimates. To track what your sessions actually cost, use `/token-cost-ledger`, which logs spend to `cogs/ai-ledger/`.

> This is reference documentation for evaluating Company OS. After setup you can remove it with `bash setup.sh --cleanup` or the cleanup option in `/setup`.

---

## At a glance

| What you do | Extra tokens from Company OS | Notes |
|-------------|------------------------------|-------|
| Any Claude Code session | ~3,450 per session | `CLAUDE.md`, loaded automatically |
| Start one agent (Claude Code) | ~6,200 to ~32,200 per start | Agent instructions plus every skill in its `skills:` list; see [per-agent table](#per-agent-context-claude-code) |
| One feature through `/ship` | roughly 250,000 to 400,000 in total (input plus output) | Estimate; see [scenario](#scenario-one-feature-through-ship) |
| `/rapid-prototype` | well under a full `/ship` | Skips the design doc, security review, QA and launch stages |
| `/gtm-sprint` | about 23,000 to 25,000 of context each time the Growth or Product agent starts, spread over many short sessions | No engineering agents involved |

---

## Always-on cost by runtime

Each runtime loads a Company OS instruction file at the start of every session. Pick the row for your runtime.

| Runtime | File loaded every session | Characters | Tokens (approx.) |
|---------|---------------------------|-----------|------------------|
| Claude Code | `CLAUDE.md` | 13,793 | ~3,450 |
| Codex CLI, Aider, other AGENTS.md runtimes | `AGENTS.md` | 28,981 | ~7,250 |
| Gemini CLI | `GEMINI.md` | 29,248 | ~7,300 |
| Cursor | `.cursor/rules/00-company-os.mdc` (always applied) | 1,471 | ~370 |
| Cursor, when you work in `artifacts/`, `standards/` or `docs/` | `.cursor/rules/10-skills.mdc` (skill catalog) | 14,385 | ~3,600 |
| Cursor, legacy single-file mode | `.cursorrules` | 18,474 | ~4,600 |

`AGENTS.md` and `GEMINI.md` are larger than `CLAUDE.md` because they carry the full skill and agent catalog inline: those runtimes have no separate skill loader. `company.config.yaml` (~2,090 tokens) is read by agents when needed, not loaded every session.

Every runtime also sends its own system prompt and tool definitions. For Claude Code that is roughly 11,000 to 13,000 tokens per session whether or not Company OS is installed. That platform baseline is not Company OS overhead.

---

## Per-agent context (Claude Code)

When Claude Code starts an agent, the agent gets its own context: its instruction file plus the full text of every skill in its `skills:` list. Each agent start also carries a smaller platform system prompt (roughly 6,000 to 8,000 tokens).

| Agent | Agent file | Skills preloaded | Total |
|-------|-----------:|-----------------:|------:|
| Orchestrator | ~1,780 | 15 | **~32,200** |
| QA & Release | ~1,610 | 9 | **~19,700** |
| Growth | ~1,430 | 9 | **~18,300** |
| Engineering (staff) | ~3,050 | 6 | **~16,500** |
| Product | ~1,500 | 8 | **~15,600** |
| Ops & Risk | ~1,490 | 9 | **~15,200** |
| Engineering: Frontend | ~1,910 | 4 | **~13,800** |
| Engineering: DevOps | ~1,690 | 5 | **~13,300** |
| Engineering: Backend | ~1,460 | 4 | **~6,200** |

The largest skills are `setup` (~7,700, Orchestrator), `ship` (~4,900, Orchestrator), `gtm-sprint` (~4,300, Growth), `ai-engineering` (~4,000, Engineering), `design-system` (~3,900, Frontend), `excalidraw` (~3,500, Engineering) and `code-review` (~3,400, Engineering and QA).

The Orchestrator is the heaviest agent because it carries the one-time `setup` and `artifact-import` procedures plus the `ship` flow. Engineering is lighter than in earlier versions: the staff engineer keeps six skills and hands domain work to the Backend, Frontend and DevOps sub-agents, which each load only their own skills.

Other runtimes do not start separate agents. The agent "acts as" the role in the same session, and reads skill files only when it needs them.

---

## Scenario: one feature through `/ship`

You send a goal of about 15,000 tokens describing a feature in detail.

### First call (main session)

| Component | Tokens |
|-----------|--------|
| Claude Code platform baseline | ~11,000 |
| `CLAUDE.md` | ~3,450 |
| Your message | ~15,000 |
| **Total first call** | **~29,450** |

### Agent starts

| Step | Context at start (platform + agent) | Output |
|------|-------------------------------------|--------|
| Orchestrator routes the goal and plans | ~39,000 plus your message | ~2,000 to 3,000 |
| Product writes the PRD | ~23,000 | ~5,000 to 10,000 |
| Engineering writes the RFC | ~24,000 | ~5,000 to 10,000 |
| Ops & Risk reviews security | ~22,000 | ~2,000 to 4,000 |
| Engineering sub-agents build (Backend, Frontend, DevOps) | ~13,000 to ~21,000 each | depends on the feature |
| QA writes the test plan and QA report | ~27,000 | ~3,000 to 5,000 |
| Growth writes the launch brief | ~25,000 | ~2,000 to 4,000 |
| Tool calls, file reads and writes | ~10,000 to 30,000 | ~5,000 to 10,000 |

Adding these up gives **roughly 250,000 to 400,000 tokens** for one feature, input and output combined. The range is wide because the build stage depends on the feature, and agents often make several calls within one stage. Prompt caching in your runtime can lower the billed cost of repeated context considerably.

---

## Company OS versus plain Claude Code

| Metric | Plain Claude Code | With Company OS | Difference |
|--------|-------------------|-----------------|------------|
| Session overhead | ~11,000 (platform) | ~14,450 | **+~3,450** |
| Agent start overhead | ~6,000 to 8,000 (platform) | ~12,000 to ~40,000 | **+~6,200 to ~32,200** |
| What you get | You prompt manually | Agents, skills, tools, stage gates and artifact validation | Included in the difference |

---

## How to reduce costs

1. **Trim unused skills.** Remove skills you do not use from an agent's `skills:` list in `os/agents/<agent>.md`, then run `bash tools/build/build.sh`. Each removed skill saves its size on every start of that agent (roughly 500 to 7,700 tokens).
2. **Slim the Orchestrator after setup.** Removing `setup` and `artifact-import` from the Orchestrator once your project is configured saves about 9,800 tokens per Orchestrator start.
3. **Trim phase-specific sub-agent skills.** For example, drop `mobile-readiness` from Frontend if you do not target mobile, or `resilience-testing` from DevOps until you need failure testing.
4. **Use cheaper models where reasoning is light.** Set `models:` in `company.config.yaml` and the matching `model:` in `os/agents/<agent>.md` (Claude Code only). `haiku` is much cheaper per token than `sonnet` or `opus`.
5. **Skip the router for small tasks.** Ask the target agent directly instead of going through the Orchestrator; that saves one agent start.
6. **Merge small skills.** If an agent only uses part of a skill, move those steps into the agent body and drop the skill from its list.
7. **Use a lighter flow.** For early ideas, `/rapid-prototype` or `/gtm-sprint` costs far less than `/ship`, and `company.stage: idea` keeps gates advisory.
