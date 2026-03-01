#!/usr/bin/env bash
# Tool: T-OPS-03 Token Cost Ledger
# Description: Logs, summarizes, and exports AI token usage and costs (COGS)
# Usage: ./tools/ops/token-ledger.sh <subcommand> [options]
# Inputs: token usage data (flags or interactive), company.config.yaml for budget
# Outputs: JSONL ledger entries, summary reports, CSV exports
set -euo pipefail

# ─── Paths ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$REPO_ROOT/company.config.yaml"
LEDGER_DIR="$REPO_ROOT/cogs/ai-ledger"
LEDGER_FILE="$LEDGER_DIR/entries.jsonl"
SUMMARY_FILE="$LEDGER_DIR/summary.md"

# ─── Color codes (portable: works on macOS and Linux) ─────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ─── Usage ────────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $(basename "$0") <subcommand> [options]

Track AI token costs as COGS.

Subcommands:
  log             Add a ledger entry
  summary         Show cost totals (daily/weekly/monthly)
  feature-cost    Show total cost for a specific feature (PRD/RFC)
  export          Export ledger to CSV
  budget          Show current month spend vs budget

Run $(basename "$0") <subcommand> --help for subcommand-specific options.

Examples:
  $(basename "$0") log --model claude-sonnet-4-20250514 --input-tokens 10000 --output-tokens 3000
  $(basename "$0") summary --period monthly
  $(basename "$0") feature-cost PRD-001
  $(basename "$0") budget

Data: $LEDGER_FILE
EOF
  exit 0
}

# ─── Helpers ──────────────────────────────────────────────────────────────────

read_config() {
  local key="$1"
  local value=""
  if [[ -f "$CONFIG_FILE" ]]; then
    value=$(grep -v '^ *#' "$CONFIG_FILE" 2>/dev/null \
      | grep "${key}:" | head -1 \
      | sed "s/.*${key}: *//" \
      | sed 's/ *#.*//' \
      | tr -d '"' | tr -d "'" \
      | xargs) || true
  fi
  echo "$value"
}

ensure_ledger_dir() {
  if [[ ! -d "$LEDGER_DIR" ]]; then
    mkdir -p "$LEDGER_DIR"
  fi
}

# Calculate cost from model and token counts (rates per million tokens)
# Uses case statement for bash 3.2 compat (no associative arrays)
calculate_cost() {
  local model="$1"
  local input_tokens="$2"
  local output_tokens="$3"
  local cache_read="$4"
  local cache_write="$5"

  local input_rate=0
  local output_rate=0
  local cache_read_rate=0
  local cache_write_rate=0

  # Normalize model name to lowercase for matching
  local model_lower
  model_lower=$(echo "$model" | tr '[:upper:]' '[:lower:]')

  case "$model_lower" in
    claude-opus-4.6*|claude-opus-4-6*)
      input_rate=5; output_rate=25; cache_read_rate=0.50; cache_write_rate=6.25 ;;
    claude-opus-4.5*|claude-opus-4-5*)
      input_rate=5; output_rate=25; cache_read_rate=0.50; cache_write_rate=6.25 ;;
    claude-opus-4.1*|claude-opus-4-1*|claude-opus-4-20250514*)
      input_rate=15; output_rate=75; cache_read_rate=1.50; cache_write_rate=18.75 ;;
    claude-opus-4*)
      input_rate=15; output_rate=75; cache_read_rate=1.50; cache_write_rate=18.75 ;;
    claude-sonnet-4-6*|claude-sonnet-4-5*|claude-sonnet-4-20250514*)
      input_rate=3; output_rate=15; cache_read_rate=0.30; cache_write_rate=3.75 ;;
    claude-sonnet-4*)
      input_rate=3; output_rate=15; cache_read_rate=0.30; cache_write_rate=3.75 ;;
    claude-haiku-4.5*|claude-haiku-4-5*)
      input_rate=1; output_rate=5; cache_read_rate=0.10; cache_write_rate=1.25 ;;
    claude-haiku-3.5*|claude-haiku-3-5*)
      input_rate=0.80; output_rate=4; cache_read_rate=0.08; cache_write_rate=1 ;;
    gpt-4o-mini*)
      input_rate=0.15; output_rate=0.60; cache_read_rate=0.075; cache_write_rate=0.15 ;;
    gpt-4o*)
      input_rate=2.50; output_rate=10; cache_read_rate=1.25; cache_write_rate=2.50 ;;
    gemini-2.0-flash*|gemini-2*flash*)
      input_rate=0.10; output_rate=0.40; cache_read_rate=0; cache_write_rate=0 ;;
    gemini-2.5-pro*|gemini*pro*)
      input_rate=1.25; output_rate=10; cache_read_rate=0; cache_write_rate=0 ;;
    *)
      echo "UNKNOWN"
      return ;;
  esac

  awk "BEGIN { printf \"%.6f\", ($input_tokens/1000000)*$input_rate + ($output_tokens/1000000)*$output_rate + ($cache_read/1000000)*$cache_read_rate + ($cache_write/1000000)*$cache_write_rate }"
}

