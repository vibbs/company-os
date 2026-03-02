#!/usr/bin/env bash
# Tool: T-OPS-04 Static Dashboard Generator
# Tier: 0
# Description: Generates a static Markdown or HTML project dashboard with gate readiness,
#              artifact graph, open risks, and cost ledger snapshot
# Usage: ./tools/ops/dashboard.sh [--html] [--out <path>] [--period <monthly|all>]
# Inputs: artifacts/ directory, cogs/ai-ledger/entries.jsonl, company.config.yaml
# Outputs: Markdown or HTML dashboard (stdout or --out path)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
ARTIFACTS_DIR="$PROJECT_ROOT/artifacts"
LEDGER_FILE="$PROJECT_ROOT/cogs/ai-ledger/entries.jsonl"
CONFIG_FILE="$PROJECT_ROOT/company.config.yaml"

# --- Parse flags ---
HTML_MODE=false
OUT_FILE=""
PERIOD="monthly"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --html) HTML_MODE=true; shift ;;
    --out) OUT_FILE="$2"; shift 2 ;;
    --period) PERIOD="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: ./tools/ops/dashboard.sh [--html] [--out <path>] [--period <monthly|all>]"
      echo ""
      echo "Generates a static project dashboard with artifact status, gate readiness,"
      echo "artifact graph, open risks, and cost snapshot."
      echo ""
      echo "Flags:"
      echo "  --html              Output as self-contained HTML (default: Markdown)"
      echo "  --out <path>        Write to file instead of stdout"
      echo "  --period <monthly|all>  Cost ledger period (default: monthly)"
      exit 0
      ;;
    *) shift ;;
  esac
done

# --- Read config ---
COMPANY_NAME=""
COMPANY_STAGE=""
COST_BUDGET=""

if [[ -f "$CONFIG_FILE" ]]; then
  COMPANY_NAME=$(grep "^  name:" "$CONFIG_FILE" 2>/dev/null | head -1 | sed 's/.*: *"\{0,1\}\([^"]*\)"\{0,1\}/\1/' | tr -d '[:space:]') || true
  COMPANY_STAGE=$(grep "^  stage:" "$CONFIG_FILE" 2>/dev/null | head -1 | sed 's/.*: *"\{0,1\}\([^"]*\)"\{0,1\}/\1/' | tr -d '[:space:]') || true
  COST_BUDGET=$(grep "cost_budget_monthly:" "$CONFIG_FILE" 2>/dev/null | head -1 | sed 's/.*: *"\{0,1\}\([^"]*\)"\{0,1\}/\1/' | tr -d '[:space:]') || true
fi

TIMESTAMP=$(date '+%Y-%m-%d %H:%M')

# --- Helper: extract frontmatter field ---
extract_field() {
  local file="$1"
  local field="$2"
  grep "^${field}:" "$file" 2>/dev/null | head -1 | sed "s/^${field}: *//" | tr -d '"' | tr -d "'" || true
}

# --- Helper: scan artifact directory ---
# Returns: count_draft count_review count_approved count_archived
scan_dir() {
  local dir="$1"
  local d=0 r=0 a=0 ar=0
  if [[ -d "$dir" ]]; then
    while IFS= read -r file; do
      local status
      status=$(extract_field "$file" "status")
      case "$status" in
        draft) d=$((d + 1)) ;;
        review) r=$((r + 1)) ;;
        approved) a=$((a + 1)) ;;
        archived) ar=$((ar + 1)) ;;
      esac
    done < <(find "$dir" -maxdepth 1 -name "*.md" -type f 2>/dev/null || true)
  fi
  echo "$d $r $a $ar"
}

# --- Build output ---
OUTPUT=""

append() {
  OUTPUT="${OUTPUT}${1}
"
}

# Section 1: Header
append "# Project Dashboard"
append ""
if [[ -n "$COMPANY_NAME" ]]; then
  append "**Company**: ${COMPANY_NAME} | **Stage**: ${COMPANY_STAGE:-not set} | **Generated**: ${TIMESTAMP}"
else
  append "**Stage**: ${COMPANY_STAGE:-not set} | **Generated**: ${TIMESTAMP}"
fi
append ""
append "---"
append ""

# Section 2: Artifact Status Table
append "## Artifact Status"
append ""
append "| Category | Total | Draft | Review | Approved | Archived |"
append "|----------|-------|-------|--------|----------|----------|"

