---
name: channel-playbook
description: Creates platform-specific marketing playbooks for acquisition channels. Use when launching or optimizing a specific growth channel (e.g., LinkedIn, Twitter, email, Product Hunt).
---

# Channel Playbook

## Reference
- **ID**: S-GROW-04
- **Category**: Growth
- **Inputs**: ICP document, messaging framework, channel selection, budget constraints
- **Outputs**: channel playbook document → artifacts/growth/
- **Used by**: Growth Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose
Produces a platform-specific marketing playbook for a chosen acquisition channel, covering content strategy, posting cadence, engagement tactics, and success metrics tailored to that channel's dynamics.

## Procedure
1. Select the target channel and review its audience dynamics, algorithm behavior, and best practices.
2. Review the ICP document to confirm audience presence on this channel.
3. Define channel-specific goals: awareness, traffic, leads, or direct conversions.
4. Adapt the messaging framework to the channel's format and tone.
5. Design the content mix: content types, formats, and ratio (e.g., 60% educational, 20% social proof, 20% promotional).
6. Define the posting cadence: frequency, best times, and scheduling tools.
7. Outline engagement tactics: community interaction, comment strategy, DM outreach rules.
8. Define paid amplification strategy if applicable: budget allocation, targeting, A/B test plan.
9. Set success metrics and KPIs: impressions, engagement rate, click-through, conversions.
10. Define the review cadence: weekly metrics review, monthly strategy adjustment.
11. Save the playbook to `artifacts/growth/`.
12. Validate the artifact using `./tools/artifact/validate.sh`.

## Quality Checklist
- [ ] Channel selection is justified by ICP presence
- [ ] Messaging is adapted to the channel's native tone
- [ ] Content mix is defined with ratios
- [ ] Posting cadence is realistic and sustainable
- [ ] Engagement tactics are specific, not generic
- [ ] Success metrics are measurable and time-bound
- [ ] Review cadence is established
- [ ] Artifact passes validation
