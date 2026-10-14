# Security policy

## Report a vulnerability

Please report security problems privately. Do not open a public issue.

Use GitHub private vulnerability reporting: <https://github.com/vibbs/company-os/security/advisories/new>

Include what you found, the steps to reproduce it, and which version you tested (`.company-os/version`). We will acknowledge your report, keep you updated while we fix it, and credit you in the release notes if you want.

## What is in scope

- `install.sh`: download, extraction, file writes and the upgrade merge
- Tool scripts in `tools/` (for example path handling, command injection, unsafe temp files)
- Hooks in `os/hooks/` and `.claude/hooks/`, and the permissions that `/setup` and `.company-os/setup.sh` generate

Out of scope: weaknesses in the AI runtimes themselves, and in products you build with Company OS.

## Supported versions

| Version | Supported |
|---------|-----------|
| 1.12.x | Yes |
| Older | No. Upgrade with `/upgrade-company-os`. |
