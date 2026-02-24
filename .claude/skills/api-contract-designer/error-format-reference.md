# RFC7807 Error Format Reference

## Standard Shape

```json
{
  "type": "https://api.example.com/errors/validation-error",
  "title": "Validation Error",
  "status": 422,
  "detail": "The 'name' field is required and must be between 1-255 characters.",
  "instance": "/api/v1/projects",
  "errors": [
    {
      "field": "name",
      "code": "required",
      "message": "Name is required"
    }
  ]
}
```

## Error Type Reference

| Status | Type Suffix | Title | When |
|--------|------------|-------|------|
| 400 | bad-request | Bad Request | Malformed request body or missing content-type |
| 401 | unauthorized | Unauthorized | Missing or invalid authentication |
| 403 | forbidden | Forbidden | Authenticated but insufficient permissions |
| 404 | not-found | Not Found | Resource does not exist |
| 409 | conflict | Conflict | Duplicate resource or state violation |
| 422 | validation-error | Validation Error | Well-formed but invalid data |
| 429 | rate-limited | Rate Limit Exceeded | Too many requests |
| 500 | internal-error | Internal Server Error | Unexpected server failure |

## i18n Support

- Use machine-readable `code` fields (e.g., `"required"`, `"too_long"`, `"invalid_format"`)
- `message` is the default locale human-readable text
- Clients map `code` → localized string on their side
- Never put user-facing text in `detail` that can't be localized
