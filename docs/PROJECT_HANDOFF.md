# Project Handoff — Doctor Appointment Platform

## Project Overview

A full-stack doctor appointment booking platform with **three portals**: patient, doctor, and admin. Patients can search for doctors by specialty, view available time slots, book appointments, and pay online. Doctors can manage their dashboard, view appointments, and mark them as complete/cancelled. Admins can view platform-wide stats and manage doctors, patients, appointments, and payments.

## Tech Stack

### Backend
- **Runtime:** Node.js + TypeScript (v5.4)
- **Framework:** Express.js (v4.19)
- **Database ORM:** Prisma (v5.14) with PostgreSQL (Neon Serverless)
- **Auth:** JWT access + refresh tokens, bcryptjs
- **Validation:** Zod
- **Real-time:** Socket.io (v4.7)
- **Email:** Nodemailer (OTP verification) with SMTP + console fallback
- **Payments:** Stripe SDK (v15.7), PayFast (Pakistan gateway placeholders)
- **Cache/OTP Store:** ioredis (v5.4) with in-memory Map fallback
- **Dev runner:** tsx (v4.11)

### Frontend
- **Framework:** Flutter (SDK >=3.2) + Dart (>=3.2)
- **State management:** Riverpod (flutter_riverpod v2.5)
- **Routing:** GoRouter (v14.2)
- **HTTP client:** Dio (v5.4)
- **Storage:** flutter_secure_storage (v9.2)
- **UI:** Google Fonts, Shimmer loading, flutter_svg, cached_network_image
- **Payments:** Mock provider (dev), Stripe SDK, PayFast placeholders
- **Video:** Agora RTC Engine (v6.5) — backend token gen + Flutter call UI (mock mode works without keys)
- **Notifications:** Backend Prisma `Notification` model + REST CRUD + Socket.io real-time events; Flutter notification list UI with unread badge
- **Firebase:** Core + Messaging — wired but not yet integrated with server push

### Infrastructure
- **Database:** Neon Serverless PostgreSQL (AWS ap-southeast-1)
- **Cache:** Redis (local, configured for future use)
- **CI:** Not configured

---

## Folder Structure

```
doctor-appointment-platform/
├── server/                         # Backend (Express + Prisma)
│   ├── prisma/
│   │   ├── migrations/             # 2 migrations: init, fix_enum_drift
│   │   ├── schema.prisma           # Full data model
│   │   └── seed.ts                 # Seed script
│   ├── src/
│   │   ├── config/
│   │   │   ├── database.ts         # Prisma client singleton
│   │   │   ├── env.ts              # Env variable loader
│   │   │   └── redis.ts            # Redis client with in-memory fallback
│   │   ├── controllers/
│   │   │   ├── adminController.ts
│   │   │   ├── authController.ts
│   │   │   ├── appointmentController.ts
│   │   │   ├── doctorController.ts
│   │   │   ├── doctorDashboardController.ts
│   │   │   ├── notificationController.ts
│   │   │   └── paymentController.ts
│   │   ├── middleware/
│   │   │   ├── auth.ts             # authenticate + authorize middleware
│   │   │   └── errorHandler.ts     # Global error handler (AppError class)
│   │   ├── routes/
│   │   │   ├── admin.ts
│   │   │   ├── auth.ts
│   │   │   ├── appointment.ts
│   │   │   ├── doctor.ts
│   │   │   ├── doctorDashboard.ts
│   │   │   ├── notification.ts
│   │   │   └── payment.ts
│   │   ├── services/
│   │   │   ├── adminService.ts
│   │   │   ├── authService.ts
│   │   │   ├── appointmentService.ts
│   │   │   ├── doctorService.ts
│   │   │   ├── emailService.ts       # SMTP sender + console fallback
│   │   │   ├── notificationService.ts
│   │   │   ├── otpStore.ts           # OTP generation, store (Redis/Map), rate limiting, max attempts
│   │   │   ├── paymentService.ts
│   │   │   └── providers/
│   │   │       ├── PaymentProvider.ts     # Abstract interface
│   │   │       ├── MockPaymentProvider.ts
│   │   │       ├── StripePaymentProvider.ts
│   │   │       └── PayFastPaymentProvider.ts
│   │   └── index.ts               # App entry point
│   ├── .env
│   ├── package.json
│   └── tsconfig.json
│
├── mobile/                         # Flutter web app
│   └── lib/
│       ├── main.dart
│       ├── app.dart                # GoRouter + redirect guard
│       ├── core/
│       │   ├── constants/api_constants.dart
│       │   ├── network/api_client.dart
│       │   └── theme/app_theme.dart
│       ├── models/
│       │   ├── admin_models.dart
│       │   ├── user.dart
│       │   ├── doctor.dart
│       │   ├── appointment.dart
│       │   ├── notification.dart
│       │   ├── payment.dart
│       │   └── doctor_appointment.dart
│       ├── providers/
│       │   ├── admin_provider.dart
│       │   ├── auth_provider.dart
│       │   ├── doctor_provider.dart
│       │   ├── appointment_provider.dart
│       │   ├── notification_provider.dart
│       │   ├── payment_provider.dart
│       │   └── doctor_dashboard_provider.dart
│       └── screens/
│           ├── admin/ (dashboard, doctors, patients, appointments, payments)
│           ├── auth/ (login, register, otp)
│           ├── common/ (splash, notifications)
│           ├── doctor/ (dashboard)
│           └── patient/ (home, search, profile, booking, appointments, payment)
│
├── docs/                           # Project documentation
│   ├── PROJECT_HANDOFF.md
│   ├── PIPELINE_AND_PHASES.md
│   ├── API_REFERENCE.md
│   ├── DATABASE_AND_MIGRATIONS.md
│   └── NEXT_PHASE_SCOPE.md
│
└── README.md
```

