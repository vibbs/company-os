---
name: mobile-readiness
description: Defines responsive web design patterns and React Native/Expo mobile architecture ensuring all products work on every screen size. Use when building mobile-first web UIs, planning native mobile apps, or adding PWA support.
allowed-tools: Read, Grep, Glob, Bash, Write
---

# Mobile Readiness

## Reference
- **ID**: S-ENG-09
- **Category**: Engineering
- **Inputs**: company.config.yaml (platforms section, tech_stack), RFCs
- **Outputs**: mobile patterns guide (standards/mobile/), per-feature responsive/mobile specifications
- **Used by**: Engineering Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose

Ensure every product surface works across all screen sizes and platforms. This skill produces responsive web patterns, React Native/Expo native mobile architecture guidance, and PWA configuration -- driven by the platforms configured in `company.config.yaml`.

## When to Use

- New feature needs responsive design specifications
- Product is adding native mobile (iOS/Android) support
- PWA support is being configured
- Existing UI needs mobile optimization

## Procedure

### Step 1: Load Context

1. Read `company.config.yaml` for:
   - `platforms.targets` (web, mobile-web, ios, android)
   - `platforms.mobile_framework` (array: expo, react-native-cli, etc.)
   - `platforms.responsive` (true/false)
   - `platforms.pwa` (true/false)
   - `tech_stack.framework`
2. Read relevant RFCs for the feature being built.
3. Check `standards/mobile/` for any existing mobile patterns.

### Step 2: Responsive Web Patterns

If `platforms.targets` includes "web" or "mobile-web", produce `standards/mobile/responsive-web.md` covering the following.

**Required Viewport Configuration**:

```html
<meta name="viewport" content="width=device-width, initial-scale=1.0">
```

**Breakpoint System**:

| Breakpoint | Range | Layout |
|------------|-------|--------|
| Mobile | 320px - 767px | Single column, stacked layout |
| Tablet | 768px - 1023px | 2-column where appropriate |
| Desktop | 1024px - 1439px | Full layout |
| Large | 1440px+ | Max-width container, centered |

**Touch Targets**:

- Minimum size: 44x44px (WCAG 2.5.5 AAA)
- Minimum spacing: 8px between targets
- No hover-only interactions (must work with tap)

**Mobile-First CSS**:

- Write base styles for mobile, add complexity with `min-width` media queries
- Avoid `max-width` queries (they override mobile-first approach)
- Use relative units (`rem`, `em`, `%`, `vh`/`vw`) over fixed pixels
- Example pattern:

```css
/* Base: mobile */
.container { padding: 1rem; }

/* Tablet and up */
@media (min-width: 768px) {
  .container { padding: 2rem; max-width: 720px; }
}

/* Desktop and up */
@media (min-width: 1024px) {
  .container { padding: 2rem; max-width: 960px; }
}
```

**Image Optimization**:

- `srcset` for responsive images
- Lazy loading for below-fold images (`loading="lazy"`)
- WebP format with fallback
- Maximum image width: 100% of container

**Performance Budget**:

| Metric | Target |
|--------|--------|
| LCP (Largest Contentful Paint) | < 2.5s on 3G |
| FID (First Input Delay) | < 100ms |
| CLS (Cumulative Layout Shift) | < 0.1 |
| Total page weight (initial load, mobile) | < 500KB |

**Typography**:

- Minimum body text: 16px (prevents iOS zoom on focus)
- Line height: 1.5 minimum for readability
- No horizontal scrolling at any breakpoint

**Forms on Mobile**:

- Use appropriate input types (`email`, `tel`, `number`) for keyboard optimization
- Labels above inputs (not beside)
- Single column form layout on mobile
- Clear error states with inline validation

### Step 3: React Native / Expo Patterns

If `platforms.targets` includes "ios" or "android", produce `standards/mobile/native-mobile.md` covering the following.

**Project Structure** (per `mobile_framework`):

- **Expo (managed)**: `app/` directory with file-based routing (Expo Router)
- **Expo (bare)**: `ios/` and `android/` directories exposed alongside JS
- **React Native CLI**: standard RN structure with platform folders

**Navigation**:

- Expo Router (recommended for Expo): file-based routing in `app/`
- React Navigation: Stack, Tab, Drawer navigators
- Deep linking configuration for both platforms

**Platform-Specific Considerations**:

- **iOS**: Safe Area handling (`SafeAreaView`), status bar styling, home indicator inset
- **Android**: back button handling, status bar translucency, navigation bar
- **Keyboard handling**: `KeyboardAvoidingView`, keyboard dismiss on tap outside inputs

**Shared Code Strategy**:

- React Native Web for code sharing between web and native
- Platform-specific files: `.ios.tsx`, `.android.tsx`, `.web.tsx`
- Shared business logic in platform-agnostic modules, platform-specific UI where needed

**Native Modules**:

| Capability | Expo | React Native CLI |
|------------|------|-----------------|
| Camera | expo-camera | react-native-camera |
| Push notifications | expo-notifications | react-native-push-notification |
| Biometrics | expo-local-authentication | react-native-biometrics |
| Secure storage | expo-secure-store | react-native-keychain |
| General storage | AsyncStorage | AsyncStorage |

