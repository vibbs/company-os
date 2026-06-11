---
name: multi-tenancy
description: Design patterns for multi-tenant architecture including org scoping, row-level security, and tenant data isolation. Use when designing or auditing tenant isolation boundaries.
user-invokable: false
---

# Multi-Tenancy

## Reference
- **ID**: S-ENG-04
- **Category**: Engineering
- **Inputs**: data model, tenant boundaries, isolation requirements, compliance constraints
- **Outputs**: multi-tenancy design document → artifacts/engineering/
- **Used by**: Engineering Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose
Defines the architecture and conventions for multi-tenant data isolation, ensuring that tenant data is properly scoped, row-level security is enforced, and cross-tenant data leakage is prevented at every layer of the stack.

## Procedure

### Step 0: Multi-Tenancy Check

Read `architecture.multi_tenant` from `company.config.yaml`.

If `false` or absent: output "Multi-tenancy not configured for this project. Set `architecture.multi_tenant: true` in company.config.yaml to enable multi-tenant design patterns." and skip the remaining procedure.

If `true`: proceed with full multi-tenancy design.

### Steps
1. Define the tenant model: what constitutes a tenant (org, workspace, account).
2. Choose the isolation strategy: shared database with RLS, schema-per-tenant, or database-per-tenant.
3. Design the org-scoping layer: how every query is automatically scoped to the current tenant.
4. Implement row-level security (RLS) policies at the database level.
5. Define middleware/context propagation to carry tenant ID through the request lifecycle.
6. Audit all data access paths to ensure no unscoped queries exist.
7. Design tenant-aware caching: cache keys must include tenant ID.
8. Define cross-tenant operation policies (admin access, data migration, support tooling).
9. Document testing strategy: how to verify isolation in automated tests.
10. Save the design document to `artifacts/engineering/`.
11. Validate the artifact using `./tools/artifact/validate.sh`.

## Quality Checklist
- [ ] Tenant model is clearly defined with boundary rules
- [ ] RLS policies are applied to all tenant-scoped tables
- [ ] No unscoped queries exist in the codebase
- [ ] Cache keys include tenant ID
- [ ] Middleware propagates tenant context on every request
- [ ] Cross-tenant access is explicitly gated and audited
- [ ] Automated tests verify tenant isolation
- [ ] Artifact passes validation
