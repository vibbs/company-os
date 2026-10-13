# Plan: End-user docs, language, and diagram overhaul

**Spec (binding authority):** the user's goal — "review the entire repo from an end user's perspective; improve docs, easy-to-understand language, and enterprise-level SVG block diagrams; review at every cycle; list issues then address them."

**Findings (evidence, read the ones your task names):** `.superpowers/sdd/2026-10-13-end-user-docs-overhaul/`
- `review-readme.md` (README / onboarding, items R1–R29)
- `review-docs.md` (SETUP / FAQ / TOKEN_COSTS / ROADMAP / CHANGELOG, items D1–D19 and diagram spots D1–D10 in last section)
- `review-skills.md` (skills / agents, items S1–S21)
- `review-tools.md` (tool scripts, items H1–H3, M1–M5, L1–L7)
- `diagram-spec.md` (verified content for the SVG diagram set)

Item numbers refer to the numbered list items in each file in order (e.g. R3 = item 3 in review-readme.md).

## Global Constraints

1. **Source of truth is `os/`.** Edit skills in `os/skills/<name>/SKILL.md` and agents in `os/agents/<name>.md`, never `.claude/skills` or `.claude/agents` directly. After any change under `os/` or to `CLAUDE.md`, run `bash tools/build/build.sh` and commit the regenerated adapters (`.claude/`, `.cursor/`, `.cursorrules`, `AGENTS.md`, `GEMINI.md`, `.codex/`) in the same commit.
2. README.md, `.company-os/docs/*.md`, `os/README.md`, `docs/**` are hand-authored (not generated).
3. **Real counts** (verify again before writing; never guess): 64 skills (`ls -d os/skills/*/ | wc -l`), 9 agents, 33 tool scripts excluding `tools/build` (`find tools -name '*.sh' -not -path 'tools/build/*' | wc -l`), current version `1.11.0` in `.company-os/version`. Prefer fewer hard-coded counts in prose; where a count is shown, it must be correct.
4. **Real command names:** a slash command equals the skill's `name:`. `/rapid-prototype` (NOT `/prototype`), `/token-cost-ledger` (NOT `/token-cost`). Skill directories are not renamed.
5. **Plain-language style:** short sentences, active voice, lead with what the reader does or gets. Define jargon on first use (PRD = product requirements document, RFC = technical design doc, COGS, gate, stage, artifact, adapter, runtime). No marketing fluff ("cannot be argued with", "soft-talked out of"). No em-dash chains in skill descriptions.
6. **Shell scripts:** bash 3.2 compatible (macOS). All use `set -euo pipefail`; any `grep` that may match nothing needs `|| true` (or sits in an `if`). No `${var,,}`. macOS/Linux `sed -i` compatibility via the existing `uname` pattern.
7. Skill frontmatter canonical schema is `docs/superpowers/SCHEMA.md` (moved by Task 5): Claude-only fields `user-invokable`, `disable-model-invocation`, `argument-hint` live under `runtimes.claude:`. Generated `.claude/skills/*/SKILL.md` must still expose them in the form Claude Code reads (verify `tools/build/build-claude.sh` does this before migrating).
8. Commit style: conventional (`docs:`, `fix:`, `feat:`, `chore:`), one concern per commit, subject ≤72 chars, body explains why. End every commit message with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Never push.
9. Diagrams are SVG files under `docs/diagrams/svg/`, embedded in Markdown with `![alt text](relative/path.svg)`. Relative paths must resolve from the embedding file (README at repo root; `.company-os/docs/X.md` uses `../../docs/diagrams/svg/...`).
10. Verification gate before any task reports DONE: `bash tools/build/build.sh --check` passes; every relative Markdown link and image in files you touched resolves (write a quick check); for scripts, run the specific commands you changed.

---

## Task 1: Harden tool scripts (help, config parsing, silent aborts)

Files: `tools/**/*.sh` except `tools/build/*` (plus `tools/build/build.sh` for the two items named), new `tools/lib/` helpers.

