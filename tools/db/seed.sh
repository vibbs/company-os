#!/usr/bin/env bash
# Tool: Seed Data Runner
# Description: Runs seed data scenarios to populate the database with test data
# Usage: ./tools/db/seed.sh [--reset] [--dry-run] [--list] <scenario>
# Inputs: scenario name (empty, minimal, nominal, edge-cases, high-volume, error-states)
# Outputs: exit 0 on success, exit 1 on failure
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
CONFIG_FILE="$PROJECT_ROOT/company.config.yaml"

# Parse flags
RESET=false
DRY_RUN=false
LIST=false
SCENARIO=""

for arg in "$@"; do
  case "$arg" in
    --reset) RESET=true ;;
    --dry-run) DRY_RUN=true ;;
    --list) LIST=true ;;
    --all) SCENARIO="all" ;;
    -*) echo "ERROR: Unknown flag: $arg"; exit 1 ;;
    *) SCENARIO="$arg" ;;
  esac
done

VALID_SCENARIOS=("empty" "minimal" "nominal" "edge-cases" "high-volume" "error-states")

# --- Helper: extract value from company.config.yaml ---
extract_config() {
  local KEY="$1"
  if [[ -f "$CONFIG_FILE" ]]; then
    grep "^  ${KEY}:" "$CONFIG_FILE" 2>/dev/null | sed "s/.*${KEY}: *//" | tr -d '"' | tr -d "'" || true
  fi
}

# --- Helper: detect tech stack from project files ---
detect_language() {
  if [[ -f "$PROJECT_ROOT/package.json" ]]; then
    if [[ -f "$PROJECT_ROOT/tsconfig.json" ]]; then
      echo "typescript"
    else
      echo "javascript"
    fi
  elif [[ -f "$PROJECT_ROOT/requirements.txt" ]] || [[ -f "$PROJECT_ROOT/pyproject.toml" ]] || [[ -f "$PROJECT_ROOT/setup.py" ]]; then
    echo "python"
  elif [[ -f "$PROJECT_ROOT/go.mod" ]]; then
    echo "go"
  else
    echo "unknown"
  fi
}

# --- List available scenarios ---
if [[ "$LIST" == "true" ]]; then
  echo "Available seed data scenarios:"
  echo ""
  for s in "${VALID_SCENARIOS[@]}"; do
    case "$s" in
      empty)       echo "  empty        - Zero records, clean slate" ;;
      minimal)     echo "  minimal      - 1-2 records per entity, minimum viable" ;;
      nominal)     echo "  nominal      - 10-50 records, realistic variety" ;;
      edge-cases)  echo "  edge-cases   - Boundary values, unicode, nulls, max lengths" ;;
      high-volume) echo "  high-volume  - 1000+ records per entity (set SEED_VOLUME env var)" ;;
      error-states) echo "  error-states - Invalid/unusual states for resilience testing" ;;
    esac
  done
  echo ""

  # Check which seed files exist
  SEEDS_DIR="$PROJECT_ROOT/seeds"
  if [[ -d "$SEEDS_DIR" ]]; then
    echo "Seed files found in seeds/:"
    ls -1 "$SEEDS_DIR/scenarios/" 2>/dev/null || echo "  (no scenario files yet)"
  else
    echo "No seeds/ directory found. Run /seed-data to generate seed files."
  fi
  exit 0
fi

# --- Validate scenario ---
if [[ -z "$SCENARIO" ]]; then
  echo "ERROR: No scenario specified"
  echo "Usage: ./tools/db/seed.sh [--reset] [--dry-run] [--list] <scenario>"
  echo "Run with --list to see available scenarios"
  exit 1
fi

if [[ "$SCENARIO" != "all" ]]; then
  FOUND=false
  for vs in "${VALID_SCENARIOS[@]}"; do
    if [[ "$SCENARIO" == "$vs" ]]; then
      FOUND=true
      break
    fi
  done
  if [[ "$FOUND" == "false" ]]; then
    echo "ERROR: Invalid scenario: '$SCENARIO'"
    echo "Valid scenarios: ${VALID_SCENARIOS[*]}"
    exit 1
  fi
fi

# --- Detect tech stack ---
LANGUAGE=$(extract_config "language")
if [[ -z "$LANGUAGE" ]]; then
  LANGUAGE=$(detect_language)
fi

DATABASE=$(extract_config "database")

echo "=== Seed Data Runner ==="
echo "Scenario: $SCENARIO"
echo "Language: $LANGUAGE"
echo "Database: $DATABASE"
echo "Reset: $RESET"
echo "Dry run: $DRY_RUN"
echo ""

SEEDS_DIR="$PROJECT_ROOT/seeds"

if [[ ! -d "$SEEDS_DIR" ]]; then
  echo "ERROR: No seeds/ directory found at project root"
  echo "Run /seed-data to generate seed files first"
  exit 1
fi

# --- Build scenario list ---
SCENARIOS_TO_RUN=()
if [[ "$SCENARIO" == "all" ]]; then
  SCENARIOS_TO_RUN=("${VALID_SCENARIOS[@]}")
else
  SCENARIOS_TO_RUN=("$SCENARIO")
fi

