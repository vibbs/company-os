#!/usr/bin/env bash
# Artifact tools on a throwaway project: validate.sh, link.sh, promote.sh and
# check-gate.sh (stage behavior and exit codes).
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/assert.sh"

# The tools find artifacts/ and company.config.yaml relative to their own
# folder, so each project gets its own copy of tools/.
P="$(make_tmp)"
cp -R "$REPO_ROOT/tools" "$P/tools"
mkdir -p "$P/artifacts/prds" "$P/artifacts/rfcs"
cd "$P"

set_stage() {
  printf 'company:\n  name: "Test"\n  stage: %s   # test stage\n' "$1" > "$P/company.config.yaml"
}

write_prd() {  # write_prd <file> <id> <status>
  cat > "$1" <<EOF
---
id: $2
type: prd
title: Team invites
status: $3
created: 2026-10-14
author: test
children: []
depends_on: []
---

# Team invites

## Acceptance Criteria
- AC-1: An admin can invite a member by email.
EOF
}

write_rfc() {  # write_rfc <file> <id> <status>
  cat > "$1" <<EOF
---
id: $2
type: rfc
title: Team invites design
status: $3
created: 2026-10-14
author: test
children: []
depends_on: []
---

# Design

Invites are stored in an invites table.
EOF
}

PRD="artifacts/prds/PRD-001.md"
RFC="artifacts/rfcs/RFC-001.md"
write_prd "$PRD" PRD-001 draft
write_rfc "$RFC" RFC-001 draft
set_stage growth

# --- validate.sh ---
assert_exit 0 bash tools/artifact/validate.sh "$PRD"
assert_contains "$OUT" "VALID: $PRD"
assert_contains "$OUT" "Type: prd"

assert_exit 0 bash tools/artifact/validate.sh --all
assert_contains "$OUT" "Validated 2 artifact(s): 2 valid, 0 invalid"

BAD="artifacts/prds/BAD.md"
cat > "$BAD" <<'EOF'
---
id: BAD-1
type: memo
status: done
parent: PRD-404
---

Body.
EOF
assert_exit 1 bash tools/artifact/validate.sh "$BAD"
assert_contains "$OUT" "INVALID: $BAD"
assert_contains "$OUT" "Missing required field: title"
assert_contains "$OUT" "Invalid status: 'done'"
assert_contains "$OUT" "Invalid type: 'memo'"
assert_contains "$OUT" "parent 'PRD-404' does not resolve"

assert_exit 1 bash tools/artifact/validate.sh --all
assert_contains "$OUT" "Validated 3 artifact(s): 2 valid, 1 invalid"

printf 'No frontmatter here.\n' > artifacts/prds/notes.md
assert_exit 1 bash tools/artifact/validate.sh artifacts/prds/notes.md
assert_contains "$OUT" "Missing YAML frontmatter"
rm -f "$BAD" artifacts/prds/notes.md

assert_exit 1 bash tools/artifact/validate.sh artifacts/prds/missing.md
assert_contains "$OUT" "File not found"
assert_exit 1 bash tools/artifact/validate.sh --bogus

# --- link.sh ---
assert_exit 0 bash tools/artifact/link.sh "$PRD" "$RFC"
assert_contains "$OUT" "Link complete: PRD-001 → RFC-001"
assert_contains "$(cat "$RFC")" "parent: PRD-001"
assert_contains "$(cat "$RFC")" "depends_on: [PRD-001]"
assert_contains "$(cat "$PRD")" "children: [RFC-001]"
assert_contains "$(cat artifacts/.audit-log/promotions.log)" "LINK: PRD-001 → RFC-001"
assert_exit 0 bash tools/artifact/validate.sh --strict "$RFC"
assert_not_contains "$OUT" "WARNINGS" "linked RFC passes bidirectional checks"

# Linking again changes nothing; re-parenting is refused.
cp "$RFC" "$P/rfc.before"
assert_exit 0 bash tools/artifact/link.sh "$PRD" "$RFC"
assert_eq "$(cat "$P/rfc.before")" "$(cat "$RFC")" "second link is a no-op"
write_prd artifacts/prds/PRD-002.md PRD-002 draft
assert_exit 1 bash tools/artifact/link.sh artifacts/prds/PRD-002.md "$RFC"
assert_contains "$OUT" "different parent"

# Artifacts whose frontmatter lacks children/depends_on still get linked.
for pair in "prds/PRD-003:prd" "rfcs/RFC-002:rfc"; do
  file="artifacts/${pair%%:*}.md"; id="$(basename "${pair%%:*}")"
  printf -- '---\nid: %s\ntype: %s\ntitle: Minimal header\nstatus: draft\ncreated: 2026-10-14\nauthor: test\n---\n\nBody.\n' "$id" "${pair##*:}" > "$file"
