---
name: artifact-import
description: Imports existing documents (PRDs, RFCs, API specs, test plans) into Company OS with proper frontmatter, type classification, and artifact linking. Use when bringing external documents into the artifact system.
user-invokable: true
argument-hint: "[path/to/file or paste content inline]"
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Artifact Import

Imports pre-existing documents from external sources (Google Docs, Notion, Confluence, local files, or inline-pasted content) into the Company OS artifact system with proper frontmatter, classification, and linking.

## Input Modes

**Mode A — File-based**: User places exported documents (Markdown, HTML, or plain text) in the `imports/` directory, then runs `/artifact-import`.

**Mode B — Inline paste**: User pastes document content directly into the prompt (e.g., "Import this as a PRD: [content]"). The skill creates the artifact file from the pasted content.

If both modes are present, process both. If neither, prompt the user:
> "No files found in `imports/` and no document content provided. Either export your docs as Markdown and place them in `imports/`, or paste the content directly."

## Procedure

### Step 1: Detect and Read Sources

1. Scan `imports/` for any non-`.gitkeep` files
2. Check the user's message for substantial document content (more than a few sentences of specification-like text)
3. Read each file or inline block completely

### Step 2: Classify Each Document

Determine the artifact type by analyzing content signals:

| Content Signals | Artifact Type |
|----------------|---------------|
| Problem statement, user stories, acceptance criteria, success metrics, scope boundaries | `prd` |
| System design, architecture, data model, modules, alternatives considered, migration plan | `rfc` |
| API endpoints, request/response schemas, error codes, auth headers, pagination | `rfc` (API-focused) |
| Test cases, test scenarios, coverage matrix, preconditions | `test-plan` |
| Test results, pass/fail counts, regression results, coverage percentages | `qa-report` |
| Threat model, security findings, vulnerability assessment, STRIDE analysis | `security-review` |
| Launch plan, go-to-market, messaging, target audience, channels | `launch-brief` |
| Decision record, ADR, rationale, alternatives considered, consequences | `decision-memo` |

**Rules:**
- If the user provides a type hint in their prompt (e.g., "Import this PRD"), trust the user over content analysis
- If classification is ambiguous, ask: "I think `filename.md` is an RFC, but it could also be a test plan. Which type should I assign?"
- If an API spec is imported alongside an RFC, ask: "Embed API spec into the RFC's API Surface section, or create as a standalone artifact?"

### Step 3: Generate Artifact IDs

Scan `artifacts/` recursively for all existing artifact IDs to find the highest number per type prefix, then auto-increment.

| Type | Prefix | Example |
|------|--------|---------|
| prd | PRD | PRD-001 |
| rfc | RFC | RFC-001 |
| test-plan | TP | TP-001 |
| qa-report | QA | QA-001 |
| security-review | SR | SR-001 |
| launch-brief | LB | LB-001 |
| decision-memo | DM | DM-001 |

### Step 4: Build Frontmatter

Generate complete YAML frontmatter for each artifact:

```yaml
---
id: {generated-id}
type: {classified-type}
title: "{extracted-title}"
status: review
created: {today or document's original date if found}
author: imported
parent: null
children: []
depends_on: []
blocks: []
tags: [imported]
---
```

**Notes:**
- `status: review` — imported artifacts are not drafts (they already exist). Users promote to `approved` after reviewing.
- `author: imported` — distinguishes agent-created from externally imported artifacts.
- `tags: [imported]` — always include. Add additional tags extracted from content or context.
- If the original document contains an author name, add as tag: `tags: [imported, author:jane-doe]`.

### Step 5: Restructure Content (Best-Effort)

Map imported content to Company OS templates where applicable:

1. Read the relevant template if one exists (`prd-template.md` for PRDs, `rfc-template.md` for RFCs)
2. Map imported headings to template headings (e.g., "Goals" → "Success Metrics")
3. Preserve all original content — never delete imported text
4. For template sections the import doesn't cover, insert the heading with: `<!-- TODO: Fill in this section -->`
5. For imported sections that don't map to the template, keep under an "Additional Context (Imported)" heading at the bottom
6. For types without templates (test-plan, qa-report, security-review, launch-brief), apply frontmatter and preserve body as-is

### Step 6: Detect Relationships and Link

When multiple documents are imported together, detect relationships:

1. **Explicit references**: Document mentions another artifact by name or ID
2. **Topic coherence**: Documents about the same feature imported together are likely related
3. **Type hierarchy**: Canonical order is PRD → RFC → test-plan/security-review → qa-report → launch-brief. If multiple types are imported for the same feature, link following this hierarchy.
4. **User hints**: If the user says "these are all for the auth feature," link them as a family

After all artifacts are written:
- Run `./tools/artifact/link.sh <parent-path> <child-path>` for each detected parent-child pair
- Run `./tools/artifact/validate.sh --strict <path>` on linked artifacts to verify bidirectional consistency

### Step 7: Write Files and Validate

For each artifact:
1. Write to the correct subdirectory: `artifacts/{type-plural}/` (e.g., `artifacts/prds/`, `artifacts/rfcs/`)
2. File naming: `{ID}-{kebab-case-slug}.md` (e.g., `PRD-001-user-authentication.md`)
3. Run `./tools/artifact/validate.sh <path>` — fix any issues and re-validate

### Step 8: Clean Up and Report

1. Delete processed files from `imports/` (preserve `.gitkeep`)
2. Print a summary:

```
## Import Summary

### Imported Artifacts
| # | Source File | Type | ID | Location | Status |
|---|------------|------|----|----------|--------|
| 1 | auth-prd.md | prd | PRD-001 | artifacts/prds/PRD-001-user-auth.md | review |
| 2 | auth-rfc.md | rfc | RFC-001 | artifacts/rfcs/RFC-001-auth-service.md | review |

### Relationships Created
- PRD-001 → RFC-001 (parent → child)

### Validation
All artifacts passed validation.

### Next Steps
1. Review each artifact — check sections marked <!-- TODO -->
2. Promote parent artifacts first: ./tools/artifact/promote.sh <prd-path> approved
3. Then promote children: ./tools/artifact/promote.sh <rfc-path> approved
4. Stage gates are now active: ./tools/artifact/check-gate.sh <gate> <path>
```

## Edge Cases

- **Duplicate detection**: If an import matches an existing artifact (same title + type), warn before creating a duplicate
- **Unrecognizable files**: Skip non-document files (CSV, images, binaries) with a note — suggest placing in `standards/` if they're reference material
- **Very large documents**: Proceed normally but note the size
- **Rough notes**: Import as-is with a note: "This appears to be rough notes. Consider expanding before promoting to `approved`."
- **No files, no paste**: Print instructions for how to export from Google Docs, Notion, or Confluence

## Reference

- **Category**: Orchestration
- **Inputs**: files in `imports/` OR inline content
- **Outputs**: properly formatted artifacts in `artifacts/` subdirectories
- **Used by**: User (directly), Orchestrator Agent
- **Tool scripts**: `./tools/artifact/validate.sh`, `./tools/artifact/link.sh`
