#!/usr/bin/env bash
# ============================================================================
# Company OS — Setup Script (Bash Fallback)
# ============================================================================
# Scaffolds directories and creates template files for Company OS.
# Use this when you want to set up Company OS before opening Claude Code.
#
# Usage:
#   bash setup.sh             # scaffold directories + template config
#   bash setup.sh --cleanup   # remove template documentation files
#
# After running this script, open Claude Code and run /setup to customize
# your configuration interactively.
# ============================================================================

set -euo pipefail

# Colors (if terminal supports them)
if [ -t 1 ]; then
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  RED='\033[0;31m'
  BLUE='\033[0;34m'
  NC='\033[0m' # No Color
else
  GREEN=''
  YELLOW=''
  BLUE=''
  RED=''
  NC=''
fi

# --- Cleanup Mode ---
if [[ "${1:-}" == "--cleanup" ]]; then
  echo -e "${BLUE}Company OS — Template Cleanup${NC}"
  echo "================================"
  echo ""
  echo "Removing template documentation files (not needed for daily operation)..."
  echo ""
  REMOVED=0
  for f in TOKEN_COSTS.md FAQ.md SETUP_COMPANY_OS.md; do
    if [ -f "$f" ]; then
      rm "$f"
      echo -e "  ${RED}Removed${NC}  $f"
      REMOVED=$((REMOVED + 1))
    fi
  done
  echo ""
  echo "================================"
  echo -e "${GREEN}Done!${NC} Removed $REMOVED template files."
  echo ""
  echo -e "${YELLOW}You may also want to:${NC}"
  echo "  - Replace README.md with your project README"
  echo "  - Delete setup.sh (this script) — it's no longer needed"
  exit 0
fi

echo -e "${BLUE}Company OS — Setup${NC}"
echo "================================"
echo ""

# Track what we create
CREATED=0
SKIPPED=0

create_dir() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
    echo -e "  ${GREEN}Created${NC}  $1/"
    CREATED=$((CREATED + 1))
  else
    SKIPPED=$((SKIPPED + 1))
  fi
}

create_file() {
  if [ ! -f "$1" ]; then
    echo "$2" > "$1"
    echo -e "  ${GREEN}Created${NC}  $1"
    CREATED=$((CREATED + 1))
  else
    SKIPPED=$((SKIPPED + 1))
  fi
}

# --- Scaffold Directories ---
echo "Scaffolding directories..."

# Artifact directories
create_dir "artifacts/prds"
create_dir "artifacts/rfcs"
create_dir "artifacts/test-plans"
create_dir "artifacts/qa-reports"
create_dir "artifacts/launch-briefs"
create_dir "artifacts/security-reviews"
create_dir "artifacts/decision-memos"
create_dir "artifacts/.audit-log"

# Standards directories
create_dir "standards/api"
create_dir "standards/coding"
create_dir "standards/compliance"
create_dir "standards/templates"
create_dir "standards/brand"

# Other directories
create_dir "imports"
create_dir "tasks"

echo ""

# --- Create Template Files ---
echo "Creating template files..."