---

## Backend Architecture

### Layered Pattern
```
Route → Controller → Service → Prisma Client → PostgreSQL
                ↕
            Middleware (auth, error handling, validation)
```

### Route Map

| Prefix | Module | Auth |
|---|---|---|
| `GET /api/v1/health` | index.ts | None |
| `POST /api/v1/auth/*` | auth | None (except `GET /me` → authenticate) |
| `GET /api/v1/doctors/*` | doctor | None (public) |
| `POST /api/v1/appointments` | appointment | authenticate + authorize('patient') |
| `GET /api/v1/appointments/my` | appointment | authenticate |
| `GET /api/v1/appointments/doctor` | appointment | authenticate + authorize('doctor') |
| `PUT /api/v1/appointments/:id/cancel` | appointment | authenticate |
| `PUT /api/v1/appointments/:id/complete` | appointment | authenticate + authorize('doctor') |
| `POST /api/v1/payments/*` | payment | authenticate |
| `GET /api/v1/payments/status/:id` | payment | authenticate |
| `GET /api/v1/appointments/:id/video-session` | agora (mounted at `/api/v1`) | authenticate |
| `GET /api/v1/doctor/dashboard/summary` | doctorDashboard | authenticate + authorize('doctor', 'admin') |
| `GET /api/v1/doctor/appointments` | doctorDashboard | authenticate + authorize('doctor', 'admin') |
| `GET /api/v1/doctor/appointments/:id` | doctorDashboard | authenticate + authorize('doctor', 'admin') |
| `PUT /api/v1/doctor/appointments/:id/complete` | doctorDashboard | authenticate + authorize('doctor', 'admin') |
| `PUT /api/v1/doctor/appointments/:id/cancel` | doctorDashboard | authenticate + authorize('doctor', 'admin') |
| `GET /api/v1/admin/dashboard/summary` | admin | authenticate + authorize('admin') |
| `GET /api/v1/admin/doctors` | admin | authenticate + authorize('admin') |
| `GET /api/v1/admin/doctors/:id` | admin | authenticate + authorize('admin') |
| `GET /api/v1/admin/patients` | admin | authenticate + authorize('admin') |
| `GET /api/v1/admin/patients/:id` | admin | authenticate + authorize('admin') |
| `GET /api/v1/admin/appointments` | admin | authenticate + authorize('admin') |
| `GET /api/v1/admin/appointments/:id` | admin | authenticate + authorize('admin') |
| `GET /api/v1/admin/payments` | admin | authenticate + authorize('admin') |
| `GET /api/v1/notifications` | notification | authenticate |
| `GET /api/v1/notifications/unread-count` | notification | authenticate |
| `PUT /api/v1/notifications/:id/read` | notification | authenticate |
| `PUT /api/v1/notifications/read-all` | notification | authenticate |

