# Setup Guide

Install Company OS into your repo, configure it in one command, and ship your first feature. Plan on about 10 minutes.

Company OS adds a team of AI agents, a set of step-by-step skills, and checking scripts to your existing project. It does not modify your application code. New to the terms? Read the [glossary in CONCEPTS.md](CONCEPTS.md#glossary).

![Install and upgrade flow: install.sh detects your runtimes, installs os/, AGENTS.md and the matching adapters, then /upgrade-company-os keeps them current](diagrams/install-upgrade.svg)

---

## 1. Prerequisites

| You need | Why |
|----------|-----|
| macOS, Linux, or Windows with WSL | The installer and tools are bash scripts (bash 3.2 or newer) |
| `curl` (or `wget`) and `tar` | The installer downloads and unpacks the release |
| `git` (a git repo is recommended) | Company OS uses git history as its audit trail. The installer works without a repo but warns you; run `git init` before you commit |
| An AI coding runtime: Claude Code, Cursor, Codex CLI, Gemini CLI, or Aider | Company OS runs inside it |
| `python3` (recommended) | Merges permissions into an existing `.claude/settings.json` |
| `jq` (recommended, Claude Code only) | The two artifact hooks (validate before promote, header check after write) skip themselves silently without it |

## 2. Pick your runtime

You choose runtimes when you install, using the `--runtime` flag. By default (`--runtime auto`) the installer looks for the runtimes on your machine and installs files for each one it finds. To choose yourself, pass one or more names, as shown in the next step.

| Runtime | `--runtime` value | Extra files installed | How to start |
|---------|-------------------|--------------------------------------------------------|--------------|
| Claude Code | `claude` | `.claude/` (agents, skills, hooks, settings) | Run `claude`, then type `/setup` |
| Cursor | `cursor` | `.cursor/rules/*.mdc`, `.cursorrules` | Open the folder in Cursor, ask it to "run the setup skill" |
| Codex CLI | `codex` | `.codex/config.md` | Run `codex`, ask it to "run the setup skill" |
| Gemini CLI | `gemini` | `GEMINI.md` | Run `gemini`, ask it to "run the setup skill" |
| Aider | `aider` | nothing extra; Aider reads `AGENTS.md` | Start Aider, ask it to follow the setup skill in `AGENTS.md` |

Every install also gets the shared files: `os/`, `tools/`, `AGENTS.md`, `CLAUDE.md` (the other runtimes' files point to it for full conventions) and `company.config.yaml`. Other values: `all` installs every adapter; `core` installs only the shared files. Add a runtime later with `./tools/registry/install-runtime.sh <runtime>`; see what is installed with `./tools/registry/list-runtimes.sh`.

Some features exist only in Claude Code: slash commands, the three automatic hooks, and per-agent memory. See [CONCEPTS.md](CONCEPTS.md#runtimes-and-adapters).

## 3. Install

From your project root:

```bash
curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh | bash
```

To choose runtimes yourself, add `-s -- --runtime=<name>` after `bash`. Use one name or several separated by commas (`claude`, `cursor`, `codex`, `gemini`, `aider`, `all` or `core`):

```bash
curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh | bash -s -- --runtime=cursor
```

Prefer to read the script before running it:

```bash
curl -fsSL https://raw.githubusercontent.com/vibbs/company-os/main/install.sh -o install.sh
less install.sh
bash install.sh --runtime=cursor   # or leave the flag off to auto-detect
```

Run `bash install.sh --help` to see every flag (`--runtime`, `--version`, `--dry-run`, `--force`, and more).

**Mono repo:** install once at the repo root; `company.config.yaml` describes the shared stack. **Multi repo:** install in each repo; each keeps its own config and artifacts.

## 4. Configure with `/setup`

`/setup` fills in `company.config.yaml`, creates the working folders, and (Claude Code only) writes `.claude/settings.json` permissions for your stack. Commit the installed files first so you can see what it changes.

Pick the mode that suits you:

| Mode | What you type | Best for |
|------|---------------|----------|
| Interactive | `/setup` | First-timers. One question per section, with defaults. |
| Express | `/setup` followed by a filled-in block (see [CONFIG_REFERENCE.md](CONFIG_REFERENCE.md#express-setup-template)) | Power users. No back-and-forth. |
| Auto-extract | `/setup https://yourproduct.com`, or `/setup` plus a pasted pitch, brief, or Notion export | Fastest. The wizard fills what it can and asks only about the gaps. |

The most important field is `company.stage` (`idea`, `mvp`, `growth`, or `scale`). It sets how strictly quality checks block you; see [stages and gates](CONCEPTS.md#stages-and-gates).

No AI runtime yet? Run `bash setup.sh` to create the folders and a blank config, then edit `company.config.yaml` by hand using [CONFIG_REFERENCE.md](CONFIG_REFERENCE.md).

## 5. Verify it worked

You should now have:

- [ ] `company.config.yaml` with at least `company.name`, `company.stage`, `tech_stack.language` and `tech_stack.framework` filled in
- [ ] `os/`, `tools/`, `AGENTS.md` and `CLAUDE.md` at the project root, plus your runtime's files from the table above
- [ ] `artifacts/`, `standards/`, `imports/` and `tasks/` folders
- [ ] `./tools/registry/health-check.sh` ends with "Health check PASSED"
- [ ] `./tools/artifact/validate.sh --all` runs without errors (it is fine if there are no artifacts yet)
- [ ] In Claude Code: a new session opens with a short Company OS context line (company, stage, branch), and `/status` prints a project summary

Something off? See [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## 6. Ship your first feature

Pick the flow that matches where you are:

![Which workflow to start with: /gtm-sprint to test demand, /rapid-prototype to prove the idea works, /ship to build and release](diagrams/workflow-paths.svg)

| Flow | Use it when | You get |
|------|-------------|---------|
| `/gtm-sprint` | You are not sure anyone will pay. No code needed. | Interview notes, a pain matrix, LOIs (letters of intent: written commitments to buy or pilot), positioning, a landing page, and a go/no-go call after 7, 14 or 21 days |
| `/rapid-prototype` | You need a demo or proof of concept fast | A time-boxed MVP (minimum viable product, the smallest working version; 4 hours, 1 day or 3 days) that skips the design doc, security review and full QA |
| `/ship` | You are building something real | A PRD (product requirements document), design doc, code, QA report and launch assets, with a pause for your approval at each gate |

For example:

```text
/ship Team management: org admins can invite, remove and change roles of team members
```

`/ship` pauses at each gate. Your job at each pause is described in [CONCEPTS.md](CONCEPTS.md#the-ship-flow). In Cursor, Codex, Gemini or Aider, ask the agent to "run the ship skill for ..." instead of typing the slash command.

## 7. Next steps

| Do this | When |
|---------|------|
| Drop existing PRDs or design docs into `imports/` and run `/artifact-import` | You already have specs elsewhere |
| Drop style guides, API specs or brand rules into `standards/` and run `/ingest` | You want agents to follow your house rules |
| Run `/dev-environment` | You want Docker Compose, `.env.example` and dev scripts for your stack |
| Run `/design-system` | You are building UI and want a consistent visual style |
| Run `/upgrade-company-os check` | Monthly, to see if a new version is out |

## Further reading

| Doc | What it covers |
|-----|----------------|
| [CONCEPTS.md](CONCEPTS.md) | Glossary, the three layers, agents, artifacts, stages and gates, the ship flow, where files live |
| [CONFIG_REFERENCE.md](CONFIG_REFERENCE.md) | Every `company.config.yaml` section, required versus optional |
| [CUSTOMIZING.md](CUSTOMIZING.md) | Changing skills and agents, adding tools, standards and imports |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Fixes for common install, hook, validation and gate problems |
| [FAQ.md](FAQ.md) | Cost, runtimes, uninstalling, and deep dives on how things work |
| [TOKEN_COSTS.md](TOKEN_COSTS.md) | What Company OS adds to your AI token bill |
| [CHANGELOG.md](CHANGELOG.md) / [ROADMAP.md](ROADMAP.md) | What changed, and what is planned |