done
assert_exit 0 bash tools/artifact/link.sh artifacts/prds/PRD-003.md artifacts/rfcs/RFC-002.md
assert_contains "$(cat artifacts/rfcs/RFC-002.md)" "parent: PRD-003"
assert_contains "$(cat artifacts/rfcs/RFC-002.md)" "depends_on: [PRD-003]" "depends_on added when the field was absent"
assert_contains "$(cat artifacts/prds/PRD-003.md)" "children: [RFC-002]" "children added when the field was absent"
assert_exit 0 bash tools/artifact/validate.sh --strict artifacts/rfcs/RFC-002.md
assert_not_contains "$OUT" "WARNINGS"
assert_exit 0 bash tools/artifact/link.sh artifacts/prds/PRD-003.md artifacts/rfcs/RFC-002.md
assert_eq "1" "$(grep -c '^depends_on:' artifacts/rfcs/RFC-002.md)" "relinking does not duplicate the field"

# A body line that starts with `id:` is not frontmatter and stays untouched.
for pair in "prds/PRD-004:prd" "rfcs/RFC-003:rfc"; do
  file="artifacts/${pair%%:*}.md"; id="$(basename "${pair%%:*}")"
  printf -- '---\nid: %s\ntype: %s\ntitle: Body has id\nstatus: draft\ncreated: 2026-10-14\nauthor: test\n---\n\n```yaml\nid: example\n```\n\n---\n\nid: other\n' "$id" "${pair##*:}" > "$file"
done
cp artifacts/prds/PRD-004.md "$P/prd4.before"
assert_exit 0 bash tools/artifact/link.sh artifacts/prds/PRD-004.md artifacts/rfcs/RFC-003.md
assert_eq "1" "$(grep -c '^children:' artifacts/prds/PRD-004.md)" "children added once, in the frontmatter"
assert_eq "$(sed -n '/^```yaml/,$p' "$P/prd4.before")" "$(sed -n '/^```yaml/,$p' artifacts/prds/PRD-004.md)" "body is unchanged by linking"
assert_eq "children: [RFC-003]" "$(sed -n '3p' artifacts/prds/PRD-004.md)" "children sits right after id"

# Child whose body repeats `id:` and `parent:` lines: the frontmatter gets the parent, the body is untouched.
printf -- '---\nid: PRD-005\ntype: prd\ntitle: P\nstatus: draft\ncreated: 2026-10-14\nauthor: test\n---\n\nBody.\n' > artifacts/prds/PRD-005.md
printf -- '---\nid: RFC-004\ntype: rfc\ntitle: R\nstatus: draft\ncreated: 2026-10-14\nauthor: test\n---\n\nid: x\nparent: zz\n' > artifacts/rfcs/RFC-004.md
assert_exit 0 bash tools/artifact/link.sh artifacts/prds/PRD-005.md artifacts/rfcs/RFC-004.md
assert_eq "parent: PRD-005" "$(sed -n '1,/^---$/p' artifacts/rfcs/RFC-004.md | grep '^parent:')" "child parent set in the frontmatter"
assert_eq "id: x
parent: zz" "$(tail -n 2 artifacts/rfcs/RFC-004.md)" "child body keeps its id: and parent: lines"

# Block-style YAML lists stay block-style, gain the new item once, and never turn into flow style.
printf -- '---\nid: PRD-006\ntype: prd\ntitle: P\nstatus: draft\ncreated: 2026-10-14\nauthor: test\nchildren:\n  - RFC-009\n---\n\nBody.\n' > artifacts/prds/PRD-006.md
printf -- '---\nid: RFC-005\ntype: rfc\ntitle: R\nstatus: draft\ncreated: 2026-10-14\nauthor: test\ndepends_on:\n  - SPEC-1\nowner: me\n---\n\nBody.\n' > artifacts/rfcs/RFC-005.md
assert_exit 0 bash tools/artifact/link.sh artifacts/prds/PRD-006.md artifacts/rfcs/RFC-005.md
assert_eq "children:
  - RFC-009
  - RFC-005" "$(sed -n '/^children:/,/^---$/p' artifacts/prds/PRD-006.md | sed '$d')" "children block list gets a block item"
assert_eq "depends_on:
  - SPEC-1
  - PRD-006
