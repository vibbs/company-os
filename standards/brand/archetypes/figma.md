# Figma Archetype: "Multiplayer Canvas"

## Overview

### Vibe
Neutral shell with vibrant contextual UI. The chrome stays quiet until you need it — then panels, toolbars, and inspectors appear exactly where relevant. Designed for collaborative, multi-user real-time environments where context changes constantly.

### Philosophy
Figma mastered the "contextual density" problem — the interface must handle both simple tasks (quick wireframe) and complex workflows (full design system) without feeling cluttered in either mode. The solution: a neutral canvas with tool-specific panels that appear on demand. The shell is deliberately boring (gray chrome) so the user's content gets 100% of the visual attention. Collaboration indicators (cursors, avatars, comments) are first-class UI citizens, not afterthoughts.

The key insight: instead of showing everything always, surface context-relevant controls in response to what the user has selected or is doing. A text element shows font controls; a shape shows fill and stroke controls; nothing selected collapses the panel to minimal chrome. This is progressive disclosure at the system level — not just within a single component, but across the entire interface layout.

### Best For
- Collaborative design and whiteboard tools
- Real-time multi-user editing environments (documents, slides, diagrams)
- Analytics dashboards with interactive, drillable panels
- Diagram and flowchart builders
- Code and content editors with rich inspector sidebars
- Slide deck editors and presentation tools
- Any product where the user's own content is the primary visual element

