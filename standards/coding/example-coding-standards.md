> **EXAMPLE** — This is a reference standards document showing the expected format. Replace it with your own coding standards, or delete it with `bash setup.sh --cleanup`.

# Coding Standards

## File Organization

- One module/class per file
- Group by feature, not by type (e.g., `features/auth/` not `controllers/`, `models/`)
- Co-locate tests next to source files (`user.ts`, `user.test.ts`)
- Keep files under 300 lines — split if larger

## Naming

- Files: `kebab-case` (e.g., `user-service.ts`, `auth_handler.py`)
- Classes/Types: `PascalCase`
- Functions/Variables: `camelCase` (JS/TS) or `snake_case` (Python/Go/Rust)
- Constants: `UPPER_SNAKE_CASE`
- Boolean variables: prefix with `is`, `has`, `should` (e.g., `isActive`, `hasPermission`)

## Error Handling

- Use typed errors / custom error classes, not generic strings
- Never swallow errors silently — log or re-throw
- Validate at system boundaries (API input, external service responses)
- Trust internal code — don't defensively validate between your own modules

## Testing

- Test behavior, not implementation details
- One assertion per test when possible
- Name tests: `should [expected behavior] when [condition]`
- Required coverage: unit tests for business logic, integration tests for API endpoints
- Mocks: only for external services, never for your own code

## Code Review Expectations

- Every PR needs at least one approval
- PRs should be reviewable in under 30 minutes (split large changes)
- Commit messages: imperative mood, under 72 characters (`Add user auth`, not `Added user authentication feature`)

## Security

- No secrets in code — use environment variables
- Parameterize all database queries (no string concatenation)
- Sanitize user input at the boundary, not deep in business logic
- Log security events (login, permission changes, data access)
