# Customizing Company OS

Make Company OS follow your processes: change a skill, add your own, teach agents your house rules, or bring in documents you already have.

**The one rule: edit `os/`, then run `bash tools/build/build.sh`.** Files under `.claude/agents/`, `.claude/skills/`, `.cursor/`, `.codex/`, `AGENTS.md` and `GEMINI.md` are generated adapters. The build overwrites any hand edits to them.

---

## How the build works

![Multi-runtime build: os/skills and os/agents are validated, then build.sh generates .claude/, AGENTS.md, GEMINI.md, .cursor/rules and .codex/](diagrams/multi-runtime-build.svg)

| You edit | Build step | Generated output |
|----------|------------|------------------|
| `os/skills/<name>/SKILL.md`, `os/agents/<name>.md` | `build-claude.sh` | `.claude/skills/`, `.claude/agents/` |
| `os/`, `CLAUDE.md` | `build-agents-md.sh` | `AGENTS.md` (Codex, Aider, other AGENTS.md runtimes) |
| same | `build-gemini.sh` | `GEMINI.md` |
| same | `build-cursor.sh` | `.cursor/rules/*.mdc`, `.cursorrules` |
| same | `build-codex.sh` | `.codex/config.md` |

```bash
bash tools/build/build.sh                  # rebuild every adapter
bash tools/build/build.sh --runtime=cursor # rebuild one adapter
bash tools/build/build.sh --check          # validate skills and agents without writing
```

Commit both `os/` and the regenerated adapters, so anyone who clones the repo gets a working setup without a build step. Claude Code's hooks (`.claude/hooks/`), settings (`.claude/settings.json`) and agent memory are not generated: edit them directly.

The full frontmatter schema for skills and agents is in [SKILL_SCHEMA.md](SKILL_SCHEMA.md).

---

## Change an existing skill

1. Open `os/skills/<name>/SKILL.md` and edit the procedure, templates or checklists. Supporting files (templates, references) sit next to `SKILL.md`.
2. Run `bash tools/build/build.sh`.
3. Run `./tools/registry/health-check.sh` to confirm every skill still passes.

Or ask an agent: "Change the prd-writer skill so every PRD has a Non-goals section."

## Add a skill

Ask an agent: "Create a new skill called `my-custom-skill` that handles [your use case]." Or by hand:

1. Create `os/skills/<skill-name>/SKILL.md`. The directory name must equal `name`.
   ```yaml
   ---
   name: skill-name             # lowercase-hyphens, max 64 characters
   description: What this skill does. Use when [situation].
   runtimes:
     claude:
       user-invokable: true     # optional: lets users run it as /skill-name
       argument-hint: "<what to pass>"   # optional: shown after /skill-name
   ---
   ```
2. Write the procedure in the body. Put custom metadata in a Reference section at the end.
3. Add supporting files (templates, examples) next to `SKILL.md`.
4. Add the skill name to the `skills:` list of the owning agent in `os/agents/<agent>.md`.
5. Run `bash tools/build/build.sh`, then `./tools/registry/health-check.sh`.

## Add an agent

Ask an agent: "Create a new agent for [responsibility] that uses [these skills]." Or by hand:

1. Create `os/agents/<agent-name>.md`:
   ```yaml
   ---
   name: agent-name             # lowercase-hyphens; must match the filename
   description: What this agent does. Use for [situation].
   tools: Read, Write, Edit, Bash, Grep, Glob
   model: sonnet                # opus | sonnet | haiku (Claude Code only)
   skills:
     - skill-directory-name     # loaded into the agent's context when it starts
   ---
   ```
2. Write the agent's instructions in the body. Include a Reference Metadata section.
3. Update the Orchestrator's routing in `os/agents/orchestrator.md` if it should receive work automatically.
4. Run `bash tools/build/build.sh`.

## Add a tool

1. Create a `.sh` file in the right `tools/<category>/` folder.
2. Start it with a header comment: Tool, Description, Usage, Inputs, Outputs.
3. Use `set -euo pipefail` and keep it bash 3.2 compatible (the macOS default).
4. Source `tools/lib/usage.sh` so `--help` prints that header, and `tools/lib/config.sh` to read settings with `cfg_get <section.key>`. Copy the two `source` lines from any existing tool.
5. Make it executable: `chmod +x tools/<category>/<tool>.sh`.
6. Mention the tool in the skills that should recommend it.

