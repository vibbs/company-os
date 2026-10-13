# Configuration Reference

`company.config.yaml` at your project root tells every agent, skill and tool about your company, tech stack and conventions. The easiest way to fill it is `/setup` (see [SETUP.md](SETUP.md#4-configure-with-setup)). Use this page when you want to edit it by hand or understand a field.

**Only two sections are required.** Fill the rest when a feature needs them.

| Section | Status | Read by |
|---------|--------|---------|
| [`company`](#company-required) | **Required** | Every agent; `stage` sets gate strictness |
| [`tech_stack`](#tech_stack-required) | **Required** | Engineering agents, CI and QA tools |
| [`api`](#api-recommended) | Recommended | `api-contract-designer`, `architecture-draft` |
| [`conventions`](#conventions-recommended) | Recommended | Commits, test and lint tools |
| [`architecture`](#architecture-optional) | Optional | `multi-tenancy`, `deployment-strategy` |
| [`observability`](#observability-optional) | Optional | `observability-baseline`, `incident-response` |
| [`i18n`](#i18n-optional) | Optional | `prd-writer`, `api-contract-designer` |
| [`platforms`](#platforms-optional) | Optional | `mobile-readiness` |
| [`analytics`](#analytics-optional) | Optional | `instrumentation` |
| [`feature_flags`](#feature_flags-optional) | Optional | `feature-flags` |
| [`email`](#email-optional) | Optional | `email-lifecycle` |
| [`ai`](#ai-optional) | Optional | `ai-engineering`, release gate, `token-cost-ledger` |
| [`experiments`](#experiments-optional) | Optional | `experiment-framework` |
| [`support`](#support-optional) | Optional | `support-operations` |
| [`design`](#design-optional) | Optional | `design-system` |
| [`models`](#models-optional-claude-code-only) | Optional, Claude Code only | Agent model choice |
| [`personas`](#personas-optional) | Optional | Agent display names |

### What happens if a field is empty

- Agents ask you to decide before they make a recommendation that depends on it.
- Tools try to detect the value (for example, a `package.json` means Node.js).
- Skills fall back to generic patterns instead of stack-specific ones.

### Agents will push back on a poor fit

If your stack does not suit a feature, agents say so and suggest an alternative. For example, MongoDB with a feature that needs complex joins gets a PostgreSQL suggestion; REST with a real-time need gets a WebSocket suggestion. These are recommendations, not blockers. Your decision stands.

### Why the config is not an artifact

The config is your **input**. Artifacts are agent **outputs** with a status lifecycle (draft to approved). The config has no lifecycle: change it whenever you decide, and it stays at the project root.

---

## Express setup template

Paste this after `/setup`, edit the values, and the wizard configures everything in one pass. It fills anything you leave out from the preset's defaults and shows a summary before writing.

```text
/setup

## Company
- Name: Acme Corp
- Product: InvoiceFlow
- Description: B2B SaaS invoicing for small businesses
- Domain: invoiceflow.com
- Stage: mvp

## Tech Stack
- Preset: nextjs
- Cache: Redis
- Queue: BullMQ

## Architecture
- Multi-tenant: true
- Tenant Isolation: RLS
- Deployment: serverless

## Platforms
- Targets: [web, mobile-web]

## Analytics
- Provider: PostHog

## Email
- Provider: Resend

## Options
- Clean Up Templates: yes
```

`Clean Up Templates: yes` deletes the example artifacts and standards, replaces the README and removes `setup.sh` after setup. The guides in `.company-os/docs/` always stay. Say `no` if you want to keep the examples. The full template, with every preset, is in `os/skills/setup/SKILL.md`.

---

## `company` (required)

```yaml
company:
  name: "Acme Corp"           # Used in artifact headers and docs
  product: "InvoiceFlow"      # Product name
  description: "One-liner"    # Gives every agent context
  domain: "invoiceflow.com"   # Primary domain
  stage: "mvp"                # idea | mvp | growth | scale
```

`stage` controls which gates block (see [stages and gates](CONCEPTS.md#stages-and-gates)) and app versioning: `idea` and `mvp` stay on `0.x.x`, and `1.0.0` comes at `growth` or `scale`. Left empty, gates behave as `growth`.

## `tech_stack` (required)

```yaml
tech_stack:
  language: "TypeScript"      # Agents tailor code and architecture to this
  framework: "Next.js"        # Architecture decisions depend on this
  runtime: "Node.js 20"
  database: "PostgreSQL"      # Data model design adapts to this
  orm: "Prisma"
  cache: "Redis"              # or none
  queue: "BullMQ"             # or none
  search: "none"
  hosting: "Vercel"
  ci: "GitHub Actions"
```

At minimum fill `language`, `framework` and `database`.

## `api` (recommended)

```yaml
api:
  style: "REST"               # REST | GraphQL | gRPC | tRPC
  spec_format: "OpenAPI 3.1"
  error_format: "RFC7807"     # or custom (put the spec in standards/api/)
  versioning: "url-path"      # url-path | header | query-param | none
  auth: "JWT"                 # JWT | API Keys | OAuth2 | session | Clerk | Auth.js
  pagination: "cursor"        # cursor | offset | none
  rate_limiting: "token-bucket"
```

## `conventions` (recommended)

```yaml
conventions:
  branching: "github-flow"    # trunk-based | gitflow | github-flow
  commit_style: "conventional" # conventional | gitmoji | freeform
  test_framework: "Vitest"    # Test tools detect and run this
  linter: "ESLint"            # Lint tool runs the right command
  formatter: "Prettier"
  monorepo: false
  monorepo_tool: ""           # Turborepo | Nx | pnpm workspaces | none
```

## `architecture` (optional)

```yaml
architecture:
  multi_tenant: true
  tenant_isolation: "RLS"     # RLS | schema-per-tenant | database-per-tenant | none
  deployment_model: "serverless" # serverless | containers | VMs | edge
```

## `observability` (optional)

```yaml
observability:
  logging: "structured-json"  # structured-json | plaintext
  log_provider: "Axiom"
  metrics: "OpenTelemetry"
  tracing: "OpenTelemetry"
  error_tracking: "Sentry"
```

## `i18n` (optional)

Set `enabled: true` only if the product supports more than one language.

```yaml
i18n:
  enabled: false
  default_locale: "en-US"
  supported_locales: []       # e.g. [en-US, fr-FR]
  strategy: "key-based"       # key-based | gettext | ICU
  fallback: "default-locale"  # default-locale | key | empty
```

## `platforms` (optional)

```yaml
platforms:
  targets: [web, mobile-web]  # web | mobile-web | ios | android
  mobile_framework: []        # react-native | expo | flutter | capacitor (list)
  responsive: true            # Enables mobile-readiness checks
  pwa: false                  # Progressive Web App support
```

## `analytics` (optional)

```yaml
analytics:
  provider: "PostHog"         # Mixpanel | Amplitude | Pendo | PostHog | none
  event_prefix: "myapp"       # Prefix for event names
  tracker_attribute: "data-track-id" # HTML attribute used for UI tracking
```

## `feature_flags` (optional)

```yaml
feature_flags:
  provider: "LaunchDarkly"    # LaunchDarkly | Flagsmith | Unleash | custom | config-file
  strategy: "release-only"    # progressive-discovery | release-only | full
  cleanup_sla_days: 14        # Max days a release flag stays after full rollout
```

## `email` (optional)

```yaml
email:
  provider: "Resend"          # Resend | Sendgrid | Postmark | SES | none
  from_address: "noreply@invoiceflow.com"
  template_engine: "react-email" # react-email | mjml | handlebars | jinja | plain-html
```

## `ai` (optional)

Fill this if your **product** calls an AI model. Setting `llm_provider` turns on an AI safety check in the release gate for features whose RFC involves AI (a warning in `idea` and `mvp`, blocking in `growth` and `scale`).

```yaml
ai:
  llm_provider: "anthropic"   # anthropic | openai | google | local | none
  llm_model: "claude-sonnet"
  embedding_provider: "none"
  vector_db: "pgvector"
  guardrails: "custom"
  cost_budget_monthly: "200"  # USD
  cost_tracking_enabled: true # Turns on the cogs/ai-ledger token ledger
  cost_alert_threshold_percent: 80
```

## `experiments` (optional)

```yaml
experiments:
  enabled: false
  min_sample_size: 100        # Per variant
  default_significance: 0.95
  max_concurrent: 3
```

## `support` (optional)

```yaml
support:
  channels: [email]           # email, chat, self-serve
  sla_tier: "basic"           # basic | standard | premium
  escalation_email: ""
```

## `design` (optional)

Run `/design-system` to choose an archetype instead of editing by hand.

```yaml
design:
  archetype: "linear"         # linear | attio | notion | figma | things3 | framer
  dark_mode: "auto"           # auto | light | dark | both
  density: "comfortable"      # compact | comfortable | spacious
  overrides: {}               # e.g. { accent: "#FF6B00" }
```

## `models` (optional, Claude Code only)

Which Claude model tier each agent uses. Other runtimes ignore this section and use their own model setting.

```yaml
models:
  orchestrator: "opus"          # Routing, gating, release approval
  engineering: "opus"           # Staff engineer: architecture, code review
  engineering_backend: "sonnet"
  engineering_frontend: "sonnet"
  engineering_devops: "sonnet"
  product: "sonnet"
  qa_release: "sonnet"
  ops_risk: "sonnet"
  growth: "sonnet"
```

Options per agent: `opus`, `sonnet`, `haiku`. The default "cost-optimized" preset keeps Opus for the Orchestrator and the Engineering staff engineer, which need the strongest reasoning, and uses Sonnet for everyone else, including the Engineering sub-agents. That saves roughly 30 to 35% of agent token cost compared with all-Opus. `/setup` offers presets: cost-optimized, all-opus, all-sonnet, custom.

To change a model by hand, update both this section and the `model:` line in `os/agents/<agent>.md`, then run `bash tools/build/build.sh`.

## `personas` (optional)

Give agents human names. This is cosmetic: it changes nothing about routing or gates.

```yaml
personas:
  orchestrator: "Alex"          # default: "Orchestrator"
  product: "Jordan"             # default: "Product Agent"
  engineering: "Morgan"         # default: "Engineering Agent"
  engineering_backend: "Casey"  # default: "Backend Engineer"
  engineering_frontend: "Drew"  # default: "Frontend Engineer"
  engineering_devops: "Avery"   # default: "DevOps Engineer"
  qa_release: "Quinn"           # default: "QA & Release Agent"
  growth: "Riley"               # default: "Growth Agent"
  ops_risk: "Sage"              # default: "Ops & Risk Agent"
```

Leave a value as `""` to use the default name. Names always appear with the role, for example "Morgan (Engineering)", in delegation messages, status output and ship flow progress.

---

## Related setup

### App versioning (automatic)

Company OS manages your app's version as part of `/ship`:

- It finds the version in `package.json`, `pyproject.toml` or a `VERSION` file.
- On release it proposes the bump (PATCH for fixes, MINOR for features, MAJOR for breaking changes) and asks you to confirm. `company.stage` keeps you on `0.x.x` until `growth`.
- Your app gets its own `CHANGELOG.md`. Entries are drafted during `/ship` and stamped at release.
- Each release gets a `v<version>` git tag.
- The release gate and `tools/deploy/pre-deploy.sh` check that the version was bumped.

`/setup` initializes this for you. To bump by hand:

```bash
./tools/versioning/version-bump.sh minor             # bump the minor version
./tools/versioning/version-bump.sh patch --dry-run   # preview a patch bump
```

Company OS tracks its own version separately, in `.company-os/version`; it never copies its own changelog into your project.

### Local development environment

1. Install your framework's dependencies (`npm install`, `pip install -r requirements.txt`, `go mod download`, `bundle install`).
2. Run `/dev-environment`. It reads `tech_stack` and generates `infra/docker-compose.dev.yml`, dev scripts in `tools/dev/`, and a `.env.example` with a port variable per service.
3. Ports live in `.env.example`, not in `company.config.yaml`:
   ```bash
   # --- App Ports (derived from tech stack config) ---
   API_PORT=8000          # FastAPI default
   WEB_PORT=3000          # React/Vite frontend
   # EXPO_PORT=8081       # Uncomment for mobile dev server
   # WORKER_PORT=9000     # Uncomment for background workers
   ```
   Full-stack frameworks (Next.js, SvelteKit) use a single `PORT`. A separate backend and frontend use `API_PORT` and `WEB_PORT`. The QA tools (`smoke-test.sh`, `contract-test.sh`, `dogfood.sh`) find URLs from `.env`, then `.env.example`, then framework defaults.
4. Start and check:
   ```bash
   cp .env.example .env                # local env file; adjust ports if needed
   bash tools/dev/start.sh             # start the database, cache, etc.
   npm run dev                         # start your app (command depends on framework)
   curl http://localhost:3000/health   # check the health endpoint
   ```
