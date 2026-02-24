---
name: api-contract-designer
description: Designs REST/GraphQL API contracts with consistent error handling, pagination, auth, and i18n. Use when designing new API endpoints, modifying existing APIs, or creating service interfaces.
allowed-tools: Read, Grep, Glob, Bash, Write
---

# API Contract Designer

## Reference
- **ID**: S-ENG-02
- **Category**: Engineering
- **Inputs**: RFC/architecture document, company.config.yaml (api section), standards/api/
- **Outputs**: API contract document, OpenAPI spec (if configured)
- **Used by**: Engineering Agent
- **Tool scripts**: ./tools/ci/openapi-lint.sh, ./tools/artifact/validate.sh

For the RFC7807 error format reference, see [error-format-reference.md](error-format-reference.md).

## Purpose

Design consistent, well-documented API contracts that follow the company's configured standards. The API contract is the bridge between frontend and backend, between your service and consumers.

## When to Use

- RFC requires new API endpoints
- Existing API needs modification or extension
- New service needs an API interface

## API Design Procedure

### Step 1: Load Configuration

Read `api.*` section from `company.config.yaml` and check `standards/api/` for existing conventions.

### Step 2: Design Resource Model

Map domain entities to API resources:
1. **Identify resources** — nouns, not verbs (users, projects, invoices)
2. **Define relationships** — nested vs. flat (prefer flat with IDs)
3. **Choose granularity** — one resource per entity, avoid mega-endpoints

```
/api/v1/users
/api/v1/users/{id}
/api/v1/projects
/api/v1/projects/{id}
```

### Step 3: Design Endpoints

Standard CRUD pattern (REST):

| Operation | Method | Path | Status Codes |
|-----------|--------|------|-------------|
| List | GET | /api/v1/{resources} | 200 |
| Create | POST | /api/v1/{resources} | 201 |
| Get | GET | /api/v1/{resources}/{id} | 200, 404 |
| Update | PATCH | /api/v1/{resources}/{id} | 200, 404 |
| Delete | DELETE | /api/v1/{resources}/{id} | 204, 404 |

Custom operations use verb-based sub-resources:
```
POST /api/v1/projects/{id}/archive
POST /api/v1/invoices/{id}/send
```

### Step 4: Design Request/Response Shapes

Rules:
- Use consistent casing (camelCase or snake_case — match codebase)
- Document required vs optional fields with validation constraints
- Always include `id`, `createdAt`, `updatedAt` on resources
- Use ISO8601 for dates, UUIDs for public IDs
- Wrap collections: `{ "data": [...], "pagination": { ... } }`

### Step 5: Design Error Responses

Use the error format from company config. For RFC7807 details, see [error-format-reference.md](error-format-reference.md).

Standard error codes: 400, 401, 403, 404, 409, 422, 429, 500.

For i18n: use machine-readable `code` fields; clients map to localized strings.

### Step 6: Design Pagination

**Cursor-based**: opaque cursor, `has_more` boolean, default limit 20, max 100.
**Offset-based**: `total`, `limit`, `offset` fields.

Follow `api.pagination` config setting.

### Step 7: Design Authentication & Authorization

Follow `api.auth` config. Define auth requirements per endpoint.

### Step 8: Design Rate Limiting

If configured, include `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset` headers. Return 429 when exceeded.

### Step 9: Produce OpenAPI Spec

If `api.spec_format` is "OpenAPI 3.1", produce a complete spec. Validate with `./tools/ci/openapi-lint.sh`.

### Step 10: Validate

- [ ] All RFC endpoints have complete contracts
- [ ] Error format matches configured standard
- [ ] Pagination matches configured style
- [ ] Auth is defined for every endpoint
- [ ] Response shapes are consistent across endpoints
- [ ] OpenAPI spec validates if applicable
- [ ] No internal implementation details exposed

## Quality Checklist

- [ ] Resource model maps cleanly to domain entities
- [ ] CRUD operations follow consistent patterns
- [ ] Error responses are structured and machine-readable
- [ ] Pagination handles edge cases (empty, single page, last page)
- [ ] Auth model is complete
- [ ] Contract is sufficient for consumers to build against independently
