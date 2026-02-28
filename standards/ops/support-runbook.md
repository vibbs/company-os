# Support Operations Runbook

This runbook provides operational procedures for customer support. It is a living document -- update it as your support processes evolve.

---

## 1. Support Channel Setup Checklist

### Email Support
- [ ] Create dedicated support inbox (e.g., support@yourdomain.com)
- [ ] Configure email forwarding/routing to ticketing system
- [ ] Set up auto-responder with ticket confirmation and expected response time
- [ ] Create email signature with support hours and self-serve links
- [ ] Test end-to-end: send test email, verify ticket creation, verify auto-response

### Chat Widget
- [ ] Select and install chat provider (Intercom, Crisp, Drift, etc.)
- [ ] Configure operating hours display (show offline message outside hours)
- [ ] Set up canned responses for top-10 most common questions
- [ ] Configure chatbot for L1 deflection (FAQ answers before human handoff)
- [ ] Define human handoff triggers (keywords, sentiment, repeated questions)
- [ ] Test end-to-end: initiate chat, verify routing, verify offline behavior

### Knowledge Base / Self-Serve
- [ ] Choose platform (Notion, GitBook, custom docs site, in-app help center)
- [ ] Structure categories: Getting Started, Account, Features, Billing, Troubleshooting
- [ ] Populate with FAQ entries from `artifacts/support/faq-*.md`
- [ ] Enable search functionality
- [ ] Add feedback widget ("Was this helpful?") to each article
- [ ] Link knowledge base from app header/footer and support email auto-responder
- [ ] Set up analytics to track article views, search queries, and feedback scores

---

## 2. Common Issue Resolution Playbook

### Password Reset
1. Verify the user's identity (email address on file, last 4 of payment method, or security question)
2. Trigger password reset flow via admin panel or auth provider dashboard
3. Confirm the reset email was sent (check email delivery logs if needed)
4. Advise the user to check spam/junk folder if not received within 5 minutes
5. If email delivery fails: escalate to engineering (L3) for auth provider investigation
6. After successful reset: suggest enabling two-factor authentication

### Billing Inquiry
1. Pull up the customer's billing history in the payment provider dashboard
2. Identify the charge in question (date, amount, description)
3. For duplicate charges: verify in payment provider, process refund if confirmed
4. For plan confusion: explain current plan details, offer to adjust if needed
5. For cancellation requests: confirm cancellation policy, process if requested, offer retention incentive if appropriate
6. Document the resolution in the ticket for future reference

### Bug Report Triage
1. Thank the user for reporting and acknowledge the issue
2. Gather: steps to reproduce, expected vs actual behavior, browser/device/OS, screenshots
3. Check known issues list and recent deployment changelog
4. Attempt to reproduce internally
5. If reproducible: create bug report, assign priority per classification taxonomy, notify user of tracking ID
6. If not reproducible: request additional details (console logs, network tab, video recording)
7. Provide workaround if available while fix is in progress

### Feature Request Handling
1. Thank the user for the suggestion
2. Document the request with: user context (role, plan, use case), requested behavior, business justification
3. Check if the request already exists in the backlog or roadmap
4. If exists: add the user's context as additional signal, notify user it is on the radar
5. If new: log as feature request, route to product for prioritization consideration
6. Set expectations: "We review all requests during planning. We cannot guarantee timelines but your input helps us prioritize."
7. Follow up when the feature ships or when a relevant update is available

---

## 3. Escalation Decision Tree

Use this decision tree to determine whether to resolve at the current level or escalate.

