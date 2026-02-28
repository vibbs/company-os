# Attio Archetype: "Polished Density"

## Overview

### Vibe
Relational data that feels explorable, not overwhelming. Layered surfaces with soft depth create visual hierarchy without hard borders. Tables and records feel premium — clean grids, warm neutrals, and rich accent colors for status. The UI invites browsing connected data across views.

### Philosophy
Attio proved that CRM and data-heavy tools don't have to look like 1990s enterprise software. The secret: treating every record as a first-class object with its own visual identity, connected to related records through clear visual links. Soft shadows and layered surfaces replace harsh grid lines. Data density is high, but breathability comes from generous padding within cells and cards. The result is an interface that handles hundreds of records while feeling modern and explorable.

### Best For
- CRM and contact management
- Admin panels and back-office tools
- ERP and business management systems
- School/university administration
- E-commerce backends (products, orders, customers)
- Data registries and inventory systems
- HR and people management tools

### Not Great For
- Creative tools requiring freeform canvas
- Consumer leisure apps (too structured)
- Content-first reading experiences
- Marketing sites or portfolios

### Reference Products
Think: Attio, Folk CRM, Notion databases, Clay, HubSpot (modern), Rows

## Dimension Tags

| Dimension | Position | Scale |
|-----------|----------|-------|
| Density | Medium-High | `sparse ······■··· compact` |
| Warmth | Neutral-Warm | `warm ····■····· cool` |
| Sophistication | High | `playful ········■·· refined` |
| Interaction | Mouse + keyboard | `point ····■····· keyboard` |

## Visual Tokens

### Colors

#### Light Mode
| Token | Value | Usage |
|-------|-------|-------|
| `--bg-primary` | `#F8F8F8` | Page background |
| `--bg-surface` | `#FFFFFF` | Cards, panels, modals |
| `--bg-surface-raised` | `#FFFFFF` | Elevated surfaces (popovers, side panels) |
| `--bg-surface-sunken` | `#F2F2F2` | Inset areas, sidebar background |
| `--border-default` | `#E8E8E8` | Default borders |
| `--border-subtle` | `#F0F0F0` | Table row dividers, subtle separators |
| `--text-primary` | `#1A1A1A` | Headings, body text |
| `--text-secondary` | `#6B6B6B` | Descriptions, metadata |
| `--text-tertiary` | `#999999` | Placeholders, disabled text |
| `--accent` | `#6366F1` | Primary actions, links (indigo-ish but warmer) |
| `--accent-hover` | `#5558E6` | Hover on primary |
| `--accent-muted` | `#EEF0FF` | Selected row, active tab background |
| `--status-success` | `#22C55E` | Active, completed, verified |
| `--status-warning` | `#EAB308` | Pending, needs attention |
| `--status-error` | `#EF4444` | Failed, overdue, blocked |
| `--status-info` | `#3B82F6` | New, in progress |
| `--tag-purple` | `#8B5CF6` | Tags / categories |
| `--tag-pink` | `#EC4899` | Tags / categories |
| `--tag-orange` | `#F97316` | Tags / categories |
| `--tag-teal` | `#14B8A6` | Tags / categories |

#### Dark Mode
| Token | Value | Usage |
|-------|-------|-------|
| `--bg-primary` | `#0F0F0F` | Page background |
| `--bg-surface` | `#1A1A1A` | Cards, panels |
| `--bg-surface-raised` | `#242424` | Elevated surfaces |
| `--bg-surface-sunken` | `#0A0A0A` | Inset areas |
| `--border-default` | `#2E2E2E` | Default borders |
| `--border-subtle` | `#222222` | Subtle separators |
| `--text-primary` | `#F0F0F0` | Headings, body text |
| `--text-secondary` | `#8A8A8A` | Descriptions, metadata |
| `--text-tertiary` | `#555555` | Placeholders, disabled |
| `--accent` | `#818CF8` | Primary actions, links |
| `--accent-hover` | `#A5B4FC` | Hover on primary |
| `--accent-muted` | `#1E1B4B` | Selected row, active tab |
| (status/tag tokens carry through from light mode) | | |