# .gitkeep files for empty directories
for dir in standards/api standards/coding standards/compliance standards/templates standards/brand imports; do
  if [ ! -f "$dir/.gitkeep" ] && [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
    touch "$dir/.gitkeep"
  fi
done

# Tasks files
create_file "tasks/todo.md" "# Todo

Current task tracking for this session."

create_file "tasks/lessons.md" "# Lessons

Accumulated corrections and patterns from agent interactions."

# company.config.yaml (only if missing)
if [ ! -f "company.config.yaml" ]; then
  cat > "company.config.yaml" << 'YAML'
# ============================================================================
# Company OS Configuration
# ============================================================================
# This is the central configuration file for your Company OS instance.
# Every agent, skill, and tool reads from this file to adapt behavior
# to your specific company, tech stack, and conventions.
#
# Instructions:
#   1. Fill in every field relevant to your project
#   2. Leave fields blank ("") if not yet decided — agents will prompt you
#   3. Run /setup in Claude Code for interactive configuration
# ============================================================================

company:
  name: ""                    # Your company or project name
  product: ""                 # Product name
  description: ""             # One-line product description
  domain: ""                  # Primary domain (e.g., acme.com)
  stage: ""                   # idea | mvp | growth | scale

tech_stack:
  language: ""                # TypeScript | Python | Go | Rust | Java
  framework: ""               # Next.js | FastAPI | Gin | Actix | Spring Boot
  runtime: ""                 # Node.js 20 | Python 3.12 | Go 1.22
  database: ""                # PostgreSQL | MySQL | MongoDB | SQLite
  orm: ""                     # Prisma | Drizzle | SQLAlchemy | GORM | none
  cache: ""                   # Redis | Memcached | none
  queue: ""                   # BullMQ | Celery | SQS | none
  search: ""                  # Elasticsearch | Meilisearch | Typesense | none
  hosting: ""                 # Vercel | AWS | GCP | Fly.io | Railway
  ci: ""                      # GitHub Actions | GitLab CI | CircleCI

api:
  style: ""                   # REST | GraphQL | gRPC | tRPC
  spec_format: ""             # OpenAPI 3.1 | GraphQL SDL | Protobuf
  error_format: ""            # RFC7807 | custom (place spec in standards/api/)
  versioning: ""              # url-path (/v1/) | header | query-param | none
  auth: ""                    # JWT | API Keys | OAuth2 | session | Clerk | Auth.js
  pagination: ""              # cursor | offset | none
  rate_limiting: ""           # token-bucket | sliding-window | none

conventions:
  branching: ""               # trunk-based | gitflow | github-flow
  commit_style: ""            # conventional | gitmoji | freeform
  test_framework: ""          # Vitest | Jest | pytest | go test | cargo test
  linter: ""                  # ESLint | Biome | Ruff | golangci-lint
  formatter: ""               # Prettier | Biome | Black | gofmt
  monorepo: false             # true | false
  monorepo_tool: ""           # Turborepo | Nx | pnpm workspaces | none

architecture:
  multi_tenant: false         # true | false
  tenant_isolation: ""        # RLS | schema-per-tenant | database-per-tenant | none
  deployment_model: ""        # serverless | containers | VMs | edge

observability:
  logging: ""                 # structured-json | plaintext
  log_provider: ""            # Axiom | Datadog | CloudWatch | stdout
  metrics: ""                 # OpenTelemetry | Prometheus | Datadog | none
  tracing: ""                 # OpenTelemetry | Jaeger | Datadog | none
  error_tracking: ""          # Sentry | Bugsnag | none

i18n:
  enabled: false              # true | false — set to true if product supports multiple locales
  default_locale: ""          # en-US | en-GB | fr-FR | etc.
  supported_locales: []       # list of locales, e.g. [en-US, fr-FR, de-DE]
  strategy: ""                # key-based | gettext | ICU — how strings are managed
  fallback: ""                # default-locale | key | empty — behavior when translation missing
YAML
  echo -e "  ${GREEN}Created${NC}  company.config.yaml"
  CREATED=$((CREATED + 1))
else
  SKIPPED=$((SKIPPED + 1))
fi

# .claude/settings.json (default Node.js permissions — only if missing)
if [ ! -f ".claude/settings.json" ]; then
  mkdir -p ".claude"
  cat > ".claude/settings.json" << 'JSON'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": [
      "Read",
      "Edit",
      "Write",
      "Glob",
      "Grep",
      "Bash(./tools/*)",
      "Bash(./tools/**/*)",
      "Bash(chmod *)",
      "Bash(mkdir *)",
      "Bash(ls *)",
      "Bash(pwd)",
      "Bash(wc *)",
      "Bash(git init*)",
      "Bash(git status*)",
      "Bash(git log *)",
      "Bash(git log)",
      "Bash(git diff *)",
      "Bash(git diff)",
      "Bash(git add *)",
      "Bash(git commit *)",
      "Bash(git branch *)",
      "Bash(git branch)",
      "Bash(git checkout *)",
      "Bash(git switch *)",
      "Bash(git fetch *)",
      "Bash(git pull *)",
      "Bash(git merge *)",
      "Bash(git stash *)",
      "Bash(git remote *)",
      "Bash(git tag *)",
      "Bash(git show *)",
      "Bash(git rev-parse *)",
      "Bash(gh *)",
      "Bash(npm *)",
      "Bash(npx *)",
      "Bash(yarn *)",
      "Bash(pnpm *)",
      "Bash(bun *)",
      "Bash(node *)"
    ],
    "deny": [
      "Bash(git push --force*)",
      "Bash(git push -f *)",
      "Bash(git push -f)",
      "Bash(git reset --hard*)",
      "Bash(git clean -f*)",
      "Bash(git clean -df*)",
      "Bash(git checkout -- .)",
      "Bash(git restore .)",
      "Bash(rm -rf *)",
      "Bash(rm -rf /)",
      "Bash(rm -f *)",
      "Bash(sudo *)",
      "Bash(curl *)",
      "Bash(wget *)",
      "Bash(nc *)"
    ]
  }
}
JSON
  echo -e "  ${GREEN}Created${NC}  .claude/settings.json (Node.js defaults)"
  CREATED=$((CREATED + 1))
else
  echo -e "  ${YELLOW}Exists${NC}   .claude/settings.json (preserved)"
  SKIPPED=$((SKIPPED + 1))
fi

echo ""
echo "================================"
echo -e "${GREEN}Done!${NC} Created $CREATED items, $SKIPPED already existed."
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Open Claude Code:  claude"
echo "  2. Run setup wizard:  /setup"
echo "  3. The wizard will customize your config and permissions interactively."
echo ""
