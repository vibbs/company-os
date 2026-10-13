---
name: channel-playbook
description: Creates a step-by-step marketing playbook for one acquisition channel such as LinkedIn, Twitter, email or Product Hunt. Use when launching or improving a growth channel.
runtimes:
  claude:
    user-invokable: true
---

# Channel Playbook

## Reference
- **ID**: S-GRO-04
- **Category**: Growth
- **Inputs**: ICP document, messaging framework, channel selection, budget constraints
- **Outputs**: channel playbook document → artifacts/growth/
- **Used by**: Growth Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose
Produces a platform-specific marketing playbook for a chosen acquisition channel, covering content strategy, posting cadence, engagement tactics, and success metrics tailored to that channel's dynamics.

## Procedure

### Direct Outreach / Founder-Led Sales

**Stage: Highest leverage at idea/mvp. Every founder should start here.**

1. **ICP-to-Prospecting**: Where targets are findable
   - LinkedIn: job title + company size filters
   - Slack/Discord communities: where your ICP hangs out
   - Twitter/X lists: curated lists of target personas
   - GitHub: for developer tools (contributors to related projects)

2. **Outreach Message Frameworks** (problem-led, not pitch-led):
   - Lead with a question about their pain point, not your solution
   - Reference something specific about them (recent post, company news)
   - Ask for 15 minutes, not a demo
   - Template: "Hey [name], I noticed [specific observation]. I'm building [one-liner] and curious — how do you currently handle [pain point]? Would love 15 min to learn from you."

3. **Follow-up Cadence** (3-touch sequence):
   - Day 0: Initial message
   - Day 3: Value-add follow-up (share relevant content/insight)
   - Day 7: Final follow-up with soft close

4. **Bridge to Discovery**: Use customer-conversations skill for the actual call prep and debrief

---

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

## Platform Deep-Dive Reference

When producing channel-specific playbooks, reference the platform-specific guidance below. These go beyond generic advice to include algorithm-specific and culture-specific knowledge.

### Twitter/X
- **Algorithm**: Engagement velocity in first hour matters most. Replies weigh more than likes. Native content (no external links) gets boosted.
- **Thread architecture**: Hook tweet → 3-5 value tweets → CTA tweet. Number each tweet.
- **Engagement pattern**: 3 value posts : 1 promotional : 1 engagement (ask questions, polls)
- **Timing**: Post when your audience is active (check analytics). Quote-tweeting adds distribution.
- **Avoid**: Link-only tweets (suppressed by algorithm), thread dumps without hooks, corporate tone.

### LinkedIn
- **Algorithm**: Comments weigh 5x likes. Native content preferred over links. Document/carousel posts get 3x reach vs text.
- **Format**: Short paragraphs (1-2 sentences), whitespace between, hook in first line (before "see more")
- **Carousel posts**: 8-12 slides, educational content, branded consistently, CTA on last slide
- **Engagement**: Comment on others' posts first. Tag people only when genuinely relevant.
- **Avoid**: Hashtag spam (use 3-5 max), direct sales pitches, cross-posted tweets.

### Reddit
- **Cultural norms**: 90-9-1 rule (90% consume, 9% comment, 1% post). Value-first, always.
- **Entry protocol**: Lurk 2 weeks, read community rules, start with comments not posts. Earn karma before sharing own content.
- **Self-promotion**: Reddit ratio — 9 genuinely helpful contributions per 1 self-promotional post. Disclose affiliation.
- **Subreddit selection**: Find 3-5 relevant subreddits. Check activity (>10 posts/day), rules, moderator stance on self-promo.
- **AMA format**: Prepare 2 weeks ahead. Answer every question. Be authentic, admit limitations.
- **Avoid**: Vote manipulation, corporate speak, ignoring moderator feedback, brigading, creating shill accounts.

