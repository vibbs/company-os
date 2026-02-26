---
name: feature-flags
description: Designs feature flag strategy, progressive discovery patterns, and per-feature flag specifications for safe rollouts and organic product learning.
allowed-tools: Read, Grep, Glob, Bash, Write
user-invokable: false
---

# Feature Flags

## Reference
- **ID**: S-ENG-10
- **Category**: Engineering
- **Inputs**: company.config.yaml (feature_flags section), RFC/architecture document, activation-onboarding output (aha moment mapping)
- **Outputs**: company-level flag strategy (standards/engineering/feature-flag-conventions.md), per-feature flag specifications
- **Used by**: Engineering Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose

Design a comprehensive feature flag strategy that goes beyond simple on/off toggles. This skill produces flag naming conventions, lifecycle management rules, cleanup SLAs, and -- when configured -- progressive discovery patterns that reveal product capabilities based on user maturity. The result is safe rollouts, clean experimentation, and an onboarding experience where users never feel overwhelmed because features appear when they are relevant.

## When to Use

- Setting up feature flag conventions for a new product
- Building a new feature that needs gated rollout
- Designing progressive disclosure of product capabilities
- Auditing existing flags for cleanup or debt
- Planning A/B experiments that require flag infrastructure

## Feature Flag Procedure

### Step 1: Load Context

Before designing any flag strategy:

1. **Read `company.config.yaml`** -- extract:
   - `feature_flags.provider` (e.g., LaunchDarkly, Flagsmith, Unleash, custom, config-file)
   - `feature_flags.strategy` (e.g., `release-only`, `progressive-discovery`, `full`)
   - `feature_flags.cleanup_sla_days` (e.g., 14, 30, 60)
2. **Read existing activation-onboarding output** in `artifacts/growth/` -- extract aha moment mapping and onboarding milestones (these feed into progressive discovery levels)
3. **Read existing RFCs** in `artifacts/rfcs/` -- understand what features are being built and need flag specs
4. **Check `standards/engineering/`** -- see if flag conventions already exist (update rather than overwrite)

### Step 2: Generate Company-Level Flag Strategy

Produce `standards/engineering/feature-flag-conventions.md` with the following structure:

#### Flag Naming Convention

Format: `ff.<domain>.<feature>`

**Rules**:
- Prefix is always `ff.` to distinguish flags from other configuration
- `<domain>` is the product area (e.g., `billing`, `onboarding`, `editor`, `auth`)
- `<feature>` is the specific capability (e.g., `annual_plans`, `ai_assist`, `sso`)
- Lowercase throughout, underscores within segments

**Examples**:
```
ff.billing.annual_plans
ff.editor.ai_assist
ff.auth.sso_login
ff.onboarding.interactive_tour
ff.dashboard.advanced_analytics
```

#### Flag Lifecycle

Every flag progresses through a defined lifecycle:

```
created → testing → rolling_out → fully_enabled → cleanup
```

| State | Description | Who Owns |
|-------|-------------|----------|
| `created` | Flag defined in code and provider, default OFF | Engineer |
| `testing` | Enabled for internal team and staging | Engineer |
| `rolling_out` | Gradual percentage rollout to production users | Engineer + Product |
| `fully_enabled` | 100% of users, monitoring for issues | Product |
| `cleanup` | Flag code removed, feature is permanent | Engineer |

#### Flag Types

The available flag types depend on the `feature_flags.strategy` config value:

| Strategy Config | Available Flag Types |
|-----------------|---------------------|
| `release-only` | Release, Ops |
| `progressive-discovery` | Discovery, Ops |
| `full` | Release, Experiment, Ops, Discovery |

**Release flag**: Temporary. Gates a deployment. Default OFF, rolled out by percentage, removed within `cleanup_sla_days` of reaching 100%. Use for any new feature deployment.

**Experiment flag**: Temporary. A/B test variant selector. Default OFF, assigns users to control/treatment groups. Removed after experiment concludes and decision is made. Requires metrics definition before creation.

**Ops flag**: Semi-permanent. Kill switch or circuit breaker. Default ON (feature active), flipped OFF to disable a misbehaving feature instantly. Reviewed quarterly -- either promote to permanent config or remove.

**Discovery flag**: Progressive. Reveals features based on user maturity level. Default determined by discovery level (Level 0 = ON for all, Level 1+ = OFF until unlocked). Transitions happen automatically based on trigger conditions. See Step 3 for the progressive discovery pattern.

#### Cleanup SLA

- Release flags: must be removed within `cleanup_sla_days` (from config) of reaching `fully_enabled`
- Experiment flags: must be removed within `cleanup_sla_days` of experiment conclusion
- Ops flags: reviewed quarterly; either promoted to permanent configuration or removed
- Discovery flags: remain active as long as progressive discovery is the product strategy

#### Flag Debt Tracking

Flags older than the cleanup SLA without a cleanup commit are flagged during code review (see `code-review` skill). Track flag debt with:

- A comment in the flag definition file noting the creation date and expected cleanup date
- A periodic audit (monthly) that lists all flags past their SLA
- CI warning (optional) that flags code referencing stale flags

#### Provider-Specific Patterns

**LaunchDarkly**: Use targeting rules for percentage rollouts. Use segments for discovery levels. Use custom attributes for tenant/user maturity data.

**Flagsmith**: Use environment-level flags for release. Use segments with trait-based rules for discovery. Use remote config for ops kill switches.

**Unleash**: Use gradual rollout strategy for release flags. Use custom strategies for discovery level evaluation. Use variants for experiment flags.

