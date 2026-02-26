> **EXAMPLE** — This is a reference standards document showing the expected format. Replace it with your own API conventions, or delete it with `bash setup.sh --cleanup`.

# API Conventions

## Naming

- Use `snake_case` for JSON field names
- Use `kebab-case` for URL paths
- Use plural nouns for collection endpoints (`/users`, not `/user`)
- Use verbs only for actions that don't map to CRUD (`/users/123/deactivate`)

## Error Responses

All error responses follow RFC 7807 (Problem Details):

```json
{
  "type": "validation_error",
  "title": "Validation Failed",
  "status": 422,
  "detail": "One or more fields failed validation",
  "errors": [
    {
      "field": "email",
      "code": "field_required",
      "message": "Email is required"
    }
  ]
}
```

- `code` is machine-readable — clients map to localized strings
- `message` is default-locale fallback text
- Never expose stack traces, internal IDs, or database details in errors

## Authentication

- Bearer tokens in `Authorization` header
- 401 for missing/expired tokens, 403 for insufficient permissions
- Include `WWW-Authenticate` header on 401 responses

## Pagination

- Cursor-based by default: `?cursor=abc123&limit=25`
- Response includes `next_cursor` (null when no more results)
- Default limit: 25, max limit: 100

## Rate Limiting

- Return `429 Too Many Requests` when limit exceeded
- Include headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`
- Use `Retry-After` header with seconds until reset

## Versioning

- URL path versioning: `/v1/users`
- Breaking changes require a new version
- Deprecation: minimum 6 months notice via `Sunset` header
