---
id: MEMO-REVIEW-001
type: decision-memo
status: review
parent: MEMO-SYS-002
children: []
depends_on:
  - MEMO-SYS-002
blocks: []
created: 2026-03-02
author: claude
title: "Company OS System Gap Analysis — Agent & Skill Review"
---

# Company OS: System Gap Analysis — Agent & Skill Review

## Executive Summary

A comprehensive outsider review of all 9 agents, 59 skills, and 31 tools identified 49 findings across 4 severity levels, plus 11 missing skills. The gaps cluster around 5 themes: (1) product discovery artifacts are formally invalid by the system's own tooling, (2) multiple skills assume enterprise-scale data that MVPs don't have, (3) the orchestrator has no failure recovery or hotfix path, (4) solopreneur operational rhythms are missing, and (5) growth skills miss the most common solopreneur acquisition channels.

---

## CRITICAL — System-Breaking

### 1. `artifacts/product/` doesn't exist, and 5+ skills produce invalid artifacts

`icp-positioning`, `sprint-prioritizer`, `feedback-synthesizer`, `ux-research`, and `market-intelligence` all write to `artifacts/product/`. This directory isn't scaffolded by `/setup`. The artifact types they produce (`icp`, `market-intelligence`, `research`) aren't in `validate.sh`'s `VALID_TYPES`. Every product discovery artifact fails validation by the system's own tooling. The entire left side of the funnel is broken.

### 2. QA agent has no `Write` tool

The QA agent's frontmatter says `tools: Read, Grep, Glob, Bash`. It cannot write files. Yet it's expected to produce QA reports, test plans, and release readiness verdicts as artifacts. Functionally blocked.

### 3. Orchestrator has no failure recovery

When an agent returns a failure, the orchestrator blocks and waits with no retry logic, no escalation path, and no "ask the user to decide" rule. A solopreneur using `/ship` on a novel feature that hits an ambiguous security review gets nothing. The system stops. No guidance on how to unstick.

### 4. No hotfix path exists

At 2 AM with a production outage, the solopreneur types "payment flow is broken." The orchestrator has no hotfix routing. It might try to start a PRD. The release-readiness-gate mentions "Expedited Release (Hotfix)" but this is buried in a skill, not surfaced as a first-class orchestrator behavior.

### 5. `dogfood` depends on a phantom `agent-browser` skill

The dogfood skill's entire web-app mode requires `agent-browser`, which doesn't exist in the codebase. The most common solopreneur case (Next.js or SvelteKit app) silently degrades to a manual checklist with zero warning.

---

## HIGH — Notable Gaps

### Theme: "Assumes Enterprise, Meets Solopreneur"

#### 6. Multiple skills assume data that doesn't exist at idea/mvp stage

| Skill | What it assumes | What actually exists at MVP |
|-------|----------------|---------------------------|
| `activation-onboarding` | Retention data, analytics funnels, enough users for A/B tests | Zero users, no analytics |
| `pricing-unit-economics` | CAC, LTV, churn rates, MRR decomposition | Zero customers, zero revenue |
| `icp-positioning` | User interviews, market research, competitor analysis | Hypotheses only |
| `feedback-synthesizer` | 10+ feedback items across sources for statistical themes | 3-4 data points max |
| `experiment-framework` | 14,000+ users per variant for significance | 100-500 DAU at best |

None of these skills have a "pre-data" or "hypothesis" mode. They all produce technically valid artifacts that are analytically meaningless at small scale.

#### 7. Release gate is too heavy for MVP despite "stage-awareness" claims

Bars 1-6 are fully enforced at all stages including `idea`. That means a 3-day-old side project needs: approved PRD, approved RFC with API contract, threat model with dependency scan logs, test plan linked to PRD ACs, zero TODOs in code, and an incident runbook. Only Bar 7 (versioning) is stage-gated. The `idea` stage should be much more permissive.

#### 8. Threat modeling is STRIDE overkill for MVP

Full STRIDE across all DFD elements produces 40-60 threat entries for a 2-route SaaS, most with identical mitigations (HTTPS, input validation, JWT). No concept of "MVP security baseline" — the 6 things you actually need before launch.

#### 9. Compliance is SOC2-only, ignores what MVPs actually need

SOC2 costs $15-50K and takes 6-12 months. At MVP, a solopreneur needs: GDPR basics checklist, CCPA awareness, "am I in PCI scope?" (no, if using Stripe), and HIPAA "do I touch health data?" The skill has no stage routing.

