---
name: user-docs
description: Produces user-facing documentation, guided tour specifications, and changelog entries for every shipped feature. Ensures users can discover, learn, and adopt new functionality.
allowed-tools: Read, Grep, Glob, Bash, Write
user-invokable: false
---

# User Documentation

## Reference
- **ID**: S-ENG-11
- **Category**: Engineering
- **Inputs**: company.config.yaml (tech_stack.framework, platforms.targets), approved PRDs, existing standards/analytics/tracker-conventions.md, OpenAPI specs
- **Outputs**: documentation strategy (standards/docs/), feature documentation, guided tour specs, changelog entries
- **Used by**: Engineering Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose

Produce user-facing documentation, guided tour specifications, and changelog entries for every shipped feature. This skill ensures that users can discover, learn, and adopt new functionality through clear written docs, in-app guided tours, and readable changelogs.

## When to Use

- A new feature is shipping and needs user-facing documentation
- Setting up the documentation strategy for a new product
- Designing in-app guided tours for onboarding or feature introduction
- Writing changelog entries for a release
- Updating API documentation after OpenAPI spec changes

## User Documentation Procedure

### Step 1: Load Context

Before producing any documentation:

1. **Read `company.config.yaml`** -- extract `tech_stack.framework` and `platforms.targets` to determine the UI framework and platform constraints
2. **Read existing PRDs** in `artifacts/prds/` -- understand what the feature does, who it is for, and what the acceptance criteria are
3. **Read `standards/analytics/tracker-conventions.md`** -- understand the `data-tour-step` attribute conventions used for guided tour targeting (produced by the `instrumentation` skill)
4. **Check `standards/docs/`** -- see if a documentation strategy already exists (update rather than overwrite)

### Step 2: Generate Documentation Strategy

Produce `standards/docs/documentation-strategy.md` with the following structure:

#### Doc Types

| Type | Purpose | When to Create |
|------|---------|----------------|
| **Getting Started** | First-time user orientation | Once per product, update per major release |
| **How-To Guides** | Task-oriented walkthroughs | One per user workflow |
| **Reference** | Technical details, API docs, config options | One per API surface or config area |
| **Troubleshooting** | Common problems and solutions | Ongoing, grows with support tickets |
| **Changelog** | What changed, when, why | One entry per release |

#### Changelog Management

- Each entry includes: version, date, summary of changes (user-facing language)
- Sourced from artifact history and commit messages, translated into user-facing language
- Categorized as: Added, Changed, Fixed, Removed
- Written for users, not developers -- explain the benefit, not the implementation

#### API Documentation

- Generated from OpenAPI specs (extends the `api-contract-designer` skill output)
- Includes endpoint descriptions, request/response examples, error codes, authentication
- Auto-updated when the OpenAPI spec changes

#### Help Center Structure

```
Category
  Article
    Section
```

- Categories map to product areas (e.g., Account, Billing, Projects, Integrations)
- Articles cover one topic (e.g., "How to invite a team member")
- Sections within an article break down sub-steps or variations

#### Writing Style

- **Concise**: short sentences, no filler words
- **Action-oriented**: start steps with verbs ("Click", "Enter", "Select")
- **No jargon**: avoid internal terminology; use words the user understands
- **Include code examples**: for API docs and technical reference, always show a working example
- **Visual aids**: reference screenshots or diagrams where the step is not obvious from text alone

### Step 3: Guided Tour Specifications

Define in-app guided tour patterns for the configured framework.

#### Tour Types

| Type | Trigger | Purpose |
|------|---------|---------|
| **Onboarding tour** | First visit after sign-up | Guide user to "aha moment" |
| **Feature introduction** | Feature first enabled (via progressive discovery flags from `feature-flags` skill) | Explain new functionality |
| **Upgrade prompt** | User encounters a gated feature | Show value of upgrading |

#### Tour Step Format

Each step in a tour specification must include:

| Field | Description | Example |
|-------|-------------|---------|
| `target` | `data-tour-step` attribute value (from `instrumentation` skill tracker conventions) | `data-tour-step="onboarding-create_project"` |
| `content` | Short copy explaining the element or action | "Create your first project to get started." |
| `position` | Tooltip placement relative to target | `bottom`, `top`, `left`, `right` |
| `action` | What the user should do at this step | `click`, `observe`, `input` |

