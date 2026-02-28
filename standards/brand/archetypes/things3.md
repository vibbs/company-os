# Things 3 Archetype: "Quiet Confidence"

## Overview

### Vibe
Warm, approachable, calm. Like writing in a Moleskine notebook. The UI radiates quiet quality — generous whitespace, organic rounded corners, subtle shadows that feel like real depth. Every interaction feels buttery smooth. The product reduces anxiety instead of amplifying it.

### Philosophy
Things 3 proved that productivity tools don't have to feel stressful. Instead of showing you everything at once (how many tasks are overdue, how behind you are), it presents one calm view at a time. The whitespace is intentional — it gives your mind room to think. Animations are satisfying but never flashy. The completion checkmark animation alone makes you want to finish tasks. The interface feels like a handcrafted object, not enterprise software.

### Best For
- Personal productivity apps and task managers
- Habit trackers and streaks
- Wellness, meditation, and mindfulness apps
- Consumer finance and budgeting tools
- Journal and diary apps
- Reading lists and bookmark managers
- Recipe managers and meal planners
- Simple CRM for freelancers and solopreneurs
- Personal portfolio and showcase sites

### Not Great For
- Enterprise SaaS with dense data tables and dashboards
- Developer tools that require high information density
- Real-time collaboration with many concurrent users
- Ops or monitoring dashboards
- Any tool where keyboard-first power users are the primary audience

### Reference Products
Think: Things 3, Craft, Bear, Todoist, Apple Reminders, Calmly Writer, Notion (personal use), Day One

---

## Dimension Tags

| Dimension | Position | Scale |
|-----------|----------|-------|
| Density | Spacious | `sparse ■·········· compact` |
| Warmth | Very Warm | `warm ■·········· cool` |
| Sophistication | Very High | `playful ··········■ refined` |
| Interaction | Touch/gesture-first | `point ■·········· keyboard` |

---

## Visual Tokens

### Colors

#### Light Mode
| Token | Value | Usage |
|-------|-------|-------|
| `--bg-primary` | `#FAFAF8` | Page background (slightly cream — warmer than pure white) |
| `--bg-surface` | `#FFFFFF` | Cards, panels, modals |
| `--bg-surface-raised` | `#FFFFFF` | Elevated surfaces (popovers, tooltips) |
| `--bg-surface-sunken` | `#F2F2EF` | Inset areas, secondary sections, input backgrounds |
| `--border-default` | `#E8E8E5` | Default borders (warm-tinted, not blue-gray) |
| `--border-subtle` | `#F0F0EC` | Subtle separators, row dividers |
| `--text-primary` | `#1C1C1E` | Headings, body text (deep but not pure black) |
| `--text-secondary` | `#8E8E93` | Descriptions, metadata, timestamps |
| `--text-tertiary` | `#AEAEB2` | Placeholders, disabled text |
| `--accent` | `#007AFF` | Primary actions, links, active states (iOS blue) |
| `--accent-hover` | `#0066D6` | Hover on primary actions |
| `--accent-muted` | `#EBF3FF` | Selected row, active item background |
| `--status-success` | `#34C759` | Completed, resolved (iOS green) |
| `--status-warning` | `#FF9500` | Overdue, caution, pending (iOS orange) |
| `--status-error` | `#FF3B30` | Failed, blocked, urgent (iOS red) |
| `--status-info` | `#007AFF` | Informational, scheduled (iOS blue) |
| `--tag-color-1` | `#5856D6` | Purple tag |
| `--tag-color-2` | `#FF2D55` | Pink/red tag |
| `--tag-color-3` | `#FF9500` | Orange tag |

