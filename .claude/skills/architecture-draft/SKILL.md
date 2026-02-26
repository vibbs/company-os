---
name: architecture-draft
description: Produces RFC/ADR defining system boundaries, modules, data model, and integration points. Use when translating a PRD into technical design, making architectural decisions, or designing new system components.
allowed-tools: Read, Grep, Glob, Bash, Write
---

# Architecture Draft (SaaS Core)

## Reference
- **ID**: S-ENG-01
- **Category**: Engineering
- **Inputs**: approved PRD, company.config.yaml, existing RFCs, standards/api/ and standards/coding/
- **Outputs**: RFC artifact → artifacts/rfcs/
- **Used by**: Engineering Agent
- **Tool scripts**: ./tools/artifact/validate.sh, ./tools/ci/openapi-lint.sh, ./tools/db/migration-check.sh

For the RFC artifact template, see [rfc-template.md](rfc-template.md).

## Purpose

Translate an approved PRD into a technical design document (RFC/ADR) that defines how the feature will be built. The RFC bridges product intent and code — it's the "how" to the PRD's "what."

## When to Use

- Approved PRD requires technical design
- Significant architectural change or new system component
- Cross-cutting concern that affects multiple modules

## Architecture Drafting Procedure

### Step 1: Load Context

Before designing anything:

1. **Read the PRD** — understand every acceptance criterion
2. **Read `company.config.yaml`** — understand tech stack constraints
3. **Read existing RFCs** in `artifacts/rfcs/` — understand architectural precedent
4. **Read standards** in `standards/api/` and `standards/coding/`
5. **Check for related artifacts** — is there an existing data model, auth system, or API pattern to extend?

### Step 2: Tech Stack Fitness Check

Evaluate whether the configured tech stack is well-suited for this feature:

| Aspect | Check |
|--------|-------|
| **Language/Framework** | Can the framework handle this pattern natively? |
| **Database** | Is the data model relational, document, or graph? Does the configured DB fit? |
| **Queue/Background** | Does this need async processing? Is the configured queue sufficient? |
| **Scale** | Will this work at the expected load? |

**If the stack is suboptimal**: Document the concern explicitly in the RFC's "Alternatives Considered" section. Recommend an alternative with tradeoffs. But respect the user's final decision.

### Step 3: Define System Boundaries

Draw the boundary between what's new, what's extended, and what's external.

```
[Client] → [API Layer] → [Service Layer] → [Data Layer]
                              ↓
                        [Queue / Jobs]
                              ↓
                      [External Services]
```

For each boundary, define: interface, protocol, and auth.

### Step 4: Design the Data Model

1. **Identify entities** — what domain objects does this feature need?
2. **Define relationships** — one-to-one, one-to-many, many-to-many
3. **Apply multi-tenancy** — if configured, apply tenant scoping
4. **Plan migrations** — new tables, columns, indexes; consider rollback strategy

### Step 5: Design API Surface

Based on `api.*` config, define endpoints, request/response shapes, error handling, auth, pagination, and validation. Produce OpenAPI spec if configured. Validate with `./tools/ci/openapi-lint.sh`.

### Step 6: Design Service Layer

Define business logic, transaction boundaries, error handling, side effects, and background jobs.

### Step 7: Address Cross-Cutting Concerns

| Concern | How Addressed |
|---------|---------------|
| **Auth & Permissions** | [describe] |
| **Multi-tenancy** | [describe or reference multi-tenancy skill] |
| **Observability** | [describe or reference observability-baseline skill] |
| **Caching** | [describe strategy, invalidation] |
| **Rate limiting** | [describe if applicable] |
| **i18n** | [string management, locale detection, fallback — or "N/A" if not enabled] |
| **Deployment Strategy** | [environment ladder, rollout approach, rollback procedure — reference deployment-strategy skill] |
| **Feature Flags** | [flag specifications for new features, progressive discovery levels — reference feature-flags skill] |
| **Platform Strategy** | [responsive web, native mobile, PWA considerations — reference mobile-readiness skill if `platforms.targets` configured] |

### Step 8: Assemble the RFC

Use the template in [rfc-template.md](rfc-template.md).

### Step 9: Validate

- [ ] RFC addresses every PRD acceptance criterion
- [ ] Data model is consistent with existing schema
- [ ] API design follows configured standards
- [ ] Multi-tenancy applied if configured
- [ ] Observability hooks defined
- [ ] Migration strategy is safe (can rollback)
- [ ] Alternatives documented with rationale
- [ ] OpenAPI spec validates if applicable
- [ ] Deployment strategy section included (references deployment-strategy skill)
- [ ] Feature flag strategy addressed (if applicable)
- [ ] Platform targets accounted for (responsive, native, PWA)
- [ ] Artifact frontmatter is complete (`./tools/artifact/validate.sh`)

### Step 10: Handoff

1. Set status to `review`
2. Store in `artifacts/rfcs/`
3. Notify Orchestrator — RFC ready for Ops & Risk review and QA test planning
4. After approval, proceed with implementation (implementation-decomposer)

## Import Variant

If an RFC or architecture document already exists outside Company OS, use `/artifact-import` instead of creating from scratch. The import skill classifies the document, applies the RFC template structure, generates frontmatter, and links it to its parent PRD if one exists. After import, review against this skill's quality checklist and ensure tech stack fitness is evaluated.

## Quality Checklist

- [ ] Every PRD acceptance criterion has a technical solution
- [ ] Tech stack fitness evaluated and concerns flagged
- [ ] Data model is normalized appropriately
- [ ] API follows configured conventions
- [ ] Cross-cutting concerns addressed (not deferred)
- [ ] Migration strategy allows safe rollback
- [ ] At least one alternative considered
- [ ] RFC is implementable by someone who hasn't read the PRD
