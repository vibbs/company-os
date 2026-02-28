---
name: design-system
description: Reads configured design archetype and UX baseline to produce project-specific design tokens, component guidance, and UX patterns. Use when building UI components, reviewing design consistency, or configuring design preferences for the first time.
user-invokable: true
argument-hint: "[generate-tokens | review | reconfigure]"
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Design System

## Reference
- **ID**: S-ENG-12
- **Category**: Engineering
- **Inputs**: company.config.yaml (design section), standards/brand/archetypes/, standards/brand/ux-baseline.md
- **Outputs**: standards/brand/design-tokens.md (project-specific), design guidance for frontend agent
- **Used by**: Frontend Engineer (sub-agent), User (directly via /design-system)
- **Tool scripts**: none

## Purpose

Provide consistent visual and UX guidance for all frontend implementation. This skill bridges the gap between "I picked an archetype" and "here are the exact tokens and patterns to use when building this component."

The skill serves three roles:
1. **Setup**: When no archetype is configured, run the full archetype selection wizard
2. **Generation**: Produce project-specific design tokens from archetype + user preferences
3. **Review**: Audit existing UI code for design consistency violations

## When to Use

- **First time**: User runs `/design-system` with no archetype configured → runs selection wizard
- **Token generation**: User runs `/design-system generate-tokens` → produces standards/brand/design-tokens.md
- **During development**: Frontend agent loads this skill's context before building any UI component
- **Review**: User runs `/design-system review` → audits codebase for design violations
- **Reconfigure**: User runs `/design-system reconfigure` → re-runs the archetype selection wizard

## Procedure

### Step 0: Detect Mode

Read `company.config.yaml` → `design.archetype` field.

- If **empty or missing** → run Step 1 (Archetype Selection Wizard)
- If **set** and argument is `generate-tokens` → run Step 3
- If **set** and argument is `review` → run Step 4
- If **set** and argument is `reconfigure` → run Step 1
- If **set** and no argument → run Step 2 (Provide Guidance)

### Step 1: Archetype Selection Wizard

This is the setup flow for users configuring their design system for the first time, or reconfiguring. It's the same flow used by `/setup` Step 5.7.

#### Question 1: Product Type

Ask: "What best describes what you're building?"

| Option | Description |
|--------|-------------|
| a) Internal tool / admin panel / data dashboard | Back-office tools, monitoring, operations |
| b) CRM / ERP / business management system | Record-heavy, relational data, multi-role |
| c) Knowledge base / wiki / content platform | Documents, articles, structured content |
| d) Collaborative workspace / real-time editor | Multi-user, canvas or document-based |
| e) Personal productivity / consumer app | Daily-use, simple flows, personal data |
| f) Marketing site / creative tool / portfolio | Visual impact, editorial quality, showcase |

#### Question 2: User Priority

Ask: "What matters most to your users?"

| Option | Description |
|--------|-------------|
| a) Speed and keyboard shortcuts | Power users who live in the app all day |
| b) Finding and managing lots of records | Navigating large datasets efficiently |
| c) Focused writing and reading | Minimal distraction, content-first |
| d) Real-time collaboration | Seeing others' work, shared context |
| e) Simplicity and calm | Approachable, never overwhelming |
| f) Visual impact and polish | Premium feel, the product itself impresses |

#### Question 3: Information Density

Ask: "How much information should users see at once?"

| Option | Description |
|--------|-------------|
| a) As much as possible | Users want density — tables, dashboards, metrics |
| b) Moderate | Good amount of info without feeling cramped |
| c) Minimal | One thing at a time, focused and clean |

#### Scoring Matrix

Each answer maps to archetype scores (1-5):

