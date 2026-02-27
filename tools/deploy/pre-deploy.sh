#!/usr/bin/env bash
# Tool: T-DEPLOY-01 Pre-Deploy Validation
# Description: Runs pre-deployment checks (git status, tests, lint, secrets, migrations, env vars)
# Usage: ./tools/deploy/pre-deploy.sh [--help]
# Inputs: reads company.config.yaml for tech stack detection
# Outputs: validation report with pass/warn/fail per check, exit 0=pass 1=warnings 2=failures
set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
CONFIG_FILE="$SCRIPT_DIR/../../company.config.yaml"

# ─── Color codes (portable: works on macOS and Linux) ───────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── Counters ───────────────────────────────────────────────────────────────────
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

# ─── Usage ──────────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $(basename "$0") [--help]

Run pre-deployment validation checks against the current project.
Reads company.config.yaml for tech stack detection.

Checks performed:
  1. Git status: no uncommitted changes
  2. Branch check: on expected deploy branch
  3. Tests pass: run configured test framework
  4. Lint passes: run configured linter
  5. No secrets in codebase: scan for common secret patterns
  6. Migrations reviewed: check for pending migrations
  7. Environment variables: compare .env.example with current env
  8. Version management: app version exists, valid semver, bumped since last release

Exit Codes:
  0  All checks passed
  1  Warnings only (non-blocking issues)
  2  One or more checks failed (do not deploy)
EOF
  exit 0
}

if [[ "${1:-}" == "--help" ]]; then
  usage
fi

# ─── Helper: read a value from company.config.yaml (basic grep, no yq needed) ──
read_config() {
  local key="$1"
  local value=""
  if [[ -f "$CONFIG_FILE" ]]; then
    value=$(grep "${key}:" "$CONFIG_FILE" 2>/dev/null | head -1 | sed "s/.*${key}: *//" | tr -d '"' | tr -d "'" | xargs) || true
  fi
  echo "$value"
}