Fix review-tools.md items H1, H2, H3, M1, M2, M3, M4, M5, L1, L5 (L5: allow the `id` field in health-check / schema so 10 skills stop warning; check `tools/build/schema/` and `tools/registry/health-check.sh`). Specifically:
- Every script accepts `-h` and `--help` as the first argument, prints its existing header comment block (Tool / Usage / Inputs / Outputs) cleanly (no shebang line, no `====` rules), and exits 0 **before** any side effect. Implement once in `tools/lib/usage.sh` (sourced) or an equivalent tiny inline snippet; be consistent.
- Create `tools/lib/config.sh` with one robust `cfg_get <dotted.key>` reader (strips trailing `# comments`, quotes, whitespace; anchored by indentation; returns empty string when missing, never aborts). Use it in lint-format.sh, run-tests.sh, migration-check.sh and any other ad-hoc reader where the swap is mechanical. Confirm with the shipped `company.config.yaml` that the linter/test framework values are now empty strings (not the comment text).
- Add `|| true` (or equivalent) to every unguarded grep pipeline listed in H3, including `extract_field` in check-gate.sh / promote.sh / link.sh / validate.sh, search-skill.sh, health-check.sh. Prove it: create a temp artifact lacking `parent:` and run check-gate rfc-to-impl / prd-to-rfc against it; the intended human message must print.
- M1: missing option values print `ERROR: --x requires a value` to stderr and exit 1 (build.sh `--runtime`, dashboard.sh `--out`/`--period`, install.sh `--branch`/`--version`/`--runtime`); unknown flags error with usage.
- M2: stub scripts parse their flags properly and print a clear "(stub — no provider configured)" line.
- M3: usage/errors go to stderr; fix check-gate usage text drift (impl-to-qa checks test plan); missing artifact path in check-gate exits 2 regardless of stage; add `validate.sh --all` (validates every `artifacts/**/*.md` with YAML frontmatter, prints a summary line, non-zero if any invalid).
- M4: sast.sh / secrets-scan.sh error when the scan path does not exist; install-runtime.sh cd's to repo root; build.sh header comments describe current behavior (os/ is the source), not "Phase A/C".
- New `tools/lib/` must be picked up by install.sh (it merges every `tools/*/` subdirectory — confirm) and must not be counted as a "tool script" in user docs (helpers are sourced, not run).
Verification: run `--help` for every script (loop) and show all exit 0 with no side effects; run `bash tools/artifact/validate.sh --all`; `bash tools/registry/health-check.sh` (expect 0 warnings for `id`); `bash tools/build/build.sh --check`.

## Task 2: Enterprise SVG diagram system

Files: `docs/diagrams/svg/*.svg` (new), `docs/diagrams/render.js` (new, Node, zero dependencies), `docs/diagrams/README.md` (new), `docs/diagrams/generate.js` + `*.excalidraw` (update stale content only).

Build a small zero-dependency Node generator `docs/diagrams/render.js` that emits a consistent, enterprise-grade SVG set from declarative specs. Content comes from `diagram-spec.md` (verified against the repo; re-verify any number you draw). Diagrams (8):
1. `system-overview.svg` — your repo + Company OS overlay; three layers (Agents → Skills → Tools) with Artifacts as the handshake; `os/` → build → runtime adapters strip.
2. `agent-org.svg` — Orchestrator over Product, Engineering (Staff → Backend / Frontend / DevOps), QA & Release, Growth, Ops & Risk, with skill counts.
3. `ship-flow.svg` — the /ship pipeline as swimlanes or a left-to-right flow: each step, the agent, the artifact produced, the gate diamonds placed AFTER the artifact they check, human-approval markers, optional steps visually distinct.
4. `stage-gates.svg` — matrix: stages (idea / mvp / growth / scale) × gates (prd-to-rfc, rfc-to-impl, impl-to-qa, release): advisory vs enforced.
5. `artifact-lineage.svg` — PRD → RFC → impl → test plan / QA report → launch brief, with status lifecycle (draft → review → approved) and enforcement chain (validate → link → promote → check-gate).
6. `multi-runtime-build.svg` — `os/` (source) → `tools/build/build.sh` + validators → `.claude/`, `.cursor/`, `AGENTS.md`, `GEMINI.md`, `.codex/` (Aider reads AGENTS.md) with "edit here / generated" labels.
7. `install-upgrade.svg` — one install command → runtime auto-detect / `--runtime` → files installed; upgrade path (`--check`, `--dry-run`, apply, backup/rollback) and `/upgrade-company-os`.
8. `workflow-paths.svg` — which flow to start with: `/gtm-sprint` (validate demand) → `/rapid-prototype` (prove tech) → `/ship` (build & launch), plus the inbound feedback loop (customer-conversations → feedback-synthesizer → sprint-prioritizer → prd-writer).

