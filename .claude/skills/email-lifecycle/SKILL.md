---
name: email-lifecycle
description: Designs email sequences, templates, and send triggers for SaaS lifecycle marketing and transactional emails. Use when planning onboarding drips, transactional notifications, activation campaigns, or retention email flows.
allowed-tools: Read, Grep, Glob, Bash, Write
---

# Email Lifecycle

## Reference
- **ID**: S-GROW-06
- **Category**: Growth
- **Inputs**: company.config.yaml (email section, tech_stack), PRDs, activation-onboarding output
- **Outputs**: email strategy (standards/email/), per-feature email templates and triggers
- **Used by**: Growth Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose

Design and document the complete email lifecycle for a SaaS product -- transactional emails, onboarding sequences, activation triggers, and retention campaigns. This skill produces a reusable email strategy and per-feature email specifications that ensure consistent, mobile-responsive, deliverable email communications.

## When to Use

- New product needs its email system designed from scratch
- Feature requires transactional or marketing email touchpoints
- Onboarding sequence needs to be created or improved
- Activation or retention email campaigns are being planned

## Procedure

### Step 1: Load Context

1. Read `company.config.yaml` for:
   - `email.provider` (Resend, Sendgrid, Postmark, SES, etc.)
   - `email.from_address`
   - `email.template_engine` (react-email, mjml, handlebars, jinja, plain-html)
   - `tech_stack.language`
   - `tech_stack.framework`
2. Read activation-onboarding output in `artifacts/growth/` if available -- map aha moments to email triggers.
3. Read relevant PRDs to understand feature-specific email needs.

### Step 2: Generate Email Strategy

Produce `standards/email/email-strategy.md` covering the following sections.

**Email Types & Purpose**:

- **Transactional** (system-triggered, immediate):
  - Welcome / email verification
  - Password reset
  - Invoice / payment receipt
  - Account changes (plan change, settings update)
  - Security alerts (new login, password changed)

- **Onboarding Sequence** (time-based drip, 5-7 emails):
  - Day 0: Welcome + single next step
  - Day 1: Getting started guide (path to aha moment)
  - Day 3: Feature highlight (show value they haven't discovered)
  - Day 5: Social proof + use case inspiration
  - Day 7: Check-in (need help?) + upgrade nudge if on free plan

- **Activation** (behavior-triggered):
  - Re-engage dormant users (no login in 7 days)
  - Milestone celebrations (first project, 10th use, etc.)
  - Upgrade prompts (hitting free tier limits)
  - Feature announcement (new capability relevant to their usage)

- **Retention** (periodic):
  - Weekly/monthly usage report
  - Tips & tricks based on usage patterns
  - What's new / changelog digest

**Template Structure** (every email):

- Subject line: max 50 chars, personalized, action-oriented
- Preheader: extends subject, max 90 chars
- Body: hero image/header -> content (2-3 short paragraphs) -> single CTA button -> footer
- Footer: unsubscribe link (required), company info, preference center link
- Mobile-responsive: single column, 14px+ body text, 44px+ tap targets

**Send Trigger Architecture**:

- Event-driven: user action -> event emitted -> email service receives -> template rendered -> sent
- Queue-based: email jobs added to background queue (reference background-jobs skill)
- Delay handling: scheduled sends use cron or delay queues
- Deduplication: prevent duplicate sends (idempotency key per user+email type+timewindow)

**Provider Patterns**:

- Resend: API-first, React Email templates, webhook delivery tracking
- Sendgrid: Dynamic templates, marketing + transactional, event webhook
- Postmark: Transactional-focused, message streams, template API
- SES: Raw sending, requires own template rendering, cheapest at scale

### Step 3: Per-Feature Email Design

For each feature that has email touchpoints:

1. **Identify email touchpoints** -- what emails does this feature trigger?
2. **Design templates**: subject, preheader, body copy, CTA
3. **Define send triggers**: which user event -> which email
4. **Set timing**: immediate (transactional), delayed (drip), periodic (digest)
5. **Handle preferences**: which emails can users opt out of? (transactional emails cannot be opted out of; marketing emails must have unsubscribe)

### Step 4: Code Pipeline Integration

Produce implementation guidance:

- **Email template directory**: `src/emails/` (or `emails/` at root)
- **Per template_engine**:
  - react-email: TypeScript components in src/emails/, preview with `email dev`
  - mjml: MJML templates compiled to HTML, preview in browser
  - handlebars: .hbs templates with variable interpolation
  - jinja: .jinja2 templates for Python backends
  - plain-html: static HTML with {{variable}} placeholders
- **Send function pattern**: `sendEmail(type, recipient, data)` wrapper that abstracts the provider
- **Queue integration**: email send jobs via configured queue (reference background-jobs skill)
- **Preview workflow**: local rendering for visual QA before sending

### Step 5: Testing Strategy

- **Render test**: every template renders without errors with sample data
- **Variable test**: all template variables have fallback defaults (no blank fields in sent emails)
- **Mobile test**: email renders correctly on mobile viewport (320px)
- **Deliverability**: SPF, DKIM, DMARC configuration guidance for the sending domain
- **Unsubscribe test**: unsubscribe link works and preference is respected on subsequent sends

### Step 6: Verify

- All transactional email types are defined (welcome, password reset, invoice, security alerts)
- Onboarding sequence is 5-7 emails with specific timing and content summaries
- Every template is mobile-responsive
- Unsubscribe link is present on all marketing/retention emails
- Run `./tools/artifact/validate.sh` on any produced artifacts

## Quality Checklist

- [ ] All transactional email types defined (welcome, password reset, invoice, security alerts)
- [ ] Onboarding sequence has 5-7 emails with specific timing and content
- [ ] Each email has: subject (<50 chars), preheader (<90 chars), single CTA, unsubscribe
- [ ] Send triggers are event-driven with specific event names
- [ ] Template engine matches configured tech stack
- [ ] Queue integration pattern defined for async sends
- [ ] Mobile-responsive template requirements specified
- [ ] Deliverability basics covered (SPF, DKIM, DMARC)
