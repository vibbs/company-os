# Universal UX Baseline

Non-negotiable UX patterns every Company OS product must implement, regardless of design archetype. These are the minimum quality bar — skip none of them.

---

## 1. Empty States

Every container that can be empty (tables, lists, dashboards, feeds, search results) must show a meaningful empty state.

**Pattern:**
```
┌──────────────────────────────────┐
│                                  │
│           [Icon, muted]          │
│                                  │
│       No projects yet            │  ← Headline: what's missing
│   Create your first project to   │  ← Description: what to do
│   start tracking work.           │
│                                  │
│      [ + New Project ]           │  ← CTA: most obvious next action
│                                  │
└──────────────────────────────────┘
```

**Rules:**
- Never show a blank container — always icon + headline + description + CTA
- Icon should be contextual (not a generic "empty box")
- CTA should be the single most logical next action
- Description should explain *why* it's empty and *how* to fill it
- For filtered views with no results: "No results match your filters" + "Clear filters" CTA
- For error-caused empty: show the error state pattern instead (see section 3)

---

## 2. Loading States

Use skeleton screens that match the shape of the loaded content. Never use a centered spinner for content areas.

**Pattern:**
```
┌──────────────────────────────────┐
│ ████████████  ██████             │  ← Skeleton matching row layout
│ ██████████████████  ████         │
│ ████████████  ██████████         │
│ ██████████████  ████             │
│                                  │
└──────────────────────────────────┘
```

**Rules:**
- Skeleton screens for all content areas (tables, cards, lists, profiles)
- Match the layout dimensions of the loaded content to prevent layout shift
- Use subtle pulse animation (opacity 0.4 → 0.7, 1.5s ease-in-out loop)
- Show skeleton within 100ms if data isn't ready — never show blank then jump to skeleton
- For progressive loading (lists, feeds): show skeletons for remaining items as loaded items appear
- For actions (button clicks, form submits): use inline loading indicator (spinner inside button, disable button)
- For navigation: keep current page visible until next page is ready (optimistic navigation)
- Spinners are acceptable ONLY for: inline button loading, pull-to-refresh, and overlay actions

---

## 3. Error States

Three tiers: field-level, action-level, and page-level.

### Field-Level (inline validation)
```
┌──────────────────────────────────┐
│ Email                            │
│ ┌──────────────────────────────┐ │
│ │ not-an-email                 │ │  ← Input with error border (red/danger)
│ └──────────────────────────────┘ │
│ ⚠ Please enter a valid email     │  ← Error text below field, red/danger color
└──────────────────────────────────┘
```

### Action-Level (toast notification)
```
┌──────────────────────────────────────┐
│ ✕  Failed to save changes.  [Retry] │  ← Toast: bottom-right, auto-dismiss 8s
└──────────────────────────────────────┘
```

### Page-Level (full-page error)
```
┌──────────────────────────────────┐
│                                  │
│           [Error icon]           │
│                                  │
│     Something went wrong         │  ← Clear, non-technical headline
│   We couldn't load this page.    │  ← Brief explanation
│   Please try again.              │
│                                  │
│   [ Retry ]  [ Go Back ]        │  ← Always include recovery actions
│                                  │
└──────────────────────────────────┘
```

**Rules:**
- Field errors: show on blur (not on keystroke), clear when user starts fixing
- Action errors: toast with retry button, auto-dismiss 8s, allow manual dismiss
- Page errors (404, 500, network): full-page with recovery actions (retry, go back, go home)
- Never show raw error codes or stack traces to users
- Always include a recovery action — never dead-end the user
- For network errors: "Check your connection and try again" + Retry button
- Log technical details to error tracking (Sentry, etc.), show human message to user

---

## 4. Form Validation

Validate inline, in real-time. Never make users submit a form to discover errors.

**Rules:**
- Validate on blur (when user leaves a field) — not on every keystroke
- Show error message directly below the field (not at top of form)
- Required fields: validate on blur if empty after user has interacted
- Format validation (email, phone, URL): validate on blur with clear format hint
- Async validation (username taken, email exists): show loading indicator, then result
- On submit: scroll to first error field, focus it, shake or highlight the field
- Success state: subtle green check or border on valid fields (optional, archetype-dependent)
- Disable submit button only while submitting — never disable to indicate "form invalid"
- Multi-step forms: validate current step before allowing navigation to next step

---

## 5. Success Feedback

Every user action that changes state must have visible confirmation.

**Patterns:**

| Action Type | Feedback | Duration |
|---|---|---|
| Save / Update | Toast: "Changes saved" or inline "Saved ✓" | 3s auto-dismiss |
| Create | Toast: "Project created" with link to new item | 5s auto-dismiss |
| Delete | Toast: "Item deleted" with Undo button | 5s (undo window) |
| Bulk action | Toast: "12 items archived" with Undo button | 5s |
| Send / Publish | Toast: "Email sent" or "Published successfully" | 3s |
| Copy to clipboard | Inline: icon changes to checkmark briefly | 2s |
| Toggle | Immediate visual state change (no toast needed) | Instant |

**Rules:**
- Auto-save: show subtle "Saving..." → "Saved" indicator near the content, not as toast
- Optimistic updates: show success immediately, roll back on error with explanation
- Toast position: consistent location (bottom-right or bottom-center, archetype-dependent)
- Maximum 1 toast visible at a time — new toasts replace old ones
- Always include Undo for destructive actions (see section 6)

