#!/bin/bash
# ============================================================================
# Hook: Auto-validate artifact before promotion
# ============================================================================
# Triggered on PreToolUse for Bash commands.
# If the command is running promote.sh, extract the artifact path and
# validate it first. Blocks promotion if validation fails.
#
# Cost: Zero tokens (command-type hook)
# ============================================================================

set -euo pipefail

# Read the tool input from stdin
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only act on promote.sh commands
if ! echo "$COMMAND" | grep -q 'promote\.sh'; then
  exit 0
fi

# Extract the artifact path (first argument after promote.sh)
ARTIFACT=$(echo "$COMMAND" | grep -oE 'promote\.sh\s+\S+' | awk '{print $2}' || true)

if [ -z "$ARTIFACT" ]; then
  exit 0
fi

# If the artifact file exists, validate it
if [ -f "$ARTIFACT" ]; then
  VALIDATE_OUTPUT=$(./tools/artifact/validate.sh "$ARTIFACT" 2>&1) || {
    jq -n --arg reason "Artifact validation failed before promotion: $VALIDATE_OUTPUT" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $reason
      }
    }'
    exit 0
  }
fi

# Validation passed or artifact not found (let promote.sh handle that error)
exit 0
