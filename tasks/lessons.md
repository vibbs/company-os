# Lessons Learned

Accumulated corrections and patterns from previous sessions. Review at session start.
When this section exceeds ~20 entries, consolidate: merge related lessons, move resolved ones to Archive.

## Patterns

<!-- Add lessons here after corrections or when noticing recurring friction -->
<!-- ### [Date] [Topic]
- **Mistake**: What went wrong
- **Fix**: What the correct approach is
- **Rule**: Generalized rule to prevent recurrence -->

### 2026-10-14 Counts drift
- **Mistake**: Hard-coded counts (skills, tools, tokens) in README, docs and diagrams went stale after structural changes, and different docs disagreed (3,400 vs 3,450 tokens).
- **Fix**: Point at the directory (`os/skills/`) instead of a number where a count adds nothing. Where a count stays, derive it (`render.js` computes diagram numbers) and check it with `/system-maintenance` (count drift step).
- **Rule**: Prefer pointing at a directory over hard-coding counts. When one fact lives in several docs, change all copies in the same commit.

### 2026-10-14 Verify runtime field names against current docs
- **Mistake**: Skills used `user-invokable` for years (it was even recorded as "correct" in memory), but Claude Code reads `user-invocable`, so `false` never hid helper skills from the `/` menu.
- **Fix**: Renamed to `user-invocable`; the build and validators accept the old spelling as a deprecated alias.
- **Rule**: Before relying on a runtime-specific field, check the runtime's current docs, and verify the effect (here: is the skill hidden?), not just that the build passes.

## Archive

<!-- Consolidated or resolved lessons moved here. Not surfaced by SessionStart hook. -->
