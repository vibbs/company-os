# Company OS

Company OS adds a team of AI agents and a reviewed workflow (requirements, design, code, QA, launch) to your existing repo. It is for solo founders and small teams building SaaS products with Claude Code, Cursor, Codex CLI, Gemini CLI or Aider.

[Quickstart](#quickstart) · [Which flow?](#which-flow-should-i-use) · [Commands](#commands) · [How it works](#how-it-works) · [Install options](#install-options) · [Docs](#documentation) · [Glossary](#glossary)

![Company OS in your repo: agents decide what happens next, skills describe how to produce each document, tools run fixed checks, and artifacts are the handshake between them](.company-os/docs/diagrams/system-overview.svg)

You stay in control. Agents draft the documents and code; you review each one and approve before work moves to the next step. Version 1.12.0, [MIT licensed](LICENSE).

---

## Quickstart

You need `git` (a git repo is recommended), `curl` (or `wget`), `tar`, and one AI coding runtime. Full prerequisites are in the [setup guide](.company-os/docs/SETUP.md#1-prerequisites).

**1. Install** from your project root:

```bash
curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh | bash
```

Prefer to read the script first:

```bash
tmp=$(mktemp -d) && curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh -o "$tmp/install.sh"
less "$tmp/install.sh"
bash "$tmp/install.sh"
```

The script goes to a temporary folder, so it never overwrites a file in your project.

**2. Start your runtime and run setup.** The installer detects which runtimes you have and adds files for each.

| Runtime | What gets installed | What you type |
|---------|---------------------|---------------|
| Claude Code | `.claude/` (agents, skills, hooks, settings) | Run `claude`, then `/setup` |
| Cursor | `.cursor/rules/*.mdc`, `.cursorrules` | Open the folder in Cursor, then ask: "run the setup skill" |
| Codex CLI | `.codex/config.md` (Codex reads `AGENTS.md`) | Run `codex`, then ask: "run the setup skill" |
| Gemini CLI | `GEMINI.md` | Run `gemini`, then ask: "run the setup skill" |
| Aider | nothing extra; Aider reads `AGENTS.md` | Start Aider, then ask it to follow the setup skill in `AGENTS.md` |

Every install also gets the shared files: `os/`, `tools/`, `AGENTS.md`, `CLAUDE.md` and `company.config.yaml`.

`/setup` asks about your product and tech stack and fills in `company.config.yaml`. You can also hand it everything at once: a pasted config block, or a URL (`/setup https://yoursite.com`) to fill in what it can from your website. See [Configure with /setup](.company-os/docs/SETUP.md#4-configure-with-setup).

**3. Ship your first feature:**

```text
/ship Add password reset by email
```

`/ship` writes a plan, then pauses after each step so you can approve, ask for changes, or stop. Outside Claude Code, see [Commands](#commands) for how to run it.

No AI runtime yet? `bash .company-os/setup.sh` creates the folders and a blank `company.config.yaml` to fill in by hand. Stuck? See [Troubleshooting](.company-os/docs/TROUBLESHOOTING.md).

### Most used commands

| Command | What it does |
|---------|--------------|
| `/setup` | Configure Company OS for your project |
| `/ship` | Take a feature from idea to release, pausing at every gate |
| `/rapid-prototype` | Build a time-boxed proof of concept (4 hours, 1 day or 3 days) |
| `/gtm-sprint` | Test market demand in 7, 14 or 21 days, no code required |
| `/status` | See artifact counts, broken links and gate readiness (`--dashboard` for HTML) |
| `/artifact-import` | Bring in PRDs, specs and plans you already have |
| `/prd-writer` | Write a product requirements document on its own |
| `/code-review` | Review a pull request or files section by section |
| `/weekly-review` | Summarize what shipped, AI spend, risks and next priorities |
| `/upgrade-company-os` | Check for, preview, apply or roll back updates |

All 46 commands are listed under [Commands](#commands).

---

## Which flow should I use?

![Three entry points: /gtm-sprint to validate demand, /rapid-prototype to prove the tech, /ship to build and launch, followed by an inbound feedback loop](.company-os/docs/diagrams/workflow-paths.svg)

| Start with | When | You get | Time |
|------------|------|---------|------|
| `/gtm-sprint` | You are not sure anyone will pay | Ideal customer profile, interview notes, pain matrix, letters of intent, launch assets | 7, 14 or 21 days; no code |
| `/rapid-prototype` | You need a demo or proof of concept | A mini-PRD (3 acceptance criteria at most) and a working demo; skips the RFC, security review and QA | 4 hours, 1 day or 3 days |
| `/ship` | You know what to build | PRD, RFC, code, test plan, QA report and launch brief | One feature, every gate |

Not sure? Describe your goal in plain words. The workflow router picks the right path, such as a bug fix, a refactor or one of the three above.

---

## Commands

In **Claude Code**, every command below is a slash command: type `/` to see the list, or type the name (for example `/ship Add team invites`). In **Cursor, Codex CLI, Gemini CLI and Aider**, ask the agent to "run the *name* skill" (for example "run the prd-writer skill for team invites"); the catalog lives in `AGENTS.md`, `GEMINI.md` or `.cursor/rules/10-skills.mdc`. To search by keyword, run `./tools/registry/search-skill.sh <query>`.

There are 64 skills in total. The 46 below are meant to be run directly; the other 18 are used by agents during a flow (for example `api-contract-designer` and `feature-flags` during `/ship`).

<details open>
<summary><strong>Getting started</strong> (6)</summary>

| Command | Purpose | Arguments |
|---------|---------|-----------|
| `/setup` | Configures Company OS for your project: company.config.yaml, permissions and folders. | `[preset \| config block \| URL \| description]` |
| `/status` | Shows a summary of project artifacts: counts by status, broken links and stage gate readiness. | `[prd \| rfc \| qa \| all \| --dashboard]` |
| `/artifact-import` | Brings existing documents (PRDs, RFCs, API specs, test plans) into Company OS with frontmatter, a type and links. | `<file path or pasted content>` |
| `/ingest` | Scans standards/ and artifacts/ for new or changed files and suggests updates to skills and config. | `[standards \| artifacts \| both]` |
| `/upgrade-company-os` | Checks for, previews, applies or rolls back Company OS updates. | `[check \| preview \| apply \| rollback]` |
| `/system-maintenance` | Audits and syncs Company OS documentation after structural changes. | — |

</details>

<details open>
<summary><strong>Build & ship</strong> (6)</summary>

| Command | Purpose | Arguments |
|---------|---------|-----------|
| `/ship` | Takes a feature from idea to release (PRD, RFC, code, QA, launch assets), pausing at each quality gate for your review. | `<what you want to build>` |
| `/rapid-prototype` | Builds a time-boxed MVP (4 hours, 1 day or 3 days) for a proof of concept or demo, skipping the RFC, security review and full QA. | `<what you want to prototype>` |
| `/gtm-sprint` | Runs a 7, 14 or 21 day go-to-market (GTM) sprint: customer interviews, positioning, landing page and distribution, with go/no-go checkpoints. | `[plan \| status \| gate-check] [7 \| 14 \| 21]` |
| `/weekly-review` | Summarizes your week: what shipped, AI spend, support themes, security health and next priorities. | `[--save]` |
| `/retrospective` | Reviews a shipped feature: traces it from PRD to launch, compares results to goals and records lessons. | `<PRD ID or feature name>` |
| `/decision-memo-writer` | Writes a decision record with rationale, alternatives considered and consequences. | — |

</details>

<details>
<summary><strong>Product</strong> (7)</summary>

| Command | Purpose | Arguments |
|---------|---------|-----------|
| `/prd-writer` | Writes a product requirements document (PRD) with problem statement, acceptance criteria, success metrics and scope. | `<feature or problem to specify>` |
| `/icp-positioning` | Defines your ideal customer profile (ICP) and how your product is positioned against alternatives. | `<product or market>` |
| `/ux-research` | Plans lean user research: method choice, interview scripts, usability tests and journey maps. | — |
| `/customer-conversations` | Prepares briefings before customer calls and records what you learned afterward. | `[prep <type> \| debrief \| patterns]` |
| `/feedback-synthesizer` | Turns messy customer feedback into themes with supporting evidence and a ranked pain matrix. | — |
| `/sprint-prioritizer` | Ranks features and work items by impact, effort and risk. | — |
| `/market-intelligence` | Scans competitors, emerging technologies and market timing. | — |

</details>

<details>
<summary><strong>Engineering</strong> (6)</summary>

| Command | Purpose | Arguments |
|---------|---------|-----------|
| `/architecture-draft` | Writes a technical design doc (RFC) covering system boundaries, modules, data model and integrations. | `<PRD ID or feature to design>` |
| `/code-review` | Reviews code in sections (architecture, quality, tests, performance) with interactive feedback. | `<PR number or file paths>` |
| `/design-system` | Sets up and applies your visual design: tokens (colors, type, spacing), component guidance and UX patterns. | `[generate-tokens \| review \| reconfigure]` |
| `/dev-environment` | Generates Docker Compose files, .env.example and dev scripts from your tech stack. | `[dev \| qa \| production \| reset]` |
| `/seed-data` | Generates test seed data, fixtures and factories for normal, edge and empty scenarios. | `<PRD ID or entity name>` |
| `/excalidraw` | Draws architecture, data flow, database (ERD) and system diagrams as Mermaid text and Excalidraw files. | `[architecture \| data-flow \| erd \| sequence \| journey \| system-overview]` |

</details>

<details>
<summary><strong>Quality & release</strong> (4)</summary>

| Command | Purpose | Arguments |
|---------|---------|-----------|
| `/test-plan-generator` | Generates a test plan from a PRD's acceptance criteria. | — |
| `/dogfood` | Tests your product the way a real user would and logs issues with severity ratings. | `<app URL> [--prd <prd-id>]` |
| `/release-readiness-gate` | Runs the final pass/fail checklist and gives a release verdict. | `<feature or release name>` |
| `/experiment-framework` | Designs A/B experiments with sample size, guardrail metrics and results analysis. | — |

</details>

<details>
<summary><strong>Growth</strong> (8)</summary>

| Command | Purpose | Arguments |
|---------|---------|-----------|
| `/positioning-messaging` | Writes the product narrative and competitive differentiators for marketing and sales. | — |
| `/landing-page-copy` | Writes conversion-focused landing page copy, section by section. | `<product, feature or campaign>` |
| `/channel-playbook` | Creates a step-by-step marketing playbook for one acquisition channel such as LinkedIn, Twitter, email or Product Hunt. | — |
| `/content-engine` | Plans a content program: editorial calendar, content briefs and ways to reuse one piece across formats. | — |
| `/seo-topic-map` | Builds keyword clusters and an internal linking plan for search-driven content. | — |
| `/email-lifecycle` | Designs email sequences, templates and send triggers for onboarding, transactional and retention emails. | — |
| `/activation-onboarding` | Designs the first-run flow and experiments that get new users to their first moment of value. | — |
| `/product-led-growth` | Designs self-serve growth: free tier, viral loops, referrals and in-product growth moments. | `<product or growth goal>` |

</details>

<details>
<summary><strong>Ops & risk</strong> (9)</summary>

| Command | Purpose | Arguments |
|---------|---------|-----------|
| `/threat-modeling` | Analyzes data flows for security threats and proposes mitigations. | `[--quick]` |
| `/security-posture` | Summarizes open threats, scan status, compliance gaps and manual checkpoints into one security snapshot. | `[--full \| --quick \| --delta]` |
| `/privacy-data-handling` | Defines how personal data is retained, accessed and deleted. | — |
| `/compliance-readiness` | Checks your readiness for a lightweight SOC 2 security audit and lists the gaps. | — |
| `/tos-privacy-drafting` | Drafts outlines of your Terms of Service and Privacy Policy. | — |
| `/incident-response` | Creates incident runbooks, post-mortem templates and incident records. | — |
| `/support-operations` | Designs customer support: FAQs, response-time tiers (SLAs), escalation paths and a feedback loop to product. | — |
| `/pricing-unit-economics` | Analyzes pricing and unit economics: customer acquisition cost (CAC) versus lifetime value (LTV). | — |
| `/token-cost-ledger` | Tracks AI token usage and spend: logs entries, reports, checks budget and shows cost per feature. | `[log \| report \| budget-check \| feature-cost]` |

</details>

---

## How it works

### Three layers

| Layer | What it is | Lives in |
|-------|------------|----------|
| **Agents** | AI roles that decide what happens next: route, delegate, approve | `os/agents/` (9 agents) |
| **Skills** | Written procedures, templates and checklists for producing one kind of document or result | `os/skills/` (64 skills) |
| **Tools** | Shell scripts that run one fixed check or action, with no AI reasoning | `tools/` (33 scripts) |

Agents use skills to know what to produce and run tools to act. Skills may recommend a tool but never run one. Artifacts (the documents agents save under `artifacts/`) are the handshake between all three. More detail is in [Concepts](.company-os/docs/CONCEPTS.md#the-three-layers).

### Agents

Six top-level agents plus three engineering sub-agents. The Orchestrator and the Engineering lead run on a stronger reasoning model (`opus`); the rest use `sonnet`. To change an agent's model (Claude Code only), set `model:` in `os/agents/<agent>.md` and run `bash tools/build/build.sh`, or let `/setup` do both for you. The `models:` section in `company.config.yaml` records your choice.

| Agent | Role |
|-------|------|
| Orchestrator | Routes objectives, enforces gates, approves releases |
| Product | Discovery, PRDs, prioritization, scope control |
| Engineering | Staff engineer: architecture, task breakdown, delegation, code review |
| Engineering: Backend | API endpoints, data models, business logic, background jobs |
| Engineering: Frontend | UI components, responsive layouts, analytics events, user docs |
| Engineering: DevOps | Deployment pipelines, monitoring, feature flags, environments |
| QA & Release | Test plans, QA reports, release readiness verdict |
| Growth | Positioning, landing pages, channels, SEO, onboarding |
| Ops & Risk | Security, privacy, compliance, pricing, legal drafts, incidents |

<details>
<summary>Show every agent with its model and skills</summary>

![Agent org chart: each agent, the model it runs on and the skills it owns](.company-os/docs/diagrams/agent-org.svg)

</details>

### The ship flow

![The /ship pipeline: the Orchestrator plans; Product writes the PRD while Growth drafts the launch brief in parallel; Engineering writes the RFC while Ops & Risk models threats; Engineering builds while QA writes the test plan; then docs, seed and verify, and the QA report; then the release gate, release summary and what next](.company-os/docs/diagrams/ship-flow.svg)

`/ship` runs its steps in four phases: plan, build (PRD, RFC, implementation), verify (docs, seed and verify, QA report) and release. Some steps run in parallel: Growth drafts the launch brief once the PRD is approved, Ops & Risk writes the threat model alongside the RFC, and QA writes the test plan once the RFC is approved. After the build, it gives you start commands, service URLs and seed data so you can try the feature yourself before QA. The [step-by-step table](.company-os/docs/CONCEPTS.md#the-ship-flow) shows what you check at each pause.

### Stage-aware gates

A gate is a scripted check (`tools/artifact/check-gate.sh`) that must pass before work moves on. How strict gates are depends on `company.stage` in `company.config.yaml`:

![Stage-aware gates: at idea every gate only warns; at mvp the PRD and RFC gates block; at growth and scale every gate blocks](.company-os/docs/diagrams/stage-gates.svg)

| Stage | Means | Gate behavior |
|-------|-------|---------------|
| `idea` | Exploring; no real users | Every gate only warns |
| `mvp` | First version with early users | `prd-to-rfc` and `rfc-to-impl` block; `impl-to-qa` and `release` warn |
| `growth` | Paying customers, growing | Every gate blocks |
| `scale` | Established product, larger team | Every gate blocks |

If `stage` is empty, gates behave as `growth`. Start permissive and tighten as you grow by changing one line.

### Artifacts

![Artifact lineage: status moves from draft to review to approved; each artifact links to its parent and children through frontmatter; validate, link, promote and check-gate enforce the rules](.company-os/docs/diagrams/artifact-lineage.svg)

Every artifact starts with a YAML header (frontmatter) holding its `id`, `type`, `title`, `status`, `created` and `author`, plus optional links (`parent`, `children`, `depends_on`, `blocks`). Status moves `draft` → `review` → `approved` → `archived`. Four scripts in `tools/artifact/` keep this honest: `validate.sh` (add `--all` to check everything), `link.sh`, `promote.sh` and `check-gate.sh`. Six months from now, `artifacts/` tells you what was built, why, and which risks were accepted.

### Hooks (Claude Code only)

Three hooks run automatically with no model calls. The session-start hook adds a few lines of context to each session. The two artifact hooks need `jq`.

| Hook | When | What it does |
|------|------|--------------|
| `session-start.sh` | A session starts | Shows company, stage, tech stack, branch and recent lessons |
| `pre-promote-validate.sh` | Before `promote.sh` runs | Validates the artifact and blocks the promotion if it is invalid |
| `post-write-artifact-check.sh` | After a file in `artifacts/` is written | Warns if the YAML header is missing |

### Feature support by runtime

| Feature | Claude Code | Cursor, Codex CLI, Gemini CLI, Aider |
|---------|-------------|--------------------------------------|
| Agents, skills, tools, artifacts, gates | Yes | Yes (skills are read from the catalog in `AGENTS.md`, `GEMINI.md` or `.cursor/rules/`) |
| Slash commands such as `/ship` | Yes | No: see [Commands](#commands) |
| Automatic hooks | Yes | No |
| Per-agent memory (`.claude/agent-memory/`) | Yes | No |
| Per-agent model choice (`models:` in config) | Yes | No: the runtime uses its own model setting |

---

## Why Company OS

- **Checks are scripts, not prompts.** Gates, validation and status changes run as shell scripts with exit codes, so they behave the same in every runtime and every session.
- **You approve every step.** The flow pauses after each artifact. Nothing reaches the next step without your go-ahead (or, at `idea` stage, without you seeing the warning).
- **The paper trail is the product.** PRDs, RFCs, threat models and QA reports are linked documents in your repo, so decisions survive past the chat session.
- **Configuration, not prompt editing.** `company.config.yaml` sets your tech stack, API conventions, branching, models and budgets; agents read it before they act.
- **Costs are visible.** AI token spend is tracked as COGS in `cogs/ai-ledger/`, and the per-session overhead is published in [Token costs](.company-os/docs/TOKEN_COSTS.md).
- **It sits beside your code.** Company OS adds its own folders and files. It does not modify your application code, existing CI or git history.

---

## Install options

Pass flags after `bash -s --` when piping, or after the script path (`bash "$tmp/install.sh" --force`). Run the script with `--help` for the same list.

| Flag | What it does |
|------|--------------|
| `--runtime <names>` | Runtimes to install adapters for (default `auto`). Values: `claude`, `cursor`, `codex`, `gemini`, `aider`, `all`, `auto`, `core`. Combine with commas: `--runtime claude,cursor` (or `--runtime=claude,cursor`). `auto` detects installed runtimes; `all` installs every adapter; `core` installs shared files only. |
| `--force` | Update existing Company OS files (keeps your config and edits) |
| `--branch <name>` | Use a specific branch (default `main`) |
| `--version <X.Y.Z>` | Install a specific release, for example `--version 1.12.0` |
| `--dry-run` | Preview what would change without writing anything |
| `--check` | Check whether an upgrade is available (run from an existing install) |
| `--changelog` | Show the changelog since the installed version (run from an existing install) |
| `--backup` | Back up Company OS files before upgrading (automatic for major upgrades) |
| `-h`, `--help` | Show help |

```bash
# Claude Code and Cursor only
curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh | bash -s -- --runtime claude,cursor

# Pin a release instead of tracking main
curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh | bash -s -- --version 1.12.0
```

Runtimes other than Claude Code need version 1.12.0 or later, so do not pin an older release with `--runtime cursor`, `codex`, `gemini` or `aider`.

Add a runtime later with `./tools/registry/install-runtime.sh <runtime>`. See what is installed with `./tools/registry/list-runtimes.sh`. If you already have `.claude/settings.json`, the installer merges the Company OS permissions into it and adds the hooks if you have none (this needs `python3`).

### What gets installed

| Path | What it is |
|------|------------|
| `os/` | Source of truth for skills and agents |
| `tools/` | Tool scripts by category, plus `build/` and `lib/` |
| `AGENTS.md`, `CLAUDE.md` | Instructions for the runtimes |
| `company.config.yaml` | Your settings |
| `.company-os/` | Version, install manifest, backups and the user docs |
| `.claude/`, `.cursor/` and `.cursorrules`, `.codex/`, `GEMINI.md` | Runtime adapters, only for the runtimes you install |
| `standards/` | Reference standards that agents read (design archetypes, UX baseline, operating procedures, security posture). Added only when missing, then yours to edit |
| `artifacts/`, `imports/`, `seeds/`, `tasks/` | Working folders for your documents, files to import, test data, and task notes (`todo.md`, `lessons.md`) |

The full tree is in [Where things live](.company-os/docs/CONCEPTS.md#where-things-live).

![Install and upgrade: install.sh detects your runtimes, installs os/, AGENTS.md and the matching adapters; /upgrade-company-os checks, previews, applies or rolls back](.company-os/docs/diagrams/install-upgrade.svg)

### Updating

Check your installed version in `.company-os/version`. In Claude Code:

```text
/upgrade-company-os            # check for updates
/upgrade-company-os preview    # preview changes
/upgrade-company-os apply      # run the upgrade
/upgrade-company-os rollback   # restore from backup
```

From a terminal:

```bash
# Download, read, preview, then apply
tmp=$(mktemp -d) && curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh -o "$tmp/install.sh"
less "$tmp/install.sh"
bash "$tmp/install.sh" --force --dry-run
bash "$tmp/install.sh" --force

# Or pin a release instead of taking the latest
bash "$tmp/install.sh" --force --version 1.12.0
```

Upgrades keep your config, permissions, artifacts, agent memory and the adapters your project already has. The installer compares your copy of each file with the template copy you last received and the new one:

- If you edited a file and the template did not change it, your file stays.
- If you both changed it, a plain upgrade keeps yours and lists it. With `--force`, it saves your copy (`.user`) and the new one (`.new`) under `.company-os/conflicts/` in the same folder path (for example `.company-os/conflicts/tools/qa/run.sh.user` and `run.sh.new`), then installs the new one. Merge them by hand. An earlier copy is never overwritten: a later one gets a timestamp suffix.
- The guides in `.company-os/docs/` belong to the template and are refreshed; if you edited one, your copy is kept next to it as `<name>.user`.
- Installs from 1.11 or earlier have no manifest, so the installer cannot tell your edits from template changes. It makes a backup first. Without `--force` it only previews. With `--force` it saves every differing file as `.user` before replacing it.

Major upgrades, installs with no manifest, and runs with `--backup` save a backup in `.company-os/backup/` first.

### Uninstalling

There is no uninstall script. Delete the files the installer added and keep the folders that hold your own work (`artifacts/`, `standards/`, `imports/`, `tasks/`, `seeds/`, `cogs/`, `.claude/agent-memory/`). If you had your own `CLAUDE.md`, `.claude/settings.json` or `tools/` before installing, remove only the Company OS parts. The [FAQ](.company-os/docs/FAQ.md#how-do-i-uninstall-company-os) has the exact list.

---

## Customizing

**Edit `os/`, then run `bash tools/build/build.sh`.** Files in `.claude/agents/`, `.claude/skills/`, `.cursor/`, `.codex/`, `AGENTS.md` and `GEMINI.md` are generated adapters; the build overwrites hand edits to them.

![Multi-runtime build: os/skills and os/agents are validated, then build.sh generates .claude/, AGENTS.md, GEMINI.md, .cursor/rules and .codex/](.company-os/docs/diagrams/multi-runtime-build.svg)

| To | Do this |
|----|---------|
| Change or add a skill | Edit or create `os/skills/<name>/SKILL.md`, then run the build |
| Change or add an agent | Edit or create `os/agents/<name>.md`, then run the build |
| Add a tool | Create `tools/<category>/<name>.sh` |
| Add an artifact type | Update `tools/artifact/validate.sh` |
| Change gate rules | Update `tools/artifact/check-gate.sh` |
| Teach agents your house rules | Add documents to `standards/`, then run `/ingest` |

After structural changes, run `/system-maintenance` to keep the docs in sync. Step-by-step guides are in [Customizing](.company-os/docs/CUSTOMIZING.md); the frontmatter schema is in [SKILL_SCHEMA.md](.company-os/docs/SKILL_SCHEMA.md).

---

## Token costs

Company OS adds an instruction file to every session (about 3,450 tokens in Claude Code) and each agent loads its own skills when it starts. A full `/ship` run is an estimated 250,000 to 400,000 tokens. Per-runtime and per-agent numbers, and ways to cut them, are in [Token costs](.company-os/docs/TOKEN_COSTS.md). Log real spend with `/token-cost-ledger`.

---

## Documentation

| Guide | Read it when |
|-------|--------------|
| [Setup](.company-os/docs/SETUP.md) | Installing and shipping your first feature (about 10 minutes) |
| [Concepts](.company-os/docs/CONCEPTS.md) | You want to understand agents, artifacts, gates and runtimes |
| [Config reference](.company-os/docs/CONFIG_REFERENCE.md) | You are editing `company.config.yaml` |
| [Customizing](.company-os/docs/CUSTOMIZING.md) | You want to change skills, add agents or teach your standards |
| [Troubleshooting](.company-os/docs/TROUBLESHOOTING.md) | Something failed |
| [FAQ](.company-os/docs/FAQ.md) | Cost, runtimes, upgrading, uninstalling, and deep dives |
| [Token costs](.company-os/docs/TOKEN_COSTS.md) | You want to estimate or reduce AI spend |
| [Roadmap](.company-os/docs/ROADMAP.md) | You want to know what is planned |
| [Changelog](.company-os/docs/CHANGELOG.md) | You are upgrading |
| [Skill schema](.company-os/docs/SKILL_SCHEMA.md) | You are writing a skill or agent |
| [Diagrams](docs/diagrams/README.md) | You want to regenerate the diagrams on this page |
| [Contributing](CONTRIBUTING.md) | You want to change Company OS itself |
| [Security](SECURITY.md) | You found a vulnerability |

Found a bug or have a question? [Open an issue](https://github.com/vibbs/company-os/issues).

---

## Glossary

| Term | Meaning |
|------|---------|
| **Agent** | An AI role that decides what happens next, such as Product or QA & Release |
| **Skill** | A written procedure with templates and checklists; in Claude Code you run it as `/name` |
| **Tool** | A shell script in `tools/` that performs one fixed action, with no AI reasoning |
| **Artifact** | A document an agent produces, saved under `artifacts/` with a YAML header |
| **Gate** | A scripted check that must pass before work moves to the next step |
| **Stage** | Your company's maturity (`idea`, `mvp`, `growth`, `scale`); it decides which gates block |
| **Runtime** | The AI coding tool you work in: Claude Code, Cursor, Codex CLI, Gemini CLI or Aider |
| **Adapter** | The runtime-specific files generated from `os/`; never edit them by hand |
| **PRD / RFC** | Product requirements document / technical design doc ("request for comments") |
| **COGS** | Cost of goods sold; Company OS tracks AI token spend as COGS |

The full glossary is in [Concepts](.company-os/docs/CONCEPTS.md#glossary).

---

## License

[MIT](LICENSE)