```
Incoming Ticket
    |
    v
Can user self-serve? (FAQ, docs, knowledge base)
    |-- YES --> Direct to self-serve resource (L1)
    |-- NO
        |
        v
    Is this a known issue with a documented fix?
        |-- YES --> Apply fix, close ticket (L2)
        |-- NO
            |
            v
        Is this a bug or technical issue?
            |-- YES --> Can L2 resolve with available tools?
            |       |-- YES --> Resolve at L2
            |       |-- NO --> Escalate to Engineering (L3)
            |-- NO
                |
                v
            Is this a billing/account issue?
                |-- YES --> Can L2 resolve with admin access?
                |       |-- YES --> Resolve at L2
                |       |-- NO --> Escalate to Finance/Engineering (L3)
                |-- NO
                    |
                    v
                Is this a security concern?
                    |-- YES --> Escalate to Engineering immediately (L3/L4)
                    |-- NO --> Handle at L2, escalate if unresolved within SLA
```

### When to Escalate (Always)
- Customer reports data loss or data exposure
- Security vulnerability is reported
- Issue affects multiple customers simultaneously
- SLA response or resolution time is about to breach
- Customer explicitly requests manager or executive contact
- Legal or regulatory implications

### When to Resolve at Current Level
- Known issue with documented workaround
- Standard account or billing operation
- FAQ-answerable question
- Feature request (document and route, do not escalate)
- Cosmetic or low-severity issue with no business impact

---

## 4. Support Metrics to Track

### Response Metrics
| Metric | Definition | Target (Basic) | Target (Standard) | Target (Premium) |
|--------|-----------|-----------------|--------------------|--------------------|
| **First Response Time** | Time from ticket creation to first human reply | < 48 hours | < 24 hours | < 4 hours |
| **Resolution Time** | Time from ticket creation to confirmed resolution | < 5 business days | < 2 business days | < 24 hours |
| **First Contact Resolution** | % of tickets resolved without escalation | > 50% | > 60% | > 70% |

### Quality Metrics
| Metric | Definition | Target |
|--------|-----------|--------|
| **CSAT (Customer Satisfaction)** | Post-resolution survey score (1-5) | > 4.0 |
| **NPS (Net Promoter Score)** | "Would you recommend?" (-100 to 100) | > 30 |
| **Reopen Rate** | % of tickets reopened after resolution | < 10% |

### Volume Metrics
| Metric | Definition | Why Track |
|--------|-----------|-----------|
| **Ticket Volume** | Total tickets per period (day/week/month) | Capacity planning |
| **Volume by Category** | Tickets grouped by classification taxonomy | Identify systemic issues |
| **Self-Serve Deflection Rate** | % of support queries resolved via self-serve | Measure knowledge base effectiveness |
| **Escalation Rate** | % of tickets escalated from L2 to L3+ | Engineering load indicator |

### Trend Indicators
- **Spike detection**: Flag when daily volume exceeds 2x the 7-day average
- **Category shift**: Alert when a single category exceeds 40% of total volume
- **Repeat contacts**: Track users who open 3+ tickets in 30 days (indicates unresolved root cause)

---

## 5. Weekly Support Review Agenda

**Duration**: 30 minutes
**Frequency**: Weekly (recommend Monday or Friday)
**Attendees**: Support lead (or solo founder wearing the support hat)

### Agenda

1. **Metrics Review** (5 min)
   - First response time (average, worst case)
   - Resolution time (average, worst case)
   - CSAT score (if survey is active)
   - Ticket volume vs previous week

2. **Volume Breakdown** (5 min)
   - Tickets by category (Bug Report, Feature Request, How-To, Billing, Account, Security, Performance)
   - Top 3 categories this week
   - Any category spikes or new patterns

3. **Top Pain Points** (10 min)
   - Identify the top 5 most frequent or most severe issues
   - For each: root cause status (known, investigating, fixed, won't fix)
   - Decide: escalate to product, escalate to engineering, update FAQ, monitor

4. **Escalation Review** (5 min)
   - Count of L3+ escalations this week
   - Status of open escalations
   - Any patterns in escalation triggers

5. **Action Items** (5 min)
   - FAQ updates needed (new entries, corrections)
   - Process improvements identified
   - Product feedback to route via feedback-synthesizer
   - Runbook updates needed

### Output
After each weekly review, update:
- `artifacts/support/support-themes-{date}.md` with the week's findings
- FAQ documents if gaps were identified
- This runbook if process improvements were agreed upon
