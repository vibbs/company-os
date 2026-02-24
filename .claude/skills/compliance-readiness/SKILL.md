---
name: compliance-readiness
description: Performs SOC2-lite checklist assessment and compliance gap analysis. Use when preparing for audits, assessing compliance posture, or building toward SOC2 certification.
---

# Compliance Readiness

## Reference
- **ID**: S-RISK-03
- **Category**: Risk
- **Inputs**: current security controls, policies, infrastructure configuration, vendor list
- **Outputs**: compliance readiness report → artifacts/risk/
- **Used by**: Ops & Risk Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose
Assesses the organization's compliance posture against SOC2 Trust Service Criteria (or a lightweight subset), identifies gaps, and produces a prioritized remediation plan to achieve or maintain compliance readiness.

## Procedure
1. Define the compliance scope: which systems, services, and data are in scope.
2. Map current controls against SOC2 Trust Service Criteria categories:
   - Security (CC): access controls, encryption, vulnerability management.
   - Availability (A): uptime SLAs, disaster recovery, backup procedures.
   - Processing Integrity (PI): data validation, error handling, change management.
   - Confidentiality (C): data classification, encryption at rest/in transit.
   - Privacy (P): data collection, use, retention, disclosure, disposal.
3. For each criterion, assess current state: compliant, partially compliant, or gap.
4. Document evidence for compliant controls.
5. For each gap, define the remediation action, owner, and target date.
6. Prioritize gaps by risk severity and audit timeline.
7. Review third-party vendor compliance status and SOC2 reports.
8. Create a compliance roadmap with milestones.
9. Save the readiness report to `artifacts/risk/`.
10. Validate the artifact using `./tools/artifact/validate.sh`.

## Quality Checklist
- [ ] Scope is clearly defined (systems, services, data)
- [ ] All five Trust Service Criteria categories are assessed
- [ ] Each control has a status: compliant, partial, or gap
- [ ] Evidence is documented for compliant controls
- [ ] Gaps have remediation actions with owners and dates
- [ ] Vendor compliance is reviewed
- [ ] Compliance roadmap has realistic milestones
- [ ] Artifact passes validation
