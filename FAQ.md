# FAQ — AI Agentic Company OS

Honest answers about what Company OS handles well, where it has partial coverage, and what you need to bring yourself. Built for solo-preneurs who rely on this system as their engineering team.

---

## 1. How does Company OS handle internationalization (i18n)?

**Coverage: Gap (with a clear path forward)**

### What Company OS does today

- The `api-contract-designer` skill mandates machine-readable `code` fields in API error responses. Clients map these codes to localized strings — the API never returns hardcoded user-facing text. See `.claude/skills/api-contract-designer/error-format-reference.md` (i18n Support section).
- `company.config.yaml` has an `i18n` section where you declare: `enabled`, `default_locale`, `supported_locales`, `strategy` (key-based / gettext / ICU), and `fallback` behavior.
- When `i18n.enabled` is true, the `prd-writer` skill captures i18n scope (target locales, translatable content types, locale detection approach) as part of requirements.
- The `architecture-draft` skill includes i18n as a cross-cutting concern in the RFC, covering string management, locale detection, and fallback strategy.

### What you need to bring

- Your locale list and priority order
- Your string management library (next-intl, react-i18next, formatjs, gettext, etc.)
- Your translation workflow (professional translators, crowdsourced, machine-assisted)
- Place any locale configuration or string extraction tooling docs in `standards/`

### Recommended workflow

1. Set `i18n.enabled: true` in `company.config.yaml` (or configure via `/setup`)
2. When creating a PRD, the skill will prompt for i18n scope
3. The RFC will address string extraction, locale detection, and fallback architecture
4. The API contract will use machine-readable codes for all user-facing responses
5. Place your i18n library docs in `standards/` and run `/ingest`

---

## 2. How are API error messages and responses localized?

**Coverage: Partial (solid foundation)**

### What Company OS does today

The `api-contract-designer` skill and its `error-format-reference.md` already enforce this pattern:

```json
{
  "type": "validation_error",
  "code": "field_required",
  "field": "email",
  "message": "Email is required"
}
```

- `code` is machine-readable — clients map it to localized strings
- `message` is default-locale human text (fallback only)
- `detail` fields never contain untranslatable user-facing text

This applies to error responses. When `i18n.enabled` is true in config, the same pattern should extend to all user-facing response text — the RFC will specify which response fields contain localizable content and how clients resolve them.

### What you need to bring

- Your client-side i18n library that maps codes to localized strings
- Your translation files or service (e.g., Crowdin, Lokalise, or static JSON files)

---

## 3. How does Company OS enforce UI/UX consistency?

**Coverage: Gap (user-provided input, not a generated skill)**

### What Company OS does today

- The `positioning-messaging` skill defines brand tone and voice guidelines. The `landing-page-copy` skill inherits these for all marketing content.
- There is no design system skill — and intentionally so. Design systems, brand guidelines, component libraries, and Figma integrations are company-specific artifacts that you bring, not something an AI agent generates from scratch.

### What you need to bring

Place these in `standards/brand/`:
- Brand guidelines (visual identity, logo usage, color palette)
- Design tokens (colors, typography, spacing, border-radius)
- Component library documentation or Figma links
- Tone of voice guide (if not captured in positioning-messaging output)

### Recommended workflow

1. Export your brand guidelines and design tokens to `standards/brand/`
2. Run `/ingest` to sync into the skill system
3. When agents create PRDs, they'll reference your brand standards for visual requirements
4. When agents design architecture, they'll consider component reuse from your library
5. All marketing content inherits your tone/voice from the messaging framework

### Why this isn't a skill

Design systems are deeply company-specific. A generic "create a design system" skill would produce exactly the kind of generic AI output you're trying to avoid. Your brand guidelines are **input** to the system, not output from it — same way API specs and compliance docs go in `standards/`.

---

## 4. How do I prevent AI-generated slop in content and UI?

**Coverage: Partial (quality checklists exist, artifact lifecycle is the enforcement mechanism)**

### What Company OS does today

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

### What you need to bring

- A brand voice document in `standards/brand/` — the more specific your voice guide, the less generic the output
- Anti-pattern examples ("never say X", "avoid Y phrasing") in your voice guide
- Your own judgment during the `review` stage — this is where you catch slop

### Recommended workflow

1. Create a brand voice doc: tone, vocabulary, anti-patterns, examples of good vs bad copy
2. Place it in `standards/brand/` and run `/ingest`
3. When Growth agents produce content, they reference your voice guide
4. Review every content artifact at the `review` stage before promoting to `approved`
5. If quality isn't there, don't promote — agents will iterate

### The honest truth

No checklist fully prevents AI slop. The real defense is: (1) specific brand voice input, (2) human review at the `review` lifecycle stage, and (3) not approving artifacts until they meet your standard. Company OS gives you the structure for all three.

---

## 5. How does Company OS prove that features actually work?

**Coverage: Covered**

### What Company OS does today

This is one of the system's core strengths. Multiple enforcement layers prevent "it's done" without proof:

