#!/usr/bin/env bash
# The committed SVG diagrams match a fresh render (needs node; skipped without).
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/assert.sh"
cd "$REPO_ROOT"

command -v node >/dev/null 2>&1 || skip "node not installed"

assert_exit 0 node docs/diagrams/render.js --check
assert_contains "$OUT" "diagrams are up to date"

# --help and unknown options must not write the SVGs.
BEFORE="$(git status --porcelain --untracked-files=all)"
assert_exit 0 node docs/diagrams/render.js --help
assert_contains "$OUT" "Usage:"
assert_not_contains "$OUT" "wrote"
assert_exit 1 node docs/diagrams/render.js --chek
assert_contains "$OUT" "Unknown option"
assert_eq "$BEFORE" "$(git status --porcelain --untracked-files=all)" "render.js --help changes nothing"

# Every diagram the docs embed exists.
for svg in system-overview agent-org ship-flow stage-gates artifact-lineage multi-runtime-build install-upgrade workflow-paths; do
  assert_file_exists ".company-os/docs/diagrams/$svg.svg"
done

finish