### Typography
| Token | Value | Usage |
|-------|-------|-------|
| `--font-family` | `'Inter', -apple-system, BlinkMacSystemFont, system-ui, sans-serif` | All text |
| `--font-size-xs` | `11px` | Tiny labels, badges |
| `--font-size-sm` | `12px` | Table metadata, secondary info |
| `--font-size-base` | `14px` | Body text, table cells, inputs |
| `--font-size-md` | `15px` | Emphasized body, subheadings |
| `--font-size-lg` | `18px` | Section headings |
| `--font-size-xl` | `22px` | Page titles |
| `--font-size-2xl` | `30px` | Dashboard hero metrics |
| `--font-weight-normal` | `400` | Body text |
| `--font-weight-medium` | `500` | Labels, table headers, nav items |
| `--font-weight-semibold` | `600` | Headings, emphasis |
| `--line-height-tight` | `1.3` | Headings, table cells |
| `--line-height-normal` | `1.55` | Body text, descriptions |
| `--letter-spacing-tight` | `-0.01em` | Headings (18px+) |

### Spacing Scale
| Token | Value | Usage |
|-------|-------|-------|
| `--space-1` | `4px` | Inline gaps, icon-to-text |
| `--space-2` | `8px` | Tight padding (tags, badges, table cells) |
| `--space-3` | `12px` | Standard padding (buttons, inputs) |
| `--space-4` | `16px` | Card padding, form group spacing |
| `--space-5` | `20px` | Panel padding, section inner spacing |
| `--space-6` | `24px` | Section gaps |
| `--space-7` | `32px` | Major layout spacing |
| `--space-8` | `48px` | Page-level vertical rhythm |

### Border Radius
| Token | Value | Usage |
|-------|-------|-------|
| `--radius-sm` | `6px` | Inputs, buttons, tags, chips |
| `--radius-md` | `8px` | Cards, dropdowns, popovers |
| `--radius-lg` | `12px` | Modals, dialogs, side panels |
| `--radius-full` | `9999px` | Avatars, status dots, pill badges |

### Shadows
| Token | Value | Usage |
|-------|-------|-------|
| `--shadow-sm` | `0 1px 3px rgba(0,0,0,0.04), 0 1px 2px rgba(0,0,0,0.06)` | Cards, subtle layering |
| `--shadow-md` | `0 4px 16px rgba(0,0,0,0.06), 0 2px 4px rgba(0,0,0,0.04)` | Dropdowns, popovers, side panels |
| `--shadow-lg` | `0 12px 32px rgba(0,0,0,0.1), 0 4px 8px rgba(0,0,0,0.05)` | Modals, command palette |

### Icons
| Property | Value |
|----------|-------|
| Set | Lucide (primary) |
| Default size | `18px` |
| Header/nav size | `20px` |
| Stroke weight | `1.75px` |
| Style | Outlined, slightly rounded caps |
| Color | `currentColor` |

### Animation
| Token | Value | Usage |
|-------|-------|-------|
| `--duration-instant` | `75ms` | Hover state changes, button feedback |
| `--duration-fast` | `150ms` | Tab switches, dropdown open |
| `--duration-normal` | `200ms` | Side panel slide, card expand |
| `--duration-slow` | `300ms` | Modal enter/exit, page transitions |
| `--easing-default` | `cubic-bezier(0.4, 0, 0.2, 1)` | Standard Material-like easing |
| Philosophy | Smooth and purposeful. Animations provide spatial context (panels slide from the side, modals scale up). Slightly slower than Linear to feel polished rather than snappy. |

## UX Patterns

### Navigation
- **Layout**: Fixed left sidebar (260px) with entity-type groups (Contacts, Companies, Deals) + main content area
- **Tabs within entities**: Top tabs for different views of the same data (Table, Board, Timeline)
- **Breadcrumbs**: Entity type > View > Record name (e.g., "Contacts > All Contacts > Jane Smith")
- **Search**: Global search bar in sidebar header. Scoped search within current view.
- **Quick switcher**: `Cmd+K` for navigation and entity search. Shows recent items.
- **Saved views**: Users create and name filtered views. Appear in sidebar under entity type.