---

## 6. Destructive Actions

Any action that permanently removes or significantly changes data requires confirmation.

**Pattern:**
```
┌──────────────────────────────────┐
│  Delete project "Alpha"?         │
│                                  │
│  This will permanently delete    │
│  the project and all 24 tasks.   │  ← Specific impact description
│  This action cannot be undone.   │
│                                  │
│          [ Cancel ]  [ Delete ]  │  ← Destructive button in red/danger
└──────────────────────────────────┘
```

**Rules:**
- Confirmation dialog: clear description of what will be deleted/changed and the impact
- Destructive button: red/danger color, right-aligned, explicit verb ("Delete" not "OK")
- Cancel button: neutral color, left of destructive button, easily accessible
- For high-impact actions (delete account, remove team member): require typing confirmation
- Undo window: 5-10 seconds after action where user can reverse it (soft delete → hard delete after window)
- Batch destructive actions: show count ("Delete 12 items?") and list affected items if < 10
- Never chain destructive actions — one confirmation per destructive operation

---

## 7. Keyboard Navigation

Every interactive element must be keyboard-accessible.

**Rules:**
- Tab order follows visual layout (left-to-right, top-to-bottom)
- Focus ring: visible 2px solid outline with 2px offset, uses accent/primary color
- Never remove focus styles — restyle them to match the design, but keep them visible
- Escape: closes modals, drawers, dropdowns, popovers (closest open layer first)
- Enter: submits forms, activates buttons, confirms dialogs
- Arrow keys: navigate within lists, menus, tabs, radio groups
- Focus trap: modals and drawers trap focus — Tab cycles within, Escape exits
- Skip links: "Skip to main content" link as first focusable element (visually hidden until focused)
- No mouse-only interactions — every hover action must have a keyboard equivalent

---

## 8. Accessible Contrast

Meet WCAG 2.1 AA minimum contrast ratios in both light and dark modes.

**Requirements:**
- Normal text (< 18px, or < 14px bold): 4.5:1 contrast ratio minimum
- Large text (≥ 18px, or ≥ 14px bold): 3:1 contrast ratio minimum
- UI components and graphical objects: 3:1 contrast ratio minimum
- Focus indicators: 3:1 contrast ratio against adjacent colors
- Placeholder text: 4.5:1 ratio (don't use light gray on white)

**Common Violations to Avoid:**
- Light gray text on white backgrounds (#999 on #FFF = 2.85:1 — fails)
- Colored text on colored backgrounds without checking contrast
- Disabled states that are completely invisible (use opacity 0.4 minimum, not 0.2)
- Status indicators that rely solely on color (add icon or text label)

**Dark Mode Specific:**
- Don't just invert colors — redesign surfaces for dark backgrounds
- Use off-white text (#E5E5E5) not pure white (#FFFFFF) on dark backgrounds to reduce glare
- Elevation in dark mode: lighter surfaces = higher elevation (opposite of light mode shadows)

---

## 9. URL Reflects State

Users should be able to bookmark, share, and refresh without losing their context.

**Rules:**
- Filters and sort: persist in URL query params (`?status=active&sort=created`)
- Pagination: persist in URL (`?page=3` or `?cursor=abc123`)
- Selected tab: persist in URL hash or path (`/settings/billing` or `/settings#billing`)
- Modal/drawer open state: persist in URL if the content is linkable (`?detail=item-123`)
- Search query: persist in URL (`?q=search+term`)
- View mode: persist in URL (`?view=grid` or `?view=list`)
- Browser back/forward: must work naturally — back closes modal, returns to previous filter state
- Deep links: every meaningful state should be directly accessible via URL
- Don't persist ephemeral state (toast visibility, dropdown open, hover state)

---

## 10. Responsive Behavior

Every screen must work on viewports from 320px to 2560px+.

**Breakpoints:**
- Mobile: 320px – 767px
- Tablet: 768px – 1023px
- Desktop: 1024px – 1439px
- Large desktop: 1440px+

**Rules:**
- Sidebar: visible on desktop, collapses to hamburger menu on tablet/mobile
- Tables: horizontal scroll on small screens (never truncate data columns)
- Cards: reflow from grid to single column on mobile
- Touch targets: minimum 44x44px on all interactive elements
- No horizontal overflow — ever. Test at 320px width.
- Font sizes: minimum 14px for body text on mobile (never smaller)
- Modals on mobile: full-screen or bottom sheet (never floating centered modal)
- Forms on mobile: single-column layout, full-width inputs
- Navigation on mobile: bottom tab bar or hamburger menu (not both)
- Images: responsive with proper aspect ratio (never stretched or cropped incorrectly)

---

## Checklist

Use this checklist when building or reviewing any component:

```
□ Empty state: icon + headline + description + CTA
□ Loading state: skeleton matching content layout
□ Error state: inline (fields), toast (actions), full page (routes)
□ Form validation: inline on blur, error below field
□ Success feedback: visible confirmation for every state change
□ Destructive actions: confirmation dialog + undo window
□ Keyboard: tab order, focus ring, Escape closes, Enter activates
□ Contrast: WCAG AA in both light and dark modes
□ URL state: filters, pagination, selection persisted
□ Responsive: works at 320px, touch targets 44px+, no overflow
```