#### Dark Mode
| Token | Value | Usage |
|-------|-------|-------|
| `--bg-primary` | `#1C1C1E` | Page background |
| `--bg-surface` | `#2C2C2E` | Cards, panels, modals |
| `--bg-surface-raised` | `#3A3A3C` | Elevated surfaces (popovers, tooltips) |
| `--bg-surface-sunken` | `#161618` | Inset areas, code blocks |
| `--border-default` | `#3A3A3C` | Default borders |
| `--border-subtle` | `#2C2C2E` | Subtle separators |
| `--text-primary` | `#F2F2F7` | Headings, body text |
| `--text-secondary` | `#8E8E93` | Descriptions, metadata |
| `--text-tertiary` | `#545458` | Placeholders, disabled |
| `--accent` | `#0A84FF` | Primary actions, links (brighter blue for dark contexts) |
| `--accent-hover` | `#338FFF` | Hover on primary |
| `--accent-muted` | `#0A2545` | Selected row, active item background |
| `--status-success` | `#30D158` | Completed, resolved |
| `--status-warning` | `#FF9F0A` | Overdue, caution |
| `--status-error` | `#FF453A` | Failed, blocked |

### Typography
| Token | Value | Usage |
|-------|-------|-------|
| `--font-family` | `'SF Pro Text', -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif` | All text (feels native and personal) |
| `--font-size-xs` | `12px` | Labels, tags, tiny metadata |
| `--font-size-sm` | `14px` | Secondary text, helper text, captions |
| `--font-size-base` | `16px` | Body text (comfortable reading size, prevents iOS zoom on input focus) |
| `--font-size-md` | `17px` | Primary list items, input text |
| `--font-size-lg` | `20px` | Section headings, panel titles |
| `--font-size-xl` | `24px` | Page titles, view headings |
| `--font-size-2xl` | `32px` | Hero numbers, greeting text |
| `--font-weight-light` | `300` | Body text, notes, descriptions (light preferred for warmth) |
| `--font-weight-normal` | `400` | Standard body and list items |
| `--font-weight-medium` | `500` | Metadata, secondary labels |
| `--font-weight-semibold` | `600` | Headings, section titles only |
| `--line-height-tight` | `1.3` | Headings, compact labels |
| `--line-height-normal` | `1.6` | Body text, notes, descriptions |
| `--letter-spacing-tight` | `-0.02em` | Large headings (24px+) |
| `--letter-spacing-normal` | `0` | Body text |

### Spacing Scale
| Token | Value | Usage |
|-------|-------|-------|
| `--space-1` | `4px` | Inline gaps, icon-to-text |
| `--space-2` | `8px` | Base unit — tight gaps, internal padding |
| `--space-3` | `12px` | Button padding (horizontal), chip padding |
| `--space-4` | `16px` | Card inner padding, input padding |
| `--space-5` | `24px` | Between sections, group gaps |
| `--space-6` | `32px` | Vertical rhythm between major content blocks |
| `--space-7` | `48px` | Page-level section spacing |
| `--space-8` | `64px` | Hero areas, top-of-page breathing room |

### Border Radius
| Token | Value | Usage |
|-------|-------|-------|
| `--radius-sm` | `6px` | Chips, small badges, tags |
| `--radius-md` | `10px` | Cards, inputs, buttons (noticeably soft and approachable) |
| `--radius-lg` | `12px` | Modals, panels, drawers |
| `--radius-xl` | `16px` | Large cards, sheets |
| `--radius-full` | `9999px` | Avatars, status dots, pill-shaped elements |

### Shadows
| Token | Value | Usage |
|-------|-------|-------|
| `--shadow-sm` | `0 1px 4px rgba(0,0,0,0.04)` | Subtle card lift — barely-there elevation |
| `--shadow-md` | `0 2px 8px rgba(0,0,0,0.06)` | Cards, list panels — floats gently |
| `--shadow-lg` | `0 8px 24px rgba(0,0,0,0.10)` | Modals, sheets, action menus |
| `--shadow-focus` | `0 0 0 3px rgba(0,122,255,0.25)` | Focus ring for accessibility |

(Dark mode shadows use slightly higher opacity: `0.12`, `0.18`, `0.28` respectively)

### Icons
| Property | Value |
|----------|-------|
| Set | SF Symbols style (Apple) or Lucide with rounded caps |
| Default size | `20px` |
| Navigation size | `22px` |
| Stroke weight | `1.5px` |
| Style | Rounded caps and joins — never sharp or angular |
| Color | Inherits from text color (`currentColor`), accent blue for active states |

