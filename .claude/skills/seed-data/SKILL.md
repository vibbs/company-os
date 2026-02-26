---
name: seed-data
description: Generates test seed data, fixtures, and factory definitions for all data scenarios. Produces tech-stack-appropriate seed files and a seed-data catalog artifact.
user-invokable: true
argument-hint: "[prd-id or entity-name]"
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Seed Data Generator

## Reference
- **ID**: S-QA-05
- **Category**: QA / Testing
- **Inputs**: PRD acceptance criteria, test plan (if exists), data models/schema files, company.config.yaml
- **Outputs**: Seed data files per scenario, seed-data-catalog artifact in `artifacts/test-data/`
- **Used by**: QA & Release Agent, Engineering Agent
- **Tool scripts**: `./tools/db/seed.sh`, `./tools/artifact/validate.sh`

## Purpose

Generate comprehensive test seed data that covers all data scenarios needed for testing, benchmarking, and dogfooding. The skill discovers domain entities from the codebase, defines named data scenarios, and produces runnable seed files appropriate to the project's tech stack.

## When to Use

- Before writing tests (to define what test data exists)
- Before running performance benchmarks (to ensure realistic data volume)
- Before dogfooding (to populate the app with realistic state)
- When a new feature introduces new domain entities
- When a test plan specifies "test data requirements" that don't yet exist

## Seed Data Procedure

### Step 1: Discover Domain Entities

Scan the codebase for domain models and data structures:

1. **Read `company.config.yaml`** — extract `tech_stack.language`, `tech_stack.framework`, `tech_stack.database`, `tech_stack.orm`
2. **Find schema/model files** based on tech stack:
   - JS/TS + Prisma: `prisma/schema.prisma`
   - JS/TS + Drizzle: `src/**/schema.ts`, `drizzle/`
   - JS/TS + TypeORM: `src/**/entity/*.ts`
   - Python + Django: `**/models.py`
   - Python + SQLAlchemy: `**/models.py`, `**/model.py`
   - Go + GORM: `**/model.go`, `**/models.go`
   - SQL migrations: `migrations/`, `db/migrate/`
3. **Read PRD acceptance criteria** (if `--prd` argument provided) to understand which entities are involved in user stories
4. **Read existing test plan** (if exists in `artifacts/test-plans/`) for test data requirements already specified

Produce an **entity catalog**:

| Entity | Source File | Key Fields | Relationships | Constraints |
|--------|------------|------------|---------------|-------------|
| User | src/models/user.ts | id, email, name, role | has_many: Posts | email: unique, not null |
| Post | src/models/post.ts | id, title, body, authorId | belongs_to: User | title: not null, max 200 |

### Step 2: Define Data Scenarios

For each entity, define values across 6 named scenarios:

#### Scenario: `empty`
- Zero records in all tables
- Use case: testing empty states, onboarding flows, "no data yet" UI

#### Scenario: `minimal`
- 1-2 records per entity, minimum viable relationships
- Use case: unit tests, basic integration tests, quick local development

#### Scenario: `nominal`
- 10-50 records per entity with realistic variety
- Diverse field values (different roles, statuses, content lengths)
- All relationship types exercised (one-to-many, many-to-many)
- Use case: integration tests, manual QA, demo environments

#### Scenario: `edge-cases`
- Boundary values for every field:
  - Strings: empty string, single char, max length, unicode (emoji, RTL, CJK), HTML entities, SQL injection attempts (escaped)
  - Numbers: 0, -1, MAX_INT, MIN_INT, floating point precision edge cases
  - Dates: epoch, far future, leap day, timezone boundaries, null dates where nullable
  - Booleans: both values, null where nullable
  - Enums: every valid value + boundary of invalid
- Null/undefined for every nullable field
- Orphaned relationships (where FK constraints allow)
- Use case: edge case testing, input validation testing, security testing

#### Scenario: `high-volume`
- 1,000-10,000 records per entity (configurable via `SEED_VOLUME` env var)
- Realistic distribution of field values (not all identical)
- All relationship cardinalities at scale
- Use case: performance benchmarks, load testing, pagination testing

#### Scenario: `error-states`
- Records in invalid/unusual states that the system should handle gracefully:
  - Soft-deleted records (if applicable)
  - Expired tokens/sessions
  - Failed payment states
  - Pending/processing states
  - Records with missing optional relationships
- Use case: error handling tests, resilience testing, recovery flow testing

### Step 3: Generate Seed Files

Based on `company.config.yaml` tech stack, generate seed files in the appropriate format:

#### For JS/TS Projects
```
seeds/
  factories/           # Reusable factory functions
    user.factory.ts
    post.factory.ts
  scenarios/
    empty.ts           # Clears all tables
    minimal.ts         # Minimal viable data
    nominal.ts         # Realistic variety
    edge-cases.ts      # Boundary values
    high-volume.ts     # Performance data
    error-states.ts    # Error condition data
  index.ts             # Exports all scenarios
```