### TikTok
- **Algorithm**: Completion rate > all other signals. 3-second hook is make-or-break. Trending audio boosts discovery.
- **Content formula**: Hook (0-3s) → Context (3-8s) → Value (8-45s) → CTA (last 3s)
- **Posting**: 1-3x daily for growth phase. Batch-create content. Use trending sounds within 48 hours.
- **Hashtags**: Mix broad (#tech, #startup) with niche (#saasfounder, #devtools). 3-5 per post.
- **Aesthetic**: Raw, authentic > polished. Behind-the-scenes, face-to-camera, screen recordings.
- **Avoid**: Repurposed Instagram content (TikTok penalizes), links in captions (use bio), overproduction.

### Instagram
- **Reels vs Stories vs Feed**: Reels for discovery (new audience), Stories for engagement (existing), Feed for brand (portfolio)
- **Reels**: 15-30s optimal. Text overlay for sound-off viewing. Cover image matters for grid.
- **Carousel posts**: 10 slides max. Educational or storytelling format. Save rates signal quality to algorithm.
- **Stories**: Use interactive features (polls, quizzes, questions) — they boost engagement signals.
- **Hashtags**: Research niche hashtags (10K-500K posts). Use 10-15 per post in caption (not comments).
- **Avoid**: Inconsistent visual style, link-in-bio without updating, neglecting alt text.

### Product Hunt
- **Launch day playbook**: Ship Tuesday-Thursday. Post at 12:01 AM PST. Prepare all assets 1 week ahead.
- **Pre-launch**: Build a coming-soon page. Collect followers. Reach out to hunters with 1000+ followers.
- **First hour**: Activate your network (email, Slack, social) for genuine engagement. Comments > upvotes.
- **Maker engagement**: Reply to EVERY comment within 1 hour. Be personal, not corporate.
- **Assets**: 6 high-quality screenshots, 1 video demo (60-90s), compelling tagline (<60 chars).
- **Post-launch**: Thank supporters, share results, continue engaging for 48 hours.

### Hacker News
- **Show HN format**: Start title with "Show HN: ". Post on weekday mornings (US time).
- **Expectations**: Technical depth valued. Explain architecture, not just features. Be ready for tough questions.
- **What works**: Open source projects, novel technical approaches, transparent company posts, honest post-mortems.
- **Commenting**: Contribute thoughtful, technical responses. Don't ask for upvotes. Don't use multiple accounts.
- **Avoid**: Marketing language, growth hacking, shallow content, astroturfing, voting rings.

## GTM Sprint Tactics

The following tactical playbooks are designed for time-boxed GTM sprints (see `/gtm-sprint`). They can also be used standalone.

### Directory Blitz

**When**: Day 9 of GTM Sprint, or any launch push needing broad visibility fast.

**Procedure**:
1. Select relevant directories from the master list below based on product category
2. Prepare a submission packet: one-liner, 3-sentence description, 3 screenshots, logo, founder bio
3. Craft a directory-specific hook using interview data (e.g., "We interviewed 60 compliance teams and found...")
4. Submit to 15+ directories in a single session
5. Track submissions in a checklist artifact

**Directory Master List** (SaaS / Developer Tools):

| Directory | Category | Notes |
|-----------|----------|-------|
| Product Hunt | Launch | Tue-Thu, 12:01 AM PST (see PH deep-dive above) |
| BetaList | Pre-launch | Good for wait-list building |
| Launching Next | Pre-launch | Upcoming product announcements |
| SaaSHub | SaaS | Alternative-to style listings |
| AlternativeTo | Alternatives | Position against specific competitors |
| G2 | Reviews | Requires verified reviews, longer setup |
| Capterra | Reviews | Pay-to-play for featured, free basic listing |
| GetApp | Reviews | Gartner-owned, good for enterprise visibility |
| StackShare | Dev tools | Developer-focused, good for technical products |
| SourceForge | Open source | If applicable |
| Indie Hackers | Community | Product directory + community post |
| Hacker News | Community | Show HN (see HN deep-dive above) |
| Dev.to | Developer | Developer community listings |
| Crunchbase | Business | Company profile, investor visibility |
| AngelList / Wellfound | Startup | Hiring + product visibility |
| AppSumo | Deals | Lifetime deal marketplace (if pricing allows) |
| Slant | Recommendations | Community-voted alternatives |
| There's An AI For That | AI | AI-specific directory (if applicable) |
| Uneed | Products | Curated product directory |

**Hook Formulas** (adapt with your interview data):
- Data-led: "We interviewed {N} {role}s and discovered {surprising finding}..."
- Pain-led: "{N}% of {role}s waste {X hours/week} on {pain point}. We fix that."
- Outcome-led: "{Company type}s using {product} save {$X/month} on {category}."

### Build-in-Public Arc

**When**: Day 5-13 of GTM Sprint, or any founder-led distribution effort.

A structured content arc that turns your GTM sprint into a public narrative. Each post builds on the last, creating a story that attracts users, talent, and investors.

**14-Day Content Arc**:

| Day | Post Type | Content | Platform |
|-----|-----------|---------|----------|
| 5 | Announcement | "I'm building X because Y. Here's what I've learned from 20 interviews..." | Twitter/LinkedIn |
| 7 | Insight | Share one surprising finding from interviews (data/chart if possible) | Twitter/LinkedIn |
| 9 | Progress | "Landing page is live. Here's our approach to [positioning angle]..." | Twitter/LinkedIn |
| 10 | Community | Share the insight chart in relevant Slack/Discord with context | Communities |
| 12 | Traction | "12-day recap: {N} interviews, {N} LOIs, {N} wait-list sign-ups" with metrics screenshot | Twitter/LinkedIn |
| 13 | Reflection | "What worked, what didn't, and what's next" — public retro | Twitter/LinkedIn/Blog |

**Principles**:
- Lead with learning, not pitching
- Share specific numbers (interviews, sign-ups, revenue) — transparency builds trust
- Acknowledge what's not working — vulnerability resonates
- Tag people you interviewed (with permission) — they become amplifiers
- Respond to every comment within 2 hours

### Competitor Poaching

**When**: Day 11 of GTM Sprint, or when entering a market with established competitors.

**Procedure**:
1. **Find Competitor Reviewers**
   - G2/Capterra: read 1-3 star reviews, note reviewer names/companies
   - Reddit: search `r/[industry]` for "[competitor] alternative" or "[competitor] frustrating"
   - Twitter/X: search "[competitor] sucks" or "[competitor] alternative"
   - App Store reviews: filter by 1-2 star ratings
   - Note: respect platform ToS — read publicly available reviews, do not scrape private data

2. **Craft Value-First Outreach**
   - Template: "Hey {name}, I noticed your review of {competitor} — you mentioned {specific frustration}. We're building {product} specifically to solve that. Would you be open to a 10-min chat about what you wish {competitor} did differently?"
   - Never badmouth the competitor directly
   - Lead with empathy for their frustration, not a sales pitch

3. **Offer Concierge Migration**
   - For the first 10-20 users: offer white-glove migration assistance
   - Template: "We'll personally migrate your data from {competitor} in under {X} hours — free for early adopters."
   - This builds loyalty and generates testimonials

4. **Track Conversion**
   - Log outreach attempts vs. responses vs. conversions
   - Feed successful patterns back into channel-playbook

## Quality Checklist
- [ ] Channel selection is justified by ICP presence
- [ ] Messaging is adapted to the channel's native tone
- [ ] Content mix is defined with ratios
- [ ] Posting cadence is realistic and sustainable
- [ ] Engagement tactics are specific, not generic
- [ ] Success metrics are measurable and time-bound
- [ ] Review cadence is established
- [ ] Platform-specific algorithm knowledge is reflected in channel tactics
- [ ] Cultural norms are respected (especially Reddit and HN)
- [ ] Directory blitz includes 15+ relevant directories (when used)
- [ ] Build-in-public arc has specific daily content plan (when used)
- [ ] Competitor poaching respects platform ToS (when used)
- [ ] Artifact passes validation

## Cross-References
- **gtm-sprint** (S-GRO-09) — orchestrates directory blitz, build-in-public, and competitor poaching within a time-boxed sprint
- **positioning-messaging** (S-GRO-01) — provides messaging hooks for directory submissions
- **content-engine** (S-GRO-07) — content multiplication from build-in-public posts
- **customer-conversations** (S-PROD-08) — interview data feeds directory hooks and competitor poaching outreach
