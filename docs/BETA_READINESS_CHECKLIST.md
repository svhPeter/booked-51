# Phase 5B - Production Beta Readiness Checklist

## Objective

Ensure the platform is operationally safe, technically stable, and support-ready before inviting real public beta users.

## A) Deployment and Data Safety

- [ ] Latest backend build deployed on Railway
- [ ] Latest frontend build deployed on Vercel
- [ ] Required Prisma migrations applied with `npx prisma migrate deploy`
- [ ] `npx prisma migrate status` reports expected state
- [ ] Neon backup/restore procedure documented and tested
- [ ] Rollback path confirmed (Railway + Vercel + Neon)

## B) Auth and Account Safety

- [ ] Pending registration flow works end-to-end
- [ ] Signup does not create final user before OTP verification
- [ ] OTP verification creates final user and correct role profile
- [ ] Retry signup for pending email updates pending record and resends OTP
- [ ] Verified duplicate signup returns sign-in guidance
- [ ] Public `role=admin` registration blocked
- [ ] Public patient register with `role=doctor` blocked
- [ ] Demo admin blocked in production
- [ ] Secure production admin verified via `admin:upsert`

## C) OTP, Email, and Recovery

- [ ] SMTP configured and tested with `npm run smtp:test`
- [ ] OTP send/resend does not hang requests
- [ ] Resend cooldown behavior verified
- [ ] Forgot password works for verified final users
- [ ] Forgot password does not activate pending-only users
- [ ] Reset password updates hash and allows new login

## D) Core User Journeys

- [ ] Patient can sign up, verify OTP, login, and book appointment
- [ ] Patient sees confirmation/detail with clinic-pay messaging
- [ ] Patient-doctor appointment chat works
- [ ] Doctor onboarding verifies then remains pending approval
- [ ] Unapproved doctor hidden from public list
- [ ] Admin approval makes doctor visible publicly

## E) Operational Readiness

- [ ] Support contact channel available in product/docs
- [ ] Basic incident runbook documented
- [ ] Error monitoring enabled (recommended: Sentry)
- [ ] Uptime monitoring enabled for health endpoint
- [ ] Log access ownership and on-call responsibility clear

## F) Legal and Trust Basics

- [ ] Terms of Service baseline published
- [ ] Privacy policy baseline published
- [ ] Data correction/removal request process documented
- [ ] Unclaimed profile governance policy drafted (for future phase)

## G) Performance and Cost Checks

- [ ] Baseline API latency measured on production
- [ ] Neon/Railway/Vercel usage thresholds tracked
- [ ] Alert thresholds set for error spikes and downtime

## Exit Criteria for Limited Beta

- [ ] No critical blocker in auth/signup/OTP/login/reset flows
- [ ] No critical blocker in booking/chat/approval workflows
- [ ] SMTP reliability verified over repeated OTP tests
- [ ] Team can support pilot users with clear escalation path