# Extract a string field from a JSONL line without jq
parse_field() {
  local line="$1"
  local field="$2"
  # Try quoted string value first, then numeric/unquoted value
  local val
  val=$(echo "$line" | sed -n 's/.*"'"$field"'" *: *"\([^"]*\)".*/\1/p')
  if [[ -z "$val" ]]; then
    val=$(echo "$line" | sed -n 's/.*"'"$field"'" *: *\([^,}]*\).*/\1/p' | tr -d ' ')
  fi
  echo "$val"
}

format_usd() {
  local amount="$1"
  awk "BEGIN { printf \"$%.2f\", $amount }"
}

format_number() {
  local num="$1"
  # Portable thousands separators (works on macOS awk + gawk)
  echo "$num" | awk '{
    n = int($1 + 0)
    if (n == 0) { print "0"; next }
    s = ""
    while (n >= 1000) {
      s = sprintf(",%03d%s", n % 1000, s)
      n = int(n / 1000)
    }
    print n s
  }'
}

budget_color() {
  local pct="$1"
  local result
  result=$(awk "BEGIN { if ($pct >= 80) print \"red\"; else if ($pct >= 50) print \"yellow\"; else print \"green\" }")
  case "$result" in
    red) echo "$RED" ;;
    yellow) echo "$YELLOW" ;;
    green) echo "$GREEN" ;;
  esac
}

# ─── Subcommand: log ─────────────────────────────────────────────────────────

cmd_log() {
  local model="" input_tokens=0 output_tokens=0 cache_read=0 cache_write=0
  local cost="" agent="manual" category="ad-hoc" feature_id="" session_id="" notes=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help)
        cat <<EOF
Usage: $(basename "$0") log [OPTIONS]

Add a token cost entry to the ledger.

Options:
  --model <name>          Model name (e.g., claude-sonnet-4-20250514) [required]
  --input-tokens <n>      Input token count [required]
  --output-tokens <n>     Output token count [required]
  --cache-read <n>        Cache read tokens (default: 0)
  --cache-write <n>       Cache write tokens (default: 0)
  --cost <usd>            Override auto-calculated cost (USD)
  --agent <name>          Agent name (default: manual)
  --category <cat>        ship-flow | agent-session | research | ad-hoc (default: ad-hoc)
  --feature <id>          Feature ID to tag (e.g., PRD-001)
  --session <id>          Session identifier
  --notes <text>          Free-form notes
