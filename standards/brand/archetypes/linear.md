# Linear Archetype: "Precision at Density"

## Overview

### Vibe
Dense, fast, precise. Every pixel earns its place. The UI feels like a precision instrument — tight rows, minimal chrome, purposeful color pops only for status and priority. Keyboard-first, zero wasted space, zero wasted motion.

### Philosophy
Linear proved that data-heavy interfaces don't have to feel cluttered. The secret: extreme restraint. Muted backgrounds, monochrome surfaces, and a near-absence of decorative elements make the *data itself* the visual hierarchy. Color is reserved exclusively for meaning — status, priority, urgency. The result is an interface that feels both information-dense and visually calm.

### Best For
- Developer tools, CLIs with web dashboards
- Project management, issue trackers, task queues
- Pipeline and workflow management
- Ops dashboards, monitoring interfaces
- Support ticket systems
- Any tool where users process queues of items quickly

### Not Great For
- Consumer leisure apps (too austere)
- Creative tools or portfolios (too constrained)
- Content-heavy reading experiences (too compact)
- Onboarding-heavy products for non-technical users

### Reference Products
Think: Linear, Raycast, Superhuman, Arc Browser, Warp Terminal, Height

## Dimension Tags

| Dimension | Position | Scale |
|-----------|----------|-------|
| Density | High | `sparse ·········■· compact` |
| Warmth | Cool | `warm ·········■· cool` |
| Sophistication | High | `playful ········■·· refined` |
| Interaction | Keyboard-first | `point ·········■· keyboard` |

## Visual Tokens

### Colors

#### Light Mode
| Token | Value | Usage |
|-------|-------|-------|
| `--bg-primary` | `#FAFAFA` | Page background |
| `--bg-surface` | `#FFFFFF` | Cards, panels, modals |
| `--bg-surface-raised` | `#FFFFFF` | Elevated surfaces (popovers, tooltips) |
| `--bg-surface-sunken` | `#F5F5F5` | Inset areas, code blocks, input backgrounds |
| `--border-default` | `#E5E5E5` | Default borders |
| `--border-subtle` | `#F0F0F0` | Subtle separators, table row dividers |
| `--text-primary` | `#171717` | Headings, body text |
| `--text-secondary` | `#737373` | Descriptions, metadata, timestamps |
| `--text-tertiary` | `#A3A3A3` | Placeholders, disabled text |
| `--accent` | `#5B5BD6` | Primary actions, links, active states |
| `--accent-hover` | `#4C4CC2` | Hover on primary actions |
| `--accent-muted` | `#EEF0FF` | Selected row, active tab background |
| `--status-success` | `#2EA043` | Done, resolved, passed |
| `--status-warning` | `#D4A72C` | In review, pending, caution |
| `--status-error` | `#E5534B` | Failed, blocked, urgent |
| `--status-info` | `#4A9EFF` | In progress, informational |
| `--priority-urgent` | `#FF6B00` | P0 / Urgent priority |
| `--priority-high` | `#E5534B` | P1 / High priority |
| `--priority-medium` | `#D4A72C` | P2 / Medium priority |
| `--priority-low` | `#737373` | P3 / Low priority |

#### Dark Mode
| Token | Value | Usage |
|-------|-------|-------|
| `--bg-primary` | `#111111` | Page background |
| `--bg-surface` | `#191919` | Cards, panels, modals |
| `--bg-surface-raised` | `#222222` | Elevated surfaces |
| `--bg-surface-sunken` | `#0D0D0D` | Inset areas, code blocks |
| `--border-default` | `#2A2A2A` | Default borders |
| `--border-subtle` | `#1F1F1F` | Subtle separators |
| `--text-primary` | `#EDEDEF` | Headings, body text |
| `--text-secondary` | `#8B8B8D` | Descriptions, metadata |
| `--text-tertiary` | `#555557` | Placeholders, disabled |
| `--accent` | `#8B8BF5` | Primary actions, links |
| `--accent-hover` | `#9D9DF7` | Hover on primary |
| `--accent-muted` | `#1E1E3A` | Selected row, active tab |
| (status/priority tokens same values as light mode) | | |

