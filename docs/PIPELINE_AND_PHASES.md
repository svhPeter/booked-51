# Pipeline & Phases

## Phase 1 — Project Setup, Auth, Doctor List, Booking *(Completed)*

### Backend
- Express + TypeScript setup with hot reload (tsx)
- Neon PostgreSQL connection via Prisma
- Prisma schema: User (patient/doctor/admin), Doctor, Patient, Appointment, Slot, Hospital, Notification, Message, Payment, Prescription, Review
- Auth: register, login (email/password), JWT access + refresh tokens, OTP verification (Nodemailer)
- Public doctor routes: list all, search by name/specialty, get by ID, available slots
- Appointment booking: create appointment with double-book prevention, get my appointments, cancel
- Middleware: authenticate (JWT verify), authorize (role check), global error handler

### Flutter
- Project setup with Riverpod + GoRouter + Dio
- Auth screens: login, register, OTP verification
- Patient screens: home, search, doctor profile, book appointment, my appointments
- Splash screen with auto-login
- Role-based routing after login/splash
- API client with token refresh interceptor

## Phase 1.5 — Booking Validation, Real Errors, Cancel Flow, Routing Stability *(Completed)*

### Changes
- CORS fixed to allow all origins in development
- Specialties endpoint URL corrected in Flutter
- Doctor profile and getById endpoints return flat responses
- Appointment service includes eagerly loads patient + doctor relations
- Real backend error messages forwarded to Flutter UI
- Role-based routing (splash screen now checks role before navigating)
- Booking validates `availableDays` + time slot format
- Double-book prevention (no overlapping appointments for same doctor + time)
- Cancel endpoint returns flat data
- My Appointments has 4 tabs + cancel button
- Booking calendar grays out unavailable dates
- **Critical bug fix:** GoRouter no longer re-created on every auth state change (uses `ref.listen` + `router.refresh()`)
- **Critical bug fix:** API client `onUnauthenticated` callback triggers `logout()` on token refresh failure

## Phase 2A — Payment Foundation *(Completed)*

### Changes
- Prisma schema: added `mock` to `PaymentProvider` enum, `paid` to `PaymentStatus` enum
- Payment service with abstract `PaymentProvider` interface + 3 implementations (Mock, Stripe, PayFast)
- Payment controller + routes: `POST /create`, `POST /mock-success`, `GET /status/:appointmentId`
- Registered in index.ts at `/api/v1/payments`
- Booking optionally creates payment record when `paymentProvider` is passed
- Flutter: payment model, provider, screen with method selection
- Booking screen navigates to payment after booking
- Payment route registered in app.dart

## Phase 2B — Doctor Dashboard *(Completed)*

### Backend
- `appointmentService.getDoctorDashboardSummary()` — counts today/upcoming/completed/cancelled + unique patients + sum of payments
- `appointmentService.getDoctorAppointments()` — enriched with patient email/phone + payment info
- `appointmentService.getDoctorAppointmentById()` — single appointment with full details
- Doctor dashboard controller: summary, list, detail, complete, cancel
- Doctor dashboard routes at `/api/v1/doctor/*` with `authenticate` + `authorize('doctor', 'admin')`
- All endpoints verify appointment belongs to requesting doctor

### Flutter
- `DoctorAppointmentModel`, `PaymentInfo`, `DashboardSummary` models
- `DoctorDashboardNotifier` — fetchSummary, fetchAppointments, completeAppointment, cancelAppointment
- `DoctorDashboardScreen` — summary cards (today/patients/earnings), 4 tabs (Today/Upcoming/Completed/Cancelled), appointment cards with patient info + status/payment badges + Complete/Cancel buttons, pull-to-refresh, loading/error/empty states

### Prisma Drift Fix *(Completed)*
- `mock` and `paid` enum values were added via `db push`, causing migration drift
- Fixed by creating a no-op migration (`20260516015934_fix_enum_drift/migration.sql`)
- Applied via `prisma migrate resolve --applied 20260516015934_fix_enum_drift`
- No data was lost, no schema was reset