EOF
        exit 0
        ;;
      --model) model="$2"; shift 2 ;;
      --input-tokens) input_tokens="$2"; shift 2 ;;
      --output-tokens) output_tokens="$2"; shift 2 ;;
      --cache-read) cache_read="$2"; shift 2 ;;
      --cache-write) cache_write="$2"; shift 2 ;;
      --cost) cost="$2"; shift 2 ;;
      --agent) agent="$2"; shift 2 ;;
      --category) category="$2"; shift 2 ;;
      --feature) feature_id="$2"; shift 2 ;;
      --session) session_id="$2"; shift 2 ;;
      --notes) notes="$2"; shift 2 ;;
      *) echo -e "${RED}Unknown option: $1${RESET}"; exit 2 ;;
    esac
  done

  # Validate required fields
  if [[ -z "$model" ]]; then
    echo -e "${RED}Error: --model is required${RESET}"
    exit 2
  fi
  if [[ "$input_tokens" -eq 0 && "$output_tokens" -eq 0 ]]; then
    echo -e "${RED}Error: --input-tokens and/or --output-tokens must be > 0${RESET}"
    exit 2
  fi

  # Validate category
  case "$category" in
    ship-flow|agent-session|research|ad-hoc) ;;
    *) echo -e "${RED}Error: --category must be one of: ship-flow, agent-session, research, ad-hoc${RESET}"; exit 2 ;;
  esac

  # Auto-calculate cost if not provided
  if [[ -z "$cost" ]]; then
    cost=$(calculate_cost "$model" "$input_tokens" "$output_tokens" "$cache_read" "$cache_write")
    if [[ "$cost" == "UNKNOWN" ]]; then
      echo -e "${YELLOW}Warning: Unknown model '$model' — cannot auto-calculate cost. Use --cost to provide manually.${RESET}"
      exit 2
    fi
  fi

  # Generate timestamp and default session_id
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  if [[ -z "$session_id" ]]; then
    session_id="manual-$(date -u +"%Y%m%d-%H%M%S")"
  fi

  # Escape notes for JSON (basic: replace quotes and backslashes)
  local escaped_notes
  escaped_notes=$(echo "$notes" | sed 's/\\/\\\\/g; s/"/\\"/g')

  # Build JSONL entry
  local entry
  entry=$(printf '{"timestamp":"%s","session_id":"%s","agent":"%s","model":"%s","input_tokens":%d,"output_tokens":%d,"cache_read_tokens":%d,"cache_write_tokens":%d,"cost_usd":%s,"feature_id":"%s","category":"%s","notes":"%s"}' \
    "$timestamp" "$session_id" "$agent" "$model" \
    "$input_tokens" "$output_tokens" "$cache_read" "$cache_write" \
    "$cost" "$feature_id" "$category" "$escaped_notes")

  # Write to ledger
  ensure_ledger_dir
  echo "$entry" >> "$LEDGER_FILE"

  # Show confirmation
  local cost_fmt
  cost_fmt=$(format_usd "$cost")
  echo -e "${GREEN}Entry logged${RESET}: $cost_fmt"
  echo -e "  Model: $model | Agent: $agent | Category: $category"
  if [[ -n "$feature_id" ]]; then
    echo -e "  Feature: ${BOLD}$feature_id${RESET}"
  fi

  # Show budget impact if budget is set
  local budget
  budget=$(read_config "cost_budget_monthly")
  if [[ -n "$budget" && "$budget" != "0" ]]; then
    local month_total
    local current_month
    current_month=$(date -u +"%Y-%m")
    month_total=$(grep "\"$current_month" "$LEDGER_FILE" 2>/dev/null | awk -F'"cost_usd":' '{sum += $2+0} END {printf "%.2f", sum}') || true
    if [[ -z "$month_total" ]]; then month_total="0.00"; fi
    local pct
    pct=$(awk "BEGIN { printf \"%.1f\", ($month_total / $budget) * 100 }")
    local color
    color=$(budget_color "$pct")
    echo -e "  Budget: ${color}$(format_usd "$month_total") / $(format_usd "$budget") ($pct%)${RESET}"
  fi
}

# ─── Subcommand: summary ─────────────────────────────────────────────────────

cmd_summary() {
  local period="monthly"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help)
        cat <<EOF
Usage: $(basename "$0") summary [OPTIONS]

Show cost totals grouped by period.

Options:
  --period <p>   daily | weekly | monthly | all (default: monthly)