### Typography
| Token | Value | Usage |
|-------|-------|-------|
| `--font-family` | `'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif` | All text |
| `--font-size-xs` | `11px` | Badges, chips, tiny labels |
| `--font-size-sm` | `12px` | Table headers, metadata, timestamps |
| `--font-size-base` | `13px` | Body text, table cells, list items |
| `--font-size-md` | `14px` | Input text, button labels |
| `--font-size-lg` | `16px` | Section headings, dialog titles |
| `--font-size-xl` | `20px` | Page titles |
| `--font-size-2xl` | `28px` | Hero numbers, key metrics |
| `--font-weight-normal` | `400` | Body text |
| `--font-weight-medium` | `500` | Labels, table headers, nav items |
| `--font-weight-semibold` | `600` | Headings, emphasis |
| `--line-height-tight` | `1.25` | Headings, compact rows |
| `--line-height-normal` | `1.5` | Body text, descriptions |
| `--letter-spacing-tight` | `-0.01em` | Headings (20px+) |
| `--letter-spacing-normal` | `0` | Body text |

### Spacing Scale
| Token | Value | Usage |
|-------|-------|-------|
| `--space-1` | `4px` | Inline gaps, icon-to-text |
| `--space-2` | `6px` | Tight padding (chips, badges) |
| `--space-3` | `8px` | Standard padding (buttons, inputs, table cells) |
| `--space-4` | `12px` | Card padding, section gaps |
| `--space-5` | `16px` | Panel padding, form group spacing |
| `--space-6` | `24px` | Section spacing |
| `--space-7` | `32px` | Page section gaps |
| `--space-8` | `48px` | Major layout spacing |

### Border Radius
| Token | Value | Usage |
|-------|-------|-------|
| `--radius-sm` | `4px` | Inputs, buttons, chips, badges |
| `--radius-md` | `6px` | Cards, dropdowns, popovers |
| `--radius-lg` | `8px` | Modals, dialogs, panels |
| `--radius-full` | `9999px` | Avatars, status dots, pill buttons |

### Shadows
| Token | Value | Usage |
|-------|-------|-------|
| `--shadow-sm` | `0 1px 2px rgba(0,0,0,0.05)` | Cards, subtle elevation |
| `--shadow-md` | `0 4px 12px rgba(0,0,0,0.08)` | Dropdowns, popovers |
| `--shadow-lg` | `0 8px 24px rgba(0,0,0,0.12)` | Modals, command palette |

(Dark mode shadows use slightly lighter values: `rgba(0,0,0,0.3)` for sm, `rgba(0,0,0,0.4)` for md, `rgba(0,0,0,0.5)` for lg)

### Icons
| Property | Value |
|----------|-------|
| Set | Lucide (primary) or Phosphor (alternative) |
| Default size | `16px` |
| Header/nav size | `20px` |
| Stroke weight | `1.5px` |
| Style | Outlined, not filled |
| Color | Inherits from text color (`currentColor`) |

### Animation
| Token | Value | Usage |
|-------|-------|-------|
| `--duration-instant` | `50ms` | Hover state changes |
| `--duration-fast` | `100ms` | Button clicks, toggles, tab switches |
| `--duration-normal` | `150ms` | Panel expand/collapse, dropdown open |
| `--duration-slow` | `200ms` | Modal enter/exit, page transitions |
| `--easing-default` | `cubic-bezier(0.25, 0.1, 0.25, 1)` | Standard easing |
| `--easing-spring` | `cubic-bezier(0.34, 1.56, 0.64, 1)` | Subtle bounce for emphasis |
| Philosophy | Fast and non-decorative. Animations communicate state change, never decorate. If removing an animation doesn't reduce clarity, remove it. |

## UX Patterns

### Navigation
- **Layout**: Fixed left sidebar (240px expanded, 48px collapsed) + main content area
- **Command palette**: `Cmd+K` / `Ctrl+K` — fuzzy search across all entities, actions, and navigation
- **Keyboard shortcuts**: Single-key for primary actions (C = create, E = edit, D = delete), modifier for secondary
- **Breadcrumbs**: Minimal — show current location, one level up. Not deep chains.
- **Sidebar groups**: collapsible, with item counts. Active item has `accent-muted` background.
- **Tab bar**: within content area for sub-views (e.g., All / Active / Backlog). Underline style, not pill style.

### Data Entry
- **Inline editing**: Click on text to edit in-place. No separate "edit mode."
- **Input height**: `32px` for standard inputs, `28px` for compact/table contexts
- **Dropdowns over modals**: Select options via dropdown, not modal dialogs
- **Auto-save**: All changes save automatically. No explicit "Save" button. Show "Saving..." → "Saved" indicator.
- **Date pickers**: Compact calendar dropdown with keyboard navigation (arrow keys to navigate, Enter to select)
- **Multi-select**: Checkboxes in lists, shift+click for range selection

