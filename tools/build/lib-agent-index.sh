#!/usr/bin/env bash
# ============================================================================
# lib-agent-index.sh — Enumerate agents with their frontmatter
# ============================================================================
# Source this file. Provides:
#   agent_source_dir            -> echoes the directory adapters should read agents from
#   agent_list                  -> echoes one agent name per line
#   agent_file <name>           -> echoes the repo-relative path to <name>'s .md file
# ============================================================================

agent_source_dir() {
  if [ -d "os/agents" ]; then
    echo "os/agents"
  elif [ -d ".claude/agents" ]; then
    echo ".claude/agents"
  else
    return 1
  fi
}

agent_list() {
  local dir
  dir="$(agent_source_dir)" || return 0
  find "$dir" -mindepth 1 -maxdepth 1 -type f -name "*.md" 2>/dev/null \
    | sed "s|$dir/||; s|\.md$||" \
    | sort
}

agent_file() {
  local name="$1"
  local dir
  dir="$(agent_source_dir)" || return 1
  echo "$dir/$name.md"
}