EOF
        exit 0
        ;;
      --period) period="$2"; shift 2 ;;
      *) echo -e "${RED}Unknown option: $1${RESET}"; exit 2 ;;
    esac
  done

  if [[ ! -f "$LEDGER_FILE" ]]; then
    echo -e "${YELLOW}No ledger entries found.${RESET}"
    echo "Run: $(basename "$0") log --model <model> --input-tokens <n> --output-tokens <n>"
    exit 0
  fi

  local current_month
  current_month=$(date -u +"%Y-%m")
  local current_date
  current_date=$(date -u +"%Y-%m-%d")

  echo -e "${BOLD}Token Cost Summary${RESET}"
  echo "═══════════════════════════════════════════════════════"

  # Filter lines based on period
  local filter_prefix=""
  local period_label=""
  case "$period" in
    daily)
      filter_prefix="$current_date"
      period_label="Today ($current_date)"
      ;;
    weekly)
      # Filter last 7 days using date comparison
      local week_start
      if [[ "$(uname)" == "Darwin" ]]; then
        week_start=$(date -u -v-7d +"%Y-%m-%d")
      else
        week_start=$(date -u -d "7 days ago" +"%Y-%m-%d")
      fi
      filter_prefix="__WEEKLY__${week_start}"
      period_label="Last 7 Days (since $week_start)"
      ;;
    monthly)
      filter_prefix="$current_month"
      period_label="This Month ($current_month)"
      ;;
    all)
      filter_prefix=""
      period_label="All Time"
      ;;
    *)
      echo -e "${RED}Unknown period: $period${RESET}"
      exit 2
      ;;
  esac

  echo -e "\nPeriod: ${BOLD}$period_label${RESET}\n"

  # Get filtered lines
  local lines
  if [[ "$filter_prefix" == __WEEKLY__* ]]; then
    # Weekly: awk-based date comparison for last 7 days
    local cutoff_date="${filter_prefix#__WEEKLY__}"
    lines=$(awk -v cutoff="$cutoff_date" '{
      match($0, /"timestamp":"([^"]+)"/, arr)
      if (arr[1] != "") {
        ts = substr(arr[1], 1, 10)
        if (ts >= cutoff) print
      }
    }' "$LEDGER_FILE" 2>/dev/null) || true
    # Fallback for macOS awk (no match with 3rd arg)
    if [[ -z "$lines" ]]; then
      lines=$(awk -v cutoff="$cutoff_date" '{
        idx = index($0, "\"timestamp\":\"")
        if (idx > 0) {
          ts = substr($0, idx + 13, 10)
          if (ts >= cutoff) print
        }
      }' "$LEDGER_FILE" 2>/dev/null) || true
    fi
  elif [[ -n "$filter_prefix" ]]; then
    lines=$(grep "\"$filter_prefix" "$LEDGER_FILE" 2>/dev/null) || true
  else
    lines=$(cat "$LEDGER_FILE" 2>/dev/null) || true
  fi

  if [[ -z "$lines" ]]; then
    echo -e "${YELLOW}No entries for this period.${RESET}"
    return
  fi

  # Totals
  local total_input total_output total_cache_read total_cache_write total_cost entry_count
  total_input=$(echo "$lines" | awk -F'"input_tokens":' '{sum += $2+0} END {printf "%d", sum}')
  total_output=$(echo "$lines" | awk -F'"output_tokens":' '{sum += $2+0} END {printf "%d", sum}')
  total_cache_read=$(echo "$lines" | awk -F'"cache_read_tokens":' '{sum += $2+0} END {printf "%d", sum}')
  total_cache_write=$(echo "$lines" | awk -F'"cache_write_tokens":' '{sum += $2+0} END {printf "%d", sum}')
  total_cost=$(echo "$lines" | awk -F'"cost_usd":' '{sum += $2+0} END {printf "%.2f", sum}')
  entry_count=$(echo "$lines" | wc -l | tr -d ' ')

  echo "Entries: $entry_count"
  echo ""

  # By category
  echo -e "${BOLD}By Category${RESET}"
  echo "───────────────────────────────────────────────────────"
  printf "  %-16s %12s\n" "Category" "Cost"
  echo "  ────────────────────────────────────"
  for cat in ship-flow agent-session research ad-hoc; do
    local cat_cost
    cat_cost=$(echo "$lines" | grep "\"$cat\"" | awk -F'"cost_usd":' '{sum += $2+0} END {printf "%.2f", sum}') || true
    if [[ -z "$cat_cost" ]]; then cat_cost="0.00"; fi
    if [[ "$cat_cost" != "0.00" ]]; then
      printf "  %-16s %12s\n" "$cat" "$(format_usd "$cat_cost")"
    fi
  done
  printf "  %-16s %12s\n" "TOTAL" "$(format_usd "$total_cost")"

  # By model
  echo ""
  echo -e "${BOLD}By Model${RESET}"
  echo "───────────────────────────────────────────────────────"
  printf "  %-35s %12s\n" "Model" "Cost"
  echo "  ──────────────────────────────────────────────────"
  local models
  models=$(echo "$lines" | sed -n 's/.*"model" *: *"\([^"]*\)".*/\1/p' | sort -u) || true
  while IFS= read -r m; do
    if [[ -n "$m" ]]; then
      local m_cost
      m_cost=$(echo "$lines" | grep "\"$m\"" | awk -F'"cost_usd":' '{sum += $2+0} END {printf "%.2f", sum}') || true
      if [[ -z "$m_cost" ]]; then m_cost="0.00"; fi
      printf "  %-35s %12s\n" "$m" "$(format_usd "$m_cost")"
    fi
  done <<< "$models"

  # By agent
  echo ""
  echo -e "${BOLD}By Agent${RESET}"
  echo "───────────────────────────────────────────────────────"
  printf "  %-20s %12s\n" "Agent" "Cost"
  echo "  ─────────────────────────────────"
  local agents
  agents=$(echo "$lines" | sed -n 's/.*"agent" *: *"\([^"]*\)".*/\1/p' | sort -u) || true
  while IFS= read -r a; do
    if [[ -n "$a" ]]; then
      local a_cost
      a_cost=$(echo "$lines" | grep "\"agent\":\"$a\"" | awk -F'"cost_usd":' '{sum += $2+0} END {printf "%.2f", sum}') || true
      if [[ -z "$a_cost" ]]; then
        a_cost=$(echo "$lines" | grep "\"agent\" *: *\"$a\"" | awk -F'"cost_usd":' '{sum += $2+0} END {printf "%.2f", sum}') || true
      fi
      if [[ -z "$a_cost" ]]; then a_cost="0.00"; fi
      printf "  %-20s %12s\n" "$a" "$(format_usd "$a_cost")"
    fi
  done <<< "$agents"

  echo ""
  echo -e "${BOLD}Token Totals${RESET}"
  echo "───────────────────────────────────────────────────────"
  printf "  Input:       %s\n" "$(format_number "$total_input")"
  printf "  Output:      %s\n" "$(format_number "$total_output")"
  printf "  Cache Read:  %s\n" "$(format_number "$total_cache_read")"
  printf "  Cache Write: %s\n" "$(format_number "$total_cache_write")"

  # Budget status
  local budget
  budget=$(read_config "cost_budget_monthly")
  if [[ -n "$budget" && "$budget" != "0" && "$period" != "all" ]]; then
    echo ""
    echo -e "${BOLD}Budget Status${RESET}"
    echo "───────────────────────────────────────────────────────"
    local pct
    pct=$(awk "BEGIN { printf \"%.1f\", ($total_cost / $budget) * 100 }")
    local remaining
    remaining=$(awk "BEGIN { printf \"%.2f\", $budget - $total_cost }")
    local color
    color=$(budget_color "$pct")
    echo -e "  Monthly budget: $(format_usd "$budget")"
    echo -e "  Spent:          ${color}$(format_usd "$total_cost") ($pct%)${RESET}"
    echo -e "  Remaining:      $(format_usd "$remaining")"

    # Projected end-of-month
    local day_of_month
    day_of_month=$(date -u +"%d" | sed 's/^0//')
    if [[ "$day_of_month" -gt 0 ]]; then
      local days_in_month=30
      local projected
      projected=$(awk "BEGIN { printf \"%.2f\", ($total_cost / $day_of_month) * $days_in_month }")
      local proj_pct
      proj_pct=$(awk "BEGIN { printf \"%.1f\", ($projected / $budget) * 100 }")
      local proj_color
      proj_color=$(budget_color "$proj_pct")
      echo -e "  Projected EOM:  ${proj_color}$(format_usd "$projected") ($proj_pct%)${RESET}"
    fi
  fi

  # Regenerate summary.md
  _generate_summary_md "$lines" "$total_cost" "$total_input" "$total_output" "$total_cache_read" "$total_cache_write" "$period_label" "$entry_count"
}