### Lists & Tables
- **Row height**: `32px` standard, `36px` comfortable. Never more than `40px`.
- **Column sorting**: Click header to sort. Arrow indicator for sort direction.
- **Resizable columns**: Drag column borders. Double-click to auto-fit.
- **Multi-select**: Click for single, Shift+Click for range, Cmd+Click for toggle
- **Batch actions**: Toolbar appears above table when items are selected ("3 selected — Archive / Delete / Assign")
- **Grouped views**: Collapsible groups with item counts. Group by status, priority, assignee.
- **Filters**: Inline filter bar above table. Chips for active filters. "X" to remove each.
- **Infinite scroll**: For long lists, load more on scroll. Show skeleton rows while loading.
- **No pagination buttons**: Prefer infinite scroll or virtual scrolling over page numbers.

### Feedback & State
- **Toasts**: Bottom-right, minimal chrome, auto-dismiss 3-5s. Maximum 1 visible at a time.
- **Optimistic updates**: Changes appear instantly. Roll back with error toast if server rejects.
- **Loading**: Skeleton rows matching table row height. No spinners for content.
- **Empty states**: Minimal — icon + one line + CTA. Not overly illustrated.
- **Progress indicators**: Thin bar at top of content area (like GitHub's loading bar), not centered spinners.

### Progressive Disclosure
- **Default**: Show primary information only. Collapse secondary details.
- **Expand on demand**: Click to expand, not hover (hover is too volatile for dense UIs).
- **Overflow menus**: `...` button for secondary actions. Keep primary actions visible.
- **Panels**: Slide-out right panel for detail views. Don't navigate away from the list.
- **Keyboard-friendly**: Arrow keys to navigate collapsed sections, Enter to expand.

### Interaction Style
- **Keyboard-driven**: Every action has a keyboard shortcut. Display shortcuts in tooltips and menu items.
- **Right-click context menus**: Full context menu on right-click for all list items.
- **Drag-and-drop**: For reordering (priority, position). Subtle drag handle on hover.
- **Vim-style navigation**: Optional j/k for up/down in lists (if archetype is keyboard-first).
- **Focus follows selection**: Selecting an item in a list auto-focuses it for keyboard action.
- **Command palette as hub**: Most common path for power users to navigate, create, and search.

## ASCII Preview

```
┌─────────────────────────────────────────────────────────────────┐
│ ◆ Acme    ┊ ⌘K Search...                              [⚙] [👤]│
├───────────┼─────────────────────────────────────────────────────┤
│           │  My Issues  ▸ Active  Backlog  Done                 │
│ ▸ Inbox 3 │─────────────────────────────────────────────────────│
│ My Issues │  ⊘ Filter ▾   Group: Status ▾   Sort: Priority ▾   │
│ Views     │─────────────────────────────────────────────────────│
│           │  ▾ In Progress — 3                                  │
│ Projects  │  ● ENG-142  Fix auth timeout       P1  ████  @jd   │
│  ▸ Alpha  │  ● ENG-138  Add rate limiting      P2  ██    @sk   │
│  ▸ Beta   │  ● ENG-155  Update SDK types       P2  ███   @jd   │
│           │                                                     │
│ Teams     │  ▾ Todo — 5                                         │
│  ▸ Eng    │  ○ ENG-160  Design token system    P2         @ml   │
│  ▸ Design │  ○ ENG-161  Add empty states       P3         @sk   │
│           │  ○ ENG-162  Keyboard shortcuts     P3         —     │
│ ─ ─ ─ ─  │  ○ ENG-163  Dark mode toggle       P3         —     │
│ Settings  │  ○ ENG-164  Export to CSV          P4         —     │
│           │                                                     │
└───────────┴─────────────────────────────────────────────────────┘
```

## Product-to-Archetype Mapping

Use this archetype when the user's product matches these patterns:
- "project management tool" → strong match
- "developer tool" or "CLI dashboard" → strong match
- "ops dashboard" or "monitoring" → strong match
- "support ticket system" or "helpdesk" → strong match
- "pipeline manager" or "workflow automation" → strong match
- "social media scheduler" or "content queue" → moderate match
