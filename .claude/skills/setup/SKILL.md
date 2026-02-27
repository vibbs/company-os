---
name: setup
description: Interactive setup wizard for Company OS. Configures company.config.yaml, generates .claude/settings.json with tech-stack-specific permissions, and scaffolds directories. Supports three modes — interactive wizard, express config block, or auto-extract from a URL/unstructured text.
user-invokable: true
argument-hint: "[preset | config block | URL | unstructured description]"
---

# Setup Wizard

Interactive setup skill for Company OS. Works on both new (greenfield) and existing projects. Company OS is an **overlay** — it adds its own files alongside your code and never touches your source.

## Modes

- **Interactive** (`/setup` or `/setup nextjs`) — step-by-step guided wizard with smart defaults
- **Express** (`/setup` + config block) — paste a pre-filled config block, wizard parses and applies it in one shot
- **Auto-Extract** (`/setup` + URL or unstructured text) — wizard fetches/reads the content, extracts company profile, infers tech stack, and presents a pre-filled config for confirmation

## Deployment Models

- **New project**: Fork/clone the template, run `/setup`
- **Existing repo**: Clone Company OS files into your repo root, run `/setup`
- **Mono repo**: Run `/setup` at the repo root. `company.config.yaml` describes the shared stack. Agents work across all packages.
- **Multi repo**: Each repo gets its own Company OS instance with independent artifacts and config.

## Express Mode

If the user provides a config block alongside `/setup`, skip interactive questions and parse the block directly. Any field not provided uses preset defaults (if a preset is specified) or is left empty.

### Express Mode Template

Users can copy this template, fill in their values, and paste it with `/setup`:

````markdown
## Company
- Name:
- Product:
- Description:
- Domain:
- Stage: idea | mvp | growth | scale

## Tech Stack
- Preset: nextjs | fastapi | express | django | go | rails | custom
- Cache: Redis | Memcached | none
- Queue: BullMQ | Celery | SQS | none
- Search: Elasticsearch | Meilisearch | Typesense | none

## Overrides (only if different from preset defaults)
- API Auth: JWT | API Keys | OAuth2 | session | Clerk | Auth.js
- API Versioning: url-path | header | query-param | none
- API Pagination: cursor | offset | none
- Rate Limiting: token-bucket | sliding-window | none
- Test Framework: Vitest | Jest | pytest | go test | cargo test
- Linter: ESLint | Biome | Ruff | golangci-lint
- Formatter: Prettier | Biome | Black | gofmt
- Branching: trunk-based | gitflow | github-flow
- Commit Style: conventional | gitmoji | freeform
- Monorepo: true | false
- Monorepo Tool: Turborepo | Nx | pnpm workspaces | none

## Architecture
- Multi-tenant: true | false
- Tenant Isolation: RLS | schema-per-tenant | database-per-tenant | none
- Deployment: serverless | containers | VMs | edge

## Observability
- Logging: structured-json | plaintext
- Error Tracking: Sentry | Bugsnag | none

## i18n
- Enabled: true | false
- Default Locale: en-US
- Supported Locales: [en-US, hi-IN, fr-FR]
- Strategy: key-based | gettext | ICU

## Platforms
- Targets: [web, mobile-web, ios, android]
- Mobile Framework: [react-native, expo, flutter, capacitor]
- PWA: true | false

## Analytics
- Provider: Mixpanel | Amplitude | Pendo | PostHog | none
- Event Prefix: my-app

## Feature Flags
- Provider: LaunchDarkly | Flagsmith | Unleash | custom | config-file
- Strategy: progressive-discovery | release-only | full

## Email
- Provider: Resend | Sendgrid | Postmark | SES | none
- From: noreply@yourdomain.com
- Template Engine: react-email | mjml | handlebars | jinja | plain-html

## Options
- Skill Categories: all | -growth | -legal
- Clean Up Templates: yes | no
````

### Express Mode Procedure

