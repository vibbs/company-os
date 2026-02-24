---
id: DM-001
type: decision-memo
title: "company.config.yaml remains at repository root"
status: approved
created: 2026-02-23
author: orchestrator
parent: null
children: []
depends_on: []
blocks: []
tags: [architecture, conventions]
---

# Decision: company.config.yaml Location

## Question

Should `company.config.yaml` move from the repository root into the `artifacts/` directory?

## Decision

**No. `company.config.yaml` stays at the repository root.**

## Rationale

### 1. Input vs Output Separation

`company.config.yaml` is **user-authored configuration input** — it defines the company's tech stack, API standards, and conventions. Artifacts are **agent-produced outputs** — PRDs, RFCs, QA reports created during the ship flow.

Moving config into artifacts conflates the source of truth (what the user decides) with generated output (what agents produce).

### 2. Lifecycle Does Not Apply

Artifacts have a lifecycle: `draft → review → approved → archived`. They have lineage tracking: `parent`, `children`, `depends_on`, `blocks`.

None of this applies to a configuration file. Config is a living document that changes when the user decides, not when an agent promotes it.

### 3. Convention Consistency

Every agent definition has `Read company.config.yaml at session start` as a behavioral rule. Tool scripts reference it at `../../company.config.yaml` from their directory. Moving it would break all these conventions.

### 4. Artifact Tooling Confusion

If config moves to `artifacts/`, tools would attempt to validate it as an artifact (checking for `id`, `type`, `status` fields), promote its status, or track its lineage — none of which make sense for configuration.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|------------|------|------|-------------|
| Move to `artifacts/config/` | Groups "important files" together | Conflates input/output, breaks conventions, requires frontmatter | Architectural confusion |
| Copy to `artifacts/` as snapshot | Creates audit trail of config changes | Duplication, drift risk, no single source of truth | Unnecessary complexity |

## Consequences

- Config remains at root, immediately visible when cloning the repo
- All agent and tool references continue to work without modification
- Config changes should be tracked via git history, not artifact lineage