### Routing Fix — Phase 1.5 Regression *(Completed)*
- Login screen listener always navigated to `/patient/home` regardless of role
- GoRouter redirect only caught role mismatches on auth routes (not patient/doctor routes)
- **Fix:** Login screen routes by role; GoRouter catch-all for role mismatches on any route

## Phase 2C — Admin Dashboard *(Completed)*

### Backend
- `AdminService` with 8 methods: getDashboardSummary, listDoctors, getDoctorById, listPatients, getPatientById, listAppointments (with status/doctor/date filters), getAppointmentById, listPayments (with status/provider filters)
- Admin controller + routes at `/api/v1/admin/*` with `authenticate` + `authorize('admin')` enforced globally via `router.use`
- Admin routes registered in index.ts
- Seed already included `admin@docbook.com`; prisma.seed config added to package.json

### Flutter
- `AdminSummary`, `AdminDoctor`, `AdminPatient`, `AdminAppointment`, `AdminPayment` models
- `AdminNotifier` — fetchSummary, fetchDoctors, fetchPatients, fetchAppointments (with filters), fetchPayments (with filters), detail fetchers
- `AdminDashboardScreen` — 8 summary cards in 2x4 grid (total doctors, patients, appointments, completed, cancelled, paid/pending payments, revenue) + 4 management navigation buttons
- `AdminDoctorsScreen` — doctor list + detail bottom sheet (specialty, fee, rating, status)
- `AdminPatientsScreen` — patient list + detail bottom sheet (gender, blood group, status)
- `AdminAppointmentsScreen` — appointment list with 5 status filter chips + doctor dropdown + detail bottom sheet (patient, doctor, payment info)
- `AdminPaymentsScreen` — payment list with 4 status chips + provider dropdown
- All routes registered in app.dart with role guard (admin only)

### Route Guard Updated
- GoRouter redirect handles all 3 roles (admin, doctor, patient)
- Catch-all rules for role mismatches: admin on patient/doctor routes → `/admin/dashboard`; non-admin on admin routes → `/patient/home`
- Splash screen and login screen navigate based on role

## Phase 2D — Video Calls (Agora) *(Completed)*

### Backend
- `agoraService.ts` — channel name generation (`appt_{appointmentId}`), mock token generation for dev, real RTC token via `agora-access-token` library, `isMockMode()` detection based on env config
- `agoraController.ts` — `getAppointmentVideoSession` handler
- `routes/agora.ts` — `GET /appointments/:id/video-session` mounted at `/api/v1`
- All security rules enforced: participant check, status check (cancelled/completed/not-confirmed blocked), admin gets metadata only
- Error handling: 403 for blocked states, 404 for missing appointments

### Flutter
- `VideoCallScreen` — full Agora RTC engine integration with real video rendering (`AgoraVideoView` for local + remote)
- Mock fallback mode when Agora keys are missing (simulated UI + connecting delay)
- Platform-aware permissions (camera/microphone) — requested on Android/iOS via `permission_handler`, skipped on web
- Call controls: mic toggle, camera toggle, switch camera, end call (all wired to Agora engine APIs)
- Error handling: connecting state, error display with leave button, graceful cleanup on dispose
- Join Call button on patient `MyAppointmentsScreen` and doctor `DoctorDashboardScreen`
- Route: `/call/:appointmentId` in app.dart

### Key Decisions
- `uid=1` for patient, `uid=2` for doctor (consistent deterministic mapping)
- Communication profile (not live streaming) — both sides are broadcasters
- Dynamic import of `agora-access-token` only when generating real tokens (avoids crash in mock mode)

## Phase 2D.1 — Real Agora Flutter Video Engine Integration *(Completed)*