### Middleware
- **authenticate:** Extracts JWT from `Authorization: Bearer <token>`, verifies, attaches `req.user`
- **authorize('role', ...):** Checks `req.user.role` against allowed roles, returns 403 if mismatch
- **errorHandler:** Catches all thrown errors, formats as `{ error: message, statusCode: n }`, avoids leaking stack traces in production

---

## Flutter Architecture

### State Management
- **Riverpod StateNotifierProvider** pattern for all state
- `AuthNotifier` manages auth state (login, register, logout, checkAuth, token refresh)
- `DoctorNotifier` manages doctor list/search/profile
- `AppointmentNotifier` manages patient booking flow
- `PaymentNotifier` manages payment creation and mock success
- `DoctorDashboardNotifier` manages doctor's summary + appointment list + actions
- `AdminNotifier` manages admin summary, doctors, patients, appointments, payments
- `NotificationNotifier` manages notification list, unread count, mark-as-read, mark-all-as-read; exposed as global provider

### Routing (GoRouter)
- Single `GoRouter` instance created via `Provider<GoRouter>`
- `ref.listen(authProvider, ...)` refreshes router on auth state changes (avoids re-creating the router)
- **Redirect guard** (in order):
  1. `/splash` → no redirect (splash handles its own navigation)
  2. Unauthenticated + not on `/auth/*` → `/auth/login`
  3. Authenticated + on `/auth/*` → role-based redirect (admin→`/admin/dashboard`, doctor→`/doctor/dashboard`, patient→`/patient/home`)
  4. Authenticated as doctor + on `/patient/*` → `/doctor/dashboard` (role mismatch catch-all)
  5. Non-doctor + on `/doctor/*` → `/patient/home` (role mismatch catch-all)
  6. Admin + on `/patient/*` or `/doctor/*` → `/admin/dashboard` (role mismatch catch-all)
  7. Non-admin + on `/admin/*` → `/patient/home` (role mismatch catch-all)

### Auth/Session Flow
1. **Splash Screen:** Calls `checkAuth()` → reads `access_token` from secure storage → calls `GET /auth/me` → navigates based on role (or `/auth/login` if unauthenticated)
2. **Login Screen:** Calls `login(email, password)` → stores tokens → navigates based on role
3. **Token Refresh:** `ApiClient` interceptor catches 401 → calls `POST /auth/refresh` with `refresh_token` → stores new `access_token` → retries original request. If refresh also fails, fires `onUnauthenticated` callback which triggers `logout()`
4. **Logout:** Clears all secure storage → resets auth state → redirect guard catches and routes to `/auth/login`

---

## Patient Flow

1. Open app → Splash → Login (or Register→OTP→Login)
2. **Home Screen:** Featured doctors, specialty quick links
3. **Search Screen:** Browse/search doctors by name/specialty, view availability
4. **Doctor Profile:** View bio, qualifications, experience, reviews
5. **Book Appointment:** Select date (unavailable dates grayed out) → confirm slot → booking creates appointment + optional payment record
6. **My Appointments:** 4 tabs (Upcoming, Pending, Completed, Cancelled) → cancel upcoming appointments
7. **Payment:** Select payment method (Mock/Stripe/PayFast) → pay
8. **Notifications:** Bell icon on home screen shows unread badge; Notification screen lists all notifications (appointment confirmed, cancelled, completed) with tap-to-mark-read

---

## Doctor Flow

