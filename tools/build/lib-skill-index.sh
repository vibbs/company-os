#!/usr/bin/env bash
# ============================================================================
# lib-skill-index.sh — Enumerate skills with their frontmatter
# ============================================================================
# Source this file. Provides:
#   skill_source_dir            -> echoes the directory adapters should read skills from
#   skill_list                  -> echoes one skill directory name per line
#   skill_file <name>           -> echoes the absolute path to <name>'s SKILL.md
# ============================================================================

# Phase A: source-of-truth is .claude/skills/. Phase C will promote os/skills/.
# Adapters call skill_source_dir to stay portable across phases.
skill_source_dir() {
  if [ -d "os/skills" ]; then
    echo "os/skills"
  elif [ -d ".claude/skills" ]; then
    echo ".claude/skills"
  else
    return 1
  fi
}

skill_list() {
  local dir
  dir="$(skill_source_dir)" || return 0
  # one entry per top-level subdirectory
  find "$dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null \
    | sed "s|$dir/||" \
    | sort
}

skill_file() {
  local name="$1"
  local dir
  dir="$(skill_source_dir)" || return 1
  echo "$dir/$name/SKILL.md"
}
