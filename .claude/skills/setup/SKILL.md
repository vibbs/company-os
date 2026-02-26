---
name: setup
description: Interactive setup wizard for Company OS. Configures company.config.yaml, generates .claude/settings.json with tech-stack-specific permissions, and scaffolds directories. Use when initializing Company OS on a new or existing project.
user-invokable: true
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Setup Wizard

Interactive setup skill for Company OS. Works on both new (greenfield) and existing projects. Company OS is an **overlay** — it adds its own files alongside your code and never touches your source.

## Deployment Models

- **New project**: Fork/clone the template, run `/setup`
- **Existing repo**: Clone Company OS files into your repo root, run `/setup`
- **Mono repo**: Run `/setup` at the repo root. `company.config.yaml` describes the shared stack. Agents work across all packages.
- **Multi repo**: Each repo gets its own Company OS instance with independent artifacts and config.

## Procedure

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
standards/ (with .gitkeep if empty)
imports/ (with .gitkeep if empty)
tasks/ (with todo.md and lessons.md if missing)
```

Do NOT create directories that are part of Company OS source (`.claude/`, `tools/`) — these should already exist from the template.

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

If user confirms:
1. Delete `TOKEN_COSTS.md`, `FAQ.md`, `SETUP_COMPANY_OS.md`, `setup.sh`
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
1. Place any reference docs in `standards/` and run `/ingest`
2. Import existing PRDs/RFCs with `/artifact-import`
3. Ask the Orchestrator to build your first feature:
   "Build [feature] for [product]"
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