**App Store Requirements**:

- **iOS**: screenshots (6.7", 6.5", 5.5"), app description, privacy nutrition labels
- **Android**: screenshots, feature graphic, content rating questionnaire
- **Both**: privacy policy URL required

**OTA Updates**:

- Expo Updates: JS bundle updates without app store review
- Update strategies: automatic (on launch), manual (check for update), forced (critical fixes)
- Rollback: revert to previous bundle if crash rate increases

### Step 4: PWA Patterns

If `platforms.pwa` is true, document the following:

- **Service worker registration**: register on load, handle update lifecycle
- **Web app manifest**: icons (192px, 512px), theme color, background color, `display: standalone`
- **Offline-first caching strategy**: cache static assets on install, network-first for API calls with cache fallback
- **Install prompt handling**: listen for `beforeinstallprompt`, show custom install UI at appropriate moment

### Step 5: Per-Feature Mobile Specification

For each feature being built, answer:

1. **Responsive behavior**: how does this feature adapt across breakpoints? (stacking, hiding, simplifying)
2. **Touch interactions**: does this feature need swipe, long press, pinch, or other gestures?
3. **Offline behavior**: does this feature work offline? What degrades gracefully?
4. **Platform-specific UI**: are there iOS/Android differences in this feature's presentation?
5. **Performance impact**: does this feature affect the mobile performance budget? (heavy images, large JS bundles, etc.)

### Step 5.5: App Store Optimization (ASO)

Only produce this section when `platforms.targets` includes "ios" or "android".

#### Keyword Research
- **Primary keyword**: the single most important term users search for your app category
- **Long-tail keywords**: 5-10 specific phrases (lower competition, higher intent)
- **Competitor keywords**: terms where top competitors rank
- Research tools: App Store Connect search metrics, Google Play Console acquisition reports, third-party (Sensor Tower, App Annie, AppFollow)

#### Metadata Optimization

| Element | iOS Limit | Android Limit | Best Practice |
|---------|-----------|---------------|---------------|
| Title | 30 chars | 30 chars | Primary keyword + brand name |
| Subtitle | 30 chars | 80 chars (short desc) | Secondary keyword + value prop |
| Keyword field | 100 chars | N/A (use description) | Comma-separated, no spaces, no duplicates |
| Description | 4000 chars | 4000 chars | First 3 lines visible without "more" — front-load benefits |

- Title formula: `[Primary Keyword] - [Brand Name]` or `[Brand Name]: [Primary Keyword]`
- Never stuff keywords — write for humans first, algorithms second
- Update metadata quarterly based on search trend changes

#### Screenshot Strategy
- **First 3 screenshots are the conversion funnel** — they appear in search results
  - Screenshot 1: Hero shot — the single most impressive feature or outcome
  - Screenshot 2: Key differentiator — what makes this app different
  - Screenshot 3: Social proof or secondary feature — builds confidence
- Screenshots 4-8: additional features, settings, edge cases
- Format: device frame + annotation text (benefit, not feature name)
- A/B test screenshot order using App Store Connect experiments or Google Play experiments

#### Review Management
- **Response templates**: thank positive reviewers, acknowledge negative feedback with resolution
- **Rating prompt timing**: after 3+ successful sessions AND a positive action (never on first launch, never after an error)
- **Star rating monitoring**: track weekly average, investigate any drop >0.2 stars
- **Feature request extraction**: tag reviews mentioning missing features → feed to feedback-synthesizer

#### ASO A/B Testing
- **iOS**: App Store Connect product page optimization (up to 3 treatments)
- **Android**: Google Play Store listing experiments (up to 5 variants)
- Test one element at a time: icon, screenshots, description, or title
- Run for minimum 7 days, need 90% confidence before declaring winner

### Step 6: Verify

- Responsive breakpoints cover all screen sizes (320px through 1440px+)
- Touch targets meet 44x44px minimum
- Performance budget is achievable with the planned feature set
- Platform-specific patterns are documented for all configured targets
- Run `./tools/artifact/validate.sh` on any produced artifacts

## Quality Checklist

- [ ] Viewport meta tag specified
- [ ] Breakpoints defined with layout guidance per breakpoint
- [ ] Touch targets minimum 44x44px enforced
- [ ] Mobile-first CSS approach documented
- [ ] Image optimization patterns specified (srcset, lazy loading, WebP)
- [ ] Performance budget defined (LCP, FID, CLS thresholds)
- [ ] If native mobile: project structure, navigation, platform considerations documented
- [ ] If PWA: service worker, manifest, offline strategy documented
- [ ] Per-feature template includes responsive, touch, offline, platform sections
- [ ] If native mobile: ASO keyword research completed (primary + long-tail)
- [ ] If native mobile: metadata optimized within character limits
- [ ] If native mobile: first 3 screenshots form a conversion narrative
- [ ] If native mobile: review management and rating prompt strategy defined