# ─── Helper: report a check result ─────────────────────────────────────────────
report_pass() {
  echo -e "  ${GREEN}PASS${RESET}  $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

report_warn() {
  echo -e "  ${YELLOW}WARN${RESET}  $1"
  WARN_COUNT=$((WARN_COUNT + 1))
}

report_fail() {
  echo -e "  ${RED}FAIL${RESET}  $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

# ─── Read config values ────────────────────────────────────────────────────────
TEST_FRAMEWORK=$(read_config "test_framework")
LINTER=$(read_config "linter")
BRANCHING=$(read_config "branching")
ORM=$(read_config "orm")

echo ""
echo -e "${BOLD}Pre-Deployment Validation${RESET}"
echo "================================"
echo "Config: ${CONFIG_FILE}"
echo ""

# ─── Check 1: Git status — no uncommitted changes ──────────────────────────────
echo -e "${BOLD}[1/8] Git Status${RESET}"
if ! command -v git &> /dev/null; then
  report_warn "git not found, skipping git checks"
elif [[ ! -d ".git" ]]; then
  report_warn "Not a git repository, skipping git checks"
else
  # Check for uncommitted changes (staged + unstaged + untracked)
  GIT_STATUS=$(git status --porcelain 2>/dev/null) || true
  if [[ -z "$GIT_STATUS" ]]; then
    report_pass "Working tree is clean"
  else
    CHANGED_COUNT=$(echo "$GIT_STATUS" | wc -l | xargs)
    report_fail "Uncommitted changes detected (${CHANGED_COUNT} file(s))"
    echo "$GIT_STATUS" | head -10 | while IFS= read -r line; do
      echo "         $line"
    done
  fi
fi
echo ""

# ─── Check 2: Branch check — on expected deploy branch ─────────────────────────
echo -e "${BOLD}[2/8] Branch Check${RESET}"
if command -v git &> /dev/null && [[ -d ".git" ]]; then
  CURRENT_BRANCH=$(git branch --show-current 2>/dev/null) || true

  # Determine expected branch from config or default to main/master
  EXPECTED_BRANCH="main"
  if [[ "$BRANCHING" == *"trunk"* ]] || [[ "$BRANCHING" == *"main"* ]]; then
    EXPECTED_BRANCH="main"
  elif [[ "$BRANCHING" == *"master"* ]]; then
    EXPECTED_BRANCH="master"
  elif [[ "$BRANCHING" == *"GitFlow"* ]] || [[ "$BRANCHING" == *"gitflow"* ]]; then
    EXPECTED_BRANCH="main"
  fi

  if [[ "$CURRENT_BRANCH" == "$EXPECTED_BRANCH" ]]; then
    report_pass "On expected branch: ${CURRENT_BRANCH}"
  else
    report_warn "On branch '${CURRENT_BRANCH}', expected '${EXPECTED_BRANCH}'"
  fi
else
  report_warn "Cannot determine branch (git not available)"
fi
echo ""

# ─── Check 3: Tests pass ───────────────────────────────────────────────────────
echo -e "${BOLD}[3/8] Tests${RESET}"
TEST_CMD=""

# Determine test command from configured framework or auto-detect
case "${TEST_FRAMEWORK,,}" in
  vitest)       TEST_CMD="npx vitest run" ;;
  jest)         TEST_CMD="npx jest --passWithNoTests" ;;
  pytest)       TEST_CMD="python -m pytest" ;;
  rspec)        TEST_CMD="bundle exec rspec" ;;
  "go test")    TEST_CMD="go test ./..." ;;
  "cargo test") TEST_CMD="cargo test" ;;
  *)
    # Auto-detect from project files
    if [[ -f "package.json" ]]; then
      if grep -q '"test"' package.json 2>/dev/null; then
        TEST_CMD="npm test"
      fi
    elif [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
      TEST_CMD="python -m pytest"
    elif [[ -f "go.mod" ]]; then
      TEST_CMD="go test ./..."
    elif [[ -f "Cargo.toml" ]]; then
      TEST_CMD="cargo test"
    fi
    ;;
esac

if [[ -z "$TEST_CMD" ]]; then
  report_warn "No test framework detected, skipping test check"
else
  echo "         Running: ${TEST_CMD}"
  if eval "$TEST_CMD" > /dev/null 2>&1; then
    report_pass "Tests passed"
  else
    report_fail "Tests failed (run '${TEST_CMD}' for details)"
  fi
fi
echo ""

# ─── Check 4: Lint passes ──────────────────────────────────────────────────────
echo -e "${BOLD}[4/8] Lint${RESET}"
LINT_CMD=""

# Determine lint command from configured linter or auto-detect
case "${LINTER,,}" in
  eslint)    LINT_CMD="npx eslint . --max-warnings=0" ;;
  biome)     LINT_CMD="npx biome check ." ;;
  prettier)  LINT_CMD="npx prettier --check ." ;;
  ruff)      LINT_CMD="ruff check ." ;;
  flake8)    LINT_CMD="flake8 ." ;;
  rubocop)   LINT_CMD="bundle exec rubocop" ;;
  clippy)    LINT_CMD="cargo clippy -- -D warnings" ;;
  golangci*) LINT_CMD="golangci-lint run" ;;
  *)
    # Auto-detect from project files
    if [[ -f "package.json" ]]; then
      if grep -q '"lint"' package.json 2>/dev/null; then
        LINT_CMD="npm run lint"
      fi
    elif [[ -f "pyproject.toml" ]]; then
      if grep -q "ruff" pyproject.toml 2>/dev/null; then
        LINT_CMD="ruff check ."
      fi
    fi
    ;;
esac

if [[ -z "$LINT_CMD" ]]; then
  report_warn "No linter detected, skipping lint check"
else
  echo "         Running: ${LINT_CMD}"
  if eval "$LINT_CMD" > /dev/null 2>&1; then
    report_pass "Lint passed"
  else
    report_fail "Lint failed (run '${LINT_CMD}' for details)"
  fi
fi
echo ""

# ─── Check 5: No secrets in codebase ───────────────────────────────────────────
# Scans source code for common secret patterns. Excludes env files, lock files,
# node_modules, and this script itself to reduce false positives.
echo -e "${BOLD}[5/8] Secret Scan${RESET}"
SECRET_PATTERNS='(API_KEY|SECRET_KEY|PRIVATE_KEY|ACCESS_TOKEN|api_key|secret_key|private_key|access_token)\s*=\s*["\x27][A-Za-z0-9+/=_-]{8,}'

