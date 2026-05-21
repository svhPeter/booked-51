# Product Strategy — DocBook Pakistan

## Vision

A **free appointment booking platform** for Pakistan that helps patients find doctors and book visits without friction, while doctors adopt the platform at zero cost. Consultation fees are **shown for transparency**; payment happens **at the clinic or directly with the doctor**—not through the platform at launch.

## Target users

| User | Need |
|------|------|
| **Patients** | Search doctors by specialty/city, book slots, get reminders, message doctor about the visit |
| **Doctors** | Manage schedule, see bookings, reduce no-shows, optional video consult |
| **Admins** | Verify doctors, moderate platform quality, view operational metrics |

## Product principles

1. **Free to book** — No platform fee for patients; no subscription required for doctors to receive bookings.
2. **Clinic-pay model** — Online payment (Stripe/PayFast) remains **dormant** until legally and operationally ready.
3. **Trust by verification** — Doctors appear publicly only after admin approval.
4. **Appointment-scoped chat** — Messaging tied to a booking, not open social chat.
5. **Scale across Pakistan** — City and specialty discovery first; provinces and clinics later.

## Pakistan market fit

- Mobile-first (Flutter web now; native iOS/Android later).
- PKR consultation fees displayed as informational.
- PayFast/Stripe code kept for future optional online pay.
- SMS/WhatsApp OTP when email deliverability is weak (Phase 5+).
- Urdu/English UI can follow once core flows are stable.

## Monetization (later — not Phase 4)

Revenue should not block doctor adoption:

| Model | Description |
|-------|-------------|
| Sponsored listings | Featured doctors in search results |
| Clinic SaaS | Multi-doctor clinic dashboard, branding |
| Verified badge | Paid verification badge after document check |
| Doctor analytics | Appointment trends, no-show rates |
| Sponsorships / ads | Health brands, pharmacies (careful UX) |
| Optional commission | Only when online payment is enabled and agreed with doctors |

## Competitive positioning

- Simpler than hospital ERP systems.
- More trustworthy than unstructured WhatsApp booking.
- Free entry vs platforms that charge per appointment upfront.

## Success metrics (early)

- Doctors onboarded and approved
- Appointments booked per week
- Booking completion rate (book → show up proxy: completed appointments)
- Doctor retention (active doctors month-over-month)
- Patient repeat bookings

## Out of scope (Phase 4)

- Online payment in active user flow
- Prescriptions and reviews (Phase 2F backlog)
- Native app store release
- Full province/city reference database

## Related docs

- [PHASE_4_SCOPE.md](PHASE_4_SCOPE.md) — Implementation scope
- [CHAT_SYSTEM_PLAN.md](CHAT_SYSTEM_PLAN.md) — Messaging design
- [COST_AND_SCALE_PLAN.md](COST_AND_SCALE_PLAN.md) — Infrastructure costs