1. Open app → Splash → Login (doctor credentials)
2. **Dashboard Screen:** Summary cards (today's appointments, total patients, this month's earnings)
3. **Appointment Tabs:** Today | Upcoming | Completed | Cancelled
4. **Appointment Cards:** Show patient name, phone, date, time, status badge, payment badge
5. **Actions:** Complete (mark appointment as completed) | Cancel (mark as cancelled)
6. **Notifications:** Bell icon in app bar shows unread badge; Notification screen lists appointment notifications

---

## Admin Flow

1. Open app → Splash → Login (admin credentials)
2. **Dashboard Screen:** 8 summary cards (total doctors, patients, appointments, completed/cancelled counts, paid/pending payment counts, revenue)
3. **Management Navigation:** Buttons for Doctors, Patients, Appointments, Payments lists
4. **Doctors List:** View all doctors, tap for detail sheet (specialty, fee, rating, active/verified status)
5. **Patients List:** View all patients, tap for detail sheet (gender, blood group, verified status)
6. **Appointments List:** Filter by status (All/Pending/Confirmed/Completed/Cancelled) and by doctor, tap for full detail + payment info
7. **Payments List:** Filter by status (All/Pending/Paid/Failed) and by provider (Mock/Stripe/PayFast), view amount, user, transaction ID
8. **Notifications:** Bell icon in app bar shows unread badge; Notification screen lists appointment notifications

---

## Payment Flow

### Architecture
- **`PaymentProvider` interface** (abstract class in `services/providers/PaymentProvider.ts`):
  - `createPayment(amount, currency, metadata)` → returns `{ transactionId, redirectUrl }`
  - `verifyPayment(transactionId)` → returns `{ verified, status }`
- **Implementations:** `MockPaymentProvider` (returns success immediately), `StripePaymentProvider`, `PayFastPaymentProvider`
- **Selection:** Based on `paymentProvider` string from request body → factory returns appropriate implementation

### Flow
1. Patient books appointment (optionally passing `paymentProvider: "mock" | "stripe" | "payfast"`)
2. Backend creates `Appointment` + `Payment` record with status `pending`
3. `POST /payments/create` → provider processes → updates payment status
4. `POST /payments/mock-success` → sets payment to `paid` (for local dev without real keys)
5. `GET /payments/status/:appointmentId` → returns current payment status

---

## Video Call Flow

### Architecture
- **Backend:** `agoraService.ts` generates channel names and tokens for Agora RTC
- **Backend:** `agoraController.ts` + `routes/agora.ts` exposes `GET /appointments/:id/video-session`
- **Flutter:** `VideoCallScreen` with real Agora engine integration + mock fallback
- **Token generation:** Uses `agora-access-token` (Node.js SDK) for RTC tokens when Agora keys are configured

### Flow
1. Patient/doctor opens a confirmed appointment card and taps **Join Call**
2. Flutter calls `GET /api/v1/appointments/:id/video-session`
3. Backend validates: appointment exists, is confirmed (not cancelled/completed), caller is a participant
4. Backend generates `channelName` (`appt_{appointmentId}`) and assigns `uid: 1` for patient, `uid: 2` for doctor
5. Returns `{ appId, channelName, token, uid, isMock }`
6. Flutter navigates to `VideoCallScreen` with session data
7. If `isMock`: simulated call UI with mock connecting delay
8. If `!isMock`: real Agora engine initialized, joins channel, renders local + remote video

### Mock vs Real Mode
| Mode | Trigger | Behavior |
|---|---|---|
| Mock | `AGORA_APP_ID` missing or starts with `your-` | Simulated UI, no real video, no Agora keys needed |
| Real (mobile) | `AGORA_APP_ID` + `AGORA_APP_CERTIFICATE` set | Full video/audio via native Agora SDK |
| Real (web) | Keys set + `iris-web-rtc_*.js` script in `web/index.html` | Requires alpha-stage Agora Web SDK setup |