owner: me" "$(sed -n '/^depends_on:/,/^owner:/p' artifacts/rfcs/RFC-005.md)" "depends_on block list gets a block item before the next key"
cp artifacts/prds/PRD-006.md "$P/prd6.before"; cp artifacts/rfcs/RFC-005.md "$P/rfc5.before"
assert_exit 0 bash tools/artifact/link.sh artifacts/prds/PRD-006.md artifacts/rfcs/RFC-005.md
assert_eq "$(cat "$P/prd6.before")" "$(cat artifacts/prds/PRD-006.md)" "block-list relink adds no duplicate (parent)"
assert_eq "$(cat "$P/rfc5.before")" "$(cat artifacts/rfcs/RFC-005.md)" "block-list relink adds no duplicate (child)"
# Inline lists still grow inline.
printf -- '---\nid: PRD-007\ntype: prd\ntitle: P\nstatus: draft\ncreated: 2026-10-14\nauthor: test\nchildren: [RFC-009]\n---\n\nBody.\n' > artifacts/prds/PRD-007.md
printf -- '---\nid: RFC-006\ntype: rfc\ntitle: R\nstatus: draft\ncreated: 2026-10-14\nauthor: test\n---\n\nBody.\n' > artifacts/rfcs/RFC-006.md
assert_exit 0 bash tools/artifact/link.sh artifacts/prds/PRD-007.md artifacts/rfcs/RFC-006.md
assert_contains "$(cat artifacts/prds/PRD-007.md)" "children: [RFC-009, RFC-006]" "inline list stays inline"

# --- promote.sh ---
assert_exit 1 bash tools/artifact/promote.sh "$PRD" approved
assert_contains "$OUT" "Cannot promote from 'draft' to 'approved'"
assert_exit 1 bash tools/artifact/promote.sh "$PRD" shipped
assert_contains "$OUT" "Invalid status"

assert_exit 0 bash tools/artifact/promote.sh "$PRD" review
assert_contains "$(cat "$PRD")" "status: review"
assert_exit 0 bash tools/artifact/promote.sh "$RFC" review
assert_exit 1 bash tools/artifact/promote.sh "$RFC" approved
assert_contains "$OUT" "parent 'PRD-001' is still 'review'"
assert_contains "$(cat "$RFC")" "status: review" "failed promotion leaves status alone"

# --- check-gate.sh: stage behavior on a PRD still in review ---
set_stage idea
assert_exit 0 bash tools/artifact/check-gate.sh prd-to-rfc "$PRD"
assert_contains "$OUT" "GATE ADVISORY"
assert_contains "$OUT" "stage: idea"

set_stage mvp
assert_exit 1 bash tools/artifact/check-gate.sh prd-to-rfc "$PRD"
assert_exit 0 bash tools/artifact/check-gate.sh impl-to-qa "$RFC"
assert_contains "$OUT" "GATE ADVISORY" "mvp: impl-to-qa is advisory"

set_stage growth
assert_exit 1 bash tools/artifact/check-gate.sh prd-to-rfc "$PRD"
assert_contains "$OUT" "GATE FAILED"
assert_contains "$OUT" "PRD status is 'review'"

assert_exit 2 bash tools/artifact/check-gate.sh prd-to-rfc artifacts/prds/PRD-404.md
assert_contains "$OUT" "PRD not found"
assert_exit 2 bash tools/artifact/check-gate.sh rfc-to-impl RFC-404
assert_exit 1 bash tools/artifact/check-gate.sh no-such-gate "$PRD"
assert_contains "$OUT" "Unknown gate"

# Approve the chain; gates now pass (by path and by id).
assert_exit 0 bash tools/artifact/promote.sh "$PRD" approved
assert_exit 0 bash tools/artifact/promote.sh "$RFC" approved
assert_contains "$(cat artifacts/.audit-log/promotions.log)" "$RFC: review → approved"
assert_exit 0 bash tools/artifact/check-gate.sh prd-to-rfc "$PRD"
assert_contains "$OUT" "GATE PASSED"
assert_exit 0 bash tools/artifact/check-gate.sh rfc-to-impl RFC-001
assert_contains "$OUT" "GATE PASSED"

# The test never touched the real repository.
assert_file_missing "$REPO_ROOT/artifacts/prds/PRD-001.md"

# --- setup.sh --cleanup removes only Company OS copies of the old root guides ---
C="$(make_tmp)"; cd "$C"
printf '# FAQ\nmy own FAQ\n' > FAQ.md
printf '# Token Cost Reference\n\nUse Company OS.\n' > TOKEN_COSTS.md
printf '# Setup Guide — AI Agentic Company OS\n' > SETUP_COMPANY_OS.md
printf '# Mine\n' > README.md
assert_exit 0 bash "$REPO_ROOT/.company-os/setup.sh" --cleanup
assert_contains "$OUT" "Kept     FAQ.md"
assert_eq "yes" "$([ -f FAQ.md ] && echo yes || echo no)" "user's own FAQ.md survives --cleanup"
assert_eq "no" "$([ -f TOKEN_COSTS.md ] && echo yes || echo no)" "Company OS TOKEN_COSTS.md copy removed"
assert_eq "no" "$([ -f SETUP_COMPANY_OS.md ] && echo yes || echo no)" "Company OS SETUP_COMPANY_OS.md copy removed"
assert_eq "yes" "$([ -f README.md ] && echo yes || echo no)" "README.md untouched"

finish
