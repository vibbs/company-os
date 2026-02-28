# Framer Archetype: "Canvas-to-Wow"

## Overview

### Vibe
Bold, editorial, high visual fidelity. The product itself is a showcase. Fluid animations, expressive typography, and rich visual effects make every interaction feel like a polished demo. The interface doesn't just work — it impresses.

### Philosophy
Framer blurred the line between a design tool and a live website. While most builders feel like restrictive grids, Framer feels like a creative canvas that happens to produce production code. The philosophy: if the building process feels premium, the output will be premium. Large typography, bold gradients, smooth page transitions, and generous whitespace create an editorial quality that makes everything feel intentional and high-end.

### Best For
- Marketing website builders and landing page tools
- Portfolio builders and creative agency tools
- Presentation and deck builders
- Email template designers
- Brand asset managers
- Visual content creators
- Any product where the UI itself is part of the sales argument

### Not Great For
- Dense data tools or admin dashboards (too much whitespace wastes screen real estate)
- Real-time operations tools (animation overhead conflicts with urgency)
- Developer CLIs or terminal-adjacent products (wrong aesthetic register)
- Products requiring rapid keyboard-driven workflows (scroll-and-browse navigation is too slow)

### Reference Products
Think: Framer, Squarespace, Webflow (publishing view), Readymag, Pitch, Canva

---

## Dimension Tags

| Dimension | Position | Scale |
|-----------|----------|-------|
| Density | Low | `sparse ■·············· compact` |
| Warmth | Variable | `warm ·······■······· cool` |
| Sophistication | Very High | `playful ·············■ refined` |
| Interaction | Scroll + Visual | `point ·····■·········· keyboard` |

---

## Visual Tokens

### Colors

#### Light Mode
| Token | Value | Usage |
|-------|-------|-------|
| `--bg-primary` | `#FFFFFF` | Page background |
| `--bg-surface` | `#FAFAFA` | Cards, panels, sections |
| `--bg-surface-raised` | `#FFFFFF` | Elevated surfaces (modals, popovers) |
| `--bg-surface-sunken` | `#F4F4F5` | Inset areas, code blocks, input backgrounds |
| `--border-default` | `#E4E4E7` | Default borders |
| `--border-subtle` | `#F1F1F3` | Subtle separators, section dividers |
| `--text-primary` | `#0A0A0A` | Headings, body text |
| `--text-secondary` | `#52525B` | Descriptions, subheadings, captions |
| `--text-tertiary` | `#A1A1AA` | Placeholders, disabled text, hints |
| `--accent-gradient-start` | `#7C3AED` | Gradient accent — purple start (primary brand) |
| `--accent-gradient-end` | `#2563EB` | Gradient accent — blue end (primary brand) |
| `--accent-alt-start` | `#F97316` | Gradient accent — orange start (secondary) |
| `--accent-alt-end` | `#EC4899` | Gradient accent — pink end (secondary) |
| `--accent-solid` | `#7C3AED` | Fallback solid accent for non-gradient contexts |
| `--accent-muted` | `#EDE9FE` | Selected state, subtle highlight backgrounds |
| `--status-success` | `#16A34A` | Success confirmations, done states |
| `--status-warning` | `#D97706` | Warnings, degraded states |
| `--status-error` | `#DC2626` | Errors, destructive actions |
| `--status-info` | `#2563EB` | Informational states, tips |

#### Dark Mode (Preferred)
| Token | Value | Usage |
|-------|-------|-------|
| `--bg-primary` | `#0A0A0A` | Page background |
| `--bg-surface` | `#141414` | Cards, panels, sections |
| `--bg-surface-raised` | `#1A1A1A` | Cards with depth, popovers, modals |
| `--bg-surface-sunken` | `#0D0D0D` | Inset areas, code blocks |
| `--border-default` | `#27272A` | Default borders |
| `--border-subtle` | `#1C1C1E` | Subtle separators, glass morphism borders |
| `--text-primary` | `#FAFAFA` | Headings, body text |
| `--text-secondary` | `#A1A1AA` | Descriptions, subheadings, captions |
| `--text-tertiary` | `#52525B` | Placeholders, disabled text, hints |
| `--accent-gradient-start` | `#A78BFA` | Gradient accent — purple start (lightened for dark bg) |
| `--accent-gradient-end` | `#60A5FA` | Gradient accent — blue end (lightened for dark bg) |
| `--accent-alt-start` | `#FB923C` | Gradient accent — orange start |
| `--accent-alt-end` | `#F472B6` | Gradient accent — pink end |
| `--accent-solid` | `#A78BFA` | Fallback solid accent for non-gradient contexts |
| `--accent-muted` | `#1E1B2E` | Selected state, subtle highlight backgrounds |
| `--status-success` | `#22C55E` | Success confirmations |
| `--status-warning` | `#FBBF24` | Warnings, degraded states |
| `--status-error` | `#F87171` | Errors, destructive actions |
| `--status-info` | `#60A5FA` | Informational states |

