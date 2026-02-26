#!/bin/bash
# ============================================================================
# Hook: Check artifact frontmatter after writing to artifacts/
# ============================================================================
# Triggered on PostToolUse for Write/Edit.
# If the file written is in artifacts/, check that it has valid YAML
# frontmatter. Prints a warning if frontmatter is missing or malformed.
#
# Cost: Zero tokens (command-type hook, PostToolUse is informational)
# ============================================================================

set -euo pipefail

# Read the tool input from stdin
INPUT=$(cat)

# Get the file path — Write uses file_path, Edit uses file_path
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only check files in the artifacts/ directory
case "$FILE_PATH" in
  */artifacts/*.md|artifacts/*.md)
    ;;
  *)
    exit 0
    ;;
esac

# Skip audit log and gitkeep
case "$FILE_PATH" in
  */.audit-log/*|*/.gitkeep)
    exit 0
    ;;
esac

# Check if file exists and has frontmatter
if [ -f "$FILE_PATH" ]; then
  FIRST_LINE=$(head -1 "$FILE_PATH")
  if [ "$FIRST_LINE" != "---" ]; then
    echo "⚠️  Artifact written without YAML frontmatter: $FILE_PATH"
    echo "   Run: ./tools/artifact/validate.sh $FILE_PATH"
  fi
fi

exit 0
