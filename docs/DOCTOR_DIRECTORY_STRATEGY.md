# Phase 5C - Pakistan Doctor Directory Strategy

## Objective

Expand doctor discovery safely and credibly in Pakistan without blind scraping or privacy-risk publication.

## Core Rule

No blind scraping. Public doctor data must be source-backed, reviewable, and correctable.

## 1) Directory Model

### Profile Types

- **Claimed profile**: doctor-managed profile with verified ownership
- **Unclaimed profile**: source-backed public listing not yet doctor-claimed

### Labeling

- Unclaimed profiles must be clearly labeled "Unclaimed"
- Claimed profiles can display stronger trust indicators after verification

## 2) Source and Data Policy

### Allowed Sources

- Publicly available, legally usable, source-attributable information
- Clinic-published doctor listings with clear public intent
- Doctor-submitted onboarding information

### Disallowed Practices

- Blind scraping of sensitive/private data
- Publishing personal data that is not clearly public/consented
- Implied endorsement without verification

## 3) Data Fields and Governance

### Core Fields

- Name
- City/area
- Specialty
- Clinic/hospital association
- Consultation fee (informational)
- PMDC registration number (stored when available)

### Governance Rules

- Track data provenance internally
- Allow correction requests with SLAs
- Allow remove/hide requests with admin review
- Maintain audit trail of profile changes

## 4) Claim Flow

1. Doctor requests profile claim
2. Platform verifies ownership/identity
3. Admin reviews and approves claim
4. Doctor edits and manages profile details
5. Profile status changes from unclaimed to claimed

## 5) Public Trust and Safety

- Only approved doctors should be publicly bookable.
- Unclaimed profiles should not enable full doctor chat workflows by default.
- Sensitive contact details should be protected unless policy permits.
- Verification badge must have clear criteria and auditability.

## 6) SEO and Discovery Strategy

- Build city -> area -> specialty landing structures
- Publish high-quality, low-noise profile pages
- Prioritize accurate local intent terms (city/specialty/clinic)
- Keep content trustworthy and continuously corrected

## 7) Rollout Approach

### Stage 1

- Keep current approved-doctor model as source of truth
- Improve profile quality and city/specialty metadata

### Stage 2

- Add unclaimed profile ingestion with strict source policy
- Add claim workflow and admin moderation

### Stage 3

- Expand coverage city-by-city
- Add trust signals (verified badge, update freshness)

## 8) Risks and Mitigations

1. **Incorrect profile data** -> correction workflow + admin moderation
2. **Doctor trust concerns** -> transparent claim and removal path
3. **Privacy complaints** -> strict source policy + rapid takedown process
4. **SEO spam risk** -> quality controls, no thin/duplicate content

## 9) Success Metrics

- Claimed profile conversion rate
- Profile correction turnaround time
- City/specialty page search impressions and CTR
- Booking conversion from directory pages
- Doctor satisfaction with claim/update process
