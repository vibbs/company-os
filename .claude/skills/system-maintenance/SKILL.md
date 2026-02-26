---
name: system-maintenance
description: Audits and syncs all Company OS documentation after structural changes. Use when skills, agents, tools, artifact types, or stage gates are added, removed, or modified.
user-invokable: true
argument-hint: "(no arguments needed)"
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# System Maintenance

Run this skill after ANY structural change to the Company OS (new/deleted/renamed skill, agent, or tool; modified `validate.sh` or `check-gate.sh`). It ensures all documentation stays in sync.

## Trigger Conditions

This skill MUST run after:
- Creating, deleting, or renaming a skill directory in `.claude/skills/`
- Creating, deleting, or renaming an agent file in `.claude/agents/`
- Creating or deleting a tool script in `tools/`
- Modifying artifact types in `tools/artifact/validate.sh`
- Modifying stage gates in `tools/artifact/check-gate.sh`

## Procedure

### Step 1: Detect Current State

Run the health check and inventory what actually exists:

```bash
./tools/registry/health-check.sh
```

Then build a current inventory:
- Count skill directories: `ls -d .claude/skills/*/`
- Count agent files: `ls .claude/agents/*.md`
- Count tool scripts: `find tools/ -name "*.sh" -type f`
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

### Step 3: Audit SETUP_COMPANY_OS.md

Read `SETUP_COMPANY_OS.md` and verify:
- **Skills table**: Does each category row list all skills that actually exist in that category?
- **Tools table**: Does each category row list all tools that actually exist?
- **Stage gate table**: Does it match the gates in `check-gate.sh`?
- **Artifact tools table**: Does it list all tools in `tools/artifact/`?
- **Directory reference tree**: Does it match the actual directory structure?
- **Skill count in tree comment**: Does it say the correct number?

Report discrepancies with specific section names.

### Step 4: Audit Agent Files

For each agent in `.claude/agents/`:
- Read its `skills:` frontmatter list
- Verify each listed skill directory exists in `.claude/skills/`
- Check if any relevant NEW skills should be added to this agent
- Verify tool scripts listed in the agent body actually exist

For the **orchestrator** specifically:
- Check delegation patterns cover all available skills
- Check gating rules reference current gate names

### Step 5: Check Cross-References

- Do skills reference tools that exist? (Grep skill files for `tools/` paths, verify each)
- Do agents reference skills that exist? (Check `skills:` lists against `.claude/skills/`)
- Are there orphan skills not listed in any agent?

### Step 6: Report

Present a summary:
```
SYSTEM MAINTENANCE REPORT
=========================
Skills:  [actual count] found, [documented count] in SETUP_COMPANY_OS.md
Agents:  [actual count] found
Tools:   [actual count] found

DISCREPANCIES:
  [file]: [section] - [what's wrong]
  ...

NO DISCREPANCIES FOUND (if clean)
```

### Step 7: Apply Fixes

For each discrepancy:
- Show the specific edit needed (file, section, old value, new value)
- Apply the fix using Edit tool
- After all fixes, re-run health-check to verify

If no discrepancies: report "All documentation is in sync" and exit.
