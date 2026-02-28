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
- [ ] Artifact passes validation