### Security Rules
- Only the **patient** and **doctor** who own the appointment may join
- **Admin** gets metadata only (no token, `isMock: true`)
- **Cancelled** appointments are blocked (403)
- **Completed** appointments are blocked (403)
- **Pending/not-confirmed** appointments are blocked (403)
- **Unrelated users** are blocked (403 — "not a participant")
- Channel names are deterministic (`appt_{appointmentId}`) so both parties join the same room
- Agora tokens expire after 1 hour (configurable in `agoraService.ts`)

---

## Notification System (Phase 2E)

### Architecture
- **Backend:** `NotificationService` with CRUD operations; creates notifications on appointment book/cancel/complete; emits Socket.io `notification` event to `user:{userId}` room
- **REST Endpoints:** `GET /notifications`, `GET /notifications/unread-count`, `PUT /notifications/:id/read`, `PUT /notifications/read-all` — all require `authenticate`
- **Flutter:** `NotificationProvider` (Riverpod) fetches list + unread count; bell icon with red badge on patient home, doctor dashboard, admin dashboard; `NotificationsScreen` with pull-to-refresh, pagination, type-based icons/colors, time-ago display, tap-to-mark-read, mark-all-read button

### Notification Types
| Type | Icon (Flutter) | Trigger |
|---|---|---|
| `appointment_booked` | ✅ green | Patient books appointment (sent to patient + doctor) |
| `appointment_cancelled` | ❌ red | Patient or doctor cancels (sent to patient + doctor) |
| `appointment_completed` | 🎉 blue | Doctor completes appointment (sent to patient) |
| `payment_paid` | 💰 gold | Payment succeeds (sent to patient) |

### Mock vs Real Mode
| Component | When Unconfigured | When Configured |
|---|---|---|
| Redis OTP store | In-memory `Map` (dev only, lost on restart) | `ioredis` with TTL expiry (5 min) |
| SMTP email | `console.log` OTP to terminal | Nodemailer sends real HTML email |
| Push notifications | Not implemented (in-app polling only) | Requires `FIREBASE_SERVER_KEY` |

### Key Files
- `server/src/config/redis.ts` — ioredis client with in-memory fallback
- `server/src/services/emailService.ts` — SMTP sender with console fallback
- `server/src/services/otpStore.ts` — OTP generation, Redis/Map storage, 60s resend cooldown, max 5 verify attempts
- `server/src/services/notificationService.ts` — notification CRUD + Socket.io emit
- `server/src/controllers/notificationController.ts` — REST handlers
- `server/src/routes/notification.ts` — notification route definitions
- `mobile/lib/models/notification.dart` — `NotificationModel` data class
- `mobile/lib/providers/notification_provider.dart` — `NotificationNotifier`
- `mobile/lib/screens/common/notifications_screen.dart` — Full notification UI
- Patient/doctor/admin home/dashboard screens — notification bell + badge

---

## Database / Prisma / Neon Setup

See `docs/DATABASE_AND_MIGRATIONS.md`.

---

## Seed Credentials

| Role | Email | Password | Notes |
|---|---|---|---|
| Patient | `patient@test.com` | `password123` | Test patient with appointments |
| Doctor | `ahmed.khan@docbook.com` | `password123` | Cardiologist, id=doctor-1 |
| Admin | `admin@docbook.com` | `password123` | Platform admin |

---

## Local Run Commands

```bash
# Backend
cd server
cp .env.example .env       # Configure DATABASE_URL, JWT_SECRET, etc.
npm install
npx prisma generate
npx prisma migrate status  # Should show "Database schema is up to date!"
npm run seed               # Seeds test doctor + patient + admin + appointments
npm run dev                # Starts on http://localhost:3000

# Flutter web (separate terminal)
cd mobile
flutter pub get
flutter run -d chrome       # Opens http://localhost:8080
```

---

## Environment Variables

All environment variables are in `server/.env`. Key variables (without secrets):