### Animation
| Token | Value | Usage |
|-------|-------|-------|
| `--duration-instant` | `100ms` | Hover state changes |
| `--duration-fast` | `200ms` | Button press, toggle, checkbox check |
| `--duration-normal` | `280ms` | Panel open/close, list item appearance |
| `--duration-slow` | `350ms` | Modal enter/exit, page transitions |
| `--easing-default` | `cubic-bezier(0.25, 0.1, 0.25, 1)` | Standard ease — smooth and natural |
| `--easing-spring` | `cubic-bezier(0.34, 1.56, 0.64, 1)` | Spring bounce — completion checkmarks, drag-and-drop settle |
| `--easing-ease-out` | `cubic-bezier(0, 0, 0.2, 1)` | Items appearing (ease out from fast) |
| Philosophy | Satisfying but never flashy. Animations make completion feel rewarding. The completion checkmark is the star. Spring easing on every confirmation. Never block the user. |

---

## UX Patterns

### Navigation
- **Layout**: Narrow left sidebar (220px) with flat section list + main content. No nested trees.
- **Sidebar sections**: Inbox, Today, Upcoming, Anytime, Someday — then a separator, then Projects. Each section has an icon and an optional count badge.
- **Active state**: Accent-blue left border + `--accent-muted` background on the active section row.
- **No command palette by default**: Navigation is intentionally simple and tap-friendly. Power user shortcuts are opt-in.
- **Mobile**: Sidebar collapses to bottom tab bar on small screens. Primary tabs: Today, Inbox, Projects.
- **Contextual header**: Main content header shows the current view name and a contextual "+" button. No persistent top navigation bar.

### Data Entry
- **Magic "+" button**: Contextual add button that appears at the bottom of the current list view. Tapping it opens a minimal inline entry form — just a title field.
- **Progressive reveal**: Title-only entry on first interaction. A secondary toolbar beneath the input reveals: Notes, Date, Tag, Checklist, Move-to-project. These are hidden until needed.
- **Natural language date input**: Type "tomorrow", "next tuesday", "in 3 days" — the system interprets and shows a friendly formatted date.
- **Minimal form fields**: Title (required), Notes (optional, expands on tap), Deadline (optional, date picker), Tags (optional, inline chips). No required fields beyond title.
- **Input height**: `52px` minimum for primary inputs on mobile (touch-friendly). `40px` for secondary fields.
- **No auto-save spinner**: Changes persist silently. No "Save" button. No "Saving..." indicator — it just works.

### Lists & Tables
- **Row height**: `48px` minimum on mobile (meets 44x44px touch target requirement). `40px` on desktop.
- **Row anatomy**: Circular checkbox left (tap to complete) + title text + optional metadata (date, project) right-aligned.
- **Drag-to-reorder**: Grab handle on long press (mobile) or hover (desktop). Spring animation on drop.
- **Swipe actions (mobile)**: Swipe right to complete with a satisfying spring animation. Swipe left to reveal Schedule / Delete actions. Haptic-style visual feedback on threshold.
- **Completion animation**: Checkbox fills with accent blue using a spring bounce. Title text fades gently. Item slides off the list with an ease-out. This is the signature interaction — make it exceptional.
- **Group by area**: Tasks can be grouped under project headings within a view. Groups are collapsible with a chevron.
- **No sorting headers**: Ordering is manual (drag) or by date. No column-sort UI — this is not a data table.
- **Empty state**: Warm, encouraging illustration or icon with short affirming copy ("All clear for today"). Never guilt-inducing.