Factory pattern:
- Use `@faker-js/faker` for realistic field generation
- Each factory returns a builder with `.build()` (in-memory) and `.create()` (persisted)
- Factories accept overrides: `userFactory.build({ role: 'admin' })`
- Relationships handled via association helpers

#### For Python Projects
```
seeds/
  factories/
    user_factory.py
    post_factory.py
  scenarios/
    empty.py
    minimal.py
    nominal.py
    edge_cases.py
    high_volume.py
    error_states.py
  __init__.py
```

Factory pattern:
- Use `factory_boy` with `faker` provider
- Each factory is a class extending `factory.Factory` (or `factory.django.DjangoModelFactory`)
- Subfactories for relationships
- Traits for common variations

#### For Go Projects
```
seeds/
  factories/
    user_factory.go
    post_factory.go
  scenarios/
    empty.go
    minimal.go
    nominal.go
    edge_cases.go
    high_volume.go
    error_states.go
  seed.go             # Main entry point
```

Factory pattern:
- Builder functions returning struct instances
- `go-faker` for realistic field generation
- Functional options for overrides

#### For SQL-only (no ORM)
```
seeds/
  00_reset.sql         # TRUNCATE/DELETE all tables (respecting FK order)
  01_minimal.sql
  02_nominal.sql
  03_edge_cases.sql
  04_high_volume.sql
  05_error_states.sql
```

SQL pattern:
- Use `INSERT ... ON CONFLICT DO NOTHING` (Postgres) or `INSERT IGNORE` (MySQL) for idempotency
- Respect foreign key insertion order
- Include comments explaining each edge case value

### Step 4: Produce Seed Data Catalog Artifact

Create an artifact in `artifacts/test-data/` with the following structure:

```markdown
---
id: SD-[feature-name]
type: test-data
title: "Seed Data Catalog: [Feature/Domain]"
status: draft
created: [YYYY-MM-DD]
author: engineering-agent
parent: [PRD-XXX if scoped to a PRD]
children: []
depends_on: []
blocks: []
tags: [seed-data, testing]
---

# Seed Data Catalog: [Feature/Domain]

## Entity Catalog
[Table from Step 1]

## Relationship Map
[Entity relationship descriptions or ASCII diagram]

## Scenarios

### empty
- Records: 0 per entity
- Use case: empty state testing

### minimal
- Records: [counts per entity]
- Use case: unit tests, basic flows

### nominal
- Records: [counts per entity]
- Notable variations: [list key field value variations]

### edge-cases
- Records: [counts per entity]
- Boundary values covered: [list per entity]

### high-volume
- Records: [counts per entity, configurable via SEED_VOLUME]
- Distribution: [describe field value distribution]

### error-states
- Records: [counts per entity]
- Error conditions: [list each error state and which entity]

## File Locations
[List all generated seed files with paths]

## Running Seeds
- All scenarios: `./tools/db/seed.sh --all`
- Single scenario: `./tools/db/seed.sh nominal`
- Reset + seed: `./tools/db/seed.sh --reset nominal`
- Dry run: `./tools/db/seed.sh --dry-run edge-cases`
```

Run `./tools/artifact/validate.sh` on the produced artifact.

### Step 5: Verify Seed Files

1. Confirm all seed files are syntactically valid (no import errors, no type errors)
2. If a database is available, run `./tools/db/seed.sh --dry-run minimal` to verify the runner dispatches correctly
3. Check that factory files import faker/factory dependencies that exist in the project's package manifest (package.json, requirements.txt, go.mod)
4. If faker/factory dependencies are missing, list them and ask the user to install

## Integration Points

- **test-plan-generator**: Reference seed scenarios in test data requirements (e.g., "Run with `edge-cases` scenario")
- **perf-benchmark-checklist**: Use `high-volume` scenario before running benchmarks
- **api-tester-playbook**: Reference specific scenarios per test category (auth tests → `nominal`, boundary tests → `edge-cases`)
- **dogfood**: Use `nominal` scenario before dogfooding to ensure realistic app state

## Quality Checklist

- [ ] All domain entities discovered and cataloged
- [ ] All 6 scenarios defined with specific field values
- [ ] Entity relationships mapped (FKs, associations)
- [ ] Seed files generated in tech-stack-appropriate format
- [ ] Factory pattern used (not raw data dumps) for maintainability
- [ ] Edge case scenario covers boundary values for every field type
- [ ] High-volume scenario has configurable record count
- [ ] Seed data catalog artifact produced with valid frontmatter
- [ ] Seed files are runnable via `./tools/db/seed.sh`
- [ ] Required dependencies (faker, factory_boy, etc.) identified
