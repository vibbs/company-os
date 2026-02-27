#!/usr/bin/env bash
set -euo pipefail

# ─── App Version Bump Tool ──────────────────────────────────────────────────────
# Detects the app version file, bumps it by the specified type, updates CHANGELOG.md,
# and creates a git tag. Stage-aware: idea/mvp stay at v0.x.x.
#
# Usage: ./tools/versioning/version-bump.sh <major|minor|patch> [--dry-run] [--no-tag]
# ─────────────────────────────────────────────────────────────────────────────────

# ─── Colors ──────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ─── Parse arguments ────────────────────────────────────────────────────────────
BUMP_TYPE=""
DRY_RUN=false
NO_TAG=false

for arg in "$@"; do
  case "$arg" in
    major|minor|patch) BUMP_TYPE="$arg" ;;
    --dry-run) DRY_RUN=true ;;
    --no-tag) NO_TAG=true ;;
    -h|--help)
      echo "Usage: ./tools/versioning/version-bump.sh <major|minor|patch> [--dry-run] [--no-tag]"
      echo ""
      echo "Options:"
      echo "  major      Bump major version (breaking changes)"
      echo "  minor      Bump minor version (new features)"
      echo "  patch      Bump patch version (bug fixes)"
      echo "  --dry-run  Show what would change without modifying files"
      echo "  --no-tag   Skip git tag creation"
      echo ""
      echo "Stage-aware:"
      echo "  idea/mvp stages: version stays at 0.x.x (major bumps become minor)"
      echo "  growth/scale stages: full semver (warns if still at 0.x.x)"
      exit 0
      ;;
    *)
      echo -e "${RED}ERROR: Unknown argument: $arg${RESET}"
      echo "Usage: ./tools/versioning/version-bump.sh <major|minor|patch> [--dry-run] [--no-tag]"
      exit 1
      ;;
  esac
done

if [[ -z "$BUMP_TYPE" ]]; then
  echo -e "${RED}ERROR: Bump type required (major, minor, or patch)${RESET}"
  echo "Usage: ./tools/versioning/version-bump.sh <major|minor|patch> [--dry-run] [--no-tag]"
  exit 1
fi

# ─── Find project root ──────────────────────────────────────────────────────────
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$PROJECT_ROOT"

# ─── Read company stage ─────────────────────────────────────────────────────────
COMPANY_STAGE="growth"  # Default: full enforcement
CONFIG_FILE="$PROJECT_ROOT/company.config.yaml"
if [[ -f "$CONFIG_FILE" ]]; then
  STAGE_VALUE=$(grep "^  stage:" "$CONFIG_FILE" | sed 's/.*stage: *//' | tr -d '"' | tr -d "'" | sed 's/ *#.*//' || true)
  if [[ -n "$STAGE_VALUE" ]]; then
    COMPANY_STAGE="$STAGE_VALUE"
  fi
fi

# ─── Detect version file ────────────────────────────────────────────────────────
VERSION_FILE=""
CURRENT_VERSION=""
VERSION_FORMAT=""  # json, toml, plain

detect_version_file() {
  # 1. package.json (Node.js/TypeScript)
  if [[ -f "package.json" ]]; then
    local ver
    ver=$(grep '"version"' package.json | head -1 | sed 's/.*"version": *"\([^"]*\)".*/\1/' || true)
    if [[ -n "$ver" && "$ver" =~ ^[0-9] ]]; then
      VERSION_FILE="package.json"
      CURRENT_VERSION="$ver"
      VERSION_FORMAT="json"
      return 0
    fi
  fi

  # 2. pyproject.toml (Python)
  if [[ -f "pyproject.toml" ]]; then
    local ver
    ver=$(grep '^version = ' pyproject.toml | head -1 | sed 's/version = "\([^"]*\)".*/\1/' || true)
    if [[ -n "$ver" && "$ver" =~ ^[0-9] ]]; then
      VERSION_FILE="pyproject.toml"
      CURRENT_VERSION="$ver"
      VERSION_FORMAT="toml"
      return 0
    fi
  fi

  # 3. VERSION file (Go, generic) — but NOT if it matches Company OS version
  if [[ -f "VERSION" ]]; then
    local ver
    ver=$(head -1 VERSION | tr -d '[:space:]')
    # Skip if this is the Company OS template version
    if [[ -f ".company-os-version" ]]; then
      local cos_ver
      cos_ver=$(head -1 .company-os-version | tr -d '[:space:]')
      if [[ "$ver" == "$cos_ver" ]]; then
        # This is Company OS's VERSION file, not the app's
        return 1
      fi
    fi
    if [[ -n "$ver" && "$ver" =~ ^[0-9] ]]; then
      VERSION_FILE="VERSION"
      CURRENT_VERSION="$ver"
      VERSION_FORMAT="plain"
      return 0
    fi
  fi

  return 1
}