Design system (apply to all 8): one shared theme object in render.js; system font stack (`-apple-system, Segoe UI, Inter, Helvetica, Arial, sans-serif`); 8px grid; rounded cards (radius 10) with 1px borders and a subtle drop shadow filter; a restrained palette with one accent per layer/agent family (color is never the only signal — every color also has a text label); title + one-line subtitle in each diagram; legend where shapes carry meaning; arrows with consistent markers; no text below 12px; text never overflows its box (compute widths conservatively; ~7.2px per char at 13px). **Dark and light mode:** embed `<style>` with CSS variables and `@media (prefers-color-scheme: dark)` overrides so the SVG reads well on GitHub light and dark themes; background is a filled rounded panel (not transparent) so contrast is guaranteed. Every SVG has `role="img"`, `<title>` and `<desc>`. Width ≤ 1200, viewBox set, no external fonts/images.
Verification: render each SVG to PNG with headless Chrome (`"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --screenshot=... --window-size=... file://...`) in both light and dark (`--force-dark-mode` or emulate via a wrapper HTML that sets `color-scheme`), LOOK at every PNG (Read tool) and fix overlaps, clipped text, crossing arrows, misalignment. Keep the PNGs out of the repo (scratch dir). `node docs/diagrams/render.js` must regenerate identical output. `docs/diagrams/README.md` explains the set, how to regenerate, and the style rules. Also update stale counts/steps in `generate.js` and regenerate the `.excalidraw` files so they are not contradictory (keep them as editable sources).

## Task 3: Skill and agent descriptions, command names, schema migration

Files: `os/skills/*/SKILL.md`, `os/agents/*.md`, `CLAUDE.md`, `tools/build/*` only if needed for the migration; regenerated adapters.

Fix review-skills.md items S1–S21 except S2's README part (Task 6 does README). Specifically:
- S1: every reference to `/prototype` → `/rapid-prototype`, `/token-cost` → `/token-cost-ledger` across `os/`, `CLAUDE.md`, `.company-os/docs/*`, `standards/`, `tools/` (grep the whole repo excluding `.git`, generated files are rebuilt).
- S3 + S5 + Global Constraint 7: migrate `user-invokable`, `disable-model-invocation`, `argument-hint` under `runtimes.claude:` in every os/ skill per SCHEMA.md; set the invokable flag explicitly on every skill (true for user-facing entry points, false for helper skills only the agents use — judge from the skill body; prd-writer, architecture-draft, icp-positioning, landing-page-copy, threat-modeling, release-readiness-gate are user-facing). First confirm `build-claude.sh` emits these to `.claude/skills/*/SKILL.md` in the form Claude Code reads (top-level `user-invokable`); fix the builder if not. Result: `build.sh --check` reports 0 warnings.
- S6–S9, S16–S18: rewrite descriptions: third-person verb-first, plain outcome first, then "Use when …", ≤ ~200 chars, jargon expanded once, no internal paths, no em dashes. Use the proposed rewrites as a starting point. Argument hints: `[a | b | c]` for enums, `<description>` for free text; add hint to product-led-growth; gtm-sprint includes the day count.
- S10: agent descriptions in plain language; sub-agents and orchestration agents say they are usually invoked by the Engineering Agent or by /ship.
- S4, S11–S15: upgrade-company-os step numbering + "What you will see" sample output for check/preview/apply/rollback; add a short "What you will see" sample to ship (sample gate prompt + how to approve/stop), status (sample summary table), gtm-sprint (sample plan excerpt + gate-check), artifact-import (before/after frontmatter + the ambiguity question); add a 5–8 line "At a glance" overview at the top of setup and ship bodies. Do not renumber steps that other files reference by number unless you update those references too (grep first).
- Run `bash tools/build/build.sh`, commit regenerated adapters.
Verification: `bash tools/build/build.sh --check` → 0 failures, 0 warnings; `grep -rn "/prototype\b\|/token-cost\b"` over repo (excluding .git and plan workspace) returns nothing user-facing; description length report (all ≤ 220 chars).