### Theme: "Missing Operational Rhythms"

#### 10. No weekly review / operational cadence skill

This is the highest-value missing piece. The system produces excellent individual artifacts but no operating rhythm. A solopreneur needs a weekly 30-minute ritual: what shipped, key metrics, top support signal, next week's priorities, AI spend, runway. Without this, all the artifacts accumulate without synthesis.

#### 11. No post-ship retrospective

After a feature ships, nobody owns "Did this work?" No capture of: did success metrics move, was the hypothesis right, what would we do differently. For a solopreneur without a team to carry institutional memory, every lesson stays unlearned.

#### 12. Inbound loop SOP is a document, not an invokable skill

The SOP at `standards/ops/inbound-loop-sop.md` defines cadences and routing perfectly but the solopreneur can't `/inbound-loop` to run it. They have to manually invoke 4 skills in sequence.

### Theme: "Growth Skills Miss the Solopreneur Reality"

#### 13. No product-led growth mechanics anywhere

7 growth skills cover messaging, landing pages, SEO, channels, onboarding, email, content. Zero coverage of: viral loops, referral programs, freemium tier design, in-product sharing, or network effects. PLG is often the primary acquisition for zero-budget solopreneurs.

#### 14. No founder-led sales / cold outreach channel

The channel-playbook covers Twitter, LinkedIn, Reddit, Product Hunt, HN — all broadcast channels. The fastest path to first 10 customers (find them, email them, get on a call) has no skill. `customer-conversations` handles the call; nothing handles finding the people.

#### 15. Landing page copy produces text, not deployable code

The skill produces structured copy in Markdown. A solopreneur using Next.js or Webflow still has a blank page and a text document side-by-side. No `.tsx` scaffold, no HTML output, no Webflow-compatible JSON.

#### 16. SEO ignores zero-authority domains

The skill produces a pillar-cluster architecture targeting keywords that a DR-0 domain cannot rank for. No guidance on ultra-long-tail strategy, no backlink acquisition, no "when to skip SEO and do distribution instead."

### Theme: "Engineering Chain Gaps"

#### 17. Security review timing is contradictory

The engineering agent says security review happens after implementation. The ship skill says threat model runs parallel with implementation planning. These contradict. Post-implementation security findings are expensive; pre-implementation is cheap.

#### 18. Code review has no security section

4 sections: Architecture, Code Quality, Tests, Performance. No Security. AI-generated code frequently produces: SQL injection, auth bypass in middleware ordering, IDOR. The most common self-review failure mode is invisible.

#### 19. `background-jobs` and `observability-baseline` are shallow stubs

~40 lines each with no tech-stack awareness. Neither reads `company.config.yaml`. Compare to `deployment-strategy` or `seed-data` which are 10x deeper. A solopreneur hitting async processing or their first production incident gets vague design docs instead of concrete patterns.

#### 20. `api-tester-playbook` produces a document, not runnable tests

The playbook describes what to test but generates no test code. `contract-test.sh` exists but isn't referenced. Compare to `seed-data` which generates tech-stack-appropriate factory files. A solopreneur still needs to choose a framework and translate the playbook manually.

#### 21. `resilience-testing` tool does 4 HTTP checks vs. the skill's full circuit breaker/latency injection plan

The tool checks: does `/health` return 200? Does curl timeout work? Does a bad path avoid 500? Does connection to port 1 fail? None of this relates to the skill's circuit breaker, latency injection, or blast radius analysis.

#### 22. Engineering sub-agent failure escalation is undefined

Phase 5 describes conflict resolution but not "sub-agent says it can't complete." No retry limit, no escalation to user, no protocol for when the blocker is the RFC itself being wrong.

### Theme: "Cross-Agent Blind Spots"

#### 23. i18n config is orphaned

`company.config.yaml` has a full `i18n` section. No agent reads it. No gate checks it. The config section exists but does nothing.

#### 24. "Improvement" work type has no agent-level implementation

The workflow-router classifies "Improvement" as a work type. Product agent only knows full PRDs. Engineering always starts from RFC. QA doesn't distinguish improvement from new feature. The work type is first-class in routing, absent in execution.

#### 25. Growth agent has no feedback loop to Product

Growth discovers "landing page converts at 0.8%." Where does that learning go? In what format? Through which channel? Unspecified. The growth-to-product signal pipeline doesn't exist.

#### 26. `conflict-resolver` isn't in the Orchestrator's skills list