#### Tour Trigger Conditions

| Condition | Description |
|-----------|-------------|
| `first_visit` | User has never visited this page before |
| `feature_first_enabled` | Feature was just unlocked at a progressive discovery level (coordinates with `feature-flags` skill) |
| `user_role` | Tour varies by role (admin sees different steps than member) |

#### Library Patterns (Tech-Stack Aware)

Select the guided tour library based on `tech_stack.framework` from config:

| Framework | Recommended Library | Notes |
|-----------|-------------------|-------|
| React / Next.js | React Joyride | Native React component, declarative step definitions |
| Vue / Nuxt | Vue Tour / Shepherd.js | Shepherd.js works across frameworks |
| Vanilla JS / Other | Intro.js or Shepherd.js | Framework-agnostic, lightweight |

#### Tour Progression and Feature Flags

Tours coordinate with the `feature-flags` skill for progressive discovery:

- **Level 1** (core features): onboarding tour fires on first visit
- **Level 2** (intermediate features): feature introduction tour fires when the feature unlocks
- **Level 3** (advanced features): contextual tooltip appears when the feature becomes available
- Tours should not fire for features the user cannot yet access

### Step 4: Per-Feature Documentation

For each feature being shipped, read the PRD and produce:

#### 4a. User-Facing Feature Documentation

- **What it does**: one-sentence summary
- **Why it matters**: the user benefit, not the technical reason
- **How to use it**: step-by-step instructions with numbered steps
- **Edge cases**: what happens if the user does X, Y, or Z
- **Related features**: links to other relevant docs

#### 4b. In-App Tour Specification

For each feature, produce a tour spec:

```yaml
tour:
  name: feature-name-intro
  trigger: feature_first_enabled
  steps:
    - target: "data-tour-step='feature-name-step1'"
      content: "Here is where you start."
      position: bottom
      action: observe
    - target: "data-tour-step='feature-name-step2'"
      content: "Click here to do the thing."
      position: right
      action: click
```

- All targets must use `data-tour-step` attributes (never fragile CSS selectors)
- Copy must be concise (under 120 characters per step)
- Tour should have 3-7 steps (fewer is better)

#### 4c. Changelog Entry Draft

Produce a user-facing changelog entry:

```markdown
### [Feature Name]
**Added** - [Date]

[One-sentence description of what users can now do.]

[Optional: one sentence on how to access or enable the feature.]
```

- Write for users, not developers ("You can now export reports as PDF" not "Added PDF export endpoint")
- Categorize as Added, Changed, Fixed, or Removed

#### 4d. API Documentation Updates

If the feature includes API changes:

1. Read the updated OpenAPI spec (produced by the `api-contract-designer` skill)
2. Generate or update endpoint documentation with descriptions, examples, and error codes
3. Include request/response examples with realistic sample data
4. Document breaking changes prominently if applicable

### Step 5: Verify

Final verification checklist:

- [ ] Every user-facing feature has documentation (what, why, how)
- [ ] Tours target `data-tour-step` attributes (not fragile CSS selectors like `.btn-primary` or `#submit`)
- [ ] Tour trigger conditions align with progressive discovery levels from `feature-flags` skill
- [ ] Changelog is up to date with user-facing language
- [ ] API docs match the current OpenAPI spec
- [ ] Documentation follows the strategy's writing style (concise, action-oriented, no jargon)
- [ ] All documentation passes spell check and readability standards

## Cross-References

- **`instrumentation` skill**: Defines `data-tour-step` tracker attribute conventions used for guided tour targeting
- **`feature-flags` skill**: Defines progressive discovery levels that coordinate with tour trigger conditions (tours fire when features unlock)
- **`api-contract-designer` skill**: Produces OpenAPI specs that serve as the source for API documentation
- **`activation-onboarding` skill**: Defines the "aha moment" and onboarding flow that guided tours should align with

## Quality Checklist

- [ ] Getting Started guide exists and is current
- [ ] Feature documentation covers what, why, and how
- [ ] Guided tour targets `data-tour-step` attributes (not fragile CSS selectors)
- [ ] Tour trigger conditions align with progressive discovery levels
- [ ] Changelog entry is user-facing (not developer-facing)
- [ ] API docs match current OpenAPI spec
- [ ] All documentation passes spell check and readability standards