_generate_summary_md() {
  local lines="$1" total_cost="$2" total_input="$3" total_output="$4"
  local total_cache_read="$5" total_cache_write="$6" period_label="$7" entry_count="$8"

  ensure_ledger_dir
  local gen_time
  gen_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  cat > "$SUMMARY_FILE" <<MDEOF
# AI Token Cost Summary

Generated: $gen_time

## Period: $period_label

**Entries:** $entry_count | **Total Cost:** $(format_usd "$total_cost")

### By Category

| Category | Cost |
|----------|------|
MDEOF

  for cat in ship-flow agent-session research ad-hoc; do
    local cat_cost
    cat_cost=$(echo "$lines" | grep "\"$cat\"" | awk -F'"cost_usd":' '{sum += $2+0} END {printf "%.2f", sum}') || true
    if [[ -z "$cat_cost" ]]; then cat_cost="0.00"; fi
    if [[ "$cat_cost" != "0.00" ]]; then
      echo "| $cat | $(format_usd "$cat_cost") |" >> "$SUMMARY_FILE"
    fi
  done
  echo "| **Total** | **$(format_usd "$total_cost")** |" >> "$SUMMARY_FILE"

  # Token totals
  cat >> "$SUMMARY_FILE" <<MDEOF

### Token Totals

| Type | Count |
|------|-------|
| Input | $(format_number "$total_input") |
| Output | $(format_number "$total_output") |
| Cache Read | $(format_number "$total_cache_read") |
| Cache Write | $(format_number "$total_cache_write") |
MDEOF

  # Budget status
  local budget
  budget=$(read_config "cost_budget_monthly")
  if [[ -n "$budget" && "$budget" != "0" ]]; then
    local pct
    pct=$(awk "BEGIN { printf \"%.1f\", ($total_cost / $budget) * 100 }")
    local remaining
    remaining=$(awk "BEGIN { printf \"%.2f\", $budget - $total_cost }")
    local status_label="UNDER BUDGET"
    if awk "BEGIN { exit !($total_cost > $budget) }"; then
      status_label="OVER BUDGET"
    fi
    cat >> "$SUMMARY_FILE" <<MDEOF

### Budget Status

- Monthly budget: $(format_usd "$budget")
- Spent: $(format_usd "$total_cost") ($pct%)
- Remaining: $(format_usd "$remaining")
- Status: **$status_label**
MDEOF
  fi

  echo -e "\n${DIM}Summary written to: $SUMMARY_FILE${RESET}"
}

