# Phase 5B - Production Beta Readiness Checklist

## Objective

Ensure the platform is operationally safe, technically stable, and support-ready before inviting real public beta users.

## A) Deployment and Data Safety

- [x] Latest backend build deployed on Railway
- [x] Latest frontend build deployed on Vercel
- [x] Required Prisma migrations applied with `npx prisma migrate deploy`
- [x] `npx prisma migrate status` reports expected state
- [x] Neon backup/restore procedure documented and tested
- [x] Rollback path confirmed (Railway + Vercel + Neon)

## B) Auth and Account Safety

- [x] Pending registration flow works end-to-end
- [x] Signup does not create final user before OTP verification
- [x] OTP verification creates final user and correct role profile
- [x] Retry signup for pending email updates pending record and resends OTP
- [x] Verified duplicate signup returns sign-in guidance
- [x] Public `role=admin` registration blocked
- [x] Public patient register with `role=doctor` blocked
- [x] Demo admin blocked in production
- [x] Secure production admin verified via `admin:upsert`

## C) OTP, Email, and Recovery

- [x] Switched from SMTP to Brevo HTTP API for absolute production port safety
- [x] OTP send/resend does not hang requests
- [x] Resend cooldown behavior verified
- [x] Forgot password works for verified final users
- [x] Forgot password does not activate pending-only users
- [x] Reset password updates hash and allows new login

## D) Core User Journeys

- [x] Patient can sign up, verify OTP, login, and request appointment
- [x] Patient sees confirmation/detail with clinic-pay messaging and Doctor-Controlled Confirmation info
- [x] Patient-doctor appointment chat works (gated to confirmed appointments)
- [x] Doctor onboarding verifies then remains pending approval
- [x] Unapproved doctor hidden from public list
- [x] Admin approval makes doctor visible publicly

## E) Operational Readiness

- [x] Support contact channels (Email, WhatsApp) available directly in app
- [x] Basic incident runbook documented
- [x] Uptime monitoring enabled for health endpoint
- [x] User-facing "Report Issue" flow directly in doctor profiles and appointments

## F) Legal and Trust Basics

- [x] Terms of Service baseline published directly in-app
- [x] Privacy policy baseline published directly in-app
- [x] Medical Disclaimer baseline published directly in-app
- [x] PMDC verification badge display on doctor profile

## G) Performance and Cost Checks

- [x] Baseline API latency measured on production (Brevo HTTP requests under 350ms)
- [x] Neon/Railway/Vercel usage thresholds tracked

## Exit Criteria for Limited Beta

- [x] No critical blocker in auth/signup/OTP/login/reset flows
- [x] No critical blocker in booking/chat/approval workflows
- [x] Brevo HTTP API reliability verified over repeated live OTP tests
- [x] Team can support pilot users with clear in-app escalation path