### Data Entry
- **Side panels**: Click a record to open detail panel (slides from right, ~400px wide). List stays visible.
- **Detail drawers**: Full record view as a drawer (slides from right, ~60% width) for complex editing.
- **Inline cell editing**: Click any table cell to edit in-place. Tab to move to next cell.
- **Input height**: `36px` standard, `32px` in table cells
- **Rich fields**: Tags (multi-select with color), links (to other records), dates (calendar picker), currency, phone, email
- **Field-level save**: Each field saves independently on blur. Show subtle "Saved" indicator.
- **Add field**: "+" button at end of table columns or bottom of detail panel to add custom fields.

### Lists & Tables
- **Row height**: `36px` standard, `40px` comfortable. Cells have generous horizontal padding.
- **Column types**: Text, number, date, select, multi-select, link (to record), email, phone, URL, formula
- **Grouping**: Group by any select/status field. Show group counts. Collapsible groups.
- **Filtering**: Filter bar with field-type-aware operators (text: contains/equals, number: >/</=, date: before/after/between)
- **Saved views**: Named filter+sort+group configurations. Pin to sidebar.
- **Linked records**: Show as clickable chips. Click to peek at record details without navigating away.
- **Bulk actions**: Select rows — toolbar appears: "Edit field", "Add tag", "Delete", "Export"
- **Pagination**: Infinite scroll with row count indicator ("Showing 1-50 of 1,234")

### Feedback & State
- **Inline save**: Subtle "Saved" checkmark next to field after edit. Fades after 2s.
- **Toast**: Bottom-center, rounded, shadow-md. For bulk actions, deletions, errors. 4s auto-dismiss.
- **Loading**: Skeleton rows for tables, skeleton cards for detail panels. Match layout shapes.
- **Empty states**: Illustration (not just icon) + headline + description + CTA. Warmer tone than Linear.
- **Optimistic updates**: Instant for field edits. Show loading spinner for record creation.

### Progressive Disclosure
- **Summary > Detail**: Table shows key fields. Click row opens side panel with all fields.
- **Side panel > Full page**: "Open in full page" link in side panel for complex records.
- **Collapsible field groups**: In detail view, group related fields. "Company Info", "Deal Info", "Notes". Expand/collapse.
- **Related records section**: At bottom of detail panel. Shows linked contacts, deals, activities. Expandable.
- **Smart defaults**: New records pre-fill sensible defaults (stage: "New", date: today, owner: current user).

### Interaction Style
- **Mouse-primary with keyboard support**: Designed for point-and-click, but Tab/Enter/Escape all work.
- **Hover reveals**: Row hover shows action buttons (edit, delete, open). Not visible by default.
- **Drag-and-drop**: For board/kanban views (drag cards between columns). For reordering saved views.
- **Context menu**: Right-click on rows for quick actions.
- **Bulk selection**: Checkbox column. Select all in current view with Cmd+A.
- **Focus mode**: Click into a record to focus. Sidebar collapses or dims. Back button to return to list.

## Component Specifications

### Table Row
```
Height:        36px standard | 40px comfortable
Cell padding:  8px vertical, 12px horizontal
Hover bg:      --bg-surface-sunken
Selected bg:   --accent-muted
Border:        1px solid --border-subtle (bottom only, no side borders)
Checkbox:      16px, appears on row hover or when any row is selected
Action icons:  Appear on hover, right-aligned, 18px Lucide icons
```

### Status Badge / Tag
```
Height:        20px
Padding:       2px 8px
Font:          12px, font-weight-medium
Radius:        --radius-full (pill)
Colors:        Background at 12% opacity of status color, text at full color
Dot:           6px circle, same color, left of label text
```