# ─── Subcommand: feature-cost ────────────────────────────────────────────────

cmd_feature_cost() {
  if [[ $# -eq 0 ]]; then
    echo -e "${RED}Error: feature ID required${RESET}"
    echo "Usage: $(basename "$0") feature-cost <feature-id>"
    echo "Example: $(basename "$0") feature-cost PRD-001"
    exit 2
  fi

  if [[ "$1" == "--help" ]]; then
    cat <<EOF
Usage: $(basename "$0") feature-cost <feature-id>

Show total cost of building a feature by summing all ledger entries
tagged with the given PRD or RFC ID.

Example:
  $(basename "$0") feature-cost PRD-001
EOF
    exit 0
  fi

  local feature_id="$1"

  if [[ ! -f "$LEDGER_FILE" ]]; then
    echo -e "${YELLOW}No ledger entries found.${RESET}"
    exit 0
  fi

  local lines
  lines=$(grep "\"feature_id\":\"$feature_id\"" "$LEDGER_FILE" 2>/dev/null) || true
  if [[ -z "$lines" ]]; then
    lines=$(grep "\"feature_id\" *: *\"$feature_id\"" "$LEDGER_FILE" 2>/dev/null) || true
  fi

  if [[ -z "$lines" ]]; then
    echo -e "${YELLOW}No entries found for feature: $feature_id${RESET}"
    exit 0
  fi

  local total_cost entry_count
  total_cost=$(echo "$lines" | awk -F'"cost_usd":' '{sum += $2+0} END {printf "%.2f", sum}')
  entry_count=$(echo "$lines" | wc -l | tr -d ' ')

  echo -e "${BOLD}Feature Cost Report: $feature_id${RESET}"
  echo "═══════════════════════════════════════════════════════"
  echo -e "Total Cost: ${BOLD}$(format_usd "$total_cost")${RESET} ($entry_count entries)"
  echo ""

  # Breakdown by agent
  echo -e "${BOLD}By Agent${RESET}"
  echo "───────────────────────────────────────────────────────"
  local agents
  agents=$(echo "$lines" | sed -n 's/.*"agent" *: *"\([^"]*\)".*/\1/p' | sort -u) || true
  if [[ -z "$agents" ]]; then
    agents=$(echo "$lines" | sed -n 's/.*"agent":"\([^"]*\)".*/\1/p' | sort -u) || true
  fi
  while IFS= read -r a; do
    if [[ -n "$a" ]]; then
      local a_cost a_model
      a_cost=$(echo "$lines" | grep "\"$a\"" | awk -F'"cost_usd":' '{sum += $2+0} END {printf "%.2f", sum}') || true
      a_model=$(echo "$lines" | grep "\"$a\"" | sed -n 's/.*"model" *: *"\([^"]*\)".*/\1/p' | head -1) || true
      if [[ -z "$a_model" ]]; then
        a_model=$(echo "$lines" | grep "\"$a\"" | sed -n 's/.*"model":"\([^"]*\)".*/\1/p' | head -1) || true
      fi
      printf "  %-20s %-30s %10s\n" "$a" "($a_model)" "$(format_usd "$a_cost")"
    fi
  done <<< "$agents"

  # Breakdown by category
  echo ""
  echo -e "${BOLD}By Phase${RESET}"
  echo "───────────────────────────────────────────────────────"
  for cat in ship-flow agent-session research ad-hoc; do
    local cat_cost
    cat_cost=$(echo "$lines" | grep "\"$cat\"" | awk -F'"cost_usd":' '{sum += $2+0} END {printf "%.2f", sum}') || true
    if [[ -z "$cat_cost" ]]; then cat_cost="0.00"; fi
    if [[ "$cat_cost" != "0.00" ]]; then
      printf "  %-16s %10s\n" "$cat" "$(format_usd "$cat_cost")"
    fi
  done

  # Timeline
  echo ""
  echo -e "${BOLD}Timeline${RESET}"
  echo "───────────────────────────────────────────────────────"
  echo "$lines" | while IFS= read -r line; do
    local ts agent lcost lnotes
    ts=$(parse_field "$line" "timestamp")
    agent=$(parse_field "$line" "agent")
    lcost=$(parse_field "$line" "cost_usd")
    lnotes=$(parse_field "$line" "notes")
    printf "  %s  %-15s %10s  %s\n" "${ts%T*}" "$agent" "$(format_usd "$lcost")" "$lnotes"
  done
}

# ─── Subcommand: export ──────────────────────────────────────────────────────

cmd_export() {
  local output="" feature_filter=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help)
        cat <<EOF
Usage: $(basename "$0") export [OPTIONS]

Export ledger to CSV.

Options:
  --output <path>     Output file (default: cogs/ai-ledger/export.csv)
  --feature <id>      Filter by feature ID
EOF
        exit 0
        ;;
      --output) output="$2"; shift 2 ;;
      --feature) feature_filter="$2"; shift 2 ;;
      *) echo -e "${RED}Unknown option: $1${RESET}"; exit 2 ;;
    esac
  done

  if [[ -z "$output" ]]; then
    output="$LEDGER_DIR/export.csv"
  fi

  if [[ ! -f "$LEDGER_FILE" ]]; then
    echo -e "${YELLOW}No ledger entries found.${RESET}"
    exit 0
  fi

  local lines
  if [[ -n "$feature_filter" ]]; then
    lines=$(grep "\"$feature_filter\"" "$LEDGER_FILE" 2>/dev/null) || true
  else
    lines=$(cat "$LEDGER_FILE")
  fi

  if [[ -z "$lines" ]]; then
    echo -e "${YELLOW}No entries to export.${RESET}"
    exit 0
  fi

  # Write CSV header
  echo "timestamp,session_id,agent,model,input_tokens,output_tokens,cache_read_tokens,cache_write_tokens,cost_usd,feature_id,category,notes" > "$output"

  # Convert JSONL to CSV
  echo "$lines" | while IFS= read -r line; do
    local ts sid agent model it ot cr cw cost fid cat notes
    ts=$(parse_field "$line" "timestamp")
    sid=$(parse_field "$line" "session_id")
    agent=$(parse_field "$line" "agent")
    model=$(parse_field "$line" "model")
    it=$(parse_field "$line" "input_tokens")
    ot=$(parse_field "$line" "output_tokens")
    cr=$(parse_field "$line" "cache_read_tokens")
    cw=$(parse_field "$line" "cache_write_tokens")
    cost=$(parse_field "$line" "cost_usd")
    fid=$(parse_field "$line" "feature_id")
    cat=$(parse_field "$line" "category")
    notes=$(parse_field "$line" "notes")
    echo "$ts,$sid,$agent,$model,$it,$ot,$cr,$cw,$cost,$fid,$cat,\"$notes\""
  done >> "$output"

  local count
  count=$(echo "$lines" | wc -l | tr -d ' ')
  echo -e "${GREEN}Exported $count entries to: $output${RESET}"
}