### Feedback & State
- **Completion is the primary feedback**: The act of checking off a task IS the feedback. No toast needed.
- **Minimal toasts**: Use only for undo actions ("Task deleted — Undo") and error states. Auto-dismiss in 4s.
- **Undo support**: Every destructive action (delete, complete, move) shows an undo toast. Single tap to undo.
- **Loading**: Skeleton screens that match the list row height and layout. Skeleton rows use `--bg-surface-sunken` as the shimmer base.
- **Error states**: Inline, below the relevant field. Warm red (`--status-error`), never alarming in tone. Short, specific copy ("Date must be in the future").
- **Success states**: The completion animation is success. No separate success toast for task completion.
- **Optimistic updates**: Changes are applied instantly in the UI. Server sync is silent.

### Progressive Disclosure
- **Start minimal**: Show only the task title on first glance. Tags, deadlines, notes, and checklists are visible only when present or when the row is expanded.
- **Tap to expand**: Tap a task row to open the detail view. Detail view shows all fields in a comfortable full-screen or half-sheet layout.
- **Add more on demand**: In detail view, fields like "Deadline", "Checklist", and "Notes" appear as faint placeholder rows. Tap to add. Don't pre-populate empty state with blank inputs.
- **Checklist inside task**: Checklists are nested inside a task, not a separate entity. Reveal on detail view.
- **Project hierarchy (one level only)**: Tasks live in Areas (top-level buckets) and Projects (inside areas). No sub-projects, no deep nesting.
- **No settings overload**: Minimal preferences. The product makes sensible defaults and doesn't ask users to configure their experience.

### Interaction Style
- **Touch-first**: Every interaction is designed for thumb use first. Primary actions are reachable in the bottom half of the screen on mobile.
- **Large tap targets**: Minimum 44x44px for all interactive elements. Checkboxes are 28px circles with a 48px tap target area.
- **Gesture vocabulary**: Swipe right (complete), swipe left (schedule/delete), long press (drag reorder), pinch (not used — avoid complex gestures).
- **No hover-only states**: All interactions must be discoverable via tap. Hover states are purely additive on desktop.
- **Haptic feedback (native)**: On iOS/Android, use `UIImpactFeedbackGenerator` (Swift) or `ReactNative.Vibration` for completion events. A gentle medium impact on checkbox completion.
- **Keyboard shortcuts (desktop, opt-in)**: `N` for new task, `Space` to complete, `E` to edit, `D` to set deadline. Display these in a help overlay (`?`), not by default.
- **Drag-and-drop**: For reordering tasks within a list. Drag handle appears on long press (mobile) or on hover at left edge of row (desktop). Drop uses spring easing to settle in place.

---

## ASCII Preview

```
┌─────────────┬────────────────────────────────────┐
│             │                                    │
│  ☀ Today    │   Today                            │
│             │                                    │
│  📥 Inbox   │   ○ Design the login page          │
│  📅 Upcoming│     Tomorrow · Project Alpha       │
│  📦 Anytime │                                    │
│  🌙 Someday │   ○ Write API documentation        │
│             │     No due date                    │
│ ─ ─ ─ ─ ─  │                                    │
│             │   ○ Review pull request #42        │
│  Projects   │     Today · Project Beta           │
│  ▸ Alpha    │                                    │
│  ▸ Beta     │                                    │
│  ▸ Personal │                                    │
│             │                                    │
│             │          [ + New To-Do ]            │
│             │                                    │
└─────────────┴────────────────────────────────────┘
```

Key: generous whitespace between rows, soft rounded corners on cards, flat sidebar with icons, contextual "+" at bottom of list, metadata (project, date) displayed subtly below the task title.

---

## Product-to-Archetype Mapping

Use this archetype when the user's product matches these patterns:
- "personal productivity" or "task manager" → strong match
- "habit tracker" or "daily routine" → strong match
- "wellness" or "meditation" or "mindfulness app" → strong match
- "journal" or "diary" or "personal writing" → strong match
- "budgeting" or "personal finance" → strong match
- "reading list" or "bookmarks" or "save for later" → strong match
- "recipe manager" or "meal planner" → strong match
- "freelancer CRM" or "client tracker" → moderate match
- "personal portfolio" or "showcase site" → moderate match
- "note-taking" or "knowledge base (personal)" → moderate match