### Typography
| Token | Value | Usage |
|-------|-------|-------|
| `--font-family-display` | `'Geist', 'Satoshi', 'Plus Jakarta Sans', system-ui, sans-serif` | Hero headings, display text |
| `--font-family-body` | `'Geist', 'Plus Jakarta Sans', system-ui, sans-serif` | Body text, UI copy |
| `--font-size-xs` | `12px` | Labels, captions, metadata |
| `--font-size-sm` | `14px` | Secondary UI text, footnotes |
| `--font-size-base` | `18px` | Body text (larger than typical — editorial feel) |
| `--font-size-lg` | `24px` | Subheadings, card titles, section labels |
| `--font-size-xl` | `32px` | Page titles, feature names |
| `--font-size-2xl` | `48px` | Hero headings (default) |
| `--font-size-3xl` | `64px` | Hero headings (large viewport, full-bleed sections) |
| `--font-weight-thin` | `200` | Large display headings (editorial contrast technique) |
| `--font-weight-light` | `300` | Supporting hero copy, large captions |
| `--font-weight-normal` | `400` | Body text |
| `--font-weight-medium` | `500` | UI labels, button text, nav items |
| `--font-weight-semibold` | `600` | Card titles, feature names |
| `--font-weight-bold` | `700` | Emphasis within body text |
| `--line-height-tight` | `1.1` | Hero display headings (very large type) |
| `--line-height-snug` | `1.25` | Section headings, card titles |
| `--line-height-normal` | `1.6` | Body text (looser than typical — editorial breathing room) |
| `--letter-spacing-tight` | `-0.03em` | Display headings (48px+, creates editorial tightness) |
| `--letter-spacing-snug` | `-0.01em` | Medium headings (24-32px) |
| `--letter-spacing-normal` | `0` | Body text, UI copy |

### Spacing Scale
| Token | Value | Usage |
|-------|-------|-------|
| `--space-1` | `8px` | Base unit — minimum gap between inline elements |
| `--space-2` | `12px` | Tight padding (buttons, badges, small chips) |
| `--space-3` | `16px` | Standard padding (inputs, compact cards) |
| `--space-4` | `24px` | Between elements within a section |
| `--space-5` | `32px` | Card internal padding, form group spacing |
| `--space-6` | `48px` | Between major components on a page |
| `--space-7` | `64px` | Between major page sections |
| `--space-8` | `96px` | Large section breaks, hero breathing room |
| `--space-9` | `128px` | Maximum section padding (full-bleed hero areas) |
| Note | — | Whitespace is a primary design element — be generous. When in doubt, add more space. |

### Border Radius
| Token | Value | Usage |
|-------|-------|-------|
| `--radius-sm` | `8px` | Small badges, tags, compact chips |
| `--radius-md` | `12px` | Buttons, inputs, small cards — default interactive element radius |
| `--radius-lg` | `16px` | Cards, panels, large interactive elements |
| `--radius-xl` | `24px` | Feature showcase cards, hero elements |
| `--radius-full` | `9999px` | Pill buttons (primary CTAs), avatars, status dots |
| Note | — | Avoid sharp corners (0-4px radius). Every element should feel like a floating object, not a rigid box. |

### Shadows
| Token | Value | Usage |
|-------|-------|-------|
| `--shadow-sm` | `0 2px 8px rgba(0,0,0,0.06), 0 1px 3px rgba(0,0,0,0.04)` | Subtle card lift |
| `--shadow-md` | `0 8px 30px rgba(0,0,0,0.12), 0 2px 8px rgba(0,0,0,0.06)` | Cards, panels — primary card shadow |
| `--shadow-lg` | `0 20px 60px rgba(0,0,0,0.16), 0 8px 24px rgba(0,0,0,0.08)` | Modals, feature showcase cards, hero elements |
| `--shadow-glow-purple` | `0 0 40px rgba(124,58,237,0.25), 0 0 80px rgba(124,58,237,0.10)` | Accent glow on CTA buttons, active elements |
| `--shadow-glow-blue` | `0 0 40px rgba(37,99,235,0.20), 0 0 80px rgba(37,99,235,0.08)` | Info highlights, gradient endpoint glow |
| `--shadow-glass` | `0 8px 32px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.08)` | Glass morphism surfaces (dark mode panels, overlays) |
| Note (dark mode) | — | In dark mode, multiply shadow opacity by 2–3x. Dark surfaces need stronger shadows to read depth. |