# Build a list of files to scan (exclude common non-source paths)
SECRETS_FOUND=false
SECRET_MATCHES=""

# Use grep to search for secret-like patterns in common source files
# Exclude: .env files (expected to have secrets), lock files, node_modules, .git, binary files
if command -v grep &> /dev/null; then
  SECRET_MATCHES=$(grep -rn --include="*.js" --include="*.ts" --include="*.jsx" --include="*.tsx" \
    --include="*.py" --include="*.rb" --include="*.go" --include="*.rs" --include="*.java" \
    --include="*.yaml" --include="*.yml" --include="*.json" --include="*.toml" \
    --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=vendor \
    --exclude-dir=.next --exclude-dir=dist --exclude-dir=build \
    --exclude=".env*" --exclude="*.lock" --exclude="*-lock.*" \
    --exclude="package-lock.json" --exclude="company.config.yaml" \
    -E "$SECRET_PATTERNS" . 2>/dev/null) || true
fi

if [[ -z "$SECRET_MATCHES" ]]; then
  report_pass "No hardcoded secrets detected"
else
  MATCH_COUNT=$(echo "$SECRET_MATCHES" | wc -l | xargs)
  report_fail "Potential secrets found in ${MATCH_COUNT} location(s)"
  echo "$SECRET_MATCHES" | head -5 | while IFS= read -r line; do
    echo "         $line"
  done
  if [[ "$MATCH_COUNT" -gt 5 ]]; then
    echo "         ... and $((MATCH_COUNT - 5)) more"
  fi
fi
echo ""

# ─── Check 6: Migrations reviewed ──────────────────────────────────────────────
# Checks if there are pending database migrations that have not been applied.
echo -e "${BOLD}[6/8] Migration Check${RESET}"
HAS_MIGRATIONS=false

case "${ORM,,}" in
  prisma)
    if [[ -d "prisma/migrations" ]]; then
      HAS_MIGRATIONS=true
      # Check for unapplied migrations by looking for migration directories
      # without a corresponding entry in the migrations table
      if command -v npx &> /dev/null; then
        if npx prisma migrate status 2>&1 | grep -q "have not yet been applied" 2>/dev/null; then
          report_warn "Pending Prisma migrations detected — review before deploying"
        else
          report_pass "No pending Prisma migrations"
        fi
      else
        report_warn "npx not available, cannot verify Prisma migration status"
      fi
    fi
    ;;
  drizzle)
    if [[ -d "drizzle" ]] || [[ -d "migrations" ]]; then
      HAS_MIGRATIONS=true
      report_warn "Drizzle migrations directory found — review pending migrations before deploying"
    fi
    ;;
  django*)
    if command -v python &> /dev/null; then
      HAS_MIGRATIONS=true
      if python manage.py showmigrations 2>&1 | grep -q "\[ \]" 2>/dev/null; then
        report_warn "Unapplied Django migrations detected — review before deploying"
      else
        report_pass "No pending Django migrations"
      fi
    fi
    ;;
  *)
    # Check for common migration directories
    for DIR in migrations db/migrate alembic/versions; do
      if [[ -d "$DIR" ]]; then
        HAS_MIGRATIONS=true
        report_warn "Migration directory '${DIR}' found — review pending migrations before deploying"
        break
      fi
    done
    ;;
esac

if [[ "$HAS_MIGRATIONS" == false ]]; then
  report_pass "No migration directories detected"
fi
echo ""

