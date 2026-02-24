---
name: threat-modeling
description: Performs data flow threat analysis with structured mitigations. Use when assessing security threats for new features, architecture changes, or compliance reviews.
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

## Quality Checklist
- [ ] Scope is clearly defined and bounded
- [ ] Data flow diagram is complete with all trust boundaries
- [ ] STRIDE analysis covers all DFD elements
- [ ] Each threat has likelihood and impact ratings
- [ ] Every high-risk threat has a defined mitigation
- [ ] Residual risks are explicitly documented and accepted
- [ ] Review triggers are specified
- [ ] Artifact passes validation
