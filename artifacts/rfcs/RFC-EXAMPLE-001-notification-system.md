---
id: RFC-EXAMPLE-001
type: rfc
title: "Notification System — Technical Design"
status: approved
created: 2026-02-22
author: engineering-agent
parent: PRD-EXAMPLE-001
children: []
depends_on: [PRD-EXAMPLE-001]
blocks: []
tags: [notifications, cross-cutting, example]
---

> **EXAMPLE ARTIFACT** — This is a reference artifact showing proper Company OS format. Delete it after reviewing, or use it as a template for your first RFC. Run `bash setup.sh --cleanup` to remove all example files.

# RFC: Notification System

## Summary

This RFC defines the technical architecture for a centralized notification system that accepts events from internal services and dispatches them across multiple channels (email, push, in-app) based on user preferences. It addresses all requirements in [PRD-EXAMPLE-001](../prds/PRD-EXAMPLE-001-notifications.md).

## Motivation

Every feature currently builds its own notification logic. This leads to duplicated integrations, inconsistent formatting, and no user-facing preference controls. A centralized service reduces per-feature effort, provides a single preference surface, and enables delivery observability across the product.

## Tech Stack Context

This RFC is deliberately tech-stack-agnostic. It describes patterns and contracts, not implementations. When implementing, consult `company.config.yaml` to select the appropriate language, framework, queue, and database.

## Design

### System Boundaries

```
[Any Internal Service]
        |
        v
  POST /notifications/send
        |
        v
+-------------------+
| Notification API  |  ---- reads ----> [Preferences Store]
+-------------------+
        |
        v
   [Message Queue]
        |
   +----+----+----+
   |         |         |
   v         v         v
[Email]  [Push]   [In-App]
Dispatcher  Dispatcher  Writer
   |         |         |
   v         v         v
[SMTP/    [FCM/     [Notification
 Provider]  APNS]     Table]
```

- **Notification API** — accepts send requests, resolves preferences, enqueues dispatch jobs.
- **Channel Dispatchers** — workers that consume queue messages and deliver via the appropriate channel.
- **In-App Writer** — writes directly to the notifications table for in-app feed queries.

### Data Model

**notifications**

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| recipient_id | UUID | FK to users |
| event_type | VARCHAR | e.g., "comment.created", "payment.failed" |
| title | VARCHAR | Rendered notification title |
| body | TEXT | Rendered notification body |
| resource_type | VARCHAR | e.g., "project", "invoice" |
| resource_id | UUID | Link to the related entity |
| is_read | BOOLEAN | Default false |
| created_at | TIMESTAMP | Indexed, used for feed ordering |

**notification_preferences**

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| user_id | UUID | FK to users |
| event_type | VARCHAR | The event category |
| channel | VARCHAR | "email", "push", "in_app" |
| enabled | BOOLEAN | Default true |
| updated_at | TIMESTAMP | |

Unique constraint on (user_id, event_type, channel).

**delivery_log**

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| notification_id | UUID | FK to notifications |
| channel | VARCHAR | "email", "push", "in_app" |
| status | VARCHAR | "pending", "delivered", "failed", "retrying" |
| attempts | INTEGER | Retry count |
| last_error | TEXT | Nullable; last failure reason |
| delivered_at | TIMESTAMP | Nullable |
| created_at | TIMESTAMP | |

### API Surface

**Send a notification** (internal service use)

```
POST /api/v1/notifications/send
Body: { event_type, recipient_id, payload: { actor, resource_type, resource_id, ... } }
Response: 202 Accepted { notification_id }
```

**List notifications** (user-facing)

```
GET /api/v1/notifications?cursor=&limit=20
Response: 200 { data: [{ id, title, body, resource_type, resource_id, is_read, created_at }], pagination: { cursor, has_more } }
```

**Mark as read**

```
PATCH /api/v1/notifications/{id}/read
Response: 200 { id, is_read: true }

POST /api/v1/notifications/read-all
Response: 200 { updated_count }
```

**Get / Update preferences**

```
GET /api/v1/notification-preferences
Response: 200 { data: [{ event_type, channel, enabled }] }

PUT /api/v1/notification-preferences
Body: { preferences: [{ event_type, channel, enabled }] }
Response: 200 { data: [{ event_type, channel, enabled }] }
```

### Delivery Strategy

1. The Notification API validates the request, renders templates, resolves user preferences, and enqueues one job per enabled channel.
2. Each channel dispatcher consumes its queue independently with configurable concurrency.
3. **Retry logic**: exponential backoff (1s, 4s, 16s), max 3 attempts. After final failure, the delivery_log entry is marked "failed" and an alert is emitted.
4. **Channel priority**: in-app is written synchronously before returning 202. Email and push are fully async.
5. **Idempotency**: each send request generates a unique notification_id used as the idempotency key for queue deduplication.

### Observability

| Signal | What to Capture |
|--------|-----------------|
| **Logs** | Structured JSON: notification_id, event_type, channel, recipient_id (hashed), status, latency_ms |
| **Metrics** | `notifications.sent` (counter by event_type), `notifications.delivered` (counter by channel), `notifications.failed` (counter by channel), `notification.delivery_latency_ms` (histogram by channel) |
| **Alerts** | Delivery failure rate > 1% over 5 minutes; queue depth > 10,000; delivery latency p95 > configured SLO |
| **Dashboard** | Sent/delivered/failed by channel over 7 days; latency percentiles; preference adoption rate |

### Security Considerations

- **Authorization**: the send endpoint is internal-only (service-to-service auth). User-facing endpoints require authenticated session.
- **Rate limiting**: the send endpoint enforces per-service rate limits to prevent notification floods. User-facing list endpoints use standard API rate limits.
- **PII handling**: notification payloads may contain user names or email addresses. Logs must hash or omit recipient_id and never log payload body at INFO level. DEBUG-level payload logging is gated behind a feature flag.
- **Unsubscribe**: every email includes a one-click unsubscribe link that maps to the preferences API. Unsubscribe tokens are signed and time-limited.
- **Content injection**: template variables are escaped before rendering to prevent XSS in in-app notifications and HTML injection in emails.

### Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|------------|------|------|-------------|
| Third-party notification service (e.g., Novu, Knock) | Faster to ship, built-in UI | Vendor lock-in, per-message cost at scale, less control over templates | Cost concerns at scale; preference for owning the delivery pipeline |
| Event-driven fan-out (no central API) | Decoupled, each service subscribes | No central preference management, duplicated template logic | Violates the goal of centralized user preferences |

## Migration Plan

1. **Phase 1**: Deploy notification tables and API behind a feature flag. Internal services continue using existing ad-hoc methods.
2. **Phase 2**: Migrate one high-traffic event type (e.g., "comment.created") to the new system. Validate delivery metrics.
3. **Phase 3**: Migrate remaining event types. Deprecate old notification code paths.
4. **Rollback**: Feature flag disables the new system; old code paths remain active until Phase 3 is validated.

## Dependencies

- Depends on: existing user authentication system, email provider integration, push notification provider integration.
- Blocks: no downstream artifacts yet (implementation tasks will be generated from this RFC).

## Open Questions

1. Should the queue use a dedicated topic per channel or a single topic with routing? (Recommendation: dedicated topic per channel for independent scaling.)
2. What template engine to use? (Depends on tech stack; defer to implementation phase.)
3. Should delivery_log be stored in the primary database or a separate analytics store? (Start in primary; migrate to analytics store if volume warrants it.)