**Custom (in-house)**: Implement a flag evaluation service that reads from database/config. Support percentage-based, user-attribute-based, and segment-based evaluation. Cache aggressively with short TTL.

**Config-file**: Use environment-specific config files (e.g., `flags.production.yaml`). Suitable for release and ops flags only. Not recommended for experiment or discovery flags (requires deploy to change).

### Step 3: Progressive Discovery Pattern

**Only applies when `feature_flags.strategy` is `progressive-discovery` or `full`.**

Progressive discovery prevents user overwhelm by revealing product capabilities as users demonstrate readiness. Features are classified into levels, and users unlock levels through natural product usage.

#### Discovery Levels

| Level | Name | Visibility | Trigger to Unlock |
|-------|------|------------|-------------------|
| **Level 0** | Core | Always visible to all users | None -- these are essential product value |
| **Level 1** | Foundations | Unlocked after user completes core flow | Action-based: user completes the "aha moment" action (e.g., first project created, first report generated) |
| **Level 2** | Power | Unlocked after proficiency demonstrated | Compound trigger: e.g., 5+ projects created AND 7+ days active AND core feature used 10+ times |
| **Level 3** | Expert | Unlocked on request or after sustained engagement | Time + action: e.g., 30+ days active AND advanced action performed, OR user explicitly requests via settings |

#### Trigger Condition Types

Each level transition is governed by one or more trigger conditions:

- **Action-based**: User performs a specific action N times (e.g., `projects.created >= 1`)
- **Time-based**: User has been active for N days (e.g., `days_since_signup >= 7`)
- **Milestone-based**: User reaches a product milestone (e.g., `onboarding.completed == true`)
- **Compound**: Multiple conditions combined with AND/OR logic
- **Manual override**: User requests access via settings, or admin grants access

#### Coordination with Activation-Onboarding

Progressive discovery levels map directly to the activation-onboarding skill's aha moment flow:

- **Level 0 to Level 1 transition** = the user has reached the aha moment (first value realization)
- **Level 1 to Level 2 transition** = the user has moved from activated to retained (habitual usage)
- **Level 2 to Level 3 transition** = the user is a power user or champion

When the activation-onboarding skill defines the aha moment action, that same action becomes the Level 1 unlock trigger for progressive discovery.

#### User Experience Rules

- Features appearing at a new level should have a subtle introduction (tooltip, badge, "New" label)
- Users should never lose access to a feature they have unlocked (levels only go up, never down)
- A "Show all features" toggle in settings allows power users to bypass progressive discovery
- Discovery level is per-user, not per-tenant (different team members may be at different levels)

### Step 4: Per-Feature Flag Specification

For each feature being built (read from the RFC):

1. **Define the flag specification**:

   | Field | Value |
   |-------|-------|
   | **Flag name** | `ff.<domain>.<feature>` |
   | **Flag type** | Release / Experiment / Ops / Discovery |
   | **Default state** | ON or OFF (with rationale) |
   | **Rollout plan** | Percentage stages and timeline (e.g., 5% day 1, 25% day 3, 50% day 5, 100% day 7) |
   | **Cleanup date** | Calculated from rollout completion + `cleanup_sla_days` |
   | **Discovery level** | Level 0 / 1 / 2 / 3 (only if strategy includes discovery) |

2. **Define metrics per flag state**:
   - What to measure when the flag is ON vs OFF
   - Success criteria for rolling out further (e.g., error rate < 0.1%, latency p99 < 200ms)
   - Failure criteria that trigger automatic rollback
   - Coordinate with the `instrumentation` skill for event taxonomy -- flag toggle events should follow the `object.action` convention (e.g., `feature_flag.evaluated`, `feature_flag.toggled`)

3. **Define the kill switch** (for Ops and Release flags):
   - What conditions trigger automatic disable (e.g., error rate spike, latency degradation, user complaints threshold)
   - Who is notified when the kill switch activates
   - What the fallback behavior is when the flag is OFF
   - How to re-enable after a kill switch event (requires explicit action, not automatic)

### Step 5: Verify

Final verification checklist:

- [ ] All new features in the RFC have a corresponding flag specification
- [ ] Progressive discovery levels are defined with concrete trigger conditions (if strategy includes discovery)
- [ ] Cleanup dates are calculated and set within `cleanup_sla_days`
- [ ] Kill switches are defined for all release and ops flags
- [ ] Flag naming follows the `ff.<domain>.<feature>` convention
- [ ] Metrics are defined for both flag-ON and flag-OFF states
- [ ] Provider-specific implementation notes are included
- [ ] Flag specifications are saved and artifact is validated with `./tools/artifact/validate.sh`

## Cross-References

- **activation-onboarding** skill: Aha moment mapping feeds directly into progressive discovery Level 1 unlock triggers. When activation-onboarding defines the first-value action, use it as the Level 0 to Level 1 transition condition.
- **instrumentation** skill: Event taxonomy for flag-related events (`feature_flag.evaluated`, `feature_flag.toggled`). Per-flag metrics should follow the instrumentation conventions and integrate into the analytics dashboard.
- **code-review** skill: Flag debt detection during reviews. Flags past their cleanup SLA should be raised as code quality issues during the Code Quality section of reviews.

## Quality Checklist

- [ ] Flag naming follows `ff.<domain>.<feature>` convention
- [ ] Flag type is classified (release, experiment, ops, discovery)
- [ ] Default state is explicit (enabled or disabled)
- [ ] Rollout plan has percentages and timeline
- [ ] Cleanup date is set within `cleanup_sla_days`
- [ ] Progressive discovery level is assigned (if strategy includes discovery)
- [ ] Kill switch conditions defined for ops and release flags