**Stage gates** — 4 gates enforced by `tools/artifact/check-gate.sh`:
- `prd-to-rfc`: PRD must be approved with testable acceptance criteria
- `rfc-to-impl`: RFC and parent PRD must both be approved
- `impl-to-qa`: RFC approved, test plan must exist
- `release`: ALL artifacts must exist and be approved

**Artifact lifecycle** — enforced by `tools/artifact/promote.sh`:
- `draft` → `review` → `approved` — cannot skip stages
- Approval requires: parent artifact approved, all dependencies approved, validation passes
- Every promotion is logged in `artifacts/.audit-log/promotions.log`

**Test plan generator** — maps every PRD acceptance criterion to test scenarios:
- Classifies tests: functional, edge case, integration, regression, destructive
- Each test has specific pass/fail criteria (not vague)
- Test coverage matrix links ACs to test types (unit, integration, E2E)

**Release readiness gate** — 6 minimum bars, ALL must pass:
1. PRD completeness (approved, testable ACs, measurable metrics)
2. Technical design (RFC approved, API contract exists, migrations documented)
3. Security & risk (threat model exists, no unresolved CRITICAL/HIGH findings)
4. Testing (test plan linked to ACs, unit/integration/contract tests pass)
5. Code quality (lint passes, no untracked TODOs)
6. Operational readiness (logging covers key ops, errors don't leak internals)

**Definition of Done** — explicit checklist in the release readiness gate:
1. PRD approved, 2. RFC approved, 3. Security reviewed, 4. Tests pass, 5. Code quality verified, 6. Operationally ready, 7. Artifacts linked, 8. Human review complete

**Verdict is binary**: APPROVED or NOT READY. No "mostly ready."

### Known limitation

Edge case coverage in test plans is recommended but not mechanically enforced — `check-gate.sh` cannot verify that a test plan is comprehensive enough. The test plan generator's quality checklist says "edge cases and error paths are covered" but this relies on the agent doing thorough work. The human review at the `review` stage is where you catch gaps.

---

## 6. How is observability baked into the development process?

**Coverage: Partial (comprehensive skill, integrated into architecture, but not a standalone release gate)**

### What Company OS does today

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

### Known limitation

There is no separate observability artifact in the release gate. The `check-gate.sh release` command checks for PRD, RFC, security review, and QA report — but not a standalone observability document. This is intentional: observability is a cross-cutting concern addressed within the RFC and verified through the operational readiness bar, not a separate deliverable.

### Recommended workflow

1. Configure `observability` section in `company.config.yaml` during `/setup`
2. The Engineering Agent will use `observability-baseline` during architecture and implementation
3. The release readiness evaluation checks operational readiness
4. If observability is critical for your product, explicitly include it in PRD acceptance criteria — this makes it a testable requirement that flows through the entire pipeline

---

## 7. How do agents communicate and coordinate without human handholding?

**Coverage: Covered (this is a core strength)**

### How it works

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

**Artifact validation** (`validate.sh`) ensures no orphaned references — if an RFC claims a parent PRD, that PRD must exist. If a PRD lists child RFCs, those RFCs must exist. Bidirectional consistency is enforced.

**Conflict resolution** — when agents disagree (Product wants feature A, Engineering flags feasibility concerns), the `conflict-resolver` skill provides structured tradeoff analysis with scoring, recommendations, and documented dissenting views.

### What the flow looks like for "Build feature X"

1. Orchestrator receives objective, consults workflow router
2. Workflow router plans: PRD → RFC → Threat Model (parallel) → Implementation → QA → Release
3. Orchestrator delegates to Product Agent → PRD produced, validated, promoted
4. Orchestrator runs `check-gate.sh prd-to-rfc` → passes
5. Orchestrator delegates to Engineering Agent → RFC produced, validated, promoted
6. Orchestrator runs `check-gate.sh rfc-to-impl` → passes
7. Engineering implements while Ops & Risk reviews security (parallel)
8. QA produces test plan and QA report
9. Orchestrator runs `check-gate.sh release` → all artifacts exist and approved
10. Growth Agent produces launch brief
11. Orchestrator approves release

At each step, the gate blocks progression until prerequisites are met. No human intervention needed for the flow itself — you intervene at `review` stages when promoting artifacts.

### Known limitation

Communication is artifact-mediated and sequential, not real-time. If the Engineering Agent discovers during implementation that an RFC assumption was wrong, it produces an updated RFC (or decision memo), and the Orchestrator re-routes. This is by design — artifact-based communication creates an audit trail. There is no "agent chat" or real-time negotiation.

---

## Still Have Questions?

- **Setup**: Run `/setup` in Claude Code for interactive configuration
- **Configuration guide**: [SETUP_COMPANY_OS.md](SETUP_COMPANY_OS.md)
- **Token costs**: [TOKEN_COSTS.md](TOKEN_COSTS.md) for per-agent cost breakdowns
- **System audit**: Run `/system-maintenance` after any structural changes
- **Issues**: [github.com/vibbs/company-os/issues](https://github.com/vibbs/company-os/issues)

> **Note**: This FAQ, along with TOKEN_COSTS.md and SETUP_COMPANY_OS.md, are template documentation that explain Company OS itself. After setup, you can remove them with `bash setup.sh --cleanup` or during the `/setup` wizard. They are not needed for daily operation.