## Task 4: Restructure user docs (.company-os/docs, os/ docs, config, scripts help)

Files: `.company-os/docs/*.md` (SETUP split into new files), `docs/superpowers/` (moved), `os/README.md`, `os/hooks/README.md`, `os/playbooks/README.md`, `company.config.yaml` (comments only), `setup.sh` (help only), `install.sh` (header/help text only), `CLAUDE.md` (path references only), `install.sh` manifest/docs copying if new docs need it.

Fix review-docs.md items D1–D19 and review-readme.md items R19–R26. Specifically:
- Split `.company-os/docs/SETUP.md` (851 lines) into: `SETUP.md` (quickstart ≤ ~150 lines: prerequisites, install, pick your runtime table, /setup, verify it worked checklist, first /ship, next steps, links), `CONCEPTS.md` (glossary of 8–10 terms; three layers; agents & delegation; artifacts & lineage; stages & gates; ship flow with "your job at each gate"), `CONFIG_REFERENCE.md` (every config section labeled Required/Optional; one copy of the express template), `CUSTOMIZING.md` (edit `os/`, run build.sh; adding skills/agents/standards; authoring schema link), and `TROUBLESHOOTING.md` (git not initialised, python3/jq missing, curl|bash concerns, wrong runtime detected, hook blocks promote, validate errors, gate fails, permission prompts, health-check). No content lost: every substantive fact in the old SETUP.md lands somewhere (keep a checklist in your report).
- FAQ: add a "Getting started" block at the top (cost, which runtime, without Claude Code, uninstall — document manual removal list since there is no uninstall script, customize, upgrade, stages), each answer leading with a one-sentence answer; move the existing 10 under "Deep dives"; add a Related footer.
- TOKEN_COSTS and ROADMAP: correct stale facts (counts, Engineering skill count, CLAUDE.md length, .claude/skills path → os/skills), add multi-runtime note, move shipped roadmap items to a collapsed Shipped list, add multi-runtime as completed.
- CHANGELOG: add `## [Unreleased]` describing the multi-runtime work (Phases A–D: AGENTS.md, GEMINI.md, .cursor, .codex, os/ as source of truth, build.sh + validators + schema, install.sh --runtime, tools/registry) and this overhaul (docs split, SVG diagrams, tool hardening, description rewrite, command name fixes). Do not bump the version.
- Move `docs/superpowers/SCHEMA.md` → `docs/contributing/SKILL_SCHEMA.md` and `docs/superpowers/specs/*` → `docs/design/` (mark the spec "Status: Implemented"); fix every reference (`grep -rn "docs/superpowers"`), including tools/build validators and Global Constraint 7's path in this plan is irrelevant to code.
- Embed the Task 2 SVGs where they help: CONCEPTS (system-overview, agent-org, artifact-lineage, stage-gates, ship-flow), SETUP (install-upgrade, workflow-paths), CUSTOMIZING and os/README (multi-runtime-build). Use correct relative paths and meaningful alt text.
- os/README, hooks/playbooks READMEs: say plainly they are placeholders, list the three real Claude hooks; clarify Aider uses AGENTS.md.
- company.config.yaml: comments only — "Run /setup instead of editing by hand", stage meanings, `# --- Optional sections below ---`, note `models:` applies to Claude Code. YAML must still parse identically (compare values before/after with the Task 1 `cfg_get` or a python yaml load if available).
- setup.sh `--help`; install.sh header lists `--runtime`, help has Examples, docs URL, notes that `--check`/`--changelog` need an existing install, and `--version` example format matches.
- Use one terminology: "sub-agent", "skill (run as /name)", "artifact" only for agent outputs, "adapter" for generated runtime files.
Verification: link/image checker over all touched Markdown; `bash -n setup.sh install.sh`; `bash setup.sh --help`; `bash install.sh --help`; build.sh --check.

