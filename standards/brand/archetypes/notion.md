# Notion Archetype: "Invisible Scaffolding"

## Overview

### Vibe
Clean canvas that disappears behind content. Generous whitespace, minimal chrome, flexible blocks. The UI recedes entirely — all you see is your work. Warm grays instead of harsh blacks, serif headings that feel editorial, and an interaction model built entirely around typing.

### Philosophy
Content-first interface where the tool itself becomes invisible. Like a perfectly designed blank notebook — the medium disappears and you're left alone with your thoughts. Notion made "structured content" feel like writing on a blank page. There is no "form" to fill out, no "modal" to complete — you type, and structure emerges. The interface is scaffolding: load-bearing but unseen.

### Best For
- Knowledge bases, wikis, and internal documentation
- Note-taking tools and personal knowledge management
- Team handbooks and onboarding documentation
- Learning management and course platforms
- Project documentation (not project management — that is Linear)
- Content CMS and editorial publishing tools
- Collaborative writing and long-form document editing

### Not Great For
- Real-time operational dashboards (too calm, no urgency)
- High-frequency transactional tools (issue trackers, queues)
- Consumer entertainment or social apps (too editorial)
- Developer tools requiring dense data tables or terminal UI
- Tools where speed and keyboard shortcuts are the primary value

### Reference Products
Think: Notion, Coda, Craft Docs, Obsidian, Bear, Confluence (modernized), GitBook, Slite

## Dimension Tags

| Dimension | Position | Scale |
|-----------|----------|-------|
| Density | Medium | `sparse ·····■····· compact` |
| Warmth | Warm | `warm ■·········· cool` |
| Sophistication | High | `playful ········■·· refined` |
| Interaction | Type-first | `point ·■·········· keyboard` |

## Visual Tokens

### Colors

#### Light Mode
| Token | Value | Usage |
|-------|-------|-------|
| `--bg-primary` | `#FFFFFF` | Page background, main content canvas |
| `--bg-surface` | `#FAFAFA` | Sidebar, secondary panels |
| `--bg-surface-raised` | `#FFFFFF` | Cards, modals, popovers |
| `--bg-surface-sunken` | `#F7F6F3` | Code blocks, callout blocks, inset areas |
| `--border-default` | `#E9E9E7` | Default borders, block separators |
| `--border-subtle` | `#F0EFEC` | Subtle table dividers, row separators |
| `--text-primary` | `#37352F` | Headings, body text — warm dark, not pure black |
| `--text-secondary` | `#787774` | Descriptions, captions, timestamps |
| `--text-tertiary` | `#ACABA8` | Placeholders, disabled text, hints |
| `--accent` | `#2EAADC` | Links, primary actions, selected borders |
| `--accent-hover` | `#2090BB` | Hover on primary actions |
| `--accent-muted` | `#EAF5FB` | Selected block background, active sidebar item |
| `--status-success` | `#0F7B6C` | Done, published, live |
| `--status-warning` | `#CB912F` | In review, pending, blocked |
| `--status-error` | `#E03E3E` | Failed, error, urgent |
| `--status-info` | `#2EAADC` | In progress, informational |

#### Dark Mode
| Token | Value | Usage |
|-------|-------|-------|
| `--bg-primary` | `#191919` | Page background |
| `--bg-surface` | `#252525` | Sidebar, secondary panels |
| `--bg-surface-raised` | `#2F2F2F` | Cards, modals, elevated surfaces |
| `--bg-surface-sunken` | `#141414` | Code blocks, callout blocks, inset areas |
| `--border-default` | `#373737` | Default borders |
| `--border-subtle` | `#2C2C2C` | Subtle separators |
| `--text-primary` | `#E3E2E0` | Headings, body text — warm off-white |
| `--text-secondary` | `#9B9A97` | Descriptions, metadata |
| `--text-tertiary` | `#64635F` | Placeholders, disabled text |
| `--accent` | `#529CCA` | Links, primary actions |
| `--accent-hover` | `#62AEDA` | Hover on primary |
| `--accent-muted` | `#1A2D3D` | Selected block background, active sidebar item |
| (status tokens maintain same hue family as light mode, lightened ~15%) | | |

### Typography
| Token | Value | Usage |
|-------|-------|-------|
| `--font-family-heading` | `'Georgia', 'Lora', 'Palatino Linotype', serif` | Page titles, H1-H2 headings |
| `--font-family-body` | `'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif` | Body text, UI chrome, labels |
| `--font-size-xs` | `11px` | Badges, chips, breadcrumbs |
| `--font-size-sm` | `13px` | Metadata, captions, sidebar items |
| `--font-size-base` | `15px` | Body text, table cells — slightly larger than Linear for reading comfort |
| `--font-size-md` | `14px` | UI chrome: buttons, inputs, labels |
| `--font-size-lg` | `18px` | H3 sub-headings |
| `--font-size-xl` | `24px` | H2 section headings |
| `--font-size-2xl` | `32px` | H1 page title |
| `--font-size-3xl` | `40px` | Hero/cover page title |
| `--font-weight-normal` | `400` | Body text, descriptions |
| `--font-weight-medium` | `500` | UI labels, table headers, sidebar items |
| `--font-weight-semibold` | `600` | Sub-headings (H3), emphasis |
| `--font-weight-bold` | `700` | Page title (H1), strong emphasis |
| `--line-height-tight` | `1.3` | Headings |
| `--line-height-normal` | `1.6` | Body text — generous for reading |
| `--line-height-relaxed` | `1.75` | Long-form prose blocks |
| `--letter-spacing-tight` | `-0.02em` | Large serif headings (32px+) |
| `--letter-spacing-normal` | `0` | Body text, UI chrome |