### Changes from Phase 2D
- Phase 2D used a placeholder `VideoCallScreen` with no real Agora SDK calls
- Phase 2D.1 replaced it with full `agora_rtc_engine` v6.5 API:
  - `createAgoraRtcEngine()` → `initialize()` → `registerEventHandler()` → `enableVideo()` → `startPreview()` → `joinChannel()`
  - `VideoViewController` for local video (PiP overlay, top-right, 120x180)
  - `VideoViewController.remote` with `RtcConnection` for remote video (full screen)
  - `muteLocalAudioStream()` / `muteLocalVideoStream()` for mic/camera toggles
  - `switchCamera()` for front/back camera toggle
  - `leaveChannel()` + `release()` on end call or dispose

### Web Limitation
- `agora_rtc_engine` web support is **alpha stage**
- Requires `iris-web-rtc_*.js` script tag in `mobile/web/index.html`
- Without it, real Agora video won't render on web (mock mode still works)
- Mobile (Android/iOS) is fully ready for real Agora

## Phase 2E — Notifications + Real Email OTP + Redis *(Completed)*

### Backend
- **redis.ts** — ioredis client with in-memory `Map` fallback; lazy connect with max 1 retry; full operation without Redis
- **emailService.ts** — Nodemailer SMTP sender when `SMTP_HOST`/`SMTP_USER`/`SMTP_PASS` are set and not placeholders; `console.log` fallback in dev
- **otpStore.ts** — OTP generation + storage (Redis TTL 600s / in-memory `Map` fallback); resend rate limiting (60s cooldown); max 5 verification attempts (429 lock); `generateAndSendOtp()` + `verifyOtp()` helpers
- **authService.ts** — Rewritten to use new OTP store; improved error codes (429 for rate limit, 400 for invalid/expired)
- **notificationService.ts** — `createNotification()`, `getNotifications()` (paginated), `markAsRead()`, `markAllAsRead()`, `getUnreadCount()`; emits via `io.to(user:${userId})`
- **notificationController.ts** — REST handlers for list, read, read-all, unread-count
- **routes/notification.ts** — `GET /`, `PUT /:id/read`, `PUT /read-all`, `GET /unread-count` (all `authenticate`)
- **appointmentService.ts** — Creates notifications on book (patient+doctor), cancel (patient+doctor), complete (patient)
- **paymentController.ts** — Creates notification on payment paid
- **index.ts** — Notification routes registered at `/api/v1/notifications`

### Flutter
- **models/notification.dart** — `NotificationModel` with `fromJson()`, type enum
- **providers/notification_provider.dart** — `NotificationNotifier` with fetch, unread count, mark-as-read, mark-all-as-read; global provider
- **screens/common/notifications_screen.dart** — Full UI: list, pull-to-refresh, load-more pagination, empty/error states, mark-as-read on tap, mark-all-read, type-based icons/colors, unread dot, time-ago
- **patient/home_screen.dart** — Notification bell + red badge; fetches unread count on init
- **doctor/doctor_dashboard_screen.dart** — Notification bell + badge; also fixed missing `api_client.dart` import (pre-existing web build blocker)
- **admin/admin_dashboard_screen.dart** — Notification bell + badge

