---
name: instrumentation
description: Defines analytics instrumentation standards including event taxonomy, tracker ID conventions, and per-feature instrumentation plans for measurable product development.
allowed-tools: Read, Grep, Glob, Bash, Write
user-invokable: false
---

# Instrumentation

## Reference
- **ID**: S-ENG-08
- **Category**: Engineering
- **Inputs**: company.config.yaml (analytics section), PRDs (success metrics), existing codebase
- **Outputs**: event taxonomy (standards/analytics/), tracker conventions (standards/analytics/), per-feature instrumentation plan
- **Used by**: Engineering Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose

Define analytics instrumentation standards so every feature ships with measurable events, consistent tracker IDs, and clear mappings from PRD success metrics to trackable data points. This skill produces the event taxonomy, tracker attribute conventions, and per-feature instrumentation plans that engineering uses during implementation.

## When to Use

- Setting up analytics for a new product or codebase
- Building a new feature that has success metrics in its PRD
- Auditing existing instrumentation for gaps or inconsistencies
- Onboarding a new analytics provider

## Instrumentation Procedure

### Step 1: Load Context

Before defining any events or conventions:

1. **Read `company.config.yaml`** -- extract:
   - `analytics.provider` (e.g., Mixpanel, Amplitude, PostHog, Segment)
   - `analytics.event_prefix` (e.g., `app_`, `myproduct_`)
   - `analytics.tracker_attribute` (e.g., `data-track-id`)
   - `observability.error_tracking` (e.g., Sentry, Bugsnag)
2. **Read existing PRDs** in `artifacts/prds/` -- collect all success metrics across features
3. **Check `standards/analytics/`** -- see if event taxonomy or tracker conventions already exist (update rather than overwrite)

### Step 2: Generate Event Taxonomy

Produce `standards/analytics/event-taxonomy.md` with the following structure:

#### AARRR Pirate Metrics Framework Mapping

Every product event maps to one of five lifecycle stages:

| Stage | Purpose | Example Events |
|-------|---------|----------------|
| **Acquisition** | How users find the product | `user.visited`, `user.signed_up`, `referral.clicked` |
| **Activation** | First value moment | `feature.first_used`, `onboarding.completed`, `project.first_created` |
| **Retention** | Users coming back | `session.started`, `feature.used_again`, `streak.maintained` |
| **Revenue** | Monetization events | `subscription.started`, `plan.upgraded`, `payment.completed` |
| **Referral** | Users inviting others | `invite.sent`, `referral.converted`, `share.clicked` |

#### Event Naming Convention

Format: `<object>.<action>`

**Objects** (the entity being acted upon):
- `user`, `session`, `feature`, `subscription`, `project`, `invite`, `page`, `error`

**Actions** (past tense verbs describing what happened):
- `created`, `completed`, `viewed`, `clicked`, `upgraded`, `failed`, `started`, `sent`, `converted`, `deleted`, `updated`, `exported`, `imported`

**Examples**:
- `user.signed_up`
- `page.viewed`
- `feature.activated`
- `subscription.upgraded`
- `project.created`
- `error.occurred`

#### Required Properties for Every Event

Every event MUST include these properties:

| Property | Type | Description |
|----------|------|-------------|
| `timestamp` | string (ISO 8601) | When the event occurred |
| `user_id` | string | Authenticated user identifier (omit if anonymous) |
| `session_id` | string | Current session identifier |
| `platform` | enum | `web` / `ios` / `android` |
| `app_version` | string | Current application version |

The `event_prefix` from config is prepended to the event name when sent to the analytics provider (e.g., if prefix is `app_` and event is `user.signed_up`, the provider receives `app_user.signed_up`).

#### Event Categories

| Category | When to Use | Examples |
|----------|-------------|----------|
| `page_view` | User navigates to a page/screen | `page.viewed` |
| `user_action` | User performs an intentional action | `button.clicked`, `form.submitted` |
| `system_event` | System-initiated events | `email.sent`, `job.completed` |
| `business_event` | Revenue and conversion events | `subscription.started`, `payment.completed` |

#### Anti-Patterns

- **No PII in event properties**: Never include email, name, phone, IP address, or any personally identifiable information as event property values
- **No high-cardinality values**: Never use full URLs, raw UUIDs, free-text input, or timestamps as property values (use categories, slugs, or enums instead)
- **No deep nesting**: Event properties must not nest objects deeper than 2 levels
- **No ambiguous names**: `clicked` alone is meaningless -- always pair with the object (`button.clicked`, `link.clicked`)
- **No future tense**: Events record what happened, not what will happen (`user.signed_up`, not `user.signing_up`)

### Step 3: Generate Tracker ID Conventions

Produce `standards/analytics/tracker-conventions.md` with the following structure:

#### Analytics Tracking Attribute

**Attribute**: Uses the value from `analytics.tracker_attribute` in config (default: `data-track-id`)

**Format**: `data-track-id="<page>-<element>-<action>"`

**Rules**:
- Lowercase throughout
- Hyphens (`-`) between segments (page, element, action)
- Underscores (`_`) within segments for multi-word names
- Every interactive element (button, link, form input, toggle, dropdown, checkbox) MUST have a tracker ID