| Answer | Linear | Attio | Notion | Figma | Things3 | Framer |
|--------|--------|-------|--------|-------|---------|--------|
| Q1-a | 5 | 4 | 1 | 3 | 1 | 1 |
| Q1-b | 3 | 5 | 2 | 1 | 1 | 1 |
| Q1-c | 1 | 1 | 5 | 2 | 3 | 2 |
| Q1-d | 2 | 2 | 2 | 5 | 1 | 3 |
| Q1-e | 1 | 1 | 3 | 1 | 5 | 2 |
| Q1-f | 1 | 1 | 1 | 3 | 2 | 5 |
| Q2-a | 5 | 3 | 2 | 3 | 1 | 1 |
| Q2-b | 3 | 5 | 2 | 2 | 1 | 1 |
| Q2-c | 1 | 1 | 5 | 1 | 4 | 2 |
| Q2-d | 2 | 2 | 2 | 5 | 1 | 3 |
| Q2-e | 1 | 1 | 3 | 1 | 5 | 2 |
| Q2-f | 1 | 2 | 1 | 3 | 2 | 5 |
| Q3-a | 5 | 4 | 1 | 3 | 1 | 1 |
| Q3-b | 3 | 3 | 3 | 3 | 3 | 3 |
| Q3-c | 1 | 1 | 4 | 1 | 5 | 4 |

Sum scores across all 3 questions. Present the top 2-3 scoring archetypes.

#### Presentation Format

For each recommended archetype, display in this format:

```
### Recommended: "{Vibe}" ({Archetype Name} archetype)
Think: {Reference Products}

  Density:        [{visual bar}] {label}
  Warmth:         [{visual bar}] {label}
  Sophistication: [{visual bar}] {label}
  Interaction:    [{visual bar}] {label}

  {ASCII Preview from archetype file — the wireframe}

  Best for: {best-for list}
  Not ideal for: {not-great-for summary}
```

**Key principles for presentation:**
- Lead with the vibe name and dimension bars, NOT the product name
- The ASCII wireframe preview is critical — it gives users who don't know the reference products a feel for the layout
- Product names are "Think: ..." hints, not the primary identifier
- Show "Best for" and "Not ideal for" so users can self-select
- If user says "show all", display all 6 archetypes

#### After Selection

1. Write `design.archetype` to `company.config.yaml`
2. Ask: "Dark mode support?" → options: auto (follow system) | light (light only) | dark (dark only) | both (user toggle) → write to `design.dark_mode`
3. Ask: "UI density preference?" → options: compact (tight spacing) | comfortable (balanced, default) | spacious (generous whitespace) → write to `design.density`
4. Confirm selection and suggest: "Run `/design-system generate-tokens` to produce your project-specific design tokens."

### Step 2: Provide Guidance (Default Mode)

When the frontend agent is building UI and invokes this skill:

1. Read `design.*` from `company.config.yaml`
2. Load the archetype file: `standards/brand/archetypes/{archetype}.md`
3. Load the UX baseline: `standards/brand/ux-baseline.md`
4. If exists, load project tokens: `standards/brand/design-tokens.md`

Return to the frontend agent:
- The **visual tokens** relevant to the component being built (colors, spacing, typography, radius, shadows)
- The **UX patterns** relevant to the component type:
  - Building a table? → archetype's Lists & Tables patterns + UX baseline's loading/empty/error states
  - Building a form? → archetype's Data Entry patterns + UX baseline's form validation rules
  - Building navigation? → archetype's Navigation patterns + UX baseline's responsive behavior
  - Building a modal? → archetype's Progressive Disclosure patterns + UX baseline's keyboard navigation
- Any **UX baseline rules** that apply (always include empty states, loading states, error handling)
- Flag any patterns that **conflict with the archetype** (e.g., using a modal in Linear archetype where inline editing is preferred)

### Step 3: Generate Tokens (`/design-system generate-tokens`)

Produce `standards/brand/design-tokens.md` by merging:

1. **Base tokens** from the configured archetype file
2. **Density adjustments**:
   - `compact`: reduce spacing scale by 25% (e.g., 8px → 6px), reduce row heights by ~4px
   - `comfortable`: use archetype defaults as-is
   - `spacious`: increase spacing scale by 25% (e.g., 8px → 10px), increase row heights by ~4px
3. **Dark mode selection**:
   - `auto` or `both`: include both light and dark palettes
   - `light`: include only light palette
   - `dark`: include only dark palette