1. **Parse** the config block — extract all key-value pairs by section header
2. **Apply preset** — if `Preset` is specified, fill in all preset defaults first
3. **Override** — apply any explicit values from the block on top of preset defaults
4. **Smart defaults** — fill remaining gaps with stage-appropriate defaults:
   - `observability.logging` → `structured-json`
   - `observability.error_tracking` → `Sentry`
   - `analytics.provider` → `none` for idea, `PostHog` for mvp+
   - `feature_flags.provider` → `config-file` for idea/mvp
   - `feature_flags.strategy` → `release-only` for idea/mvp, `full` for growth/scale
   - `analytics.event_prefix` → lowercase hyphenated product name
   - `email.from_address` → `noreply@{domain}`
   - `email.template_engine` → infer from tech stack (react-email for TS, jinja for Python, etc.)
   - `platforms.targets` → `[web, mobile-web]` for Next.js, `[web]` for others
   - `platforms.responsive` → `true`
5. **Display summary** — show the full resolved config as a table for user confirmation
6. **On confirmation** — proceed directly to Step 6 (Write config), Step 7 (Settings), Step 8 (Scaffold), then handle Options (skill categories, template cleanup), then Step 11 (Verify)

If the user says "looks good" or confirms, apply everything. If they want changes, apply those changes and re-confirm.

---

## Auto-Extract Mode

If the user provides a URL or pastes unstructured text (pitch deck content, about page copy, investor memo, product brief, Notion dump, etc.), the wizard extracts as much as it can automatically.

### Detecting Auto-Extract Mode

The input is Auto-Extract if ANY of these are true:
- Contains a URL (starts with `http://` or `https://`)
- Contains prose paragraphs (not structured `- Key: Value` pairs)
- Contains a mix of freeform text and partial config values
- Reads like marketing copy, pitch content, or a product description

### Auto-Extract Procedure

1. **Fetch/Read the content**:
   - If URL provided → use `WebFetch` to retrieve and extract page content
   - If text pasted → use the text directly
   - If multiple URLs → fetch all and combine

2. **Extract company profile** — look for:
   - Company name (from logo, header, footer, "About" section, legal text)
   - Product name (from headline, hero section, title tag)
   - Description (from meta description, hero subtitle, "What we do" section)
   - Domain (from the URL itself or contact information)
   - Stage — infer from signals:
     - "coming soon", "waitlist", "beta" → `idea` or `mvp`
     - "trusted by X customers", pricing page, case studies → `growth`
     - Enterprise features, SOC2 badges, large customer logos → `scale`

3. **Infer tech stack** — look for signals in the content AND in the codebase:
   - Check the repo for `package.json`, `requirements.txt`, `go.mod`, `Cargo.toml`, `Gemfile`, `pom.xml`
   - From website: check meta tags, response headers (`x-powered-by`, `server`), script sources, framework fingerprints
   - From text: mentions of specific technologies ("built with React", "powered by Django", "Node.js backend")
   - If no tech signals found → ask the user to pick a preset

4. **Infer product characteristics** — look for:
   - Multi-tenant signals: "teams", "organizations", "workspaces", "per-seat pricing"
   - i18n signals: multiple language options, locale switcher, "available in X countries"
   - Mobile signals: "mobile app", app store links, "responsive", QR codes
   - B2B vs B2C: pricing model, target audience language
   - Auth signals: "Sign in with Google", "SSO", "enterprise login"

5. **Build a pre-filled config** — map extracted data to Company OS config fields:
   - Fill everything that was confidently extracted
   - Mark uncertain fields with `(inferred)` annotation
   - Leave truly unknown fields empty

6. **Present for confirmation** — show the extracted config as a summary table:
   ```
   ## Auto-Extracted Configuration

   Source: https://neevak.com + codebase analysis

   ### Company Profile
   | Field | Extracted Value | Confidence |
   |-------|----------------|------------|
   | Name | Univas Collective | high — from footer |
   | Product | Neevak | high — from title |
   | Description | School fee management... | high — from hero |
   | Domain | neevak.com | high — from URL |
   | Stage | mvp | medium — no pricing page yet |

   ### Tech Stack
   | Field | Extracted Value | Confidence |
   |-------|----------------|------------|
   | Preset | nextjs | high — package.json found |
   | ... | ... | ... |

   Fields I couldn't determine: [list]

   Does this look right? I'll ask about the missing fields.
   ```