| Variable | Purpose | Default |
|---|---|---|
| `PORT` | Server port | `3000` |
| `DATABASE_URL` | PostgreSQL connection (pooled, for Prisma) | (required) |
| `DIRECT_URL` | PostgreSQL connection (direct, for migrations) | (required) |
| `JWT_SECRET` | JWT signing secret | (required) |
| `JWT_REFRESH_SECRET` | Refresh token secret | (required) |
| `JWT_EXPIRES_IN` | Access token lifetime | `15m` |
| `JWT_REFRESH_EXPIRES_IN` | Refresh token lifetime | `7d` |
| `REDIS_URL` | Redis connection | `redis://localhost:6379` |
| `SMTP_*` | Email config for OTP | — |
| `STRIPE_SECRET_KEY` | Stripe secret | — |
| `PAYFAST_*` | PayFast config | — |
| `AGORA_*` | Agora config for video calls | — |
| `FIREBASE_SERVER_KEY` | Firebase push notifications | — |

---

## Known Limitations

- **Stripe/PayFast require real keys** — Use `mock` payment provider for local development
- **Video calls** — Mock video works without Agora keys; real Agora video needs `AGORA_APP_ID` + `AGORA_APP_CERTIFICATE` in `.env`; web additionally needs `iris-web-rtc_*.js` script in `web/index.html`
- **Push notifications** — Firebase messaging wired in Flutter but no server push integration yet (backend has `FIREBASE_SERVER_KEY` env var placeholder); in-app notifications via REST polling work now
- **Email OTP** — Requires real SMTP credentials (`SMTP_HOST`, `SMTP_USER`, `SMTP_PASS`); falls back to console output in dev
- **Redis** — Used for OTP storage when available; falls back to in-memory `Map`; not yet used for rate limiting, session caching, or queueing
- **No doctor activate/deactivate** — Admin can view doctor isActive flag but cannot toggle it
- **Prescriptions** — Schema has `Prescription` model but no endpoints or UI
- **Reviews** — Schema has `Review` model but no endpoints or UI (except average rating display)
- **Chat/Messages** — Schema has `Message` model but no endpoints or UI
- **No tests** — No unit/integration tests written yet

---

## Security Notes

- JWTs are stored in `flutter_secure_storage` (encrypted at rest on device)
- Passwords hashed with bcryptjs
- Role-based access control enforced server-side (JWT role claim is the authority)
- CORS allows all origins in development (`origin: true`), should be locked down in production
- Helmet middleware provides HTTP security headers
- Video sessions are participant-only — patient and doctor verified server-side against appointment record before issuing tokens
- Cancelled/completed appointments cannot start a video session
- OTP resend rate-limited (60s cooldown), verification locked after 5 failed attempts (429)
- No API rate limiting beyond OTP-specific limits
- No request size validation beyond 10mb limit
- No audit logging

---

## New Developer Onboarding

1. Clone the repo
2. Install Node 20+ and Flutter SDK (>=3.2)
3. Configure `server/.env`:
   - `DATABASE_URL` + `DIRECT_URL` — PostgreSQL connection (required)
   - `JWT_SECRET` + `JWT_REFRESH_SECRET` — JWT signing keys (required)
   - `REDIS_URL` — Optional; falls back to in-memory if omitted
   - `SMTP_HOST`, `SMTP_USER`, `SMTP_PASS` — Optional; OTP falls back to console if omitted or placeholder
   - `STRIPE_SECRET_KEY`, `AGORA_APP_ID`, etc. — Optional for mock/payment/video dev
4. Run `cd server && npm install && npx prisma generate && npm run seed && npm run dev`
   - Server starts on http://localhost:3000
   - OTP codes print to console (no SMTP required)
   - All features work without Redis, SMTP, Stripe, or Agora keys
5. Run `cd mobile && flutter pub get && flutter run -d chrome`
   - Flutter web opens on http://localhost:8080
6. Test patient login: `patient@test.com` / `password123`
   - Check notifications bell on home screen (unread badge for new bookings)
7. Test doctor login: `ahmed.khan@docbook.com` / `password123`
   - Check notifications bell in app bar
8. Test admin login: `admin@docbook.com` / `password123`
9. Read all docs in `docs/` for architecture and reference
10. See `docs/NEXT_PHASE_SCOPE.md` for planned work