The orchestrator is supposed to "arbitrate conflicts between agents" but doesn't have the `conflict-resolver` skill registered. It's in the Engineering agent's list.

---

## MEDIUM — Improvement Opportunities

| # | Finding | Suggested Fix |
|---|---------|---------------|
| 27 | `customer-conversations` has no pre-customer path | Add `cold-outreach` conversation type for idea-stage |
| 28 | `sprint-prioritizer` doesn't define sprint capacity | Add Step 0: hours/sprint, effort scale definition |
| 29 | `ship` Seed & Verify assumes `dev-environment` was already run | Add preflight check for `tools/dev/start.sh` existence |
| 30 | `setup` doesn't link to `dev-environment` as immediate next step | Elevate to step 1 in Next Steps |
| 31 | `decision-memo-writer` has no template or ID convention | Add template + `DM-{NNN}` convention |
| 32 | `ingest` has no state tracking, re-processes everything | Write `.company-os/last-ingest.json` timestamp |
| 33 | `prd-template.md` missing Measurement Plan and Discovery Validation sections | Add both sections to template |
| 34 | `status` doesn't scan `artifacts/product/` or `artifacts/experiments/` | Add to directory scan list |
| 35 | Token cost ledger requires manual token counts nobody has | Add session-type lookup table for estimates |
| 36 | `privacy-data-handling` never reads config for actual data processors | Read analytics/email/payments providers from config |
| 37 | `support-operations` escalation assumes team members | Add solopreneur mode: L1-L4 are all you |
| 38 | `content-engine` multiplication math ignores human cost | Add "Solo Founder Mode" priority order |
| 39 | `tos-privacy-drafting` has no deployment guidance | Add "how to publish" and "this is an outline, not final" |
| 40 | `email-lifecycle` has no fallback when email provider isn't configured | Add Step 0 provider selection guide |
| 41 | `positioning-messaging` brand identity scope too heavy for MVP | Mark Steps 8-11 as growth/scale only |
| 42 | Product agent memory cap (5 topic files) too low for real usage | Raise to 10 files with archiving |
| 43 | Orchestrator parallel execution only documented in ship skill | Add parallel rules to orchestrator directly |
| 44 | `multi-tenancy` has no config guard | Check `architecture.multi_tenant` first |
| 45 | `instrumentation` has no fallback when analytics not configured | Add provider selection guide |
| 46 | `ai-engineering` has no eval tooling reference | Recommend PromptFoo/RAGAS by stack |
| 47 | `design-system` review has no automated accessibility checks | Reference axe-core CLI |
| 48 | Persona feature adds ceremony without solopreneur value | Make optional and collapsed in config |
| 49 | `observability-baseline` ID collision with `code-review` (both S-ENG-06) | Reassign to S-ENG-15 |

---

## Missing Skills

| Skill | Why | Priority |
|-------|-----|----------|
| `/weekly-review` | Operating rhythm for solo founder — synthesizes everything weekly | HIGH |
| `/product-led-growth` | Viral loops, referral programs, freemium design | HIGH |
| `/retrospective` | Post-ship "did it work?" capture | HIGH |
| `/inbound-loop` | Orchestrates the full feedback synthesis cycle | MEDIUM |
| `/founder-led-sales` | Cold outreach, finding first 10 customers | MEDIUM |
| `/db-migration` | Safe migration patterns per ORM/database | MEDIUM |
| `/investor-update` | Monthly investor communication (extract from pricing skill) | LOW |
| `/sunset-feature` | Feature lifecycle closure and archival | LOW |
| `/smoke-test-writer` | Generate smoke tests for critical paths | LOW |
| `/slo-definition` | SLI/SLO/error budget definition | LOW |
| `/metrics-dashboard` | "My 5 numbers this week" definition | LOW |

---

## Top 5 Highest-Leverage Fixes

1. **Add `artifacts/product/` to setup + types to validate.sh** — Unblocks the entire product discovery funnel.
2. **Add `Write` to QA agent + `conflict-resolver` to Orchestrator skills** — Two one-line fixes that unblock core functionality.
3. **Add orchestrator recovery + hotfix protocols** — Without these, any failure or emergency puts the system in undefined state.
4. **Create `/weekly-review` skill** — The single highest-value addition. Makes every other artifact compound over time.
5. **Add pre-data/hypothesis modes to MVP-stage skills** — Makes the system actually work for solopreneurs on day 1.
