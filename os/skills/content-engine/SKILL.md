---
name: content-engine
description: Produces multi-format content strategies with editorial calendars, content briefs, and multiplication workflows. Use when building a content marketing engine, planning blog/newsletter cadence, or creating content briefs.
---

# Content Engine

## Reference
- **ID**: S-GRO-07
- **Category**: Growth / Content
- **Inputs**: company.config.yaml, positioning-messaging output, seo-topic-map output, product context
- **Outputs**: editorial calendar → artifacts/growth/, content briefs → artifacts/growth/
- **Used by**: Growth Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose

Build a sustainable content marketing engine that goes beyond one-off landing pages. Produces editorial calendars with publishing cadence, content briefs for each piece, and a content multiplication workflow that transforms one pillar piece into 5+ derivative assets across formats. Works downstream of seo-topic-map (which provides keywords and clusters) and positioning-messaging (which provides voice and narrative).

## When to Use

- Setting up content marketing for the first time
- Planning quarterly/monthly editorial calendar
- Creating content briefs for specific pieces
- Building a content multiplication workflow (blog → social → email → video)
- Auditing content performance and planning refreshes

## Procedure

### Step 1: Load Context

1. Read `company.config.yaml` -- product, domain, stage, platforms
2. Read positioning-messaging output in `artifacts/growth/` -- brand voice, value propositions
3. Read seo-topic-map output -- keyword clusters, pillar pages
4. Read email-lifecycle output -- newsletter cadence (content must feed email sequences)
5. Read channel-playbook output -- which platforms are active (determines derivative formats)

### Step 2: Define Content Strategy

1. Set content mission: "Help [ICP] achieve [outcome] through [content type]"
2. Define content pillars (3-5 topics aligned with keyword clusters and brand expertise)
3. Set publishing cadence based on company stage:
   - idea/mvp: 1 piece/week (quality over quantity)
   - growth: 2-3 pieces/week
   - scale: daily across multiple formats
4. Define content formats:
   - **Blog posts**: 800-2000 words, SEO-optimized, educational
   - **Case studies**: customer stories, problem -> solution -> results
   - **Tutorials**: step-by-step guides, code examples if relevant
   - **Comparisons**: vs. competitor pages, alternative-to pages
   - **Newsletters**: curated digest, 1x/week or 2x/month
   - **Social posts**: derivatives from pillar content
   - **Video scripts**: outline for YouTube/Loom content (optional)

### Step 3: Build Editorial Calendar

Produce a rolling 4-week editorial calendar:

```markdown
## Editorial Calendar -- [Month Year]

| Week | Pillar | Format | Title/Topic | Target Keyword | Status |
|------|--------|--------|-------------|----------------|--------|
| W1 | [Pillar 1] | Blog | [Working title] | [keyword] | Draft |
| W1 | [Pillar 1] | Social (3x) | Derivatives from blog | -- | Pending |
| W2 | [Pillar 2] | Tutorial | [Working title] | [keyword] | Draft |
| W2 | [Pillar 2] | Newsletter | Digest + tutorial excerpt | -- | Pending |
| W3 | [Pillar 3] | Case Study | [Customer story] | [keyword] | Draft |
| W4 | [Pillar 1] | Comparison | [vs. Competitor X] | [keyword] | Draft |
```

Include: pillar rotation, format variety, keyword targeting, dependencies.

### Step 4: Produce Content Briefs

For each content piece in the calendar, produce a brief:

1. **Title & Working Title**: SEO-optimized title + internal working title
2. **Target Keyword**: Primary keyword + 2-3 secondary keywords (from seo-topic-map)
3. **Content Type**: Blog / Tutorial / Case Study / Comparison / Newsletter
4. **Target Length**: Word count range
5. **Audience**: Which ICP segment
6. **Outline**: H2/H3 structure with key points per section
7. **CTA**: What action should the reader take next
8. **Internal Links**: Which existing content to link to (from topic map clusters)
9. **SEO Checklist**: Title tag, meta description, alt text guidance, URL slug
10. **Distribution**: Where this piece will be shared (channels from channel-playbook)

### Step 5: Content Multiplication Workflow

Define how each pillar piece generates 5+ derivatives:

```
1 Blog Post (pillar)
+-- 3 Social Posts (key takeaways as individual posts)
|   +-- Twitter/X: thread or single post
|   +-- LinkedIn: professional angle
|   +-- Instagram: visual card or carousel
+-- 1 Newsletter Excerpt (summary + link)
+-- 1 Email Sequence Entry (drip campaign content)
+-- 1 Video Script Outline (talking points for 3-5 min video)
+-- 1 Community Post (Reddit/HN value-first version)
```

**Solo Founder Mode** (idea/mvp stage):

Priority order for content multiplication:
1. Primary piece (blog post, guide, or video)
2. Community post (highest leverage per effort — Reddit, HN, Indie Hackers, relevant Slack)
3. Newsletter excerpt (if email list exists)

Social posts are copy-paste from community post. Video script and email sequence deferred to growth stage. Focus on depth over breadth — one great piece per week beats five mediocre ones.

Rules:
- Each derivative adapts tone and format for its platform (reference channel-playbook)
- Derivatives should be publishable standalone (not just "read our blog post")
- Schedule derivatives across the week (don't dump everything on publish day)
- Track which derivatives were created for each pillar piece

### Step 6: Content Performance Framework

Define metrics to track per piece:
- **Traffic**: pageviews, unique visitors, time on page
- **Engagement**: scroll depth, comments, shares, saves
- **Conversion**: CTA clicks, sign-ups, demo requests attributed to content
- **SEO**: ranking position for target keyword, organic traffic over time

Define review cadence:
- Weekly: check new content performance
- Monthly: review top/bottom performers, adjust calendar
- Quarterly: audit all content, refresh/prune underperformers

### Step 7: Validate and Save

1. Save editorial calendar to `artifacts/growth/content-calendar-{quarter}.md`
2. Save content briefs to `artifacts/growth/content-brief-{title}.md`
3. Run `./tools/artifact/validate.sh` on all artifacts
4. Link to seo-topic-map and positioning-messaging artifacts

## Quality Checklist

- [ ] Content mission statement defined
- [ ] 3-5 content pillars aligned with keyword clusters
- [ ] Publishing cadence is realistic for company stage
- [ ] Editorial calendar covers at least 4 weeks
- [ ] Each piece has a content brief with outline and CTA
- [ ] Content multiplication workflow defined (1 piece -> 5+ derivatives)
- [ ] Performance metrics defined per content type
- [ ] Internal linking strategy references seo-topic-map
- [ ] Artifacts have valid frontmatter

## Cross-References

- **seo-topic-map**: Provides keyword clusters and pillar page structure that content-engine fills with actual content plans
- **positioning-messaging**: Provides brand voice and value propositions that guide content tone
- **channel-playbook**: Defines active platforms that determine derivative formats
- **email-lifecycle**: Newsletter and drip sequences consume content from the engine
- **landing-page-copy**: Landing pages may reference or link to content pieces
