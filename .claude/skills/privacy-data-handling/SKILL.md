---
name: privacy-data-handling
description: Defines data retention policies, access controls, and deletion procedures. Use when establishing or auditing how personal and sensitive data is stored, accessed, and removed.
---

# Privacy & Data Handling

## Reference
- **ID**: S-RISK-02
- **Category**: Risk
- **Inputs**: data inventory, regulatory requirements (GDPR, CCPA), system architecture
- **Outputs**: data handling policy document → artifacts/risk/
- **Used by**: Ops & Risk Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose
Establishes clear policies for data retention, access controls, and deletion procedures that comply with privacy regulations and protect user data throughout its lifecycle from collection to destruction.

## Procedure
1. Inventory all personal and sensitive data collected: what data, where stored, why collected.
2. Classify data by sensitivity level: public, internal, confidential, restricted.
3. Define retention periods for each data category based on business need and regulatory requirements.
4. Design access control policies: who can access what data, under what conditions, with what audit trail.
5. Define the data deletion procedure: user-initiated deletion, retention-based expiry, right-to-be-forgotten flows.
6. Document data processing lawful bases (consent, legitimate interest, contractual necessity).
7. Define data breach notification procedures: detection, assessment, notification timeline.
8. Design audit logging for all data access and modifications.
9. Map data flows to third-party processors and define DPA requirements.
10. Save the data handling policy to `artifacts/risk/`.
11. Validate the artifact using `./tools/artifact/validate.sh`.

## Quality Checklist
- [ ] All personal data fields are inventoried
- [ ] Data classification levels are assigned
- [ ] Retention periods are defined and justified
- [ ] Access controls follow principle of least privilege
- [ ] Deletion procedures cover all storage locations (DB, backups, caches, logs)
- [ ] Breach notification timeline meets regulatory requirements
- [ ] Third-party data processors are documented with DPAs
- [ ] Artifact passes validation
