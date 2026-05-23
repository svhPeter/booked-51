# Product Requirements Document (PRD)

## Product

DocBook Pakistan - a Pakistan-first free doctor appointment booking platform

## Version

v1.0 (Pre-UI/UX Polish, Pre-iOS Beta)

## 1) Product Vision

DocBook is a free doctor appointment platform for Pakistan where patients discover doctors, view essential profile details, and book appointments without paying platform fees.

Why this matters in Pakistan:

- Booking is fragmented across calls, walk-ins, WhatsApp chats, and clinic front desks.
- Patients often lack a trusted, simple place to compare doctor basics: specialty, city, clinic, and fee.
- Many doctors and clinics are price-sensitive for software adoption, especially early-stage digital workflows.

Why free booking matters:

- Removes friction for first-time users.
- Accelerates doctor onboarding and network effects.
- Improves retention by avoiding early monetization pressure.

Why clinic-pay/direct-pay model is the right launch model:

- Aligns with existing local behavior and trust patterns.
- Avoids early payment disputes and gateway complexity.
- Keeps growth focused on appointment success and operational reliability first.

At launch, consultation fee is informational only, and payment is handled directly at clinic/doctor level.

## 2) Target Users

### Patients

- Need quick doctor discovery by city/specialty.
- Need transparent fee/address info before booking.
- Need lightweight communication around booked appointments.

### Doctors

- Need a free digital presence and booking channel.
- Need appointment management without expensive software.
- Need verification workflow to build trust.

### Clinics / Front Desk Teams

- Need better booking visibility.
- Need lower no-show risk through reminders and clearer confirmations.
- Need simple handoff between patient and doctor schedules.

### Admin / Operator

- Need doctor verification and quality moderation.
- Need operational visibility (approvals, bookings, activity).
- Need safe controls for launch reliability and abuse handling.

### Future Advertisers / Partners (Later)

- Health brands, diagnostics, pharmacies, clinic groups.
- Participation should not degrade trust or booking UX.

## 3) Core Value Proposition

### For Patients

- Find doctors by city/specialty.
- Check fee/address/specialty before booking.
- Book appointments for free.
- View appointment confirmation and details.
- Chat with doctor only around the booked appointment.
- Receive notifications and OTP-based account safety.

### For Doctors

- Free onboarding and booking funnel.
- Dashboard for appointment workflow.
- Basic patient communication via appointment-scoped chat.
- Verified listing after admin approval.

### For Platform Owner

- Build a trustworthy doctor network by city/specialty.
- Lay SEO foundation for local healthcare discovery pages.
- Preserve future monetization options without blocking adoption.

## 4) Current MVP Scope (Already Implemented)

### Auth and Account Safety

- Email OTP flows for signup and verification.
- Patient signup flow.
- Doctor onboarding flow.
- Forgot password and reset flow.
- Production admin bootstrap controls.
- Demo data separation controls.

### Booking and Care Journey

- Free appointment booking.
- Appointment confirmation/detail screens.
- Patient-doctor appointment chat.
- In-app notifications.
- Profile edit and sign out.

### Trust and Operations

- Admin doctor approval workflow.
- Role guards (patient/doctor/admin).
- Production hardening (rate limiting, CORS, error handling, logging).

### Infrastructure and Deployments

- Frontend: Vercel (Flutter web).
- Backend: Railway (Node/Express + Prisma).
- Database: Neon PostgreSQL.

### Payment Status

- Payment backend exists but remains dormant.
- Active user flow is clinic-pay/direct-pay only.

## 5) Production Readiness Gaps (Before Real Public Beta)

1. Confirm pending registration migration is applied in production.
2. Confirm SMTP deliverability is stable in production.
3. Confirm secure non-demo admin account is active.
4. Confirm demo users are safely isolated/deactivated as needed.
5. Execute full live QA for signup/OTP/login/onboarding/booking/chat.
6. Add centralized error monitoring and alerting.
7. Finalize backup/recovery checks for Neon and deployment rollback.
8. Complete UI/UX polish for confidence and trust at first visit.

## 6) Phase 5A - UI/UX Polish Scope

### Objective

Deliver a polished, mobile-friendly web experience that feels production-grade without changing core business logic.

### Screen Scope

1. Public landing page
2. Login / Signup / OTP / Forgot Password
3. Patient home
4. Doctor search/list
5. Doctor profile
6. Booking flow
7. Appointment confirmation
8. Appointment detail
9. Chat
10. Patient profile
11. Doctor dashboard
12. Doctor profile editor
13. Admin dashboard
14. Admin doctor approval
15. All empty/loading/error states