### Side Panel
```
Width:         400px (peek) | 60vw (full drawer)
Entry:         Slides in from right, --duration-normal, --easing-default
Overlay:       None for peek (list remains interactive) | rgba(0,0,0,0.2) for full drawer
Header:        Record name (font-size-lg, font-weight-semibold) + close (X) + open-in-full icon
Padding:       --space-5 (20px) on all sides
Shadow:        --shadow-lg on left edge
```

### Button — Primary
```
Height:        36px
Padding:       0 16px
Font:          14px, font-weight-medium
Radius:        --radius-sm (6px)
Background:    --accent
Color:         #FFFFFF
Hover:         --accent-hover background
Active:        scale(0.98) transform
Transition:    --duration-instant
```

### Button — Secondary (Ghost)
```
Height:        36px
Padding:       0 12px
Font:          14px, font-weight-medium
Radius:        --radius-sm (6px)
Background:    transparent
Border:        1px solid --border-default
Color:         --text-primary
Hover:         --bg-surface-sunken background
```

### Button — Icon
```
Size:          32px (compact) | 36px (standard)
Radius:        --radius-sm (6px)
Background:    transparent
Color:         --text-secondary
Hover:         --bg-surface-sunken background, --text-primary color
Icon:          18px Lucide
```

### Input / Text Field
```
Height:        36px standard | 32px in table cells
Padding:       0 12px
Font:          14px, font-weight-normal
Radius:        --radius-sm (6px)
Background:    --bg-surface
Border:        1px solid --border-default
Focus border:  --accent, no box-shadow ring
Placeholder:   --text-tertiary
```

### Dropdown / Popover
```
Min-width:     180px
Max-height:    320px (scrollable)
Padding:       4px (around item list)
Item height:   32px
Item padding:  0 12px
Item font:     14px, font-weight-normal
Item hover:    --bg-surface-sunken
Radius:        --radius-md (8px)
Shadow:        --shadow-md
Border:        1px solid --border-default
```

### Avatar
```
Sizes:         24px (inline/table) | 32px (comment/mention) | 40px (profile)
Shape:         --radius-full (circle)
Fallback:      Initials on --accent-muted background, --accent text color
Font:          font-weight-medium, size proportional to avatar (50% of height)
```

### Linked Record Chip
```
Height:        24px
Padding:       2px 8px
Font:          12px, font-weight-medium
Radius:        --radius-sm (6px)
Background:    --bg-surface-sunken
Border:        1px solid --border-default
Color:         --text-primary
Hover:         --accent-muted background, --accent color, cursor pointer
Icon:          Optional 12px entity-type icon left of label
```

## Responsive Behavior

### Mobile (320px - 767px)
- Left sidebar collapses to a bottom tab bar (max 5 tabs: main entity groups + Settings)
- Table view switches to card list view — each record rendered as a stacked card
- Side panel becomes full-screen sheet (slides up from bottom)
- Bulk selection toolbar appears at bottom of screen when rows are selected
- Inline cell editing is replaced by tapping to open the record detail sheet
- Touch targets: all interactive elements minimum 44x44px

### Tablet (768px - 1023px)
- Sidebar narrows to icon-only rail (60px) with tooltips on hover
- Table columns reduce to 4-5 most important fields; remaining accessible via side panel
- Side panel uses 50% width drawer with overlay
- Filter bar collapses to a single "Filters" button that opens a modal

### Desktop (1024px+)
- Full sidebar (260px) with labels
- All table columns visible, horizontally scrollable when overflow
- Side panel is 400px peek (no overlay, list remains interactive)
- Keyboard shortcuts fully enabled

### Large Screen (1440px+)
- Main content area max-width: 1280px, centered
- Sidebar stays fixed at 260px
- Table gains extra breathing room — row height can increase to 40px comfortable mode

## Accessibility

- **Color contrast**: All text meets WCAG AA (4.5:1 for body, 3:1 for large text)
- **Focus indicators**: 2px solid --accent ring, 2px offset, on all interactive elements
- **Screen reader**: Proper `aria-label` on icon-only buttons, `role="grid"` on tables, `aria-selected` on rows
- **Keyboard navigation**: Full Tab order through sidebar, table, and side panel. Arrow keys navigate table rows. Escape closes side panel/modal.
- **Reduced motion**: Wrap all transitions in `@media (prefers-reduced-motion: no-preference)` — instant fallbacks for users with motion sensitivity
- **Status colors**: Never rely on color alone — always pair color with an icon or text label for status badges