if ! detect_version_file; then
  echo -e "${RED}ERROR: No app version file found.${RESET}"
  echo "Expected one of:"
  echo "  - package.json with \"version\" field"
  echo "  - pyproject.toml with version field"
  echo "  - VERSION file (plain text)"
  echo ""
  echo "Run /setup to initialize app versioning, or create a VERSION file:"
  echo "  echo '0.1.0' > VERSION"
  exit 1
fi

# ─── Parse current version ──────────────────────────────────────────────────────
if ! [[ "$CURRENT_VERSION" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
  echo -e "${RED}ERROR: Current version '$CURRENT_VERSION' is not valid semver (expected MAJOR.MINOR.PATCH)${RESET}"
  exit 1
fi

CUR_MAJOR="${BASH_REMATCH[1]}"
CUR_MINOR="${BASH_REMATCH[2]}"
CUR_PATCH="${BASH_REMATCH[3]}"

# ─── Apply stage-aware bump rules ───────────────────────────────────────────────
EFFECTIVE_BUMP="$BUMP_TYPE"
STAGE_NOTE=""

case "$COMPANY_STAGE" in
  idea|mvp)
    if [[ "$BUMP_TYPE" == "major" ]]; then
      if [[ "$CUR_MAJOR" -eq 0 ]]; then
        # v0.x breaking changes bump minor (standard v0 semver)
        EFFECTIVE_BUMP="minor"
        STAGE_NOTE="(stage: $COMPANY_STAGE — major bump capped to minor for v0.x.x)"
      else
        # Shouldn't happen in idea/mvp, but handle gracefully
        STAGE_NOTE="(stage: $COMPANY_STAGE — warning: version is already v${CUR_MAJOR}.x.x)"
      fi
    fi
    ;;
  growth|scale)
    if [[ "$CUR_MAJOR" -eq 0 ]]; then
      echo -e "${YELLOW}WARNING: App is at v${CURRENT_VERSION} but company stage is '${COMPANY_STAGE}'.${RESET}"
      echo -e "${YELLOW}Consider bumping to v1.0.0 to signal production readiness.${RESET}"
      echo -e "${YELLOW}To do so, manually set the version to 1.0.0 and run this script with 'patch'.${RESET}"
      echo ""
      STAGE_NOTE="(stage: $COMPANY_STAGE — still at v0.x.x)"
    fi
    ;;
esac

# ─── Calculate new version ──────────────────────────────────────────────────────
NEW_MAJOR="$CUR_MAJOR"
NEW_MINOR="$CUR_MINOR"
NEW_PATCH="$CUR_PATCH"

case "$EFFECTIVE_BUMP" in
  major)
    NEW_MAJOR=$((CUR_MAJOR + 1))
    NEW_MINOR=0
    NEW_PATCH=0
    ;;
  minor)
    NEW_MINOR=$((CUR_MINOR + 1))
    NEW_PATCH=0
    ;;
  patch)
    NEW_PATCH=$((CUR_PATCH + 1))
    ;;
esac

NEW_VERSION="${NEW_MAJOR}.${NEW_MINOR}.${NEW_PATCH}"
TODAY=$(date +%Y-%m-%d)