**Examples**:
```
data-track-id="login-submit_btn-click"
data-track-id="dashboard-export_btn-click"
data-track-id="settings-theme_toggle-change"
data-track-id="profile-avatar_input-upload"
data-track-id="nav-pricing_link-click"
data-track-id="onboarding-skip_btn-click"
```

#### Error Tracking Attribute

**Attribute**: `data-sentry-component="<ComponentName>"`

**Rules**:
- PascalCase component name (matches React/Vue component naming)
- Applied to every route-level or page-level component
- Enables error tracking tools (Sentry, Bugsnag) to group errors by component

**Examples**:
```
data-sentry-component="LoginPage"
data-sentry-component="DashboardView"
data-sentry-component="SettingsPanel"
data-sentry-component="CheckoutFlow"
```

#### Guided Tour Targeting Attribute

**Attribute**: `data-tour-step="<tour>-<step>"`

**Rules**:
- Lowercase with hyphens
- `<tour>` is the tour name, `<step>` is the step identifier
- Applied to elements that guided tours need to highlight or anchor to

**Examples**:
```
data-tour-step="onboarding-welcome"
data-tour-step="onboarding-create_project"
data-tour-step="feature-intro-step3"
data-tour-step="billing-upgrade_prompt"
```

#### Framework Implementation Patterns

**React / Next.js**:
```jsx
<button
  data-track-id="dashboard-export_btn-click"
  data-sentry-component="DashboardView"
  onClick={handleExport}
>
  Export
</button>
```

**Vue**:
```vue
<button
  :data-track-id="`dashboard-export_btn-click`"
  data-sentry-component="DashboardView"
  @click="handleExport"
>
  Export
</button>
```

**Plain HTML**:
```html
<button
  data-track-id="dashboard-export_btn-click"
  data-sentry-component="DashboardView"
  onclick="handleExport()"
>
  Export
</button>
```

**Note**: The `analytics.tracker_attribute` value in `company.config.yaml` determines the primary attribute name. If the config specifies `data-analytics` instead of `data-track-id`, all examples above should use `data-analytics` as the attribute name.

### Step 4: Per-Feature Instrumentation

For each feature being built:

1. **Read PRD success metrics** -- extract every measurable goal
2. **Map each metric to specific events** that prove or disprove it:
   - Identify the event(s) needed to calculate the metric
   - Define event names following the taxonomy
   - Define event properties specific to the feature
3. **List all new UI components that need tracker IDs**:
   - Buttons, links, form fields, toggles, tabs, modals
   - Apply the naming convention from Step 3
4. **Define dashboard requirements**:
   - What graphs to create (line chart for trends, bar chart for comparisons, funnel for conversion)
   - What metrics to display (counts, rates, durations, percentages)
   - What alerts to configure (thresholds, anomaly detection)

**Example mapping**:

Success metric from PRD: *"80% of users complete onboarding within 5 minutes"*

| Event | Properties | Purpose |
|-------|-----------|---------|
| `onboarding.started` | `timestamp` | Marks the start of onboarding |
| `onboarding.step_completed` | `step_number`, `step_name`, `timestamp` | Tracks progress through steps |
| `onboarding.completed` | `duration_seconds`, `steps_completed` | Marks successful completion |
| `onboarding.abandoned` | `last_step`, `duration_seconds` | Marks drop-off |

Dashboard: Funnel chart showing started -> step 1 -> step 2 -> ... -> completed. Alert if completion rate drops below 70%.

### Step 5: Audit Existing Instrumentation

Grep the codebase for existing tracker attributes and event calls:

1. **Find existing tracker attributes**: Search for `data-track-id`, `data-sentry-component`, `data-tour-step` (and the configured `analytics.tracker_attribute` if different)
2. **Find existing event calls**: Search for the analytics provider's track/send function (e.g., `analytics.track(`, `mixpanel.track(`, `posthog.capture(`)
3. **Identify gaps**:
   - Interactive components missing tracker IDs
   - Events defined in the taxonomy but not instrumented in code
   - Events in code that do not follow the naming convention
   - Inconsistent property names across similar events
4. **Produce an audit summary** listing each gap with its file location and recommended fix

### Step 6: Verify

Final verification checklist:

- [ ] Every AARRR stage has at least 2-3 events defined
- [ ] Event naming strictly follows `object.action` convention
- [ ] Required properties (timestamp, user_id, session_id, platform, app_version) are documented for every event
- [ ] Tracker ID convention is specific with format, rules, and examples
- [ ] Anti-patterns are listed (no PII, no high-cardinality, no deep nesting)
- [ ] Every PRD success metric maps to one or more trackable events
- [ ] Dashboard requirements are specific (chart type, metric, alert threshold) -- not vague ("track usage")
- [ ] Existing instrumentation has been audited for gaps

## Quality Checklist

- [ ] AARRR framework events defined for each stage
- [ ] Event naming follows `object.action` convention
- [ ] Required properties documented for every event
- [ ] Tracker ID convention is specific with examples
- [ ] Anti-patterns are listed (no PII, no high-cardinality)
- [ ] Per-feature events map to PRD success metrics
- [ ] Dashboard requirements are specific (not "track usage")