7. **Fill gaps** — for fields that couldn't be extracted:
   - If a preset was determined, apply preset defaults
   - For remaining unknowns, ask the user (interactive-style) only for those specific fields
   - Apply smart defaults for everything else

8. **On confirmation** — proceed to Step 6 (Write config) through Step 11 (Verify), same as Express mode

### Example Usage

**URL mode:**
```
/setup https://neevak.com
```

**Text dump mode:**
```
/setup

We're Univas Collective, building Neevak — a school fee management
platform for Indian K-12 schools. Schools currently use Excel, cash
counters, and WhatsApp to manage crores in fee collection. We're
replacing that with a proper infrastructure layer.

We're using Next.js with TypeScript, PostgreSQL, and deploying on
Vercel. Each school is a tenant with RLS isolation. We need mobile
support — parents will use Android primarily. We're at MVP stage,
about to onboard our first 10 pilot schools.

Tech: Next.js 14, Prisma, PostgreSQL, Redis for caching, BullMQ for
background jobs (receipt generation, payment reminders). Auth via
Clerk. We'll need WhatsApp integration for notifications.
```

The wizard would extract all of that into a pre-filled config, infer the preset (Next.js + Vercel), set multi-tenant with RLS, platforms targeting web + mobile-web + android, and present the full config for one-click confirmation.

---

## Interactive Mode Procedure

### Step 1: Detect Environment

1. Check if `company.config.yaml` exists and has any non-empty values
2. Check if `.claude/settings.json` exists and has permissions
3. Check if `artifacts/`, `tools/`, `standards/` directories exist
4. Classify the situation:
   - **Fresh setup**: No config or all fields empty → full walkthrough
   - **Reconfigure**: Config exists with values → ask "Update existing configuration or start fresh?"
   - **Overlay**: Existing codebase detected (e.g., `package.json`, `requirements.txt`, `go.mod`, `Cargo.toml`) → note existing stack, suggest preset

### Step 2: Company Profile

Gather the following (skip fields that already have values unless user wants to update):

- `company.name` — company or project name
- `company.product` — product name
- `company.description` — one-line product description
- `company.domain` — primary domain (optional)
- `company.stage` — idea | mvp | growth | scale

### Step 3: Tech Stack Selection

Offer presets first to save time, then allow customization:

| Preset | Language | Framework | Runtime | DB | ORM | Hosting | CI |
|--------|----------|-----------|---------|-----|-----|---------|-----|
| **Next.js + Vercel** | TypeScript | Next.js | Node.js 20 | PostgreSQL | Prisma | Vercel | GitHub Actions |
| **FastAPI + AWS** | Python | FastAPI | Python 3.12 | PostgreSQL | SQLAlchemy | AWS | GitHub Actions |
| **Express + Railway** | TypeScript | Express | Node.js 20 | PostgreSQL | Prisma | Railway | GitHub Actions |
| **Django + AWS** | Python | Django | Python 3.12 | PostgreSQL | Django ORM | AWS | GitHub Actions |
| **Go + Fly.io** | Go | Gin | Go 1.22 | PostgreSQL | GORM | Fly.io | GitHub Actions |
| **Rails + Heroku** | Ruby | Rails | Ruby 3.3 | PostgreSQL | ActiveRecord | Heroku | GitHub Actions |
| **Custom** | — | — | — | — | — | — | — |

After preset selection, walk through remaining `tech_stack` fields not covered by preset:
- `cache` (Redis | Memcached | none)
- `queue` (BullMQ | Celery | SQS | none)
- `search` (Elasticsearch | Meilisearch | Typesense | none)

If the environment has existing files (e.g., `package.json` → Node.js), suggest the matching preset.

### Step 4: API & Conventions

Provide smart defaults based on the chosen preset. Only prompt when the user needs to decide.