DIRS=("prds" "rfcs" "test-plans" "qa-reports" "security-reviews" "launch-briefs" "decision-memos")
LABELS=("PRDs" "RFCs" "Test Plans" "QA Reports" "Security Reviews" "Launch Briefs" "Decision Memos")

for i in "${!DIRS[@]}"; do
  read -r d r a ar <<< "$(scan_dir "$ARTIFACTS_DIR/${DIRS[$i]}")"
  total=$((d + r + a + ar))
  append "| ${LABELS[$i]} | $total | $d | $r | $a | $ar |"
done

append ""

# Section 3: Gate Readiness Per Feature
append "## Gate Readiness"
append ""

PRD_DIR="$ARTIFACTS_DIR/prds"
RFC_DIR="$ARTIFACTS_DIR/rfcs"
SEC_DIR="$ARTIFACTS_DIR/security-reviews"
QA_DIR="$ARTIFACTS_DIR/qa-reports"

if [[ -d "$PRD_DIR" ]] && find "$PRD_DIR" -maxdepth 1 -name "*.md" -type f 2>/dev/null | grep -q .; then
  append "| Feature | PRD | RFC | Security | QA | Ready? |"
  append "|---------|-----|-----|----------|-----|--------|"

  while IFS= read -r prd_file; do
    prd_id=$(extract_field "$prd_file" "id")
    prd_title=$(extract_field "$prd_file" "title")
    prd_status=$(extract_field "$prd_file" "status")
    [[ -z "$prd_id" ]] && continue

    # Short display name
    display="${prd_title:-$prd_id}"
    if [[ ${#display} -gt 30 ]]; then
      display="${display:0:27}..."
    fi

    # PRD status
    prd_badge="draft"
    [[ "$prd_status" == "approved" ]] && prd_badge="approved"
    [[ "$prd_status" == "review" ]] && prd_badge="review"

    # Check RFC exists (look for parent reference or children link)
    rfc_badge="—"
    if [[ -d "$RFC_DIR" ]]; then
      rfc_match=$(grep -rl "parent:.*${prd_id}" "$RFC_DIR" 2>/dev/null | head -1) || true
      if [[ -z "$rfc_match" ]]; then
        # Also check PRD's children field
        children=$(extract_field "$prd_file" "children")
        if [[ -n "$children" ]]; then
          for child_id in $(echo "$children" | tr -d '[]' | tr ',' ' '); do
            child_id=$(echo "$child_id" | tr -d '[:space:]')
            child_match=$(grep -rl "^id: *${child_id}" "$RFC_DIR" 2>/dev/null | head -1) || true
            if [[ -n "$child_match" ]]; then
              rfc_match="$child_match"
              break
            fi
          done
        fi
      fi
      if [[ -n "${rfc_match:-}" ]]; then
        rfc_status=$(extract_field "$rfc_match" "status")
        rfc_badge="${rfc_status:-draft}"
      fi
    fi

    # Check security review exists
    sec_badge="—"
    if [[ -d "$SEC_DIR" ]]; then
      sec_match=$(grep -rl "parent:.*${prd_id}\|depends_on:.*${prd_id}" "$SEC_DIR" 2>/dev/null | head -1) || true
      if [[ -z "$sec_match" ]] && [[ -n "${rfc_match:-}" ]]; then
        rfc_id=$(extract_field "$rfc_match" "id")
        sec_match=$(grep -rl "parent:.*${rfc_id}\|depends_on:.*${rfc_id}" "$SEC_DIR" 2>/dev/null | head -1) || true
      fi
      if [[ -n "${sec_match:-}" ]]; then
        sec_status=$(extract_field "$sec_match" "status")
        sec_badge="${sec_status:-draft}"
      fi
    fi

    # Check QA report exists
    qa_badge="—"
    if [[ -d "$QA_DIR" ]]; then
      qa_match=$(grep -rl "parent:.*${prd_id}\|depends_on:.*${prd_id}" "$QA_DIR" 2>/dev/null | head -1) || true
      if [[ -z "$qa_match" ]] && [[ -n "${rfc_match:-}" ]]; then
        rfc_id=$(extract_field "$rfc_match" "id")
        qa_match=$(grep -rl "parent:.*${rfc_id}\|depends_on:.*${rfc_id}" "$QA_DIR" 2>/dev/null | head -1) || true
      fi
      if [[ -n "${qa_match:-}" ]]; then
        qa_status=$(extract_field "$qa_match" "status")
        qa_badge="${qa_status:-draft}"
      fi
    fi

    # Overall readiness
    ready="No"
    if [[ "$prd_badge" == "approved" && "$rfc_badge" == "approved" && "$sec_badge" != "—" && "$qa_badge" == "approved" ]]; then
      ready="Yes"
    elif [[ "$prd_badge" == "approved" && "$rfc_badge" == "approved" ]]; then
      ready="Partial"
    fi

    append "| $display | $prd_badge | $rfc_badge | $sec_badge | $qa_badge | $ready |"
  done < <(find "$PRD_DIR" -maxdepth 1 -name "*.md" -type f 2>/dev/null || true)
else
  append "*No PRDs found. Run /ship to create your first feature.*"
fi

append ""

# Section 4: Artifact Graph (Mermaid)
append "## Artifact Graph"
append ""
append '```mermaid'
append "graph TD"

GRAPH_NODES=""
GRAPH_EDGES=""
NODE_COUNT=0

# Walk all artifact files and build graph
for dir in "${DIRS[@]}"; do
  full_dir="$ARTIFACTS_DIR/$dir"
  [[ -d "$full_dir" ]] || continue
  while IFS= read -r file; do
    id=$(extract_field "$file" "id")
    title=$(extract_field "$file" "title")
    status=$(extract_field "$file" "status")
    parent=$(extract_field "$file" "parent")
    children=$(extract_field "$file" "children")
    depends_on=$(extract_field "$file" "depends_on")
    [[ -z "$id" ]] && continue

    NODE_COUNT=$((NODE_COUNT + 1))
    # Sanitize ID for Mermaid (replace - with _)
    safe_id=$(echo "$id" | tr '-' '_')
    short_title="${title:-$id}"
    if [[ ${#short_title} -gt 25 ]]; then
      short_title="${short_title:0:22}..."
    fi

    # Node with style
    GRAPH_NODES="${GRAPH_NODES}  ${safe_id}[\"${id}: ${short_title}\"]
"
    case "$status" in
      approved) GRAPH_NODES="${GRAPH_NODES}  style ${safe_id} fill:#22c55e,color:#fff
" ;;
      review)   GRAPH_NODES="${GRAPH_NODES}  style ${safe_id} fill:#f59e0b,color:#fff
" ;;
      draft)    GRAPH_NODES="${GRAPH_NODES}  style ${safe_id} fill:#94a3b8,color:#fff
" ;;
      archived) GRAPH_NODES="${GRAPH_NODES}  style ${safe_id} fill:#64748b,color:#fff
" ;;
    esac

    # Parent edge
    if [[ -n "$parent" ]]; then
      safe_parent=$(echo "$parent" | tr '-' '_')
      GRAPH_EDGES="${GRAPH_EDGES}  ${safe_parent} --> ${safe_id}
"
    fi

    # depends_on edges
    if [[ -n "$depends_on" ]]; then
      for dep in $(echo "$depends_on" | tr -d '[]' | tr ',' ' '); do
        dep=$(echo "$dep" | tr -d '[:space:]')
        [[ -z "$dep" ]] && continue
        safe_dep=$(echo "$dep" | tr '-' '_')
        GRAPH_EDGES="${GRAPH_EDGES}  ${safe_dep} -.-> ${safe_id}
"
      done
    fi
  done < <(find "$full_dir" -maxdepth 1 -name "*.md" -type f 2>/dev/null || true)
done

if [[ $NODE_COUNT -gt 0 ]]; then
  printf '%s' "$GRAPH_NODES" >> /dev/null  # validate
  OUTPUT="${OUTPUT}${GRAPH_NODES}${GRAPH_EDGES}"
else
  append "  empty[\"No artifacts yet\"]"
  append "  style empty fill:#94a3b8,color:#fff"
fi

append '```'
append ""
append "*Green = approved, Yellow = review, Gray = draft. Solid arrows = parent/child, Dashed = depends_on.*"
append ""

# Section 5: Open Risks
append "## Open Risks"
append ""

RISK_COUNT=0
RISK_TABLE=""

if [[ -d "$SEC_DIR" ]]; then
  while IFS= read -r file; do
    status=$(extract_field "$file" "status")
    # Only check draft/review (not approved/archived — those are resolved)
    if [[ "$status" == "draft" || "$status" == "review" ]]; then
      id=$(extract_field "$file" "id")
      title=$(extract_field "$file" "title")
      created=$(extract_field "$file" "created")

      # Count severity markers in body (below frontmatter)
      body_start=$(grep -n "^---$" "$file" 2>/dev/null | tail -1 | cut -d: -f1) || true
      if [[ -n "$body_start" ]]; then
        crit=$(tail -n +"$((body_start + 1))" "$file" 2>/dev/null | grep -ci "CRITICAL") || true
        high=$(tail -n +"$((body_start + 1))" "$file" 2>/dev/null | grep -ci "HIGH") || true
      else
        crit=0
        high=0
      fi

      if [[ ${crit:-0} -gt 0 || ${high:-0} -gt 0 ]]; then
        RISK_COUNT=$((RISK_COUNT + 1))
        sev="HIGH"
        [[ ${crit:-0} -gt 0 ]] && sev="CRITICAL"
        RISK_TABLE="${RISK_TABLE}| ${id:-unknown} | ${title:-untitled} | $sev | ${status} | ${created:-unknown} |
"
      fi
    fi
  done < <(find "$SEC_DIR" -maxdepth 1 -name "*.md" -type f ! -name "POSTURE-*" 2>/dev/null || true)
fi

if [[ $RISK_COUNT -gt 0 ]]; then
  append "| Artifact | Title | Severity | Status | Created |"
  append "|----------|-------|----------|--------|---------|"
  OUTPUT="${OUTPUT}${RISK_TABLE}"
else
  append "*No open CRITICAL or HIGH risks found.*"
fi

append ""

# Section 6: Cost Ledger Snapshot
append "## Cost Ledger"
append ""

if [[ -f "$LEDGER_FILE" ]]; then
  CURRENT_MONTH=$(date '+%Y-%m')
  TOTAL_COST=0
  ENTRY_COUNT=0

  # Parse JSONL with awk — extract cost and agent fields
  # Format: {"timestamp":"...","cost":0.05,"agent":"engineering",...}
  if [[ "$PERIOD" == "monthly" ]]; then
    COST_DATA=$(awk -v month="$CURRENT_MONTH" '
      BEGIN { FS="[,{}]" }
      $0 ~ month {
        for (i=1; i<=NF; i++) {
          if ($i ~ /"cost"/) {
            split($i, a, ":")
            gsub(/[^0-9.]/, "", a[2])
            total += a[2]
            count++
          }
          if ($i ~ /"agent"/) {
            split($i, a, ":")
            gsub(/[" ]/, "", a[2])
            agents[a[2]] += 1
          }
        }
      }
      END {
        printf "%.2f %d", total, count
        for (ag in agents) printf " %s:%d", ag, agents[ag]
      }
    ' "$LEDGER_FILE" 2>/dev/null) || true
  else
    COST_DATA=$(awk '
      BEGIN { FS="[,{}]" }
      {
        for (i=1; i<=NF; i++) {
          if ($i ~ /"cost"/) {
            split($i, a, ":")
            gsub(/[^0-9.]/, "", a[2])
            total += a[2]
            count++
          }
        }
      }
      END { printf "%.2f %d", total, count }
    ' "$LEDGER_FILE" 2>/dev/null) || true
  fi

  if [[ -n "$COST_DATA" ]]; then
    TOTAL_COST=$(echo "$COST_DATA" | awk '{print $1}')
    ENTRY_COUNT=$(echo "$COST_DATA" | awk '{print $2}')
  fi

  append "**Period**: ${PERIOD} (${CURRENT_MONTH:-all})"
  append "**Total cost**: \$${TOTAL_COST:-0.00} across ${ENTRY_COUNT:-0} entries"

  if [[ -n "$COST_BUDGET" && "$COST_BUDGET" != "0" && "$COST_BUDGET" != "" ]]; then
    # Calculate percentage
    if command -v bc &>/dev/null; then
      PCT=$(echo "scale=0; ${TOTAL_COST:-0} * 100 / ${COST_BUDGET}" | bc 2>/dev/null) || true
    else
      PCT=$(awk "BEGIN { printf \"%.0f\", (${TOTAL_COST:-0} / ${COST_BUDGET}) * 100 }" 2>/dev/null) || true
    fi
    append "**Budget**: \$${COST_BUDGET}/month | **Used**: ${PCT:-0}%"

    # Visual bar (20 chars wide)
    BAR_WIDTH=20
    if [[ -n "$PCT" ]]; then
      FILLED=$((PCT * BAR_WIDTH / 100))
      [[ $FILLED -gt $BAR_WIDTH ]] && FILLED=$BAR_WIDTH
      EMPTY=$((BAR_WIDTH - FILLED))
      BAR=$(printf '%0.s█' $(seq 1 "$FILLED" 2>/dev/null) 2>/dev/null)$(printf '%0.s░' $(seq 1 "$EMPTY" 2>/dev/null) 2>/dev/null) || true
      append "\`${BAR:-░░░░░░░░░░░░░░░░░░░░}\` ${PCT}%"
    fi
  fi
else
  append "*No cost data found. Run /token-cost to log your first entry.*"
fi

append ""
append "---"
append "*Generated by tools/ops/dashboard.sh | ${TIMESTAMP}*"

# --- HTML wrapper ---
if [[ "$HTML_MODE" == true ]]; then
  HTML_OUTPUT="<!DOCTYPE html>
<html lang=\"en\">
<head>
  <meta charset=\"UTF-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
  <title>Company OS Dashboard</title>
  <script src=\"https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js\"></script>
  <style>
    :root { --bg: #0f172a; --fg: #e2e8f0; --border: #334155; --accent: #3b82f6; }
    body { font-family: system-ui, -apple-system, sans-serif; background: var(--bg); color: var(--fg); max-width: 960px; margin: 0 auto; padding: 2rem; line-height: 1.6; }
    h1 { border-bottom: 2px solid var(--accent); padding-bottom: 0.5rem; }
    h2 { color: var(--accent); margin-top: 2rem; }
    table { border-collapse: collapse; width: 100%; margin: 1rem 0; }
    th { background: #1e293b; text-align: left; }
    th, td { border: 1px solid var(--border); padding: 8px 12px; }
    tr:nth-child(even) { background: #1e293b; }
    code { background: #1e293b; padding: 2px 6px; border-radius: 3px; }
    .mermaid { background: #1e293b; padding: 1rem; border-radius: 8px; margin: 1rem 0; }
    hr { border-color: var(--border); }
    em { color: #94a3b8; }
    strong { color: #f1f5f9; }
  </style>
</head>
<body>"

  # Convert markdown to simple HTML
  BODY_HTML=$(echo "$OUTPUT" | sed \
    -e 's/^# \(.*\)/<h1>\1<\/h1>/' \
    -e 's/^## \(.*\)/<h2>\1<\/h2>/' \
    -e 's/^\*\*\([^*]*\)\*\*/<strong>\1<\/strong>/g' \
    -e 's/\*\([^*]*\)\*/<em>\1<\/em>/g' \
    -e 's/^---$/<hr>/' \
    -e 's/`\([^`]*\)`/<code>\1<\/code>/g' \
  )

  # Handle mermaid blocks
  BODY_HTML=$(echo "$BODY_HTML" | sed \
    -e 's/^```mermaid/<div class="mermaid">/' \
    -e 's/^```$/<\/div>/' \
  )

  # Handle tables (simple conversion)
  BODY_HTML=$(echo "$BODY_HTML" | awk '
    /^\|.*\|$/ {
      if (!in_table) {
        print "<table>"
        in_table = 1
        is_header = 1
      }
      # Skip separator rows
      if ($0 ~ /^\|[-| ]+\|$/) next

      gsub(/^\|/, "")
      gsub(/\|$/, "")
      n = split($0, cells, "|")
      if (is_header) {
        printf "<tr>"
        for (i=1; i<=n; i++) {
          gsub(/^ +| +$/, "", cells[i])
          printf "<th>%s</th>", cells[i]
        }
        printf "</tr>\n"
        is_header = 0
      } else {
        printf "<tr>"
        for (i=1; i<=n; i++) {
          gsub(/^ +| +$/, "", cells[i])
          printf "<td>%s</td>", cells[i]
        }
        printf "</tr>\n"
      }
      next
    }
    in_table && !/^\|/ {
      print "</table>"
      in_table = 0
    }
    { print }
    END { if (in_table) print "</table>" }
  ')

  HTML_OUTPUT="${HTML_OUTPUT}
${BODY_HTML}
  <script>mermaid.initialize({ startOnLoad: true, theme: 'dark' });</script>
</body>
</html>"

  OUTPUT="$HTML_OUTPUT"
fi

# --- Write output ---
if [[ -n "$OUT_FILE" ]]; then
  echo "$OUTPUT" > "$OUT_FILE"
  echo "Dashboard written to: $OUT_FILE"
else
  echo "$OUTPUT"
fi
