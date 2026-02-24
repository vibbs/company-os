---
name: tos-privacy-drafting
description: Drafts Terms of Service and Privacy Policy outlines tailored to the product. Use when creating initial legal documents or reviewing existing TOS/Privacy Policy for completeness.
---

# TOS & Privacy Policy Drafting

## Reference
- **ID**: S-LEGAL-01
- **Category**: Legal
- **Inputs**: product description, data handling policy, jurisdiction requirements, business model
- **Outputs**: TOS and Privacy Policy draft outlines → artifacts/legal/
- **Used by**: Ops & Risk Agent
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose
Produces structured draft outlines for Terms of Service and Privacy Policy documents that cover the essential legal requirements, tailored to the product's business model, data practices, and target jurisdictions. These are outlines for legal review, not final legal documents.

## Procedure
1. Gather inputs: product description, business model, data handling policy, target jurisdictions.
2. Draft the **Terms of Service** outline covering:
   - Service description and eligibility
   - Account registration and responsibilities
   - Acceptable use policy and prohibited conduct
   - Intellectual property rights (user content, platform IP)
   - Payment terms, billing, and refund policy (if applicable)
   - Limitation of liability and warranty disclaimers
   - Termination and suspension conditions
   - Dispute resolution (arbitration, governing law, jurisdiction)
   - Modification of terms and notification procedures
3. Draft the **Privacy Policy** outline covering:
   - Data collected: what, how, and why
   - Legal bases for processing (consent, legitimate interest, contract)
   - Data sharing: third parties, processors, international transfers
   - User rights: access, correction, deletion, portability, objection
   - Data retention periods
   - Cookie policy and tracking technologies
   - Children's privacy (COPPA compliance if applicable)
   - Contact information for privacy inquiries
4. Flag jurisdiction-specific requirements (GDPR, CCPA, etc.) that need legal counsel review.
5. Mark all sections as DRAFT — NOT LEGAL ADVICE.
6. Save the draft outlines to `artifacts/legal/`.
7. Validate the artifact using `./tools/artifact/validate.sh`.

## Quality Checklist
- [ ] TOS covers all standard sections for a SaaS product
- [ ] Privacy Policy addresses data collection, use, sharing, and rights
- [ ] Jurisdiction-specific requirements are flagged
- [ ] Payment and billing terms match the business model
- [ ] User rights section covers GDPR and CCPA requirements
- [ ] All sections are clearly marked as DRAFT for legal review
- [ ] Document includes disclaimer that it is not legal advice
- [ ] Artifact passes validation