**API section:**
- `api.style` — REST | GraphQL | gRPC | tRPC
- `api.spec_format` — OpenAPI 3.1 | GraphQL SDL | Protobuf
- `api.error_format` — RFC7807 | custom
- `api.versioning` — url-path (/v1/) | header | query-param | none
- `api.auth` — JWT | API Keys | OAuth2 | session | Clerk | Auth.js
- `api.pagination` — cursor | offset | none
- `api.rate_limiting` — token-bucket | sliding-window | none

**Conventions section:**
- `conventions.branching` — trunk-based | gitflow | github-flow
- `conventions.commit_style` — conventional | gitmoji | freeform
- `conventions.test_framework` — Vitest | Jest | pytest | go test | cargo test
- `conventions.linter` — ESLint | Biome | Ruff | golangci-lint
- `conventions.formatter` — Prettier | Biome | Black | gofmt
- `conventions.monorepo` — true | false
- `conventions.monorepo_tool` — Turborepo | Nx | pnpm workspaces | none (only if monorepo is true)

**Preset defaults** (apply these, ask user to confirm or change):

| Field | Next.js + Vercel | FastAPI + AWS | Express + Railway | Django + AWS | Go + Fly.io | Rails + Heroku |
|-------|-----------------|---------------|-------------------|-------------|-------------|----------------|
| api.style | REST | REST | REST | REST | REST | REST |
| api.spec_format | OpenAPI 3.1 | OpenAPI 3.1 | OpenAPI 3.1 | OpenAPI 3.1 | OpenAPI 3.1 | OpenAPI 3.1 |
| api.auth | JWT | JWT | JWT | session | JWT | session |
| api.pagination | cursor | cursor | cursor | offset | cursor | offset |
| conventions.test_framework | Vitest | pytest | Vitest | pytest | go test | RSpec |
| conventions.linter | ESLint | Ruff | ESLint | Ruff | golangci-lint | RuboCop |
| conventions.formatter | Prettier | Black | Prettier | Black | gofmt | RuboCop |
| conventions.branching | trunk-based | trunk-based | trunk-based | trunk-based | trunk-based | github-flow |
| conventions.commit_style | conventional | conventional | conventional | conventional | conventional | conventional |

### Step 5: Architecture, Observability & i18n

Prompt for key decisions:
- `architecture.multi_tenant` — true | false (default: false)
- `architecture.tenant_isolation` — only if multi_tenant is true
- `architecture.deployment_model` — serverless | containers | VMs | edge

Observability with sensible defaults:
- `observability.logging` — structured-json (default)
- `observability.error_tracking` — Sentry (default) | Bugsnag | none
- Leave `log_provider`, `metrics`, `tracing` as `""` (can configure later)

i18n (only prompt if user indicates international audience):
- `i18n.enabled` — true | false (default: false)
- If true: `i18n.default_locale`, `i18n.supported_locales`, `i18n.strategy` (key-based | gettext | ICU), `i18n.fallback`

### Step 5.5: Platforms, Analytics, Feature Flags & Email

**Platforms** — ask about target platforms:
- `platforms.targets` — [web, mobile-web, ios, android] (default: [web] for web frameworks, [web, mobile-web] for Next.js/Nuxt)
- `platforms.mobile_framework` — [react-native, expo, flutter, capacitor] (only if ios or android in targets; array, supports multiple)
- `platforms.responsive` — true | false (default: true for any web target)
- `platforms.pwa` — true | false (default: false)

**Preset platform defaults:**

| Preset | targets | responsive | mobile_framework |
|--------|---------|------------|-----------------|
| Next.js + Vercel | [web, mobile-web] | true | [] |
| FastAPI + AWS | [web] | true | [] |
| Express + Railway | [web] | true | [] |
| Django + AWS | [web] | true | [] |
| Go + Fly.io | [web] | true | [] |
| Rails + Heroku | [web] | true | [] |