## ASCII Preview

```
+-------------------------------------------------------------------------+
| [o] Acme CRM     [Search...]                                 [cog] [user]|
+----------------+--------------------------------------------------------+
|                | Contacts > All Contacts                                 |
| Contacts     v | Table  Board  Timeline                                  |
|  All Contacts  +---------------------------------------------------------+
|  By Company    | [x] Status: Active   + Add filter    |  234 contacts    |
|  New Leads     +---------------------------------------------------------+
|                | [ ] Name          Company       Email        Stage      |
| Companies    v | --------------------------------------------------------|
|  All           | [ ] Jane Smith    [Stripe]       jane@s...  [o] Customer|
|  Enterprise    | [ ] Tom Chen      [Vercel]       tom@v...   [o] Customer|
|                | [ ] Mia Park      [Linear]       mia@l...   [ ] Lead    |
| Deals        v | [ ] Alex Kim      [Notion]       alex@n..   [o] Prospect|
|  Pipeline      | [ ] Sara Lee      [Figma]        sara@f..   [ ] Lead    |
|  Won           |                                                         |
|  Lost          |         +-------------------------------------------+  |
|                |         | Jane Smith                    [x]  [->]   |  |
| - - - - - - -  |         | Company:  [Stripe]                        |  |
| Settings       |         | Email:    jane@stripe.com                 |  |
|                |         | Stage:    [o] Customer                    |  |
|                |         | Activity: 2 days ago                      |  |
|                |         +-------------------------------------------+  |
+----------------+--------------------------------------------------------+
```

## Implementation Notes for Frontend Agent

### CSS Variable Setup
Declare all tokens in `:root` (light mode) and `[data-theme="dark"]` (dark mode). Do not use hardcoded hex values anywhere in component styles — always reference the token variable.

```css
:root {
  --bg-primary: #F8F8F8;
  --bg-surface: #FFFFFF;
  /* ... all tokens ... */
}

[data-theme="dark"] {
  --bg-primary: #0F0F0F;
  --bg-surface: #1A1A1A;
  /* ... dark overrides ... */
}
```

### Table Implementation Priority
1. Virtualize rows if list exceeds 200 items (use `react-virtual` or `@tanstack/virtual`)
2. Column widths: use `minmax()` in CSS Grid, allow user resizing via drag handle
3. Sticky first column (name/title) when horizontal scroll occurs
4. Sticky header row always

### Side Panel Animation
```css
.side-panel {
  transform: translateX(100%);
  transition: transform var(--duration-normal) var(--easing-default);
}

.side-panel.open {
  transform: translateX(0);
}

@media (prefers-reduced-motion: reduce) {
  .side-panel {
    transition: none;
  }
}
```

### Instrumentation Requirements
Every interactive element must have `data-track-id` and `data-sentry-component` attributes. For table rows, use `data-track-id="<entity>_table-row-click"`. For side panel open/close, use `data-track-id="<entity>_side_panel-open"` and `data-track-id="<entity>_side_panel-close"`.

Guided tours should target `data-tour-step` attributes, never CSS selectors. Example for onboarding:
- `data-tour-step="onboarding-sidebar_nav"` on the first sidebar entity group
- `data-tour-step="onboarding-table_row"` on the first table row
- `data-tour-step="onboarding-side_panel"` on the side panel open trigger
- `data-tour-step="onboarding-add_record"` on the new record button

## Product-to-Archetype Mapping

Use this archetype when the user's product matches these patterns:
- "CRM" or "contact management" — strong match
- "admin panel" or "back-office" — strong match
- "ERP" or "business management" — strong match
- "school administration" or "student management" — strong match
- "e-commerce backend" or "order management" — strong match
- "inventory" or "asset management" — strong match
- "HR tool" or "people management" — strong match
- "data registry" or "record management" — strong match