4. **User overrides** from `design.overrides` (e.g., `{ accent: "#FF6B00" }` replaces the accent color)

Output format:

```markdown
# Design Tokens — {Product Name}

Generated from: {archetype} archetype
Density: {density} | Dark mode: {dark_mode}
Last generated: {date}

## Colors
### Light Mode
(token table from archetype, with any overrides applied)

### Dark Mode
(token table, if applicable)

## Typography
(token table)

## Spacing
(token table, adjusted for density)

## Border Radius
(token table)

## Shadows
(token table)

## Icons
(icon configuration)

## Animation
(timing tokens)

## CSS Custom Properties

Copy these into your global stylesheet:

\```css
:root {
  /* Colors — Light */
  --bg-primary: {value};
  --bg-surface: {value};
  ...

  /* Typography */
  --font-family: {value};
  --font-size-base: {value};
  ...

  /* Spacing */
  --space-1: {value};
  ...
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg-primary: {dark value};
    ...
  }
}
\```
```

### Step 4: Review (`/design-system review`)

Audit existing frontend code for design consistency violations.

#### Checks to Run

1. **Hardcoded colors**: Grep for hex codes (`#[0-9a-fA-F]{3,8}`) in component files (not in token/theme files). Flag any that should use design tokens.

2. **Hardcoded spacing**: Grep for pixel values in margin/padding (`margin: 17px`, `padding: 5px`) that don't match the spacing scale.

3. **Missing UX baseline patterns**: For each page/component, check:
   - Does it handle empty state? (grep for "empty", "no results", "no data" patterns)
   - Does it handle loading state? (grep for "skeleton", "loading", "Suspense" patterns)
   - Does it handle error state? (grep for "error", "ErrorBoundary", "catch" patterns)

4. **Typography violations**: Grep for hardcoded font-size values that don't match the type scale.

5. **Touch target size**: Grep for button/input height values below 44px on interactive elements.

6. **Contrast issues**: Flag any text color + background color combinations that might fail WCAG AA.

#### Report Format

```
## Design System Review

Archetype: {archetype}
Files scanned: {count}
Issues found: {count}

### Critical (must fix)
- {file}:{line} — Hardcoded color #FF0000, should use --status-error
- {file}:{line} — No empty state for user list component

### Warning (should fix)
- {file}:{line} — Spacing 5px doesn't match spacing scale (nearest: 4px)
- {file}:{line} — Button height 36px below 44px touch target minimum

### Info (consider)
- {file}:{line} — Spinner used for content loading, prefer skeleton screen
```

## Auto-Extract Heuristics

When the setup wizard runs in auto-extract mode (from URL or text), use these keywords to suggest an archetype:

| Keywords in Description | Suggested Archetype |
|------------------------|-------------------|
| admin, dashboard, management, internal, operations, monitoring | Linear |
| CRM, contacts, leads, records, customers, inventory, ERP, school | Attio |
| docs, wiki, knowledge, articles, notes, writing, learning, course | Notion |
| collaboration, real-time, whiteboard, canvas, editor, analytics | Figma |
| personal, simple, consumer, wellness, health, finance, habit, journal | Things 3 |
| marketing, creative, portfolio, landing, brand, visual, showcase | Framer |

If multiple keywords match different archetypes, prefer the one with the most keyword hits. If tied, fall back to the 3-question wizard.

## Graceful Degradation

If `design.archetype` is not configured and the skill is invoked by the frontend agent (not directly by user):
1. Warn: "No design archetype configured. UI will use safe defaults."
2. Fall back to **Things 3** archetype (safest default — warm, accessible, works for any product)
3. Add a note to the component: "<!-- TODO: Configure design archetype with /design-system -->"
4. Still apply the full UX baseline (empty states, loading, errors, etc.)

## Express Mode Template

For `/setup` express mode, add this section to the config block:

```
## Design
- Archetype: linear | attio | notion | figma | things3 | framer
- Dark Mode: auto | light | dark | both
- Density: compact | comfortable | spacious
```
