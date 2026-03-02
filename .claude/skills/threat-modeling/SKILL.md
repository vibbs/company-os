---
name: threat-modeling
description: Performs data flow threat analysis with structured mitigations. Use when assessing security threats for new features, architecture changes, or compliance reviews.
argument-hint: "[optional: --quick]"
---

# Threat Modeling

## Reference
- **ID**: S-RISK-01
- **Category**: Risk
- **Inputs**: system architecture, data flow diagrams, trust boundaries, asset inventory
- **Outputs**: threat model document → artifacts/risk/
- **Used by**: Ops & Risk Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose
Produces a structured threat model that identifies attack surfaces, enumerates threats using a systematic methodology (STRIDE), and maps each threat to concrete mitigations, ensuring security is considered proactively rather than reactively.

## Procedure

### Step 0: Stage-Aware Mode Selection

Read `company.stage` from `company.config.yaml`. If `idea` or `mvp`:

**MVP Security Checklist** (use instead of full STRIDE):
1. Auth provider (not roll-your-own)
2. HTTPS enforced
3. Input sanitization on all user-supplied fields
4. Payment webhook signature verification (if applicable)
5. No secrets in code (run `./tools/security/secrets-scan.sh`)
6. Dependency scanning configured

Reserve full STRIDE analysis for `growth`/`scale` stages or features touching financial data/PII at scale. If user passes `--quick`, always use MVP mode regardless of stage.

1. Define the scope: which system, feature, or data flow is being modeled.
2. Draw or review the data flow diagram (DFD): external entities, processes, data stores, data flows.
3. Identify trust boundaries: where data crosses between trust zones.
4. Enumerate threats using STRIDE (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege) for each element.
5. Rate each threat: likelihood (1-5) and impact (1-5), calculate risk score.
6. For each threat, define a mitigation: preventive control, detective control, or accepted risk.
7. Prioritize mitigations by risk score.
8. Document residual risks: threats accepted without full mitigation.
9. Define review triggers: when this threat model should be revisited.
10. Save the threat model to `artifacts/risk/`.
11. Validate the artifact using `./tools/artifact/validate.sh`.

## Cross-References
- **security-posture** (S-RISK-04) — aggregate view of all threat model findings across features; run `/security-posture` for cross-cutting risk inventory
- **release-readiness-gate** (S-QA-03) — consumes threat model as a required artifact for Bar 3 (Security & Risk)

## Quality Checklist
- [ ] Scope is clearly defined and bounded
- [ ] Data flow diagram is complete with all trust boundaries
- [ ] STRIDE analysis covers all DFD elements
- [ ] Each threat has likelihood and impact ratings
- [ ] Every high-risk threat has a defined mitigation
- [ ] Residual risks are explicitly documented and accepted
- [ ] Review triggers are specified
- [ ] Artifact passes validation
