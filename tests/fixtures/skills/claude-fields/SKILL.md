---
name: claude-fields
description: Fixture skill using top-level fields Claude Code documents.
when_to_use: When testing the validator.
arguments: target
allowed-tools: Read Grep
disallowed-tools: Bash
model: sonnet
effort: high
context: fork
agent: Explore
background: false
hooks: {}
paths: "src/**"
shell: bash
runtimes:
  claude:
    user-invocable: true
---

# Fixture

Body.
