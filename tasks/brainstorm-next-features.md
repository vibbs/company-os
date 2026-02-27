# Next Features Brainstorm

Captured from real usage observations. Priority order reflects impact.

---

## 1. Post-Ship "What's Next" Suggestions (HIGH)

**Problem:** After a ship cycle completes, the user is left wondering what to build next. The system has rich context from the just-completed work but doesn't surface it.

**Approach:** Extend the ship skill's final step (not a separate skill) with a "Phase 8: Post-Ship Recommendations" that reads:
- PRD out-of-scope items
- RFC future considerations / tech debt noted
- Deferred decisions from decision memos
- TODO/FIXME comments added during implementation
- Patterns from `tasks/lessons.md`

**Output:** Ranked list of 3-5 natural next moves with one-liner descriptions. User picks one, says "build that", orchestrator kicks off a new cycle.

**Where it lives:** Ship skill procedure, final step. Not a separate skill.

**Decision:** Ephemeral conversation output only. No artifact — avoids cleanup burden if user goes a different direction.

---

## 2. Dev Environment / Docker Compose Generator (HIGH)

**Problem:** The system knows the tech stack (PostgreSQL, Redis, BullMQ from config) but doesn't help set up the actual dev infrastructure. Users have to manually create docker-compose files.

**Approach:** A `dev-environment` skill that reads `company.config.yaml` and generates environment-specific Docker Compose files.

**Key decisions (settled):**
- Lives in `infra/` folder (not project root, not `.devcontainer/`)
- Multiple environment files: `infra/docker-compose.dev.yml`, `infra/docker-compose.qa.yml`, etc.
- Start with basics only — just the services declared in config (db, cache, queue)
- No extras (monitoring, observability) unless user requests them
- Respect that some users deploy with docker-compose on VPS — not just local dev
- No dev containers (overkill for now)

**What gets generated (minimum):**
- `infra/docker-compose.dev.yml` — services from tech_stack config
- `.env.example` — environment variables template
- `tools/dev/start.sh` / `tools/dev/stop.sh` / `tools/dev/reset.sh` — convenience scripts

**What reads from config:**
- `tech_stack.database` → PostgreSQL/MySQL/MongoDB service
- `tech_stack.cache` → Redis/Memcached service
- `tech_stack.queue` → RabbitMQ/BullMQ (uses Redis) service
- `tech_stack.search` → Elasticsearch/Meilisearch (if configured)

**Trigger:** Could be suggested after `/setup` completes: "Run `/dev-environment` to set up your local infrastructure."

**Decisions:**
- Owned by DevOps sub-agent (`engineering-devops`)
- If user already has docker-compose files: offer to review/merge, don't overwrite
- Shell scripts only (no Makefile for now)

---

## 3. Agent Personas / Custom Names (NICE-TO-HAVE)

**Problem:** Agents are referred to by functional names ("Product Agent", "Engineering Agent"). Custom names add personality and make multi-agent conversations more natural.

**Approach:** Optional `personas` section in `company.config.yaml`:
```yaml
personas:
  orchestrator: "Alex"
  product: "Jordan"
  engineering: "Morgan"
  qa_release: "Quinn"
  growth: "Riley"
  ops_risk: "Sage"
```

**Key decisions:**
- Default to functional names if not configured
- Gender-neutral defaults (Alex, Jordan, Morgan, Quinn, Riley, Sage)
- Functional role always visible alongside name: "Morgan (Engineering)"
- Purely cosmetic — zero impact on routing, gating, or functionality
- `/setup` wizard gets an optional fun step: "Want to name your agents?"

**Where it surfaces:**
- Agent self-references in conversation
- Status skill output: "Alex reports: all gates passing"
- Ship flow progress: "Handing off to Morgan for RFC..."

**Implementation touches:**
- Each agent `.md` reads persona from config
- Status skill reads personas for display
- Orchestrator uses names in delegation messages

**Open questions:**
- Should agents also have configurable avatars/emojis? (e.g., "Morgan 🔧")
- Should the user be able to set a custom persona per agent beyond just a name? (tone, formality level)