### Icons
| Property | Value |
|----------|-------|
| Set | Lucide (primary) or custom SVG for brand moments |
| Default size | `20px` |
| Hero / feature size | `24px` |
| Stroke weight | `1.5px` (outlined) or filled variants for emphasis points |
| Color | Inherits from text (`currentColor`) or uses gradient fill for hero icons |
| Style | Outlined by default; filled only for active/selected states and hero feature icons |

### Animation
| Token | Value | Usage |
|-------|-------|-------|
| `--duration-instant` | `100ms` | Micro-interactions (hover color shifts, button press) |
| `--duration-fast` | `200ms` | Tooltip appear, badge toggle, icon swap |
| `--duration-normal` | `300ms` | Card entrance, panel open, tab switch |
| `--duration-slow` | `500ms` | Page section reveal, hero entrance, modal appear |
| `--duration-cinematic` | `800ms` | Full-page transitions, onboarding reveals |
| `--easing-default` | `cubic-bezier(0.25, 0.1, 0.25, 1)` | Standard easing for most transitions |
| `--easing-spring` | `cubic-bezier(0.34, 1.56, 0.64, 1)` | Spring physics for element entrances (slight overshoot) |
| `--easing-smooth` | `cubic-bezier(0.4, 0, 0.2, 1)` | Material-style ease for scrolls and reveals |
| Scroll reveals | Fade-up with `translateY(24px) → translateY(0)` | Elements animate in as user scrolls down |
| Parallax | Subtle `translateY` at 0.1–0.2x scroll rate | Background layers, hero imagery, decorative shapes |
| Page transitions | Fade + subtle scale (`scale(0.98) → scale(1)`) | Between routes/sections |
| Hover on cards | `translateY(-4px)` + shadow deepens | Creates floating card effect |
| Philosophy | Animation is a feature, not a detail. Every entrance, transition, and hover state should feel deliberate. Aim for spring physics over linear easing. Never remove animation to "simplify" — reduce duration instead. |

---

## UX Patterns

### Navigation
- **Layout**: Minimal top nav — logo left, 3-4 links center or right, single CTA button far right. No sidebar navigation. Content IS the navigation.
- **Scroll-based sections**: Full-page scroll snapping between major sections on marketing/landing pages. Each section is a distinct visual moment.
- **Dashboard variant**: Floating toolbar at top (not docked to edge) + breadcrumb trail below it. The toolbar itself has rounded corners and a shadow — it feels like a floating element, not a system chrome bar.
- **Mobile nav**: Hamburger that reveals a full-screen overlay with large type menu items and smooth slide-in animation.
- **Active states**: Underline slides between nav items on hover (animated `width` transition), not a background highlight.
- **CTA button**: Pill shape (`border-radius: 9999px`), gradient background, subtle glow shadow. Clearly the most visually distinct element in the nav.

### Data Entry
- **Visual builders**: Drag-and-drop canvas as the primary input paradigm. Direct manipulation with live preview is the default — not form fields.
- **WYSIWYG editors**: What you edit is what gets published. No separate "edit" and "preview" modes for content editing.
- **Property panels**: Contextual sidebar panels slide in when an element is selected on the canvas. Panel dismisses when nothing is selected.
- **Live preview**: Changes reflect in a preview pane in real time. The preview IS the source of truth for what the output looks like.
- **Form fields** (when forms are needed): Large, generous input height (`52-56px`), `border-radius: 12px`, prominent label above input, subtle border that brightens on focus with a gradient glow.
- **Input focus**: On focus, the border transitions to a gradient (`var(--accent-gradient-start)` → `var(--accent-gradient-end)`). Focus is visually celebratory, not just functional.

### Lists & Tables
- **Card-based grids**: Default list view is a thumbnail grid (2-4 columns), not a data table. Items display a large visual preview, title, and minimal metadata.
- **Gallery-first**: Visual browsing over text scanning. If an item has a thumbnail, the thumbnail should dominate.
- **Hover reveals**: Additional actions (edit, duplicate, delete) appear on card hover via an animated overlay. The card itself lifts (`translateY(-4px)`) on hover.
- **Sorting and filtering**: Minimal controls above the grid — a single filter bar that slides down when activated. Filter chips appear as pill badges.
- **List view toggle**: Users can switch between grid and list views. List view retains the generous row height (`56-64px`) and shows thumbnails inline.
- **Empty state**: Illustrated empty state with a large icon, short copy, and a prominent CTA. Empty states are invitations, not apologies.
- **Loading state**: Shimmer skeleton cards matching the exact card shape. No spinner.