### Not Great For
- Simple CRUD forms or admin panels (over-engineered for the task)
- Consumer shopping or content browsing (canvas metaphor doesn't fit)
- Mobile-first products (three-panel layout requires desktop real estate)
- Onboarding-heavy products for non-technical audiences (steep learning curve)

### Reference Products
Think: Figma, Miro, Excalidraw, Pitch, Loom Studio, FigJam, Whimsical, Framer, Penpot

## Dimension Tags

| Dimension | Position | Scale |
|-----------|----------|-------|
| Density | Variable | `sparse ·····■····· compact` (panels dense; canvas free) |
| Warmth | Neutral | `warm ·····■····· cool` |
| Sophistication | Very High | `playful ··········■ refined` |
| Interaction | Mixed | `point ···■······· keyboard` (canvas=mouse; shortcuts=keyboard) |

## Visual Tokens

### Colors

#### Light Mode
| Token | Value | Usage |
|-------|-------|-------|
| `--bg-primary` | `#F5F5F5` | Page/app background |
| `--bg-canvas` | `#FFFFFF` | Central canvas area |
| `--bg-toolbar` | `#2C2C2C` | Top toolbar background |
| `--bg-panel` | `#FFFFFF` | Left/right panel backgrounds |
| `--bg-panel-header` | `#F0F0F0` | Panel section headers |
| `--bg-surface-raised` | `#FFFFFF` | Floating menus, dropdowns |
| `--bg-surface-sunken` | `#EBEBEB` | Input backgrounds, inset areas |
| `--border-default` | `#E0E0E0` | Panel borders, section dividers |
| `--border-subtle` | `#EBEBEB` | Subtle separators inside panels |
| `--text-primary` | `#333333` | Body text, panel labels |
| `--text-secondary` | `#6E6E6E` | Metadata, secondary labels |
| `--text-tertiary` | `#9E9E9E` | Placeholders, disabled text |
| `--text-on-toolbar` | `#CCCCCC` | Icon and label text on dark toolbar |
| `--text-on-toolbar-active` | `#FFFFFF` | Active tool text on dark toolbar |
| `--accent` | `#0D99FF` | Primary actions, selection handles, links |
| `--accent-hover` | `#0080E0` | Hover on primary actions |
| `--accent-muted` | `#E5F4FF` | Selected state background in lists |
| `--selection-handle` | `#0D99FF` | Canvas selection box and resize handles |
| `--collab-cursor-1` | `#FF6B6B` | Collaborator cursor (user 1) |
| `--collab-cursor-2` | `#FFD93D` | Collaborator cursor (user 2) |
| `--collab-cursor-3` | `#6BCB77` | Collaborator cursor (user 3) |
| `--status-success` | `#2EA043` | Success, published, resolved |
| `--status-warning` | `#D4A72C` | Warning, pending, caution |
| `--status-error` | `#E5534B` | Error, failed, destructive |
| `--status-info` | `#4A9EFF` | Informational, in progress |

#### Dark Mode
| Token | Value | Usage |
|-------|-------|-------|
| `--bg-primary` | `#1E1E1E` | Page/app background |
| `--bg-canvas` | `#2C2C2C` | Central canvas area |
| `--bg-toolbar` | `#1E1E1E` | Top toolbar background |
| `--bg-panel` | `#2C2C2C` | Left/right panel backgrounds |
| `--bg-panel-header` | `#383838` | Panel section headers |
| `--bg-surface-raised` | `#383838` | Floating menus, dropdowns |
| `--bg-surface-sunken` | `#1A1A1A` | Input backgrounds, inset areas |
| `--border-default` | `#3D3D3D` | Panel borders, section dividers |
| `--border-subtle` | `#333333` | Subtle separators inside panels |
| `--text-primary` | `#E0E0E0` | Body text, panel labels |
| `--text-secondary` | `#999999` | Metadata, secondary labels |
| `--text-tertiary` | `#5E5E5E` | Placeholders, disabled text |
| `--text-on-toolbar` | `#B0B0B0` | Icon and label text on toolbar |
| `--text-on-toolbar-active` | `#FFFFFF` | Active tool text on toolbar |
| `--accent` | `#0D99FF` | Primary actions, selection handles (same) |
| `--accent-hover` | `#3AADFF` | Hover on primary actions |
| `--accent-muted` | `#0D3A5C` | Selected state background in lists |
| `--selection-handle` | `#0D99FF` | Canvas selection box and handles |
| (collab cursor tokens same values as light mode) | | |
| (status tokens same values as light mode) | | |

### Typography
| Token | Value | Usage |
|-------|-------|-------|
| `--font-family` | `'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif` | All UI text |
| `--font-size-2xs` | `10px` | Tiny canvas labels, ruler numbers |
| `--font-size-xs` | `11px` | Toolbar labels, badges, chips |
| `--font-size-sm` | `12px` | Panel labels, property names, tooltips |
| `--font-size-base` | `13px` | Panel values, list items, inputs |
| `--font-size-md` | `14px` | Section headings inside panels |
| `--font-size-lg` | `16px` | Modal titles, major headings |
| `--font-size-xl` | `20px` | Empty state headings |
| `--font-weight-normal` | `400` | Body text, panel values |
| `--font-weight-medium` | `500` | Property labels, nav items |
| `--font-weight-semibold` | `600` | Section headers, modal titles |
| `--line-height-tight` | `1.2` | Toolbar labels (maximize density) |
| `--line-height-normal` | `1.5` | Panel descriptions, modal body |
| `--letter-spacing-normal` | `0` | Body text |
| Philosophy | Extremely compact chrome (11-12px) preserves canvas space. Panel content is 12-13px. Only modal/overlay text reaches 14px+. |  |

### Spacing Scale
| Token | Value | Usage |
|-------|-------|-------|
| `--space-1` | `4px` | Inline gaps, icon-to-label in toolbar |
| `--space-2` | `6px` | Toolbar item padding (horizontal) |
| `--space-3` | `8px` | Panel row padding, input padding |
| `--space-4` | `12px` | Panel section padding |
| `--space-5` | `16px` | Panel padding (horizontal sides) |
| `--space-6` | `20px` | Spacing between panel sections |
| `--space-7` | `24px` | Modal padding |
| `--space-8` | `32px` | Major layout section gaps |
| Philosophy | Toolbars use 4-8px. Panels use 8-12px. Canvas has no padding — elements are positioned freely. |  |

### Border Radius
| Token | Value | Usage |
|-------|-------|-------|
| `--radius-xs` | `2px` | Tiny toggles, small chips, status dots |
| `--radius-sm` | `4px` | Input fields, small buttons |
| `--radius-md` | `6px` | Standard buttons, dropdowns, tooltips |
| `--radius-lg` | `8px` | Panels, floating menus, modals |
| `--radius-full` | `9999px` | Avatars, presence bubbles, pill badges |

### Shadows
| Token | Value | Usage |
|-------|-------|-------|
| `--shadow-sm` | `0 1px 3px rgba(0,0,0,0.12)` | Slight elevation for toolbar buttons (active state) |
| `--shadow-md` | `0 4px 16px rgba(0,0,0,0.16)` | Floating panels, context menus, dropdowns |
| `--shadow-lg` | `0 8px 32px rgba(0,0,0,0.24)` | Modals, dialogs, overlay drawers |
| `--shadow-panel` | `2px 0 8px rgba(0,0,0,0.12)` | Sidebar panels casting shadow onto canvas |
| Philosophy | Panels cast noticeable shadows to visually separate from the canvas behind them. Canvas elements have no shadow — they exist in their own spatial layer. |  |

(Dark mode shadows: multiply alpha by 2x — e.g., `rgba(0,0,0,0.32)` for md, `rgba(0,0,0,0.48)` for lg)

### Icons
| Property | Value |
|----------|-------|
| Set | Custom iconography (first choice) or Lucide (fallback) |
| Toolbar size | `14px` — tight spacing, maximize canvas |
| Panel size | `14px` — consistent with toolbar |
| Modal/overlay size | `16px` — slightly larger for contextual actions |
| Stroke weight | `1.5px` |
| Style | Outlined; filled only for active/selected tool state |
| Color | `--text-on-toolbar` on toolbar; `currentColor` in panels |

### Animation
| Token | Value | Usage |
|-------|-------|-------|
| `--duration-instant` | `0ms` | All canvas operations (move, resize, draw) — zero latency |
| `--duration-fast` | `100ms` | Toolbar active state, icon hover |
| `--duration-panel` | `150ms` | Panel show/hide slide, property updates |
| `--duration-modal` | `200ms` | Modal open/close, overlay drawers |
| `--easing-default` | `cubic-bezier(0.25, 0.1, 0.25, 1)` | Standard easing for panels |
| `--easing-out` | `cubic-bezier(0.0, 0.0, 0.2, 1)` | Panel entry (slides in) |
| `--easing-in` | `cubic-bezier(0.4, 0.0, 1, 1)` | Panel exit (slides out) |
| Philosophy | Canvas operations are instant — any perceptible lag breaks the direct-manipulation illusion. Panel animations (150ms) signal context switch. Never animate canvas elements programmatically for decoration. |  |

## UX Patterns

### Navigation
- **Layout**: Top toolbar (tool selection) + left panel (layers/pages/assets) + center canvas + right panel (properties/inspect). All three side panels are collapsible independently.
- **Panel visibility**: Context-driven. Selecting an element shows its properties in the right panel. Deselecting collapses the right panel to minimal state.
- **Page navigation**: Left panel bottom section shows page list. Click to switch pages. Double-click to rename.
- **Zoom and pan**: `Cmd/Ctrl + scroll` to zoom; `Space + drag` to pan. Zoom level visible in toolbar. `Cmd/Ctrl + 0` to fit to screen.
- **File breadcrumb**: Top-left shows file name → page name. Click to rename.
- **Multiplayer presence**: Avatar stack in toolbar top-right. Click an avatar to follow that user's viewport. Active users shown with colored cursors on canvas.

### Data Entry
- **Property panels**: Click an element on the canvas → right panel shows editable properties (position, size, fill, stroke, typography). Edit directly in panel fields.
- **Direct manipulation**: Resize by dragging handles, move by dragging element, rotate by dragging near corner handle.
- **Input precision**: Tab through property fields in the right panel. Supports math expressions (`width: 100+20`).
- **Color picker**: Click any color swatch to open inline color picker. Supports hex, RGB, HSL, and color variables.
- **Auto-layout**: Drag elements to compose; apply auto-layout for alignment and spacing rules.
- **No save button**: All changes are persisted automatically. History is maintained for undo (Cmd+Z unlimited).

### Lists & Tables
- **Layer tree**: Left panel shows nested layer hierarchy. Indent = nesting. Click to select, drag to reorder. Click arrow to expand/collapse groups.
- **Layer naming**: Double-click layer name to rename inline. Descriptive names encouraged (auto-named by element type).
- **Asset library**: Left panel "Assets" tab shows components, styles, and variables. Filterable search at top. Drag to canvas to place.
- **Component grid**: Grid view inside asset library for browsing components visually. List view available for power users.
- **Pages list**: Thin tab strip at the bottom of the left panel. Click to switch, double-click to rename, drag to reorder.
- **Search in layers**: Cmd+F opens layer search overlay. Highlights matching layers in tree and canvas.

### Feedback & State
- **Real-time collaboration**: Other users' cursors appear on canvas with name labels. Cursor color corresponds to their avatar color.
- **Presence avatars**: Top-right toolbar shows circular avatar stack. Badge count when more than 4 users present.
- **Comment threads**: Click with comment tool to place an anchored comment on the canvas. Comments visible to all collaborators. Resolved comments collapse.
- **Version history**: Accessible from File menu. Timeline of named and auto-saved versions. Preview without reverting.
- **Connection status**: Subtle indicator in toolbar (green dot = connected; yellow = reconnecting; red = offline). Offline mode allows local edits that sync on reconnect.
- **Toasts**: Bottom-center, brief, auto-dismiss 3s. Used for system messages ("Link copied", "Component updated").
- **Loading skeletons**: When assets/thumbnails load, placeholder gray rectangles maintain layout.
- **Conflict resolution**: Optimistic updates with last-write-wins per property. No "save conflict" dialogs — properties merge at field level.

### Progressive Disclosure
- **Right panel contextuality**: Panel content changes entirely based on selection. Text selected → typography controls. Shape selected → fill/stroke controls. Nothing selected → document settings.
- **Inspect mode**: Toggle between "Design" and "Inspect" tabs in right panel. Inspect shows developer-ready values (CSS, spacing tokens, asset export).
- **Overflow properties**: Secondary properties (advanced corner controls, blend modes) hidden behind expand toggle. Show by default only the most-used properties.
- **Plugin panel**: Plugins live in a dedicated panel section. Hidden unless plugins are installed.
- **Context menus**: Right-click on canvas element reveals full action menu (copy, paste, group, lock, hide, component actions).
- **Keyboard shortcuts overlay**: `Cmd+Shift+?` opens overlay listing all shortcuts. Discoverable but not intrusive.

### Interaction Style
- **Tool-based**: Active tool determines cursor behavior and available interactions. Tools live in left side of toolbar.
- **Mouse-primary for canvas**: Pan, zoom, select, resize, draw — all mouse/trackpad driven.
- **Keyboard shortcuts for switching**: V (move), F (frame), R (rectangle), O (circle), T (text), P (pen). One-key tool switch.
- **Modifier keys**: Shift constrains proportions; Alt copies on drag; Cmd selects within group.
- **Multi-select**: Click to select one, Shift+click to add to selection, drag to marquee-select area.
- **Double-click to enter**: Double-click a group to enter it; double-click a component to edit master.
- **Escape to exit**: Escape deselects and exits sub-modes (editing text, entering group).
- **Drag and drop**: Reorder layers, drag assets from library to canvas, drag images from desktop into canvas.

## ASCII Preview

```
┌────────────────────────────────────────────────────────────────────┐
│ ▶ Move │ □ Frame │ ○ Shape │ T Text │ ✎ Pen │  100%  ▾ │ 👤 👤 [+]│
├──────────┬──────────────────────────────────────┬───────────────────┤
│ Layers   │                                      │ Design   Inspect  │
│          │                                      │                   │
│ ▾ Page 1 │    ┌─────────────────────────┐        │ X    120   Y   80 │
│  ▸ Hero  │    │                         │        │ W    400   H   60 │
│  ▸ Nav   │    │   Welcome to Acme   ←●  │        │                   │
│  ▸ Cards │    │                         │        │ Fill              │
│  ▸ CTA   │    └─────────────────────────┘        │ ██ #1A1A1A  100% │
│          │                                      │                   │
│ Assets   │    ┌────────────┐ ┌────────────┐      │ Font   Inter      │
│          │    │            │ │            │      │ Size   32  Wt 600 │
│ ▸ Local  │    │  Feature   │ │  Feature   │      │ LH     1.4        │
│ ▸ Shared │    │  Card 1    │ │  Card 2    │      │                   │
│          │    └────────────┘ └────────────┘      │ ─────────────── ─ │
│          │                                      │                   │
│          │                ✎ alex                │ 👤 alex  👤 mia   │
└──────────┴──────────────────────────────────────┴───────────────────┘
```

## Product-to-Archetype Mapping

Use this archetype when the user's product matches these patterns:
- "collaborative editor" or "real-time whiteboard" → strong match
- "design tool" or "wireframing tool" → strong match
- "diagram builder" or "flowchart tool" → strong match
- "analytics dashboard with drillable panels" → strong match
- "slide deck editor" or "presentation builder" → strong match
- "real-time workspace" or "multiplayer canvas" → strong match
- "code playground with inspector" → moderate match
- "document editor with rich sidebar" → moderate match
- "project management tool" → weak match (prefer Linear archetype)
- "consumer mobile app" → no match (canvas layout requires desktop)