**Analytics** — ask if the product needs analytics (recommended for all products beyond `idea` stage):
- `analytics.provider` — Mixpanel | Amplitude | Pendo | PostHog | none (default: none for `idea`, PostHog for `mvp`+)
- `analytics.event_prefix` — auto-suggest from `company.product` (lowercase, hyphenated)
- `analytics.tracker_attribute` — data-track-id (default) | data-analytics | custom

**Feature Flags** — ask about rollout strategy:
- `feature_flags.provider` — LaunchDarkly | Flagsmith | Unleash | custom | config-file (default: config-file for early stage)
- `feature_flags.strategy` — progressive-discovery | release-only | full (default: release-only for `idea`/`mvp`, full for `growth`/`scale`)
- `feature_flags.cleanup_sla_days` — number of days (default: 14)

**Email** — ask if the product sends emails (skip for pure API products):
- `email.provider` — Resend | Sendgrid | Postmark | SES | none (default: none)
- `email.from_address` — auto-suggest: noreply@{company.domain}
- `email.template_engine` — react-email (for TypeScript/Next.js) | mjml (for any) | handlebars (for Node.js) | jinja (for Python) | plain-html (default: infer from tech stack)

### Step 5.6: Model Preferences

Ask: "Which model tier should each agent use? This controls cost vs. capability."

Offer presets first:

| Preset | Orchestrator | Engineering | Product | QA | Ops & Risk | Growth |
|--------|-------------|-------------|---------|-----|-----------|--------|
| **Cost-Optimized** (Recommended) | opus | opus | sonnet | sonnet | sonnet | sonnet |
| **All Opus** | opus | opus | opus | opus | opus | opus |
| **All Sonnet** | sonnet | sonnet | sonnet | sonnet | sonnet | sonnet |
| **Custom** | — | — | — | — | — | — |

**Default**: Cost-Optimized — keeps Opus for Orchestrator (routing/gating) and Engineering (architecture/implementation), uses Sonnet for structured/template-driven agents.

If user selects Custom, walk through each agent:
- `models.orchestrator` — opus (recommended) | sonnet | haiku
- `models.engineering` — opus (recommended) | sonnet
- `models.product` — sonnet (recommended) | opus
- `models.qa_release` — sonnet (recommended) | opus
- `models.ops_risk` — sonnet (recommended) | opus
- `models.growth` — sonnet (recommended) | opus | haiku

After selection, update both:
1. `company.config.yaml` `models:` section with the chosen values
2. Each `.claude/agents/*.md` frontmatter `model:` field to match

### Step 6: Write `company.config.yaml`

Write the complete config file with all gathered values. Preserve the comment structure from the template. Leave uncollected optional fields as `""`.

### Step 7: Generate / Merge `.claude/settings.json`

**If `.claude/settings.json` already exists:**
1. Read and parse the existing file
2. Preserve ALL existing user rules in `allow` and `deny` arrays
3. Add Company OS base permissions + tech-stack-specific permissions
4. Deduplicate — don't add rules that already exist
5. Write back the merged result

**If `.claude/settings.json` does not exist:**
1. Create it fresh with base + tech-stack permissions

#### Base Permissions (always included)

**Allow:**
```json
"Read", "Edit", "Write", "Glob", "Grep",
"Bash(./tools/*)", "Bash(./tools/**/*)",
"Bash(chmod *)", "Bash(mkdir *)", "Bash(ls *)", "Bash(pwd)", "Bash(wc *)",
"Bash(git init*)", "Bash(git status*)", "Bash(git log *)", "Bash(git log)",
"Bash(git diff *)", "Bash(git diff)", "Bash(git add *)", "Bash(git commit *)",
"Bash(git branch *)", "Bash(git branch)", "Bash(git checkout *)",
"Bash(git switch *)", "Bash(git fetch *)", "Bash(git pull *)",
"Bash(git merge *)", "Bash(git stash *)", "Bash(git remote *)",
"Bash(git tag *)", "Bash(git show *)", "Bash(git rev-parse *)",
"Bash(git push *)", "Bash(git push)",
"Bash(gh *)"
```

