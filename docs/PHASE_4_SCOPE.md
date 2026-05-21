# Phase 4 Scope

## Overview

| Sub-phase | Goal | Status |
|-----------|------|--------|
| **4A** | Free booking UX, profiles, sign-out, admin doctor approval, home UX | In progress |
| **4B** | Appointment-scoped chat (REST + Socket.io) | Planned after 4A |

Payment backend and Prisma `Payment` model remain **unchanged and dormant** in the active user flow.

---

## Phase 4A — Product stabilization + free booking

### 4A.1 Free booking flow

- [x] Remove `/patient/payment` from active booking path
- [x] `appointment_confirmation_screen.dart` after successful book
- [x] `appointment_detail_screen.dart` with cancel, video, fee note
- [x] `GET /api/v1/appointments/:id` (patient/doctor/admin on record)
- [x] Microcopy: consultation fee (pay at clinic), no online payment

### 4A.2 Profiles and sign-out

- [x] `GET/PUT /api/v1/patients/me`
- [x] `GET/PUT /api/v1/doctor/profile`
- [x] Patient and doctor profile screens
- [x] Sign-out menu on patient, doctor, admin shells
- [x] OTP verify redirect by role
- [x] Optional `POST /auth/logout` from client

### 4A.3 Admin doctor approval

- [x] `Doctor.isApproved` field + migration
- [x] Public listing: `isActive` + `isApproved`
- [x] `PUT /admin/doctors/:id/approve` and `/reject`
- [x] Admin Flutter approve/reject/deactivate UI

### 4A.4 UX polish

- [x] Patient shell: bottom nav (Home, Search, Appointments, Profile)
- [x] Upcoming appointment card on home
- [x] Specialty chips → search with query param
- [x] Doctor public profile fee disclaimer
- [x] Doctor self-profile edit from dashboard

### 4A acceptance criteria

1. Patient books without seeing payment providers.
2. Confirmation shows fee + “pay at clinic” message.
3. Patient can open appointment detail and cancel.
4. All roles can sign out and edit basic profile.
5. Unapproved doctors do not appear in public search.
6. `npm run build` and `flutter analyze` pass.

---

## Phase 4B — Appointment chat

### Backend

- [x] `Message.appointmentId` migration (additive)
- [x] `GET/POST /appointments/:id/messages`
- [x] `PUT /appointments/:id/messages/read`
- [x] `GET /appointments/:id/messages/unread-count`
- [x] `GET /admin/appointments/:id/chat-meta` (metadata only)
- [x] Socket.io rooms `appointment:{id}` with membership check

### Flutter

- [x] `chat_screen.dart` from appointment detail
- [x] Socket.io client + 10s polling fallback
- [x] Unread badge on appointment cards

### 4B acceptance criteria

1. Only patient and doctor on the appointment can read/send messages.
2. Admin sees counts/timestamps only, not message body.
3. Messages persist and paginate correctly.

---

## Out of scope

- Stripe webhooks / PayFast live integration
- Prescriptions & reviews (2F)
- iOS/Android store release
- Province/city reference tables
- Message report/block UI (documented for future)

## Deployment notes

After schema migrations on production:

```bash
cd server
npx prisma migrate deploy
```

Never use `migrate reset` or `db push` on Neon production.