### Feedback & State
- **Success**: Celebratory micro-animation — confetti burst, checkmark that draws itself, or card that bounces gently. Success is a moment worth marking.
- **Error**: Element shakes horizontally (`translateX` oscillation, 3 cycles, 400ms total) + red glow shadow replaces the default shadow. Clear inline error message below the field.
- **Loading**: Animated placeholder shimmer (`background: linear-gradient(90deg, ...)` that travels left to right). Matches the shape of the content being loaded exactly.
- **Toasts**: Bottom-center position (not bottom-right — more editorial, more centered). Pill-shaped, not rectangular. Slide up from bottom with spring easing. Auto-dismiss 4s.
- **Publish / deploy state**: Special multi-step progress indicator. Each step has a distinct visual state (waiting, active with pulse animation, complete with checkmark). This is a "moment" in the product — treat it with ceremony.
- **Optimistic updates**: Apply immediately, roll back gracefully if the server rejects. Do not make users wait for confirmation of low-stakes actions.

### Progressive Disclosure
- **Mode-based disclosure**: The UI shifts meaningfully between modes — Edit mode, Preview mode, Publish mode. Each mode hides irrelevant controls and surfaces mode-specific ones. The toolbar and panel contents transform per mode.
- **Context-sensitive panels**: When a user selects an element, the relevant property panel appears. When they deselect, it hides. No persistent empty panels.
- **Collapsed sections**: Advanced options are grouped in collapsible accordions within panels. Default collapsed. Expand on user intent, not on hover.
- **Tooltips for secondary info**: Hover a control to see its name, shortcut, and a one-line description. Tooltips use the glass morphism style (dark semi-transparent background with a subtle border).
- **Progressive feature access**: Basic features visible immediately. Advanced features revealed as user demonstrates intent (attempts an advanced action, reaches a certain usage threshold, or upgrades).

### Interaction Style
- **Scroll-driven exploration**: The primary navigation model on marketing/landing pages is scroll. Each scroll section is a distinct visual narrative beat.
- **Scroll-triggered animations**: Elements animate into view as they enter the viewport. Use `IntersectionObserver` — not scroll-position arithmetic. Stagger sibling elements by `60-80ms` for a cascading entrance effect.
- **Parallax hints**: Background layers and decorative elements move at a slower scroll rate than content (`0.1–0.2x` scroll multiplier). Keep it subtle — the point is depth, not distraction.
- **Cursor changes**: The cursor changes to indicate interactive surfaces. Canvas areas use a crosshair or custom canvas cursor. Draggable elements show a grab/grabbing cursor. This is a signal to the user that the UI is alive.
- **Smooth scroll snapping**: Between major page sections, apply `scroll-snap-type: y mandatory` with `scroll-snap-align: start`. Gives scroll a polished, cinematic feel.
- **Hover reveals on cards**: All interactive card elements reveal secondary actions (edit, share, duplicate) via a semi-transparent overlay that fades in on hover. The overlay uses `backdrop-filter: blur(4px)` for glass effect.
- **Drag-and-drop**: Primary interaction for canvas-based features. Show a ghost element (50% opacity, shadow) during drag. Highlight drop targets with a gradient border.

---

## ASCII Preview

```
┌────────────────────────────────────────────────────────────────┐
│  ◆ Studio          Projects   Templates   Publish      [Sign in]│
│                                                                │
│                                                                │
│              Your websites,                                    │
│                 reimagined.                                     │
│                                                                │
│         Start with a template or blank canvas                  │
│                                                                │
│              [ Get Started ]                                   │
│                                                                │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐ │
│  │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│  │ ░░░░░░░░░░░░░░░░│  │ ▒▒▒▒▒▒▒▒▒▒▒▒│ │
│  │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│  │ ░░░░░░░░░░░░░░░░│  │ ▒▒▒▒▒▒▒▒▒▒▒▒│ │
│  │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│  │ ░░░░░░░░░░░░░░░░│  │ ▒▒▒▒▒▒▒▒▒▒▒▒│ │
│  │                  │  │                  │  │              │ │
│  │  Portfolio Site  │  │  SaaS Landing    │  │  Blog Theme  │ │
│  │  Modern & clean  │  │  Bold gradients  │  │  Editorial   │ │
│  └──────────────────┘  └──────────────────┘  └──────────────┘ │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

---

## Product-to-Archetype Mapping

Use this archetype when the user's product matches these patterns:
- "marketing website builder" or "landing page tool" → strong match
- "portfolio builder" or "creative portfolio tool" → strong match
- "presentation builder" or "deck tool" → strong match
- "brand asset manager" or "visual content creator" → strong match
- "email template designer" → strong match
- "creative agency tool" or "design showcase" → strong match
- "no-code website builder" → strong match
- "visual storytelling tool" or "interactive report builder" → moderate match
- "blog platform with emphasis on design" → moderate match
- "e-commerce storefront builder" → moderate match (if design is a differentiator)