### Spacing Scale
| Token | Value | Usage |
|-------|-------|-------|
| `--space-1` | `4px` | Inline icon-to-text gap |
| `--space-2` | `8px` | Base unit — tight padding (chips, badges, inline controls) |
| `--space-3` | `12px` | Button padding, compact input padding |
| `--space-4` | `16px` | Standard block spacing, line spacing between paragraphs |
| `--space-5` | `24px` | Between content blocks, section rhythm |
| `--space-6` | `32px` | Section gaps, page padding horizontal |
| `--space-7` | `48px` | Major layout sections |
| `--space-8` | `64px` | Page-level vertical breathing room |

### Border Radius
| Token | Value | Usage |
|-------|-------|-------|
| `--radius-sm` | `3px` | Inline code, small badges, toggle handles |
| `--radius-md` | `4px` | Buttons, inputs, block handles — subtle, almost sharp |
| `--radius-lg` | `6px` | Cards, dropdowns, callout blocks |
| `--radius-full` | `9999px` | Avatars, status dots, pill tags |

### Shadows
| Token | Value | Usage |
|-------|-------|-------|
| `--shadow-none` | `none` | Default surfaces — Notion is flat, borders preferred over shadows |
| `--shadow-sm` | `0 1px 3px rgba(0,0,0,0.06)` | Dropdowns, context menus, popovers only |
| `--shadow-md` | `0 4px 16px rgba(0,0,0,0.08)` | Modals, dialogs, slash command palette |
| Philosophy | Near-shadowless by design. Use `--border-default` instead of shadow to define surfaces. Reserve shadows exclusively for floating/overlaid elements. | |

(Dark mode shadows: `rgba(0,0,0,0.3)` for sm, `rgba(0,0,0,0.45)` for md)

### Icons
| Property | Value |
|----------|-------|
| Set | Lucide (primary) or custom hand-crafted |
| Default size | `18px` |
| Sidebar/nav size | `18px` |
| Stroke weight | `1.5px` |
| Style | Outlined, not filled — with muted color, not full primary color |
| Color | `--text-secondary` by default (`#787774`), `--text-primary` on hover/active |

### Animation
| Token | Value | Usage |
|-------|-------|-------|
| `--duration-instant` | `50ms` | Hover state highlights on blocks |
| `--duration-fast` | `100ms` | Button clicks, checkbox toggles, inline controls |
| `--duration-normal` | `200ms` | Sidebar expand/collapse, panel transitions, dropdown open |
| `--duration-slow` | `300ms` | Page transitions, modal enter/exit |
| `--easing-default` | `cubic-bezier(0.25, 0.1, 0.25, 1)` | Standard ease — subtle and non-intrusive |
| `--easing-ease-out` | `cubic-bezier(0.0, 0.0, 0.2, 1)` | Elements entering the screen |
| Philosophy | Almost imperceptible. Animation exists to communicate structural change (panel opening, block inserting), never to delight or attract attention. If an animation draws the eye away from content, it is too much. |

## UX Patterns

### Navigation
- **Layout**: Fixed left sidebar (240px expanded, 0px / icon-only collapsed) + full-width content canvas
- **Sidebar tree**: Hierarchical nested page list with disclosure triangles. Indent increases per level. No hard depth limit.
- **Sidebar items**: Page emoji + page title. Hover reveals `...` for options and `+` for adding sub-pages.
- **Active state**: `--accent-muted` background fill on the active page row. No left border indicator — fill only.
- **No top nav bar**: The sidebar IS the navigation. No secondary nav. The page title is inside the content area, not a chrome header.
- **Breadcrumbs**: Shown only inside shared/public pages or when navigating within a database. Otherwise absent.

### Data Entry
- **Block-based editing**: Every element is a block. Type to create paragraph blocks. Slash command (`/`) to insert other block types (headings, toggles, databases, images, dividers, callouts).
- **Type to create**: There is no toolbar to click. You type, the content appears. Formatting commands follow keyboard shortcuts (Markdown-like: `##` for H2, `**bold**`, `- ` for bullet).
- **Slash command palette**: `/` opens an inline command palette anchored to the cursor. Search for block types by name. Esc to dismiss.
- **Drag to reorder**: Every block shows a drag handle (`⠿`) on hover (left of the block). Drag to reorder. Visual insertion line shows drop target.
- **Inline editing only**: No separate "edit mode." Click anywhere on the canvas to place cursor and begin editing immediately.
- **Properties (databases)**: Inline property editor within database rows. Click property value to edit inline. No separate edit dialog for simple properties.