### Key Decisions
- OTP store uses Redis when `REDIS_URL` is set and Redis is reachable; falls back to in-memory `Map` otherwise
- Email uses SMTP when configured with real credentials (detects `your-`/`placeholder` prefixes to skip); falls back to `console.log`
- Notifications created asynchronously (`.catch(() => {}))` to not block appointment/payment flows
- Socket.io emits `notification` event to `user:${userId}` room on creation; Flutter does not yet join socket rooms (future: Firebase push)
- Doctor dashboard had a latent missing-import bug that broke `flutter build web` — fixed

## Current Verified Status *(As of May 18, 2026)*

| Check | Status |
|---|---|
| Prisma migrate status | ✅ Database schema is up to date (2 migrations) |
| TypeScript compile | ✅ tsc --noEmit exit 0 |
| Flutter analyze | ✅ 0 errors, 0 warnings, 37 info lints (all pre-existing in untargeted files) |
| Flutter build web | ✅ Built successfully |
| Backend health | ✅ Server starts and responds on port 3000 |
| Admin login | ✅ admin@docbook.com, role=admin, token issued |
| Doctor login | ✅ Ahmed Khan, role=doctor, token issued |
| Patient login | ✅ Test Patient, role=patient, token issued |
| Admin dashboard summary | ✅ Doctors:5, Patients:4, Appts:15, Revenue:7500 |
| Doctor dashboard summary | ✅ Today:1, Upcoming:10 |
| Patient booking + payment | ✅ Creates appointment + payment record |
| Notification — patient booked | ✅ "Your appointment with {doctor}...has been confirmed" |
| Notification — doctor booked | ✅ "New appointment booked with {patient}..." |
| Notification — cancel (both) | ✅ "Your appointment...has been cancelled" + doctor notified |
| Notification — unread count | ✅ Increments/decrements correctly |
| Notification — mark as read | ✅ Returns isRead: true |
| Notification — mark all as read | ✅ Returns success |
| Notification — unauthenticated blocked | ✅ 401 |
| OTP registration + verify | ✅ User created, verified, authenticated |
| OTP resend rate limit | ✅ 429 "Please wait before requesting another OTP" |
| OTP max attempts lockout | ✅ 429 after 5 failed verifications |
| OTP console fallback | ✅ OTP printed to terminal when SMTP unconfigured/placeholder |
| Video session — patient uid=1 | ✅ uid=1, same channel as doctor |
| Video session — doctor uid=2 | ✅ uid=2, same channel as patient |
| Video session — cancelled blocked | ✅ 403 "appointment is cancelled" |
| Video session — completed blocked | ✅ 403 "appointment is completed" |
| Video session — unrelated user blocked | ✅ 403 "not a participant" |
| Video session — not found | ✅ 404 |
| Video session — mock mode | ✅ Returns mock token when keys missing |
| Health check — DB status | ✅ Returns database: healthy/unhealthy |
| Rate limiting — login | ✅ 10 requests/min per IP |
| Rate limiting — register | ✅ 5 requests/min per IP |
| Rate limiting — resend OTP | ✅ 5 requests/min per IP |
| Env validation — missing DATABASE_URL | ✅ Fails fast with clear message |
| Env validation — missing JWT_SECRET | ✅ Fails fast with clear message |
| CORS — dev mode | ✅ Open origin |
| CORS — production mode | ✅ Restricted to FRONTEND_URL |
| Request size limit | ✅ 1mb (down from 10mb) |
| Structured logging | ✅ JSON in prod, human-readable in dev |
| Prisma error — unique constraint | ✅ Returns 409 with field name |
| Prisma error — not found | ✅ Returns 404 |
| Secrets sanitized in logs | ✅ password, token, secret, authorization redacted |
| .env.example created | ✅ Documented with categories and placeholders |

## Phase 3A — Production Hardening *(Completed)*

### Changes
- **env.ts** — Rewritten with fail-fast validation for required vars (DATABASE_URL, DIRECT_URL, JWT_SECRET, JWT_REFRESH_SECRET); production-mode placeholder detection; dev-mode warnings for optional unconfigured services
- **index.ts** — Added rate limiting (login:10/min, register:5/min, resend-otp:5/min); reduced request body limit to 1mb; CORS supports comma-separated `FRONTEND_URL` origins; enhanced health check with DB reachability + uptime; request logging middleware (method, path, status, duration)
- **logger.ts** — New structured logger; JSON output in production, human-readable in dev; automatic redaction of secrets (password, token, secret, authorization, cookie)
- **errorHandler.ts** — Added Prisma error handling (P2002 → 409, P2025 → 404, P2003 → 400, connection → 503); dev mode shows stack traces, production sanitizes all errors
- **Event logging** — Login success/failure, registration, appointment booked/cancelled/completed, payment paid, video session created, notification created
- **.env.example** — Created with categorized variables (🔴 required, 🟡 optional, 🟢 future)
- **express-rate-limit** — Installed and configured for auth endpoints
- **NEXT_PHASE_SCOPE.md** — Updated to reflect Phase 3A completion and Phase 3B scope

## Phase 3B — Deployment Preparation *(Completed)*

### Changes
- **package.json** — Added `db:migrate:deploy`, `postinstall` (auto Prisma generate), kept `build` + `start` + `dev`
- **api_constants.dart** — API base URL uses `String.fromEnvironment('API_BASE_URL')` with localhost default; production builds pass `--dart-define=API_BASE_URL=https://api.example.com/api/v1`
- **docs/DEPLOYMENT_GUIDE.md** — Created: hosting recommendations (Railway/Render for backend, Vercel/Cloudflare for Flutter web, Neon for DB, Upstash for Redis), build/start commands, migration flow, health check, post-deploy checklist, rollback notes
- **docs/PRODUCTION_ENV_CHECKLIST.md** — Created: required vs optional env vars, secret generation, what never to commit, rotation notes, example production .env
- **docs/FINAL_QA_CHECKLIST.md** — Created: 50+ test items covering health, auth, roles, booking, payments, doctor dashboard, admin dashboard, notifications, video, CORS, Flutter web, Prisma, build verification

## Phase 4E — Production Launch Safety *(Completed)*

### Changes
- **Pending registration model** — Patient signup and doctor onboarding use `PendingRegistration` with OTP hash, expiry, attempt counter, resend cooldown
- **Demo data flag** — All seeded users marked `isDemo=true`; demo admin login blocked in production
- **Admin bootstrap** — `npm run admin:upsert` creates/updates real admin with `isDemo=false`
- **Forgot/reset password** — Redis-backed OTP with rate limiting and constant-time responses
- **Doctor onboarding** — `/auth/register-doctor` creates unapproved doctors; admin approval required for public listing
- **Seed safety** — Seed script blocked in `NODE_ENV=production` unless `ALLOW_DEMO_SEED=true`

## Phase 5A — Production Email Delivery (Brevo HTTP API) *(Completed)*

### Root Cause
Gmail SMTP timed out from Railway (connection setup exceeded 10-15s). Brevo SMTP also timed out due to Railway's restricted outbound SMTP ports.

### Solution
Switched production email delivery from SMTP to **Brevo HTTP API** (`https://api.brevo.com/v3/smtp/email`), which uses standard HTTPS (port 443) and bypasses all SMTP port restrictions.

### Changes
- **emailService.ts** — Dual-provider architecture: `EMAIL_PROVIDER=brevo` uses Brevo HTTP API via `fetch()`; `EMAIL_PROVIDER=smtp` uses nodemailer (local/dev fallback). Singleton pooled SMTP transporter for dev. All 4 OTP paths (signup, resend, doctor onboarding, forgot password) use the same `sendOtpEmail()` function with template-specific subjects and HTML
- **env.ts** — Added `emailProvider`, `brevoApiKey`, `emailFromName`
- **index.ts** — Health endpoint shows `email.provider` (brevo/smtp/none); startup logs active provider
- **adminController.ts** — `POST /admin/email-diagnostic` sends test emails via all 4 templates, returns `sent`, `durationMs`, `provider` per template. No secrets exposed
- **authService.ts** — All registration/resend flows log structured `EmailSendResult` (sent/fallback/durationMs)
- **otpStore.ts** — Forgot password uses `forgot_password` template with structured logging
- **.env.example** — Brevo HTTP API as primary production recommendation; Gmail SMTP as local/dev only

### QA Results (2026-05-24)

| Test | Result | Timing |
|------|--------|--------|
| Health (Brevo provider) | ✅ | — |
| Admin diagnostic — all 4 templates | ✅ sent=true | 138–355ms |
| Patient signup → OTP received | ✅ | 2.97s |
| Retry pending signup (no "already registered") | ✅ | — |
| Login before verify blocked | ✅ 401 | — |
| Resend OTP → email received | ✅ | 2.64s |
| Patient OTP verify → login | ✅ | — |
| Forgot password → OTP received | ✅ | 1.61s |
| Reset password → login with new password | ✅ | — |
| Doctor onboarding → OTP received | ✅ | 2.70s |
| Doctor verify → isApproved=false | ✅ | 4.18s |
| Admin approve doctor | ✅ | — |
| Demo admin blocked | ✅ 401 | — |

### Required Railway Environment Variables
```
EMAIL_PROVIDER=brevo
BREVO_API_KEY=<Brevo API key>
EMAIL_FROM=<Brevo verified sender email>
EMAIL_FROM_NAME=DocBook
```

---

## Phase 5B — UI/UX Polish *(Completed)*

### Design System
- **app_theme.dart** — Expanded `AppColors` (14 semantic colors including surfaces), `AppShadows` utility (sm/md/lg), polished button/input/card/chip/snackbar/bottomsheet themes, Inter typography via Google Fonts
- **ui_components.dart** — New reusable widget library: `MessageBanner` (4 variants), `StatusBadge` (10 status factory), `EmptyStateWidget`, `SectionHeader`, `InfoCard`, `TrustBanner`, `LoadingButton`

### Auth Screens (7 screens polished)
- **splash_screen.dart** — Gradient background, scale+fade animation, rounded logo with shadow
- **login_screen.dart** — Brand icon header, MessageBanner, LoadingButton, trust badges, keyboard actions
- **register_screen.dart** — Section labels (Personal/Security), Pakistan-friendly hints, helper text
- **otp_verification_screen.dart** — Email highlighted badge, 60s countdown timer, resend success banner
- **forgot_password_screen.dart** — Centered icon header, submit on enter
- **reset_password_screen.dart** — Pre-filled email badge, section label, success snackbar
- **doctor_onboarding_screen.dart** — Info banner (admin review timeline), 3 section labels, accent submit

### Patient Screens (7 screens polished)
- **home_screen.dart** — Gradient next-appointment card, quick action grid, trust banner, specialties grid, pull-to-refresh
- **search_screen.dart** — EmptyStateWidget, card shadows
- **my_appointments_screen.dart** — EmptyStateWidget, StatusBadge.fromStatus, removed dead code
- **appointment_detail_screen.dart** — StatusBadge inline, card shadows
- **appointment_confirmation_screen.dart** — Rounded icon, semantic surface colors
- **doctor_profile_screen.dart** — Verified specialty badge pill
- **patient_profile_screen.dart** — Avatar header, section labels, prefixIcons, LoadingButton

### Doctor & Admin Screens (7 screens polished)
- **doctor_dashboard_screen.dart** — EmptyStateWidget, StatusBadge.fromStatus, card shadows
- **doctor_profile_edit_screen.dart** — Section labels, prefixIcons, helper text, LoadingButton
- **admin_dashboard_screen.dart** — Icon-enriched summary grid, management cards with counts
- **admin_doctors_screen.dart** — StatusBadge, EmptyStateWidget, drag handle, themed avatars
- **admin_patients_screen.dart** — StatusBadge, EmptyStateWidget, drag handle
- **admin_appointments_screen.dart** — StatusBadge.fromStatus, EmptyStateWidget, themed cards
- **admin_payments_screen.dart** — StatusBadge.fromStatus, EmptyStateWidget, themed cards

### Common Screens
- **notifications_screen.dart** — EmptyStateWidget, semantic AppColors for notification types

### Code Quality
- Removed all dead `_statusColor` methods (replaced by StatusBadge)
- Removed unused imports
- Zero raw `Colors.grey`/`Colors.red` in screen code (except video_call_screen functional UI)
- Consistent `AppShadows.sm` on all card containers
- Consistent `Border.all(color: AppColors.border, width: 0.5)` borders

---

## Next Planned Phase

### Future Feature Phases
- **Phase 2F** — Prescriptions & Reviews
- **Phase 2G** — Chat/Messaging enhancements
- **Phase 6** — Mobile Native (iOS/Android)