## Task 5: README rewrite for first-time users

Files: `README.md` only (plus `LICENSE` untouched).

Rewrite README.md around a newcomer's first five minutes, fixing review-readme.md R1–R18, R27–R29 and S2's command list. Structure:
1. Title, two plain sentences on what it is and who it is for, a one-line nav bar.
2. Hero image: `docs/diagrams/svg/system-overview.svg`.
3. Quickstart (install command, review-first option, start your runtime, `/setup`, first `/ship`), with a per-runtime "after install" table (Claude Code, Cursor, Codex, Gemini, Aider: what gets installed, what you type).
4. Which flow should I use? (`workflow-paths.svg`) — /gtm-sprint vs /rapid-prototype vs /ship in a 3-row table.
5. Commands: complete table of every user-invokable skill (name as `/name`, one-line purpose, arguments) — generated from frontmatter after Task 3 (read `runtimes.claude.user-invokable`). State how to discover commands in each runtime.
6. How it works: three layers (correct dependency rule: agents use skills and run tools; skills only recommend tools), agents (`agent-org.svg`), ship flow (`ship-flow.svg`), stage-aware gates (`stage-gates.svg` + small table), artifacts (`artifact-lineage.svg`), hooks (3-row table; Claude Code only), feature support by runtime table.
7. Install options (flag table matching `install.sh --help` exactly), what gets installed, updating, uninstalling (honest manual list).
8. Customizing (edit `os/`, run build.sh; `multi-runtime-build.svg`), token costs (short + link), docs index linking SETUP, CONCEPTS, CONFIG_REFERENCE, CUSTOMIZING, TROUBLESHOOTING, FAQ, TOKEN_COSTS, ROADMAP, CHANGELOG, contributing schema.
9. Glossary (8–10 one-liners), License `[MIT](LICENSE)`.
Merge "Design Philosophy" and "Why Company OS" into one short evidence-based "Why" section. Keep ASCII diagrams out (SVG replaces them). Soften "never touches your source" to "does not modify your application code"; remove the false uninstall claim. Every count, flag, path, and command must be verified against the repo.
Verification: link/image checker; script that cross-checks every `/command` mentioned in README against `os/skills/*/SKILL.md` names; every install flag in README appears in `install.sh --help`.

## Task 6: Consistency sweep and system maintenance

Files: any file with stale counts/paths/names found by the sweep; `CLAUDE.md` (only if facts are wrong); regenerated adapters.

Run the `system-maintenance` skill procedure (`os/skills/system-maintenance/SKILL.md`) end to end against the changes from Tasks 1–5. Then repo-wide sweeps: stale counts (`62 skills`, `31 tool`, `63 skills`), `docs/superpowers`, `.claude/skills/` or `.claude/agents/` given as the place to *edit*, `/prototype`, `/token-cost` (non-ledger), "Phase A/C" wording in user-facing text. Fix what you find. Update `tasks/todo.md` with a review section summarizing the overhaul. Add one lesson to `tasks/lessons.md` (counts drift: prefer pointing at the directory over hard-coding counts). Rebuild adapters.
Verification: build.sh --check (0 failures, 0 warnings); `bash tools/registry/health-check.sh`; `bash tools/artifact/validate.sh --all`; link/image checker across all *.md outside .git and artifacts; grep sweeps return nothing.
