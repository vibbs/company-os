# FAQ

Short answers to the questions new users ask first, then deep dives on what Company OS handles well, where coverage is partial, and what you need to bring yourself. Terms are defined in the [glossary](CONCEPTS.md#glossary).

---

## Getting started

### What does Company OS cost?

Company OS itself is free and open source (MIT); you pay only for the AI runtime and model usage you already have.

- In Claude Code, `CLAUDE.md` adds roughly 3,450 tokens to every session, and each agent adds its instructions and skills when it starts.
- A full `/ship` run uses far more than a normal chat because several agents each do a stage of work.
- [TOKEN_COSTS.md](TOKEN_COSTS.md) has the breakdown and ways to cut it. `/token-cost-ledger` logs what your sessions actually cost.

### Which runtime should I use?

Use Claude Code if you can: it is the only runtime with slash commands, automatic hooks and per-agent memory.

| Runtime | Works? | What you lose compared with Claude Code |
|---------|--------|------------------------------------------|
| Claude Code | Full support | Nothing |
| Cursor | Yes, via `.cursor/rules/` | Slash commands, hooks, agent memory, per-agent models |
| Codex CLI | Yes, via `AGENTS.md` | Same as Cursor |
| Gemini CLI | Yes, via `GEMINI.md` | Same as Cursor |
| Aider | Yes, via `AGENTS.md` | Same as Cursor |

The installer detects which ones you have. See [SETUP.md](SETUP.md#2-pick-your-runtime).

### Can I use it without Claude Code?

Yes: install with `--runtime cursor`, `codex`, `gemini` or `aider` and ask the agent to "run the *name* skill" wherever the docs say `/name`.

The agents, skills, tools, artifacts and gates all work the same. The gates are shell scripts, so they behave identically everywhere. Without any AI runtime, `bash setup.sh` scaffolds the folders and a blank config for you to fill in by hand.

### How do I uninstall Company OS?

There is no uninstall script; delete the files the installer added, keeping anything that holds your own work.

| Remove | Notes |
|--------|-------|
| `os/`, `.company-os/` | Company OS source, version, manifest, backups and these docs |
| `tools/` | Company OS scripts. If you had your own `tools/` folder before installing, delete only `analytics/`, `artifact/`, `build/`, `ci/`, `db/`, `deploy/`, `lib/`, `ops/`, `qa/`, `registry/`, `security/` and `versioning/` inside it |
| `AGENTS.md`, `GEMINI.md`, `.cursorrules`, `.cursor/rules/00-company-os.mdc`, `10-skills.mdc`, `20-agents.mdc`, `.codex/` | Runtime adapters (only the ones that were installed exist) |
| `.claude/agents/`, `.claude/skills/`, `.claude/hooks/` | Claude Code adapter. If you had your own agents, skills or hooks there, keep those files |
| `.claude/settings.json` | The installer merged permissions and hooks into it. Delete it if Company OS created it; otherwise remove the Company OS allow rules and the `hooks` block |
| `CLAUDE.md` | If Company OS created it, delete it. If you already had one, delete everything from `## Company OS Overview` to the end |
| `company.config.yaml` | Your settings |
| `artifacts/`, `standards/`, `imports/`, `tasks/`, `seeds/`, `cogs/`, `.claude/agent-memory/` | **Your work.** PRDs, designs, reports, standards and lessons. Keep or archive them before deleting |

Then commit the removal.

### How do I customize a skill or add my own?

Edit or add files under `os/skills/` (or `os/agents/`), then run `bash tools/build/build.sh`.

Never edit `.claude/skills/` or the other generated adapters; the build overwrites them. Step-by-step instructions are in [CUSTOMIZING.md](CUSTOMIZING.md).

### How do I upgrade?

Run `/upgrade-company-os` (or `/upgrade-company-os check` to only look).

It previews the changes, keeps your config and edited files, saves a backup, and can roll back. These guides in `.company-os/docs/` are always refreshed; if you edited one, your copy is kept next to it as `<name>.user`. Without Claude Code, re-run the installer with `--force`; add `--dry-run` first to preview. See the [CHANGELOG](CHANGELOG.md) for what changed.

### What is the difference between idea, mvp, growth and scale?

`company.stage` describes how mature your company is, and it decides which quality gates block you and which only warn.

| Stage | Means | Gates |
|-------|-------|-------|
| `idea` | Exploring; no real users | All warn only |
| `mvp` | First version with early users | Requirements and design gates block |
| `growth` | Paying customers, growing | All block |
| `scale` | Established product, larger team | All block |

Details: [stages and gates](CONCEPTS.md#stages-and-gates).

### What do I do if `/setup` fails or a hook blocks me?

Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md); it covers the common cases with exact fixes.

The top five: git not initialized, `jq` or `python3` missing, a hook blocking a promotion because the artifact is invalid, `validate.sh` errors, and gates blocking more than you expected (usually an empty or wrong `company.stage`).

### Does Company OS change my application code?

Not on install: the installer only adds its own files and merges into `CLAUDE.md` and `.claude/settings.json`.

Agents write application code only when you ask them to build something, for example with `/ship` or `/rapid-prototype`, and `/ship` pauses for your approval at each gate.

---

## Deep dives: how it works

### 1. How does Company OS handle internationalization (i18n)?

**Coverage: Gap (with a clear path forward)**

#### What Company OS does today

- The `api-contract-designer` skill mandates machine-readable `code` fields in API error responses. Clients map these codes to localized strings — the API never returns hardcoded user-facing text. See `os/skills/api-contract-designer/error-format-reference.md` (i18n Support section).
- `company.config.yaml` has an `i18n` section where you declare: `enabled`, `default_locale`, `supported_locales`, `strategy` (key-based / gettext / ICU), and `fallback` behavior.
- When `i18n.enabled` is true, the `prd-writer` skill captures i18n scope (target locales, translatable content types, locale detection approach) as part of requirements.
- The `architecture-draft` skill includes i18n as a cross-cutting concern in the RFC, covering string management, locale detection, and fallback strategy.

#### What you need to bring

- Your locale list and priority order
- Your string management library (next-intl, react-i18next, formatjs, gettext, etc.)
- Your translation workflow (professional translators, crowdsourced, machine-assisted)
- Place any locale configuration or string extraction tooling docs in `standards/`

#### Recommended workflow

1. Set `i18n.enabled: true` in `company.config.yaml` (or configure via `/setup`)
2. When creating a PRD, the skill will prompt for i18n scope
3. The RFC will address string extraction, locale detection, and fallback architecture
4. The API contract will use machine-readable codes for all user-facing responses
5. Place your i18n library docs in `standards/` and run `/ingest`

---

### 2. How are API error messages and responses localized?

**Coverage: Partial (solid foundation)**

#### What Company OS does today

The `api-contract-designer` skill and its `error-format-reference.md` already enforce this pattern (RFC 7807 problem details):

```json
{
  "type": "https://api.example.com/errors/validation-error",
  "title": "Validation Error",
  "status": 422,
  "errors": [
    { "field": "email", "code": "required", "message": "Email is required" }
  ]
}
```

- `code` is machine-readable — clients map it to localized strings
- `message` is default-locale human text (fallback only)
- `detail` fields never contain untranslatable user-facing text

This applies to error responses. When `i18n.enabled` is true in config, the same pattern should extend to all user-facing response text — the RFC will specify which response fields contain localizable content and how clients resolve them.

#### What you need to bring

- Your client-side i18n library that maps codes to localized strings
- Your translation files or service (e.g., Crowdin, Lokalise, or static JSON files)

---

### 3. How does Company OS enforce UI/UX consistency?

**Coverage: Partial (a design-system skill plus your own brand input)**

#### What Company OS does today

- The `/design-system` skill sets up and applies your visual design. The first run asks a few questions and picks one of six design archetypes (`linear`, `attio`, `notion`, `figma`, `things3`, `framer`), saved as `design.archetype` in `company.config.yaml`.
- `/design-system generate-tokens` writes `standards/brand/design-tokens.md`: colors, type, spacing and radius from the archetype, with your `design.overrides` applied. `/design-system review` audits UI code against those tokens.
- Every product also follows `standards/brand/ux-baseline.md`: empty states, loading, errors, forms and accessibility. The Frontend sub-agent loads the skill before it builds UI.
- The `positioning-messaging` skill defines brand tone and voice. The `landing-page-copy` skill inherits it for marketing content.

#### What you bring

Your own brand material overrides the archetype defaults. Place it in `standards/brand/`:
- Brand guidelines (visual identity, logo usage, color palette). `standards/brand/brand-guidelines.md` is a template you can fill in.
- Your own design tokens, if you already have them
- Component library documentation or Figma links

#### Recommended workflow

1. Run `/design-system` and pick an archetype (or run it from `/setup`)
2. Add your brand material to `standards/brand/` and run `/ingest`
3. Run `/design-system generate-tokens` to produce the project token file
4. Build UI; run `/design-system review` before release

#### What it does not do

It does not design screens or create a component library or Figma file for you. The archetypes are starting points; your brand guidelines are the input that makes the result yours.

---

### 4. How do I prevent AI-generated slop in content and UI?

**Coverage: Partial (quality checklists exist, artifact lifecycle is the enforcement mechanism)**

#### What Company OS does today

**Quality checklists in Growth skills:**
- `landing-page-copy`: Hero headline under 10 words, 8th-grade readability, benefits are outcome-focused not feature-focused, social proof is specific and credible, FAQ addresses real buyer objections
- `positioning-messaging`: Value propositions are specific and benefit-oriented, differentiators are defensible and evidence-backed, tone and voice are consistent throughout
- `channel-playbook`: Engagement tactics are specific not generic, tone adapted to platform norms

**Artifact lifecycle IS the anti-slop gate:**
- All agent-generated content starts as `draft`
- Must be promoted through `review` → `approved` via `promote.sh`
- The `review` step is your human quality gate — you read it, verify it doesn't feel generic, then promote
- If an artifact is `approved`, someone has explicitly signed off on it
- The release readiness gate (`release-readiness-gate`) verifies all artifacts are `approved` before shipping

#### What you need to bring

- A brand voice document in `standards/brand/` — the more specific your voice guide, the less generic the output
- Anti-pattern examples ("never say X", "avoid Y phrasing") in your voice guide
- Your own judgment during the `review` stage — this is where you catch slop

#### Recommended workflow

1. Create a brand voice doc: tone, vocabulary, anti-patterns, examples of good vs bad copy
2. Place it in `standards/brand/` and run `/ingest`
3. When Growth agents produce content, they reference your voice guide
4. Review every content artifact at the `review` stage before promoting to `approved`
5. If quality isn't there, don't promote — agents will iterate

#### The honest truth

No checklist fully prevents AI slop. The real defense is: (1) specific brand voice input, (2) human review at the `review` lifecycle stage, and (3) not approving artifacts until they meet your standard. Company OS gives you the structure for all three.

---

### 5. How does Company OS prove that features actually work?

**Coverage: Covered**

#### What Company OS does today

This is one of the system's core strengths. Multiple enforcement layers prevent "it's done" without proof:

**Stage gates** — 4 gates enforced by `tools/artifact/check-gate.sh`:
- `prd-to-rfc`: PRD must be approved and contain acceptance criteria
- `rfc-to-impl`: RFC and parent PRD must both be approved
- `impl-to-qa`: RFC approved, test plan must exist
- `release`: PRD, RFC and QA report approved, security review exists, app version is valid semver and was bumped (plus an AI safety check when `ai.llm_provider` is set)

**Artifact lifecycle** — enforced by `tools/artifact/promote.sh`:
- `draft` → `review` → `approved` — cannot skip stages
- Approval requires: parent artifact approved, all dependencies approved, validation passes
- Every promotion is logged in `artifacts/.audit-log/promotions.log`

**Test plan generator** — maps every PRD acceptance criterion to test scenarios:
- Classifies tests: functional, edge case, integration, regression, destructive
- Each test has specific pass/fail criteria (not vague)
- Test coverage matrix links ACs to test types (unit, integration, E2E)

**Release readiness gate** — 10 bars, evaluated by the `release-readiness-gate` skill. Bars 1 to 7 must pass; the rest are optional, advisory or conditional. Several bars are advisory at early stages (`idea`, sometimes `mvp`):
1. PRD completeness (approved, testable ACs, measurable metrics, explicit scope)
2. Technical design (RFC approved, API contract if the API changes, data model and migrations documented)
3. Security & risk (threat model exists, no unresolved CRITICAL/HIGH findings, dependency and secrets scans run, posture snapshot)
4. Testing (test plan linked to ACs, unit/integration/contract tests pass)
5. Code quality (lint passes, no untracked TODOs, follows `standards/coding/`)
6. Operational readiness (logging covers key operations, errors don't leak internals, rollback and deployment strategy, pre-deploy checks pass, incident runbook at `growth`+)
7. Release versioning (app version file, semver, bumped since last release, changelog entry; advisory at `idea`)
8. Dogfood report (optional and non-blocking unless `qa.dogfood_blocking: true`)
9. Design quality (archetype set, UX baseline patterns, design tokens; advisory at `idea`/`mvp`, enforced at `growth`/`scale`)
10. AI safety (only when `ai.llm_provider` is set and the RFC covers AI features; advisory at `idea`/`mvp`, enforced at `growth`/`scale`)

**Definition of Done** — explicit checklist in the release readiness gate:
1. PRD approved, 2. RFC approved, 3. Security reviewed, 4. Tests pass, 5. Code quality verified, 6. Operationally ready, 7. Artifacts linked, 8. Human review complete

**Verdict is binary**: APPROVED or NOT READY. No "mostly ready."

#### Known limitation

Edge case coverage in test plans is recommended but not mechanically enforced — `check-gate.sh` cannot verify that a test plan is comprehensive enough. The test plan generator's quality checklist says "edge cases and error paths are covered" but this relies on the agent doing thorough work. The human review at the `review` stage is where you catch gaps.

Two additional capabilities help close this gap: the `seed-data` skill generates structured test data for all scenarios (including edge-cases and error-states), and the `dogfood` skill autonomously exercises the running product as a real user would — catching integration failures, broken flows, and UX issues that unit tests miss.

---

### 6. How is observability baked into the development process?

**Coverage: Partial (comprehensive skill, integrated into architecture, but not a standalone release gate)**

#### What Company OS does today

**Observability Baseline skill** (`observability-baseline`) is comprehensive:
- Structured logging format (JSON, required fields: request_id, tenant_id, user_id)
- Log level conventions
- Application metrics naming scheme and label cardinality
- Distributed tracing conventions (span naming, context propagation, sampling)
- SLO-aligned alerting
- Sensitive data exclusion (PII, secrets never logged)

**Integrated into the architecture flow:**
- The `architecture-draft` skill includes observability as a cross-cutting concern in Step 7 — every RFC addresses logging, metrics, and tracing
- The Engineering Agent applies observability conventions during implementation
- `company.config.yaml` has a full `observability` section (logging format, provider, metrics, tracing, error tracking)

**Checked at release:**
- Release readiness gate Bar 6 (Operational Readiness) verifies: logging covers key operations, error handling doesn't leak internal details, performance baselines met

#### Known limitation

There is no separate observability artifact in the release gate. The `check-gate.sh release` command checks for PRD, RFC, security review, and QA report — but not a standalone observability document. This is intentional: observability is a cross-cutting concern addressed within the RFC and verified through the operational readiness bar, not a separate deliverable.

#### Recommended workflow

1. Configure `observability` section in `company.config.yaml` during `/setup`
2. The Engineering Agent will use `observability-baseline` during architecture and implementation
3. The release readiness evaluation checks operational readiness
4. If observability is critical for your product, explicitly include it in PRD acceptance criteria — this makes it a testable requirement that flows through the entire pipeline

---

### 7. How do agents communicate and coordinate?

**Coverage: Covered (this is a core strength)**

![Agent org chart: the Orchestrator routes to Product, Engineering, QA & Release, Growth and Ops & Risk; Engineering delegates to Backend, Frontend and DevOps sub-agents](diagrams/agent-org.svg)

#### How it works

Agents communicate through **artifacts**, not direct messaging. Every agent-produced document has YAML frontmatter with `parent`, `children`, `depends_on`, and `blocks` fields that create a directed graph of relationships.

```
Product Agent → PRD artifact → Engineering Agent → RFC artifact → QA Agent → QA Report
                                     ↓
                              Ops & Risk Agent → Security Review
                                     ↑
                              Orchestrator (routes + gates)
```

**The Orchestrator** is the coordinator. It uses the `workflow-router` skill to:
1. Classify the objective type (new feature, bug fix, improvement, research, launch, compliance)
2. Inventory existing artifacts
3. Build an execution plan (which agents, which artifacts, which order)
4. Identify parallelizable work (threat model + test plan can run alongside implementation)
5. Enforce stage gates at every transition

**Stage gates are the handoff checkpoints.** When the Engineering Agent finishes an RFC, it can't proceed to implementation until the Orchestrator verifies `check-gate.sh rfc-to-impl` passes. This ensures the previous agent delivered quality work before the next agent starts.

**Artifact validation** (`validate.sh`) ensures no orphaned references — if an RFC claims a parent PRD, that PRD must exist. If a PRD lists child RFCs, those RFCs must exist. Bidirectional consistency (parent lists child and child names parent) is enforced with `validate.sh --strict`.

**Conflict resolution** — when agents disagree (Product wants feature A, Engineering flags feasibility concerns), the `conflict-resolver` skill provides structured tradeoff analysis with scoring, recommendations, and documented dissenting views.

#### What the flow looks like for "Build feature X"

1. Orchestrator receives the objective, consults the workflow router and shows you the plan
2. Workflow router plans: PRD → RFC → Implementation → QA → Release, with the launch brief, threat model and test plan in parallel
3. Orchestrator delegates to Product Agent → PRD produced, validated, promoted to review
4. Orchestrator runs `check-gate.sh prd-to-rfc` → you approve the PRD
5. Growth Agent drafts the launch brief in parallel once the PRD is approved
6. Orchestrator delegates to Engineering Agent → RFC produced; Ops & Risk writes the threat model alongside it
7. Orchestrator runs `check-gate.sh rfc-to-impl` → you approve the RFC
8. Engineering implements while QA writes the test plan; `check-gate.sh impl-to-qa` → you approve
9. User docs, seed and verify (you try the feature), then QA produces the QA report
10. Orchestrator runs `check-gate.sh release` → all required artifacts exist and are approved → you give the final go

Agents hand off through artifacts; you approve at each pause. The gates block progression until the prerequisites are met.

#### Known limitation

Communication is artifact-mediated and sequential, not real-time. If the Engineering Agent discovers during implementation that an RFC assumption was wrong, it produces an updated RFC (or decision memo), and the Orchestrator re-routes. This is by design — artifact-based communication creates an audit trail. There is no "agent chat" or real-time negotiation.

---

### 8. How does Company OS handle production incidents?

**Coverage: Covered**

#### What Company OS does today

The `incident-response` skill (used by the Ops & Risk Agent) provides a structured incident management framework:

- **Severity classification** — 4 levels (P0 Critical through P3 Low) with examples, response times and resolution targets for each
- **Triage procedures** — a checklist per severity: acknowledge, open an incident channel, run `status-check.sh`, size the blast radius, decide rollback or hotfix, and send status updates on a schedule
- **Runbook generation** — produces service-specific runbooks with diagnostic commands, common failure modes, and resolution steps
- **Rollback checklists** — step-by-step rollback procedures with verification gates at each step
- **Communication templates** — pre-written templates for status page updates, stakeholder notifications, and customer communications at each severity level
- **Post-mortems** — uses the 5 Whys framework to identify root causes, with sections for timeline reconstruction, contributing factors, corrective actions, and follow-up tracking

The `tools/ops/status-check.sh` tool checks HTTP endpoints (status code, response time, SSL) and can be run during incidents to assess service status.

#### What you need to bring

- Your service topology and dependency map (place in `standards/ops/`)
- Your on-call rotation and escalation contacts
- Your status page provider (Statuspage, Betteruptime, etc.)
- Service-specific diagnostic commands and log locations

#### Recommended workflow

1. Place your operational standards in `standards/ops/` and run `/ingest`
2. When an incident occurs, the Ops & Risk Agent generates a runbook tailored to the affected service
3. During resolution, use `status-check.sh` for quick health verification
4. After resolution, the agent produces a post-mortem using the 5 Whys framework
5. Corrective actions feed back into RFCs and PRDs for the next ship cycle

---

### 9. How are features safely rolled out?

**Coverage: Covered**

#### What Company OS does today

Two skills work together to ensure safe, progressive feature rollouts:

**Feature flags skill** (`feature-flags`) defines a progressive discovery pattern with 4 levels:
- **Core** — essential features available to all users immediately
- **Foundations** — unlocked after initial onboarding/setup is complete
- **Power** — unlocked as users demonstrate proficiency with the product
- **Expert** — advanced features gated behind explicit opt-in or usage thresholds

Features are gated behind flags that control visibility and access. The skill covers flag naming conventions, lifecycle management (creation through retirement), and audience targeting strategies.

**Deployment strategy skill** (`deployment-strategy`) handles the release mechanics:
- **Environment ladder** — defines progression from local to staging to production with promotion criteria at each step
- **Rollout strategies** — chosen by hosting model: atomic deploys plus feature flags on serverless, rolling update, blue-green or canary on containers, blue-green on VMs, regional rollout on the edge
- **Rollback procedures** — automated and manual rollback triggers with verification steps

The `tools/deploy/pre-deploy.sh` tool runs 8 checks before a deployment: git status, branch, tests, lint, secret scan, migrations, environment variables and version management.

The `feature_flags` section in `company.config.yaml` sets your flag provider, flag strategy (`progressive-discovery`, `release-only` or `full`) and cleanup SLA (how many days a release flag may stay after full rollout).

#### What you need to bring

- Your feature flag provider credentials and setup (LaunchDarkly, Flagsmith, or custom)
- Your environment definitions and access controls
- Your deployment pipeline configuration (CI/CD system)

#### Recommended workflow

1. Configure `feature_flags` and deployment settings in `company.config.yaml`
2. When the Engineering Agent creates an RFC, it includes a feature flag strategy section
3. During implementation, flags are created following the naming conventions from the skill
4. Before deployment, `pre-deploy.sh` validates readiness
5. Rollout follows the deployment strategy for your hosting model (for example canary or blue-green on containers, feature flags for gradual exposure on serverless)
6. Flags are retired after the feature is stable and fully rolled out

---

### 10. How does Company OS support mobile development?

**Coverage: Partial (comprehensive guidance, but not a native build system)**

#### What Company OS does today

The `mobile-readiness` skill covers two paths:

**Responsive web** (when `platforms.responsive: true` in config):
- Breakpoint definitions and media query conventions
- Touch target sizing (minimum 44x44px) and gesture handling
- Mobile-first CSS architecture patterns
- Performance budgets for mobile networks (target LCP, bundle size limits)
- Viewport and safe area handling

**React Native / Expo** (when `platforms.targets` includes `ios` or `android`):
- Project structure conventions for shared and platform-specific code
- Navigation patterns (stack, tab, drawer) with deep linking
- Native module integration guidelines
- App store requirements checklist (screenshots, metadata, review guidelines)
- OTA update strategy (Expo Updates, CodePush)

The `platforms` section in `company.config.yaml` lets you specify your targets (`[web, mobile-web, ios, android]`). When responsive is enabled, code reviews automatically check mobile compatibility — the `code-review` skill flags missing breakpoints, non-responsive layouts, and accessibility issues on touch devices.

#### What you need to bring

- Your device/browser support matrix (place in `standards/engineering/`)
- Your responsive breakpoint values (if different from defaults)
- For native: your Expo/React Native project configuration
- App store developer accounts and signing certificates (for iOS/Android)

#### Recommended workflow

1. Configure the `platforms` section in `company.config.yaml` during `/setup`
2. PRDs will capture platform-specific requirements when multiple targets are configured
3. RFCs address responsive/native concerns in the Platform Strategy cross-cutting section
4. Code reviews flag mobile compatibility issues automatically
5. QA test plans include device-specific test scenarios
6. For native apps, the deployment strategy includes app store submission checklists

#### Known limitation

Company OS does not replace your native build toolchain (Xcode, Android Studio, Expo EAS). It provides architectural guidance, review checklists, and process structure — but the actual build, signing, and store submission are handled by your CI/CD pipeline and native tools.

---

## Related

- [SETUP.md](SETUP.md): install and first run
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md): fixes for common problems
- [TOKEN_COSTS.md](TOKEN_COSTS.md): what Company OS costs in tokens
- [CHANGELOG.md](CHANGELOG.md): what changed in each version
- `/status`: summary of your artifacts and gate readiness
- `/upgrade-company-os`: check for and apply updates
- `/system-maintenance`: re-sync docs after structural changes
- Issues and questions: [github.com/vibbs/company-os/issues](https://github.com/vibbs/company-os/issues)

> This FAQ and the other files in `.company-os/docs/` explain Company OS itself. `bash setup.sh --cleanup` (or the cleanup option in `/setup`) keeps them; delete them by hand if you do not want them.