### Lists & Tables
- **View switching**: The same database can be rendered as Table, Board (kanban), Gallery, Calendar, List, or Timeline. Toggle between views via tabs at the top of the database block.
- **Table rows**: Comfortable height (36-40px). Click row to open full-page detail. No row-level actions toolbar — use `...` per row or right-click.
- **Column widths**: Draggable. Columns store their width preference.
- **Filters and sorts**: Applied via toolbar above the database. Shown as active chips. No filter sidebar — inline only.
- **Grouped views**: Board is the canonical "grouped by status" view. Table supports grouping via `Group by` in the view options.
- **Inline database**: Databases can be embedded inside any page as a block. They render full-featured even inline.

### Feedback & State
- **Minimal toast use**: Only for confirmations that cannot be inferred from the content itself (e.g., "Link copied", "Moved to Trash"). Destructive actions get a brief confirmation toast.
- **Optimistic updates**: Changes appear immediately without waiting for server confirmation. Auto-save runs continuously. No explicit "Save" button anywhere.
- **Saving indicator**: Small "Saving..." / "All changes saved" text in the top bar — subtle, not a modal or progress bar.
- **Loading**: Skeleton blocks matching approximate content layout. Sidebar items shimmer while loading.
- **Empty states**: Minimal and inviting — show a prompt to start typing or add the first item. "Press Enter to start writing..." style placeholder text directly in the editor.
- **Error states**: Inline under the affected block or input. Never full-page error modals for recoverable errors.

### Progressive Disclosure
- **Nested pages**: The primary information architecture primitive. Click a page title to go deeper. The sidebar tree reveals hierarchy. Back button to go up.
- **Toggle blocks**: A first-class block type that collapses/expands child content. Used for FAQ-style content, collapsible sections, nested outlines.
- **Synced blocks**: Blocks whose content mirrors another block elsewhere in the workspace. Change one, all instances update.
- **Property reveal**: Database rows show a selected set of visible properties. Hidden properties are accessible via the row detail view or "Show more" control.
- **Hover reveals**: Block drag handles, `+` buttons for adding blocks, and row action menus only appear on hover — not at rest. Reduces visual noise.

### Interaction Style
- **Type-first**: The primary creation mechanism is typing. All secondary creation flows branch from the cursor or slash command.
- **Slash commands as primary creation**: `/` is the universal "create" shortcut. Users learn this once and can access every block type, embed type, and template from it.
- **Markdown shortcuts**: `#`, `##`, `###` for headings; `- ` or `* ` for bullets; `1. ` for numbered lists; `> ` for blockquotes; `---` for dividers. Familiar and zero-UI.
- **Keyboard navigation**: Tab to indent list items, Shift+Tab to outdent. Arrow keys to move between blocks. Enter to create new blocks, Backspace on empty block to delete.
- **Mouse use**: Primarily for selecting blocks (drag to select multiple), dragging blocks to reorder, clicking to place cursor, and clicking database row to open detail.
- **No keyboard shortcut hub**: Unlike Linear, Notion does not optimize for keyboard power users navigating lists at speed. The keyboard model is document-editing, not issue-triaging.

## ASCII Preview

```
┌──────────────┬──────────────────────────────────────────┐
│ 🏠 Home      │                                          │
│              │  Product Roadmap                         │
│ 📋 Roadmap   │  ═══════════════                         │
│   Q1 Goals   │                                          │
│   Q2 Goals   │  Our priorities for building the next    │
│              │  generation of collaboration tools.      │
│ 📝 Meeting.. │                                          │
│ 📚 Wiki      │  ▸ Key Metrics                           │
│   Eng Wiki   │                                          │
│   Design..   │  ┌──────────────────────────────────────┐│
│              │  │ Feature       Status    Owner   Due  ││
│ 🗂 Databases │  │─────────────────────────────────────│││
│   Tasks      │  │ Auth v2       🟢 Done   @alex  Jan  ││
│   Projects   │  │ Search        🔵 Active  @mia  Feb  ││
│   Contacts   │  │ Dark mode     ○ Todo    @tom   Mar  ││
│              │  └──────────────────────────────────────┘│
│ + New page   │                                          │
└──────────────┴──────────────────────────────────────────┘
```

## Product-to-Archetype Mapping

Use this archetype when the user's product matches these patterns:
- "knowledge base" or "wiki" or "internal docs" → strong match
- "note-taking tool" or "personal knowledge management" → strong match
- "team handbook" or "onboarding documentation" → strong match
- "content CMS" or "editorial publishing" → strong match
- "learning management" or "course platform" → strong match
- "project documentation" (docs about projects, not project management) → strong match
- "collaborative writing" or "long-form editor" → strong match
- "company intranet" or "employee portal" → moderate match
- "project management tool" (tracking and velocity) → weak match (use Linear archetype instead)
