---
name: api-tester-playbook
description: Generates API testing playbooks covering contract tests, authentication testing, pagination validation, and error handling. Use when building or reviewing API test suites.
---

# API Tester Playbook

## Reference
- **ID**: S-QA-02
- **Category**: QA
- **Inputs**: API specification (OpenAPI/Swagger), auth model, endpoint inventory
- **Outputs**: API test playbook → artifacts/qa/
- **Used by**: QA Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose
Produces a structured API testing playbook that covers contract testing, authentication and authorization edge cases, pagination correctness, rate limiting behavior, and error response validation for every endpoint.

## Procedure
1. Collect the API specification (OpenAPI/Swagger) or endpoint inventory.
2. For each endpoint, generate contract tests: verify response shape matches the schema.
3. Design authentication tests: valid tokens, expired tokens, missing tokens, wrong scopes.
4. Design authorization tests: tenant isolation, role-based access, resource ownership.
5. Design pagination tests: first page, last page, empty results, invalid cursors, page size limits.
6. Design error handling tests: 400 (bad input), 404 (not found), 409 (conflict), 429 (rate limit), 500 (server error).
7. Design idempotency tests for mutating endpoints (POST, PUT, DELETE).
8. Define expected response headers (CORS, cache-control, rate-limit headers).
9. Organize tests into a runnable playbook with setup/teardown steps.
10. Save the playbook to `artifacts/qa/`.
11. Validate the artifact using `./tools/artifact/validate.sh`.

## Quality Checklist
- [ ] Every endpoint has contract tests
- [ ] Auth edge cases (expired, missing, wrong scope) are covered
- [ ] Authorization boundaries are tested (tenant isolation, RBAC)
- [ ] Pagination is tested for boundary conditions
- [ ] Error responses match documented status codes and shapes
- [ ] Mutating endpoints have idempotency tests
- [ ] Rate limiting behavior is validated
- [ ] Artifact passes validation