# ─── Check 7: Environment variables ────────────────────────────────────────────
# Compares .env.example with currently set environment variables to find gaps.
echo -e "${BOLD}[7/8] Environment Variables${RESET}"
if [[ -f ".env.example" ]]; then
  MISSING_VARS=()

  # Read variable names from .env.example (lines that look like KEY=value)
  while IFS= read -r line; do
    # Skip comments and empty lines
    if [[ "$line" =~ ^#.*$ ]] || [[ -z "$line" ]]; then
      continue
    fi
    # Extract variable name (everything before the first =)
    VAR_NAME=$(echo "$line" | cut -d'=' -f1 | xargs)
    if [[ -n "$VAR_NAME" ]]; then
      # Check if the variable is set in the current environment or in a .env file
      if [[ -z "${!VAR_NAME:-}" ]]; then
        # Also check .env file if it exists
        if [[ -f ".env" ]]; then
          if ! grep -q "^${VAR_NAME}=" .env 2>/dev/null; then
            MISSING_VARS+=("$VAR_NAME")
          fi
        else
          MISSING_VARS+=("$VAR_NAME")
        fi
      fi
    fi
  done < .env.example

  if [[ ${#MISSING_VARS[@]} -eq 0 ]]; then
    report_pass "All environment variables from .env.example are set"
  else
    report_warn "Missing environment variables (${#MISSING_VARS[@]}):"
    for VAR in "${MISSING_VARS[@]+"${MISSING_VARS[@]}"}"; do
      echo "         - ${VAR}"
    done
  fi
else
  report_warn "No .env.example file found — cannot verify environment variables"
fi
echo ""

# ─── Check 8: Version management ─────────────────────────────────────────────
echo -e "${BOLD}[8/8] Version Management${RESET}"

APP_VERSION=""
APP_VERSION_SRC=""

# Detect app version file (package.json > pyproject.toml > VERSION)
if [[ -f "package.json" ]]; then
  APP_VERSION=$(grep '"version"' package.json | head -1 | sed 's/.*"version": *"\([^"]*\)".*/\1/' || true)
  APP_VERSION_SRC="package.json"
elif [[ -f "pyproject.toml" ]]; then
  APP_VERSION=$(grep '^version = ' pyproject.toml | head -1 | sed 's/version = "\([^"]*\)".*/\1/' || true)
  APP_VERSION_SRC="pyproject.toml"
elif [[ -f "VERSION" ]]; then
  # Skip if this is Company OS's VERSION file
  VER_CONTENT=$(head -1 VERSION | tr -d '[:space:]')
  COS_CONTENT=""
  if [[ -f ".company-os/version" ]]; then
    COS_CONTENT=$(head -1 .company-os/version | tr -d '[:space:]')
  elif [[ -f ".company-os-version" ]]; then
    COS_CONTENT=$(head -1 .company-os-version | tr -d '[:space:]')
  fi
  if [[ "$VER_CONTENT" != "$COS_CONTENT" ]]; then
    APP_VERSION="$VER_CONTENT"
    APP_VERSION_SRC="VERSION"
  fi
fi

if [[ -z "$APP_VERSION" ]]; then
  report_warn "No app version file found (package.json, pyproject.toml, or VERSION)"
elif ! [[ "$APP_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
  report_fail "App version '${APP_VERSION}' in ${APP_VERSION_SRC} is not valid semver"
else
  report_pass "App version: ${APP_VERSION} (${APP_VERSION_SRC})"

  # Check if version has been bumped since last release
  if [[ -f ".previous-version" ]]; then
    PREV_APP_VERSION=$(head -1 .previous-version | tr -d '[:space:]')
    if [[ "$APP_VERSION" == "$PREV_APP_VERSION" ]]; then
      report_warn "Version unchanged since last release (${PREV_APP_VERSION}) — consider bumping"
    else
      report_pass "Version bumped: ${PREV_APP_VERSION} → ${APP_VERSION}"
    fi
  fi
fi
echo ""

# ─── Summary ────────────────────────────────────────────────────────────────────
TOTAL=$((PASS_COUNT + WARN_COUNT + FAIL_COUNT))
echo "================================"
echo -e "${BOLD}Pre-Deploy Summary${RESET}: ${TOTAL} check(s)"
echo -e "  ${GREEN}Pass:${RESET}     ${PASS_COUNT}"
echo -e "  ${YELLOW}Warnings:${RESET} ${WARN_COUNT}"
echo -e "  ${RED}Failures:${RESET} ${FAIL_COUNT}"
echo ""

# ─── Exit code: 0=all pass, 1=warnings only, 2=any failures ────────────────────
if [[ $FAIL_COUNT -gt 0 ]]; then
  echo -e "${RED}BLOCKED: Fix failures before deploying.${RESET}"
  exit 2
elif [[ $WARN_COUNT -gt 0 ]]; then
  echo -e "${YELLOW}CAUTION: Review warnings before deploying.${RESET}"
  exit 1
else
  echo -e "${GREEN}READY: All checks passed. Safe to deploy.${RESET}"
  exit 0
fi