### UX Standards

- Fast perceived load on low bandwidth.
- Clear success/error language (no silent failures).
- Trust-first visual hierarchy for medical context.
- Consistent spacing, typography, and touch targets.
- Mobile-responsive web and PWA polish.

### Acceptance Criteria

- Every core flow has explicit loading, error, and success states.
- OTP/signup errors are specific and actionable.
- Search -> doctor profile -> booking -> confirmation path is frictionless.
- Admin approval actions are clear and reversible where appropriate.

## 7) Phase 5B - Production Beta Readiness

### Objective

Ship a controlled public beta with operational safety and reliable onboarding.

### Required Checks

- Live QA checklist executed against production.
- Admin safety verified (secure admin account, demo admin blocked).
- SMTP test passed and monitored.
- Pending registration tests passed end-to-end.
- Doctor onboarding + approval path verified.
- Support/contact flow visible to users.
- Basic privacy policy and terms published.
- Monitoring/alerting integrated (recommended: Sentry + uptime checks).
- Neon backup and restore checklist validated.

### Exit Criteria

- Signup/OTP/login/reset flows reliable under normal load.
- No blocker bugs in booking, chat, or approval workflows.
- Operational owner can handle incidents within defined response time.

## 8) Phase 5C - Pakistan Doctor Directory Strategy (Safe Unclaimed Profiles)

### Principle

No blind scraping. No publication of sensitive/private doctor data without source legitimacy and review.

### Strategy

1. Use source-backed public information only.
2. Mark unclaimed profiles clearly as "Unclaimed".
3. Offer doctor claim flow with verification steps.
4. Apply admin review before claim approval.
5. Provide doctor update/remove request workflow.
6. Keep PMDC registration field for verification enrichment.
7. Model city/area/specialty and clinic associations cleanly.

### Trust and Privacy Rules

- No private phone/email disclosure by default.
- Corrections and removals must be honored quickly.
- Unclaimed profile should not imply endorsement.

## 9) Unique / Out-of-the-Box Ideas

1. WhatsApp-assisted booking handoff for low-friction user support.
2. Clinic QR booking posters for walk-in conversion.
3. No-app web booking links for direct doctor/clinic sharing.
4. Low-bandwidth mode with compressed assets and simplified cards.
5. Doctor claim profile flow with progressive verification badge.
6. Area-level SEO pages (city/area/specialty intent capture).
7. Reminder stack (appointment + follow-up nudges).
8. Front-desk mode for clinic staff scheduling.
9. "Available today" doctor discovery filter.
10. Simple doctor mini-site page generated from approved profile.

## 10) Monetization (Later, Not MVP Booking Flow)

No forced patient booking fee in early stage.

Potential future models:

- Sponsored doctor listings
- Verified profile badge
- Featured city/specialty pages
- Doctor analytics tools
- Ads/sponsorships (careful trust-safe placement)
- Premium clinic operational tools

Monetization must not block free patient booking during early growth.

## 11) Technical Architecture (Current)

- Frontend: Flutter web (Vercel), mobile-ready codebase for iOS/Android
- Backend: Node.js + Express (Railway)
- ORM: Prisma
- Database: Neon PostgreSQL
- Auth: JWT access/refresh
- Real-time: Socket.io for appointment chat events
- Email: SMTP OTP delivery with fallback logging
- Governance: admin approval gate for doctor public visibility
- Payments: backend present, active UX dormant

## 12) Risks

1. Wrong or stale doctor data (trust risk)
2. Unverified/low-quality doctor profiles
3. Fake bookings / misuse behavior
4. OTP deliverability degradation
5. Privacy/compliance concerns
6. Support and moderation workload
7. Slow doctor onboarding/adoption
8. Cost scaling under traffic spikes

## 13) Success Metrics

- Verified doctors onboarded
- Appointments booked (daily/weekly)
- Appointment completion rate
- OTP success and completion rate
- Repeat patient booking rate
- Search usage by city/specialty
- Doctor approval turnaround time
- Appointment chat usage rate
- No-show trend (if measurable)

## 14) Build Roadmap

1. Finish production auth/OTP stabilization
2. Complete Phase 5A UI/UX polish
3. Build and validate iOS app package
4. Launch limited beta with 5-10 doctors
5. Collect patient/doctor feedback and iterate
6. Launch public landing + SEO pages
7. Introduce safe doctor claim profile flow
8. Expand city coverage gradually

## Non-Goals (Current)

- No active Stripe/PayFast checkout in user flow.
- No blind doctor scraping/import launch.
- No forced patient convenience fee.
