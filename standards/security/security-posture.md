# Security Posture Standard

Defines the security baseline for Company OS projects: tool risk tiering, secrets policy, mandatory human-review checkpoints, and safe execution defaults. Agents read this standard during security reviews and release readiness checks.

---

## 1. Tool Tiering Policy

Every tool script is classified by blast radius. Agents must respect these tiers.

| Tier | Name | Description | Examples | Who Can Use |
|------|------|-------------|----------|-------------|
| 0 | Read-only | No state change. Safe for all agents, all contexts. | `validate.sh`, `check-gate.sh`, `dependency-scan.sh`, `secrets-scan.sh`, `sast.sh`, `support-faq-check.sh`, `status-check.sh` | All agents |
| 1 | Write-local | Writes to artifact files or local ledger. No external impact. | `link.sh`, `promote.sh`, `token-ledger.sh` | All agents, with artifact frontmatter |
| 2 | Write-external | Affects deployment state, release artifacts, or infrastructure config. | `pre-deploy.sh`, `version-bump.sh`, `smoke-test.sh` | Engineering Agent only; Orchestrator approves |
| 3 | Human-required | Irreversible or high-blast-radius operations on production systems. | Production DB ops, billing changes, secret rotation, credential updates | Requires explicit user confirmation |

### Tier Classification Rules
- Default tier for new tools is **Tier 1** (write-local) unless the tool interacts with external systems
- Tool tier is documented in the tool script's header comment: `# Tier: 0|1|2|3`
- Agents must not escalate tier — a Tier 0 tool cannot be used in a Tier 2 context

---

## 2. Secrets Policy

### 2.1 What Counts as a Secret
- API keys (Stripe, Resend, analytics providers, etc.)
- Authentication tokens (JWT signing secrets, OAuth client secrets)
- Database connection strings containing credentials
- Private keys (SSH, SSL/TLS certificates)
- Webhook signing secrets
- Third-party service credentials (AWS, GCP, Vercel tokens)
- Encryption keys

### 2.2 Storage Rules by Stage

| Stage | Secret Storage | Rationale |
|-------|---------------|-----------|
| `idea` / `mvp` | `.env` files (local, git-ignored) | Speed over ceremony |
| `growth` | Environment variables via hosting provider (Vercel, Railway, etc.) | No local secrets in CI |
| `scale` | Dedicated secret manager (AWS Secrets Manager, Vault, Doppler) | Audit trail + rotation |

All stages: template secrets in `.env.example` with placeholder values. Never commit actual values.

### 2.3 Redaction Guidelines
- **In logs**: replace secret values with `[REDACTED]` before writing to any file or artifact
- **In artifacts**: never include actual secret values; reference by environment variable name (e.g., `STRIPE_SECRET_KEY`)
- **In LLM context**: if sending code context that may contain secrets, strip `.env` file contents. Use `secrets-scan.sh` to verify before committing.

### 2.4 Allowlist Mechanism
- Create `standards/security/secrets-allowlist.txt` to document known false positives
- Format: one pattern per line with explanation comment
  ```
  # Test API key used only in seed data
  sk_test_example123
  ```
- `secrets-scan.sh` checks for this file and excludes matched patterns

### 2.5 Secret Rotation Policy

| Trigger | Action |
|---------|--------|
| Suspected exposure (commit, log leak, breach) | Rotate immediately. Tier 3 confirmation required. |
| Team member departure | Rotate all shared secrets within 24 hours |
| Annual review | Rotate long-lived secrets (internal API keys with no external exposure) |
| Dependency vulnerability | Rotate if the vulnerability could have exposed secrets |

Rotation procedure: human confirms → generate new secret → update all dependent services → verify functionality → revoke old secret → document in incident record.

---

## 3. Mandatory Human-Review Checkpoints

These operations require explicit user confirmation before any agent proceeds. The agent must present the information specified below and wait for the user's typed confirmation.

### 3.1 Production Data Deletion

**Trigger**: Any operation that deletes customer records, truncates tables, or drops data.

**Agent must present**:
- Table/collection name
- Estimated record count affected
- Whether a backup exists
- Recovery options (point-in-time restore, soft-delete reversal)
- Rollback plan

**User confirms**: Acknowledges the scope and confirms deletion.

### 3.2 Billing Configuration Changes

**Trigger**: Plan price changes, discount grants, refunds above configured threshold, payment method removal.

**Agent must present**:
- Current state (existing price, plan, discount)
- Proposed change
- Number of affected customers
- Revenue impact estimate (monthly/annual)

**User confirms**: Acknowledges the financial impact and confirms the change.

### 3.3 Production Database Schema Changes

**Trigger**: Any DDL operation in production (ALTER TABLE, DROP COLUMN, DROP TABLE, index changes).

**Agent must present**:
- Migration SQL (forward)
- Rollback SQL (reverse)
- Estimated downtime or lock duration
- Backup confirmation

**User confirms**: Acknowledges the migration scope and confirms execution.

### 3.4 Secret Rotation

**Trigger**: Any operation that generates, changes, or revokes production secrets.

**Agent must present**:
- Which secret is being rotated
- New value storage location
- Services that depend on this secret
- Test plan to verify post-rotation

**User confirms**: Acknowledges the rotation scope and confirms.

### 3.5 External Credential Changes

**Trigger**: Changing API keys for payment processors, email providers, analytics, or external APIs in production.

**Agent must present**:
- Service name and old key reference
- New key source (dashboard URL, CLI command)
- Features that depend on this credential
- Verification steps

**User confirms**: Acknowledges the credential update and confirms.

---

## 4. Safe Execution Defaults

These defaults apply to all agent operations unless explicitly overridden by the user.

1. **Smallest scope first** — default to the narrowest scope possible (single artifact, single feature, single table). Never default to "all."
2. **Dry-run before write** — when a tool has a `--dry-run` flag, run it first and present results before the real execution.
3. **Validate before promote** — always run `validate.sh` before `promote.sh`. The pre-promote hook enforces this, but agents should also call it explicitly.
4. **No silent side effects** — every tool invocation must be visible in the conversation. Agents must not run tools in the background without informing the user.
5. **Pre-deploy checks pass first** — `pre-deploy.sh` must pass before any deployment-related tool is invoked.
6. **Read before write** — always read a file before editing it. Never write to a file blindly.
7. **Log destructive actions** — any Tier 2 or Tier 3 operation should be noted in the relevant artifact (decision-memo, incident record, or changelog).

---

## 5. Posture Snapshot

A posture snapshot is a `security-review` artifact that aggregates the current security state of the project. It is stored in `artifacts/security-reviews/` with a `POSTURE-` prefix.

### When to Generate
- Before any release (part of release readiness)
- After resolving a security incident
- Monthly, if the project is in `growth` or `scale` stage
- On demand via `/security-posture`

### What It Contains
- Open findings from all threat model artifacts (CRITICAL/HIGH/MEDIUM)
- Last scan dates for `dependency-scan.sh` and `secrets-scan.sh`
- Compliance status against this standard's 4 sections
- Unresolved human checkpoint triggers
- Recommendations for next actions

### CLI Check
Run `./tools/security/posture-check.sh` for a quick CLI posture summary without generating a full artifact.
