---
name: test-plan-generator
description: Generates comprehensive test plans from PRD acceptance criteria. Use when a new feature needs a structured testing strategy before implementation begins.
---

# Test Plan Generator

## Reference
- **ID**: S-QA-01
- **Category**: QA
- **Inputs**: PRD with acceptance criteria, architecture context, risk areas
- **Outputs**: test plan document → artifacts/qa/
- **Used by**: QA Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose
Transforms PRD acceptance criteria into a structured test plan covering functional, edge-case, integration, and regression scenarios, ensuring every requirement has verifiable test coverage before code is written.

## Procedure
1. Read the PRD and extract all acceptance criteria.
2. For each acceptance criterion, derive one or more test scenarios.
3. Classify each scenario: functional, edge case, integration, regression, or destructive.
4. Define test data requirements for each scenario.
5. Identify dependencies: APIs, services, or fixtures needed for test execution.
6. Prioritize scenarios by risk: high-risk paths get more thorough coverage.
7. Define pass/fail criteria for each scenario.
8. Map scenarios to test types: unit, integration, E2E, manual exploratory.
9. Estimate effort for test implementation.
10. Save the test plan to `artifacts/qa/`.
11. Validate the artifact using `./tools/artifact/validate.sh`.

## Mobile Test Scenarios

If `platforms.targets` in `company.config.yaml` includes mobile targets, add the following test categories:

### Responsive Web (when `platforms.responsive: true`)
- **Viewport testing**: Verify layouts at mobile (320px, 375px), tablet (768px), and desktop (1024px, 1440px) breakpoints
- **Touch interaction**: All interactive elements meet 44x44px minimum touch target
- **Orientation**: Layouts work in both portrait and landscape
- **Soft keyboard**: Forms remain accessible when virtual keyboard is open
- **Scroll behavior**: No horizontal scroll on mobile viewports

### Native Mobile (when `platforms.targets` includes `ios` or `android`)
- **Platform-specific**: iOS safe area insets, Android back button behavior
- **Offline behavior**: Feature degrades gracefully without network
- **Performance**: Screen transitions < 300ms, list scrolling at 60fps
- **Deep linking**: Feature is reachable via deep link if applicable

### PWA (when `platforms.pwa: true`)
- **Offline**: Service worker caches required assets
- **Install prompt**: App is installable and works standalone
- **Background sync**: Pending actions sync when connection restored

## Quality Checklist
- [ ] Every acceptance criterion has at least one test scenario
- [ ] Edge cases and error paths are covered
- [ ] Test data requirements are specified
- [ ] Scenarios are classified by type (unit, integration, E2E)
- [ ] High-risk areas have deeper coverage
- [ ] Pass/fail criteria are unambiguous
- [ ] Dependencies and fixtures are listed
- [ ] Mobile test scenarios included (if platform targets are configured)
- [ ] Artifact passes validation