# --- Execute based on language ---
for CURRENT_SCENARIO in "${SCENARIOS_TO_RUN[@]}"; do
  echo "--- Running scenario: $CURRENT_SCENARIO ---"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY RUN] Would execute scenario: $CURRENT_SCENARIO"
  fi

  case "$LANGUAGE" in
    typescript|javascript)
      SCENARIO_FILE="$SEEDS_DIR/scenarios/${CURRENT_SCENARIO}.ts"
      JS_SCENARIO_FILE="$SEEDS_DIR/scenarios/${CURRENT_SCENARIO}.js"

      if [[ "$RESET" == "true" && "$CURRENT_SCENARIO" == "${SCENARIOS_TO_RUN[0]}" ]]; then
        RESET_FILE="$SEEDS_DIR/scenarios/empty.ts"
        if [[ ! -f "$RESET_FILE" ]]; then
          RESET_FILE="$SEEDS_DIR/scenarios/empty.js"
        fi
        if [[ -f "$RESET_FILE" ]]; then
          if [[ "$DRY_RUN" == "true" ]]; then
            echo "[DRY RUN] Would reset database using: $RESET_FILE"
          else
            echo "Resetting database..."
            if command -v npx &>/dev/null; then
              npx tsx "$RESET_FILE" 2>/dev/null || node "$RESET_FILE"
            else
              node "$RESET_FILE"
            fi
          fi
        fi
      fi

      if [[ -f "$SCENARIO_FILE" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
          echo "[DRY RUN] Would run: npx tsx $SCENARIO_FILE"
        else
          if command -v npx &>/dev/null; then
            npx tsx "$SCENARIO_FILE" 2>/dev/null || node "$SCENARIO_FILE"
          else
            node "$SCENARIO_FILE"
          fi
        fi
      elif [[ -f "$JS_SCENARIO_FILE" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
          echo "[DRY RUN] Would run: node $JS_SCENARIO_FILE"
        else
          node "$JS_SCENARIO_FILE"
        fi
      else
        echo "WARNING: Scenario file not found: $SCENARIO_FILE"
        echo "Run /seed-data to generate seed files"
        exit 1
      fi
      ;;

    python)
      # Convert scenario name to Python module (edge-cases -> edge_cases)
      PY_SCENARIO=$(echo "$CURRENT_SCENARIO" | tr '-' '_')
      SCENARIO_FILE="$SEEDS_DIR/scenarios/${PY_SCENARIO}.py"

      if [[ "$RESET" == "true" && "$CURRENT_SCENARIO" == "${SCENARIOS_TO_RUN[0]}" ]]; then
        if [[ -f "$SEEDS_DIR/scenarios/empty.py" ]]; then
          if [[ "$DRY_RUN" == "true" ]]; then
            echo "[DRY RUN] Would reset database using: seeds/scenarios/empty.py"
          else
            echo "Resetting database..."
            python -m seeds.scenarios.empty
          fi
        fi
      fi

      if [[ -f "$SCENARIO_FILE" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
          echo "[DRY RUN] Would run: python -m seeds.scenarios.${PY_SCENARIO}"
        else
          python -m "seeds.scenarios.${PY_SCENARIO}"
        fi
      else
        echo "WARNING: Scenario file not found: $SCENARIO_FILE"
        exit 1
      fi
      ;;

    go)
      SCENARIO_FILE="$SEEDS_DIR/scenarios/${CURRENT_SCENARIO}.go"

      if [[ "$RESET" == "true" && "$CURRENT_SCENARIO" == "${SCENARIOS_TO_RUN[0]}" ]]; then
        if [[ -f "$SEEDS_DIR/scenarios/empty.go" ]]; then
          if [[ "$DRY_RUN" == "true" ]]; then
            echo "[DRY RUN] Would reset database using: seeds/scenarios/empty.go"
          else
            echo "Resetting database..."
            go run "$SEEDS_DIR/scenarios/empty.go"
          fi
        fi
      fi

      if [[ -f "$SCENARIO_FILE" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
          echo "[DRY RUN] Would run: go run $SCENARIO_FILE"
        else
          go run "$SCENARIO_FILE"
        fi
      else
        echo "WARNING: Scenario file not found: $SCENARIO_FILE"
        exit 1
      fi
      ;;

    *)
      # Fallback: look for SQL files
      SCENARIO_FILE="$SEEDS_DIR/${CURRENT_SCENARIO}.sql"
      if [[ -f "$SCENARIO_FILE" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
          echo "[DRY RUN] Would execute SQL file: $SCENARIO_FILE"
          echo "[DRY RUN] Database: ${DATABASE:-unknown}"
        else
          case "$DATABASE" in
            postgres|postgresql)
              psql "${DATABASE_URL:-}" -f "$SCENARIO_FILE"
              ;;
            mysql)
              mysql "${DATABASE_URL:-}" < "$SCENARIO_FILE"
              ;;
            sqlite)
              sqlite3 "${DATABASE_URL:-db.sqlite}" < "$SCENARIO_FILE"
              ;;
            *)
              echo "ERROR: Cannot determine how to execute SQL for database: ${DATABASE:-unknown}"
              echo "Set DATABASE_URL or configure tech_stack.database in company.config.yaml"
              exit 1
              ;;
          esac
        fi
      else
        echo "ERROR: No seed file found for scenario '$CURRENT_SCENARIO' and language '$LANGUAGE'"
        echo "Looked for: $SCENARIO_FILE"
        echo "Run /seed-data to generate seed files"
        exit 1
      fi
      ;;
  esac

  echo "--- Scenario $CURRENT_SCENARIO complete ---"
  echo ""
done

echo "✅ Seed data loaded successfully"