## Add an artifact type

1. Add the type to `VALID_TYPES` in `tools/artifact/validate.sh`.
2. Create a matching folder under `artifacts/`.
3. Update the skills that should produce the new type.

## Trim skills to cut cost

Each skill an agent lists in `skills:` is loaded every time that agent starts. Removing skills you never use from `os/agents/<agent>.md` (then rebuilding) lowers token cost. See [TOKEN_COSTS.md](TOKEN_COSTS.md#how-to-reduce-costs).

After any structural change (new, removed or renamed skill, agent or tool; changes to `validate.sh` or `check-gate.sh`), run `/system-maintenance` to bring the docs back in sync.

---

## Teach agents your standards

Put permanent reference documents in `standards/`. Agents read them continuously. Then run `/ingest`.

| Folder | Put here |
|--------|----------|
| `standards/api/` | OpenAPI specs, API style guides, error format examples, auth docs |
| `standards/coding/` | Code style guides, lint configs, naming conventions, architecture decision records |
| `standards/compliance/` | SOC 2, GDPR or HIPAA requirements, audit logging rules |
| `standards/templates/` | Your own artifact templates (these override the skill defaults), PR and issue templates |
| `standards/brand/` | Brand guidelines, design tokens, logo rules, component library or Figma links |
| `standards/ops/` | Runbooks, incident severity definitions, SLOs and escalation policies, on-call templates |
| `standards/analytics/` | Event naming, tracking plans, dashboard and KPI definitions, consent rules |
| `standards/docs/` | Documentation style guides, API doc and end-user doc conventions, release note formats |
| `standards/email/` | Email templates, lifecycle sequences, deliverability and transactional-vs-marketing rules |
| `standards/engineering/` | Engineering principles, ADRs, code ownership and review policy, release procedures |
| `standards/growth/`, `standards/mobile/`, `standards/security/` | Channel playbooks; mobile platform guidelines; security posture and threat model baselines |
| `standards/engineering-preferences.md` | Your team's engineering philosophy (used by `code-review`) |

When brand standards exist, agents use them for visual requirements and tone.

### Run `/ingest`

Ask: "I've added our API spec to standards/api/. Run /ingest." It will:

1. Scan `standards/` and `artifacts/` for new or changed files.
2. Work out which skills and agents are affected.
3. Compare the new standard with the current skill procedure.
4. Suggest specific updates.
5. Apply them after you review (or automatically, if you say so).

This is how your house rules end up inside the skill procedures.

---

## Import documents you already have

`standards/` holds **permanent** reference docs. `imports/` is a **temporary** drop zone for existing specs (PRDs, design docs, API specs, test plans) that you want to bring into the artifact lifecycle.

1. Export the documents from Google Docs, Notion, Confluence or wherever, as Markdown or HTML.
2. Put them in `imports/`.
3. Run `/artifact-import`, or ask: "I've placed our PRD and architecture doc in imports/. Import them."

You can also paste content directly: "Import this as a PRD: [paste]".

The import skill:

- classifies each document by type (PRD, RFC, test plan, ...),
- adds a YAML header with a unique ID,
- restructures the content to match the Company OS template (best effort),
- detects and links related documents,
- moves each file to the right `artifacts/` folder and deletes it from `imports/`,
- validates every result.

Imported artifacts start at `review`, not `draft`, because they are already complete. Read them, then promote to `approved`, parents first (PRD before RFC). Gates apply immediately, and the Orchestrator can carry on from them (for example, from an imported PRD to a new RFC). Run `/ingest` afterwards if the imports should change skill procedures.

---

## Things you can just ask for

| Ask | What runs |
|-----|-----------|
| "Build a team management feature where org admins can invite, remove and manage members with roles." | The full ship flow: PRD, RFC, threat model, build, QA, release |
| "Is the auth feature ready to ship?" | `check-gate.sh release`: lists which artifacts exist, which are missing, and their status |
| "What artifacts do we have? What's the state of the project?" | `/status` (or `detect-changes.sh`): every artifact with its type and status |
| "I've exported our PRD from Notion into imports/. Bring it in." | `/artifact-import` |
| "I've added our API spec to standards/api/. Sync the system." | `/ingest` |