**Deny:**
```json
"Bash(git push --force*)", "Bash(git push -f *)", "Bash(git push -f)",
"Bash(git reset --hard*)", "Bash(git clean -f*)", "Bash(git clean -df*)",
"Bash(git checkout -- .)", "Bash(git restore .)",
"Bash(rm -rf *)", "Bash(rm -rf /)", "Bash(rm -f *)",
"Bash(sudo *)", "Bash(curl *)", "Bash(wget *)", "Bash(nc *)"
```

#### Tech-Stack-Specific Additions (add to allow)

| Language | Additional Bash Permissions |
|----------|---------------------------|
| TypeScript / JavaScript | `npm *`, `npx *`, `yarn *`, `pnpm *`, `bun *`, `node *` |
| Python | `python *`, `python3 *`, `pip *`, `pip3 *`, `poetry *`, `uv *` |
| Go | `go *` |
| Rust | `cargo *`, `rustc *` |
| Ruby | `ruby *`, `gem *`, `bundle *`, `rails *` |
| Java | `mvn *`, `gradle *`, `java *`, `javac *` |

#### Monorepo Tool Additions (add to allow if monorepo is true)

| Tool | Additional Bash Permissions |
|------|---------------------------|
| Turborepo | `turbo *` |
| Nx | `nx *` |
| pnpm workspaces | (already covered by `pnpm *`) |

### Step 8: Scaffold Directories

Create any missing directories (idempotent — skip if they already exist):

```
artifacts/prds/
artifacts/rfcs/
artifacts/test-plans/
artifacts/qa-reports/
artifacts/launch-briefs/
artifacts/security-reviews/
artifacts/decision-memos/
artifacts/.audit-log/
standards/api/
standards/coding/
standards/compliance/
standards/templates/
standards/brand/
standards/ops/
standards/analytics/
standards/docs/
standards/email/
standards/engineering/
imports/ (with .gitkeep if empty)
tasks/ (with todo.md and lessons.md if missing)
seeds/ (with .gitkeep)
artifacts/test-data/ (with .gitkeep)
```

Do NOT create directories that are part of Company OS source (`.claude/`, `tools/`) — these should already exist from the template.

### Step 8b: Initialize App Versioning

Set up version tracking for the user's application. This is separate from Company OS versioning — this tracks the user's product version.

1. **Detect existing version file**:
   - If `package.json` exists and has a `"version"` field → use it (don't overwrite)
   - If `pyproject.toml` exists and has a `version` field → use it
   - If a `VERSION` file exists (and is not the Company OS version — check against `.company-os-version`) → use it
   - If none found → create `VERSION` file with the appropriate initial version

2. **Set initial version based on stage**:
   - If `company.stage` is `idea` or `mvp` (or empty): version starts at `0.1.0`
   - If `company.stage` is `growth` or `scale`: version starts at `1.0.0`
   - If an existing version file was detected, keep its current value

3. **Create app CHANGELOG.md** (only if no CHANGELOG.md exists):
   ```markdown
   # Changelog

   All notable changes to this project are documented in this file.
   Format based on [Keep a Changelog](https://keepachangelog.com/).

   ## [Unreleased]

   ## [0.1.0] - {today's date}
   ### Added
   - Initial release
   ```
   Use the initial version from step 2 in the heading (0.1.0 or 1.0.0).

4. **Create `.previous-version`** with `0.0.0` (baseline for first bump detection)

5. **Add `.previous-version` to `.gitignore`** if not already present (internal tracking file, not user-facing)

6. **Report**: "App versioning initialized at v{version}. The ship flow will auto-bump versions on each release."

### Step 9: Skill Category Selection (Optional)

Ask: "Which skill categories do you need? All are included by default."

- **Product** (PRDs, prioritization, ICP) — default: keep
- **Engineering** (architecture, API design, implementation) — default: keep
- **QA & Release** (test plans, release gates, benchmarks) — default: keep
- **Growth** (launch, SEO, content, activation) — default: keep (suggest removing for internal tools)
- **Legal & Compliance** (privacy, TOS, compliance, pricing) — default: keep (suggest removing for early-stage)

If user removes a category, note it but don't delete skills (they're harmless if unused and easy to re-enable). Add a comment to `company.config.yaml`:

```yaml
# Disabled skill categories: growth, legal
```

### Step 10: Template Documentation Cleanup (Optional)

Ask: "Would you like to clean up template documentation files? These explain Company OS itself and aren't needed for daily operation."

| File | Purpose | Recommendation |
|------|---------|----------------|
| `README.md` | Describes Company OS template | **Replace** with a project-specific README |
| `TOKEN_COSTS.md` | Token cost reference for adopters | **Remove** (reference only) |
| `FAQ.md` | Company OS capability FAQ | **Remove** (reference only) |
| `SETUP_COMPANY_OS.md` | Setup guide for template | **Remove** after setup complete |
| `setup.sh` | One-time scaffolding script | **Remove** after first run |
| `artifacts/prds/PRD-EXAMPLE-001-notifications.md` | Example PRD artifact | **Remove** after reviewing |
| `artifacts/rfcs/RFC-EXAMPLE-001-notification-system.md` | Example RFC artifact | **Remove** after reviewing |
| `standards/api/example-api-conventions.md` | Example API standards | **Remove** after reviewing |
| `standards/coding/example-coding-standards.md` | Example coding standards | **Remove** after reviewing |

If user confirms:
1. Delete `TOKEN_COSTS.md`, `FAQ.md`, `SETUP_COMPANY_OS.md`, `setup.sh`, example artifacts, and example standards
2. Replace `README.md` with a minimal project README:
   ```
   # {company.product}
   {company.description}
   ```
3. Report what was cleaned up

Files that are **always kept** (operationally required):
- `CLAUDE.md` — auto-loaded every session, governs all agent behavior
- `company.config.yaml` — central configuration for all agents/skills/tools
- `.claude/` — agents, skills, settings
- `tools/` — enforcement scripts
- `artifacts/`, `standards/`, `tasks/`, `imports/` — working directories

### Step 11: Verify & Report

1. Run `./tools/registry/health-check.sh` — verify all skills discoverable
2. Validate `company.config.yaml` is well-formed YAML
3. Validate `.claude/settings.json` is well-formed JSON
4. Print setup summary:

```
## Setup Complete

### Company Profile
- Company: {name}
- Product: {product}
- Stage: {stage}

### Tech Stack
- {language} / {framework} / {database}
- Hosting: {hosting}, CI: {ci}

### Permissions
- .claude/settings.json configured with {N} allow rules, {M} deny rules
- Tech stack: {language} permissions included

### Directories
- {N} directories created, {M} already existed

### Next Steps
1. **Install dependencies** — run `npm install`, `pip install -r requirements.txt`, `go mod download`, or the equivalent for your tech stack
2. **Set up dev infrastructure** — run `/dev-environment` to generate Docker Compose files, `.env.example`, and dev scripts. Then: `cp .env.example .env && bash tools/dev/start.sh`
3. **Place reference docs** in `standards/` and run `/ingest` to sync agents
4. **Import existing artifacts** — if you have PRDs, RFCs, or specs elsewhere, run `/artifact-import` to bring them in
5. **Generate seed data** — after your first ship cycle creates domain entities, run `/seed-data` to generate test data for all scenarios
6. **Build your first feature** — ask the Orchestrator: "Build [feature] for [product]"
```

## Edge Cases

- **No git repo**: Warn user to run `git init` first (artifacts use timestamps but git history aids audit)
- **Conflicting stack signals**: If `package.json` exists but user picks Python preset, note the conflict but proceed (mono repos legitimately mix stacks)
- **Existing `.claude/settings.json` with custom rules**: Merge carefully — never remove user rules, only add
- **Re-running `/setup`**: Idempotent for directories and settings merge. Config overwrites with new values.

## Reference

- **Category**: Orchestration
- **Inputs**: user prompts, existing config state, environment signals
- **Outputs**: `company.config.yaml`, `.claude/settings.json`, scaffolded directories
- **Used by**: User (directly), Orchestrator Agent
- **Tool scripts**: `./tools/registry/health-check.sh`
