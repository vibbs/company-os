# RFC Artifact Template

Use this template when creating a new RFC. Copy it into `artifacts/rfcs/` and fill in each section.

```markdown
---
id: RFC-[XXX]
type: rfc
title: "[Feature Name] — Technical Design"
status: draft
created: [YYYY-MM-DD]
author: engineering-agent
parent: PRD-[XXX]
children: []
depends_on: [PRD-XXX]
blocks: []
tags: []
---

# RFC: [Feature Name]

## Summary
[1-2 sentence overview of what this RFC proposes]

## Motivation
[Link to PRD, restate the problem briefly]

## Tech Stack Context
- Language: [from config]
- Framework: [from config]
- Database: [from config]
- [Any stack fitness concerns]

## Design

### System Boundaries
[Diagram + description]

### Data Model
[Tables, relationships, migrations]

### API Surface
[Endpoints, payloads, errors]

### Service Layer
[Business logic, transactions, side effects]

### Background Jobs
[Async operations, if any]

### Cross-Cutting Concerns
[Auth, multi-tenancy, observability, caching]

## Alternatives Considered
| Alternative | Pros | Cons | Why Rejected |
|------------|------|------|-------------|
| ... | ... | ... | ... |

## Migration Strategy
[How to deploy safely: feature flags, gradual rollout, rollback plan]

## Dependencies
- [What this depends on]
- [What depends on this]

## Open Questions
- [Unresolved technical decisions]
```
