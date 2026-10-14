---
name: system-maintenance
description: Audits and syncs Company OS documentation after structural changes. Use after adding, removing or changing skills, agents, tools, artifact types or stage gates.
user-invocable: true
---

# System Maintenance

Run this skill after ANY structural change to the Company OS (new/deleted/renamed skill, agent, or tool; modified `validate.sh` or `check-gate.sh`). It ensures all documentation stays in sync.

## Trigger Conditions

This skill MUST run after:
- Creating, deleting, or renaming a skill directory in `os/skills/`
- Creating, deleting, or renaming an agent file in `os/agents/`
- Creating or deleting a tool script in `tools/`
- Modifying artifact types in `tools/artifact/validate.sh`
- Modifying stage gates in `tools/artifact/check-gate.sh`

Skills and agents are authored under `os/`. `.claude/skills/` and `.claude/agents/` are generated from it, so audit `os/` and regenerate with `bash tools/build/build.sh` rather than editing the generated copies.

## Where the facts are documented

Audit these places. Do not recreate this content in `SETUP.md`, which is only the install quickstart.

| Fact | Documented in |
|------|---------------|
| Skills by owning agent | `.company-os/docs/CONCEPTS.md` ("Skills by agent") |
| Tools by category, artifact tools | `.company-os/docs/CONCEPTS.md` ("Tools by category", "Artifact tools") |
| Stage gate and stage tables | `.company-os/docs/CONCEPTS.md` ("Stages and gates") |
| Directory tree | `.company-os/docs/CONCEPTS.md` ("Where things live") |
| Skill, tool and agent counts | `README.md`, `.company-os/docs/CONCEPTS.md`, `.company-os/docs/ROADMAP.md` |
| Adding a skill, agent, tool or artifact type | `.company-os/docs/CUSTOMIZING.md` |
| Config sections | `.company-os/docs/CONFIG_REFERENCE.md` |
| Diagram numbers | `docs/diagrams/render.js` (run `node docs/diagrams/render.js --check`) |

## Procedure

### Step 1: Detect Current State

Run the health check and inventory what actually exists:

```bash
./tools/registry/health-check.sh
bash tools/build/build.sh --check
```

Then build a current inventory:
- Count skill directories: `ls -d os/skills/*/ | wc -l`
- Count agent files: `ls os/agents/*.md | wc -l`
- Count runnable tool scripts: `find tools -name "*.sh" -type f -not -path "tools/build/*" -not -path "tools/lib/*" | wc -l`
- List artifact types from `validate.sh` (grep for `VALID_TYPES`)
- List stage gates from `check-gate.sh` (grep for gate names)

### Step 2: Audit CLAUDE.md

Read `CLAUDE.md` and verify:
- **Architecture table**: Does it list the correct layer locations?
- **Key files list**: Are all key files mentioned?
- **Enforcement tools list**: Does it reference all tools in `tools/artifact/`?
- **Ingest reference**: Is `/ingest` mentioned if the skill exists?
- **Skill count**: If mentioned, does it match the actual count?

Report discrepancies with specific line numbers.

### Step 3: Audit the user docs

Read `.company-os/docs/CONCEPTS.md` and verify:
- **Skills by agent**: Does each owner row list every skill that agent's `skills:` frontmatter names?
- **Tools by category**: Does each category row list every script in that `tools/` folder?
- **Artifact tools**: Does it list all tools in `tools/artifact/` and describe what each does?
- **Stage gates and stages**: Do the gate and stage tables match `check-gate.sh`?
- **Directory tree**: Does it match the actual directory structure?

Then read `.company-os/docs/CUSTOMIZING.md` and confirm its steps for adding a skill, agent, tool or artifact type still match the real files and the build. Report discrepancies with specific section names.

### Step 4: Check count drift

Compare every count written in prose with the filesystem numbers from Step 1:

```bash
grep -nE '[0-9]+ (skills|agents|tool scripts|scripts)' README.md .company-os/docs/*.md CLAUDE.md
```

Ignore counts inside CHANGELOG entries for past versions. Fix any other count that disagrees. Where a count is not needed, replace it with a pointer to the directory (for example "see `os/skills/`") so it cannot drift.

### Step 5: Audit Agent Files

For each agent in `os/agents/`:
- Read its `skills:` frontmatter list
- Verify each listed skill directory exists in `os/skills/`
- Check if any relevant NEW skills should be added to this agent
- Verify tool scripts listed in the agent body actually exist

For the **orchestrator** specifically:
- Check delegation patterns cover all available skills
- Check gating rules reference current gate names

### Step 6: Check Cross-References

- Do skills reference tools that exist? (Grep skill files for `tools/` paths, verify each)
- Do agents reference skills that exist? (Check `skills:` lists against `os/skills/`)
- Are there orphan skills not listed in any agent?
- Do slash commands in docs match skill `name:` values (for example `/rapid-prototype`, `/token-cost-ledger`)?

### Step 7: Report

Present a summary:
```
SYSTEM MAINTENANCE REPORT
=========================
Skills:  [actual count] found, [documented count] in README / CONCEPTS
Agents:  [actual count] found
Tools:   [actual count] found

DISCREPANCIES:
  [file]: [section] - [what's wrong]
  ...

NO DISCREPANCIES FOUND (if clean)
```

### Step 8: Apply Fixes

For each discrepancy:
- Show the specific edit needed (file, section, old value, new value)
- Apply the fix using Edit tool (edit `os/` for skills and agents, then run `bash tools/build/build.sh`)
- After all fixes, re-run `./tools/registry/health-check.sh`, `bash tools/build/build.sh --check` and `node docs/diagrams/render.js --check`

If no discrepancies: report "All documentation is in sync" and exit.

## Reference

- **ID**: S-ORG-07
- **Category**: Orchestration
- **Inputs**: all agent, skill, tool, and documentation files
- **Outputs**: corrected documentation files
- **Used by**: User (directly), Orchestrator Agent
- **Tool scripts**: `./tools/registry/health-check.sh`