# ─── Display plan ───────────────────────────────────────────────────────────────
echo -e "${BOLD}App Version Bump${RESET}"
echo "================================"
echo -e "  File:      ${VERSION_FILE}"
echo -e "  Current:   ${CURRENT_VERSION}"
echo -e "  Bump:      ${BUMP_TYPE}${STAGE_NOTE:+ ${DIM}${STAGE_NOTE}${RESET}}"
echo -e "  New:       ${GREEN}${NEW_VERSION}${RESET}"
echo -e "  Stage:     ${COMPANY_STAGE}"
echo -e "  Date:      ${TODAY}"
echo ""

if [[ "$DRY_RUN" == true ]]; then
  echo -e "${YELLOW}DRY RUN — no files modified.${RESET}"
  exit 0
fi

# ─── Write new version to file ──────────────────────────────────────────────────
case "$VERSION_FORMAT" in
  json)
    # Update package.json version field
    if [[ "$(uname)" == "Darwin" ]]; then
      sed -i '' "s/\"version\": *\"${CURRENT_VERSION}\"/\"version\": \"${NEW_VERSION}\"/" "$VERSION_FILE"
    else
      sed -i "s/\"version\": *\"${CURRENT_VERSION}\"/\"version\": \"${NEW_VERSION}\"/" "$VERSION_FILE"
    fi
    echo -e "  ${GREEN}Updated${RESET}  ${VERSION_FILE} → ${NEW_VERSION}"
    ;;
  toml)
    # Update pyproject.toml version field
    if [[ "$(uname)" == "Darwin" ]]; then
      sed -i '' "s/^version = \"${CURRENT_VERSION}\"/version = \"${NEW_VERSION}\"/" "$VERSION_FILE"
    else
      sed -i "s/^version = \"${CURRENT_VERSION}\"/version = \"${NEW_VERSION}\"/" "$VERSION_FILE"
    fi
    echo -e "  ${GREEN}Updated${RESET}  ${VERSION_FILE} → ${NEW_VERSION}"
    ;;
  plain)
    echo "$NEW_VERSION" > "$VERSION_FILE"
    echo -e "  ${GREEN}Updated${RESET}  ${VERSION_FILE} → ${NEW_VERSION}"
    ;;
esac

# ─── Update CHANGELOG.md ────────────────────────────────────────────────────────
if [[ -f "CHANGELOG.md" ]]; then
  # Insert versioned heading after ## [Unreleased] line
  # Pattern: ## [Unreleased] → ## [Unreleased]\n\n## [NEW_VERSION] - DATE
  if grep -q '## \[Unreleased\]' CHANGELOG.md; then
    if [[ "$(uname)" == "Darwin" ]]; then
      sed -i '' "s/## \[Unreleased\]/## [Unreleased]\\
\\
## [${NEW_VERSION}] - ${TODAY}/" CHANGELOG.md
    else
      sed -i "s/## \[Unreleased\]/## [Unreleased]\n\n## [${NEW_VERSION}] - ${TODAY}/" CHANGELOG.md
    fi
    echo -e "  ${GREEN}Updated${RESET}  CHANGELOG.md → [${NEW_VERSION}] - ${TODAY}"
  else
    echo -e "  ${YELLOW}Warning${RESET}  CHANGELOG.md exists but has no [Unreleased] section — skipped"
  fi
else
  echo -e "  ${DIM}Skipped${RESET}  CHANGELOG.md (not found)"
fi

# ─── Save previous version ──────────────────────────────────────────────────────
echo "$CURRENT_VERSION" > .previous-version
echo -e "  ${GREEN}Updated${RESET}  .previous-version → ${CURRENT_VERSION}"

# ─── Git tag ─────────────────────────────────────────────────────────────────────
if [[ "$NO_TAG" == false ]]; then
  if command -v git &> /dev/null && [[ -d ".git" ]]; then
    TAG="v${NEW_VERSION}"
    if git tag -l "$TAG" | grep -q "$TAG"; then
      echo -e "  ${YELLOW}Warning${RESET}  Git tag ${TAG} already exists — skipped"
    else
      git tag "$TAG"
      echo -e "  ${GREEN}Created${RESET}  Git tag: ${TAG}"
    fi
  else
    echo -e "  ${DIM}Skipped${RESET}  Git tag (not a git repository)"
  fi
fi

# ─── Summary ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}Version bumped: ${CURRENT_VERSION} → ${NEW_VERSION}${RESET}"