# ─── Subcommand: budget ──────────────────────────────────────────────────────

cmd_budget() {
  if [[ "${1:-}" == "--help" ]]; then
    cat <<EOF
Usage: $(basename "$0") budget

Show current month spend vs configured budget.

Reads ai.cost_budget_monthly from company.config.yaml.
EOF
    exit 0
  fi

  local budget
  budget=$(read_config "cost_budget_monthly")

  if [[ -z "$budget" || "$budget" == "0" ]]; then
    echo -e "${YELLOW}No budget configured.${RESET}"
    echo ""
    echo "Set a monthly budget in company.config.yaml:"
    echo "  ai:"
    echo "    cost_budget_monthly: \"100\"  # USD"
    echo ""
    echo "Suggested budgets by stage:"
    echo "  idea:   \$25 - \$50"
    echo "  mvp:    \$50 - \$200"
    echo "  growth: \$200 - \$1,000"
    echo "  scale:  \$1,000+"
    exit 0
  fi

  local current_month
  current_month=$(date -u +"%Y-%m")
  local month_total="0.00"

  if [[ -f "$LEDGER_FILE" ]]; then
    month_total=$(grep "\"$current_month" "$LEDGER_FILE" 2>/dev/null | awk -F'"cost_usd":' '{sum += $2+0} END {printf "%.2f", sum}') || true
    if [[ -z "$month_total" ]]; then month_total="0.00"; fi
  fi

  local pct
  pct=$(awk "BEGIN { printf \"%.1f\", ($month_total / $budget) * 100 }")
  local remaining
  remaining=$(awk "BEGIN { printf \"%.2f\", $budget - $month_total }")
  local color
  color=$(budget_color "$pct")

  echo -e "${BOLD}Budget Status — $current_month${RESET}"
  echo "═══════════════════════════════════════════════════════"
  echo -e "  Monthly budget: $(format_usd "$budget")"
  echo -e "  Spent:          ${color}$(format_usd "$month_total") ($pct%)${RESET}"
  echo -e "  Remaining:      $(format_usd "$remaining")"

  # Projected end-of-month
  local day_of_month
  day_of_month=$(date -u +"%d" | sed 's/^0//')
  if [[ "$day_of_month" -gt 0 && "$month_total" != "0.00" ]]; then
    local days_in_month=30
    local projected
    projected=$(awk "BEGIN { printf \"%.2f\", ($month_total / $day_of_month) * $days_in_month }")
    local proj_pct
    proj_pct=$(awk "BEGIN { printf \"%.1f\", ($projected / $budget) * 100 }")
    local proj_color
    proj_color=$(budget_color "$proj_pct")
    echo -e "  Projected EOM:  ${proj_color}$(format_usd "$projected") ($proj_pct%)${RESET}"
  fi

  # Alert threshold
  local threshold
  threshold=$(read_config "cost_alert_threshold_percent")
  if [[ -z "$threshold" ]]; then threshold="80"; fi
  local over_threshold
  over_threshold=$(awk "BEGIN { print ($pct >= $threshold) ? 1 : 0 }")
  if [[ "$over_threshold" -eq 1 ]]; then
    echo ""
    echo -e "  ${RED}⚠ Spend has reached ${pct}% of budget (threshold: ${threshold}%)${RESET}"
    echo -e "  ${RED}  Review spend by category: $(basename "$0") summary${RESET}"
  fi
}

# ─── Main dispatcher ─────────────────────────────────────────────────────────

if [[ $# -eq 0 ]]; then
  usage
fi

SUBCOMMAND="$1"
shift

case "$SUBCOMMAND" in
  log) cmd_log "$@" ;;
  summary) cmd_summary "$@" ;;
  feature-cost) cmd_feature_cost "$@" ;;
  export) cmd_export "$@" ;;
  budget) cmd_budget "$@" ;;
  --help|-h) usage ;;
  *) echo -e "${RED}Unknown subcommand: $SUBCOMMAND${RESET}"; usage ;;
esac
