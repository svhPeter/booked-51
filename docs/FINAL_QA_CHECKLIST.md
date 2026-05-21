# Final QA Checklist — Doctor Appointment Platform

Run through this checklist after every deployment to verify core functionality.

---

## Backend Health

- [ ] `GET /api/v1/health` returns `{"status":"ok","database":"healthy","uptime":...}`
- [ ] `NODE_ENV` is `production` in the response environment
- [ ] Logs are JSON-formatted (not human-readable)

---

## Authentication

- [ ] Patient can log in: `POST /api/v1/auth/login` with `patient@test.com` / `password123`
- [ ] Doctor can log in: `POST /api/v1/auth/login` with `ahmed.khan@docbook.com` / `password123`
- [ ] Admin can log in: `POST /api/v1/auth/login` with `admin@docbook.com` / `password123`
- [ ] Invalid credentials return 401 "Invalid email or password"
- [ ] Unauthenticated request returns 401 "Access denied. No token provided."
- [ ] Registration: `POST /api/v1/auth/register` creates user and returns "OTP sent to email"
- [ ] OTP verification: `POST /api/v1/auth/verify-otp` returns access + refresh tokens
- [ ] Rate limiting: 10+ rapid login attempts return 429
- [ ] JWT refresh: `POST /api/v1/auth/refresh` returns new token pair

---

## Role Access

- [ ] Patient cannot access doctor dashboard → 403
- [ ] Patient cannot access admin routes → 403
- [ ] Doctor cannot access patient routes → (redirect in app)
- [ ] Doctor cannot access admin routes → 403
- [ ] Admin can access all routes

---

## Booking & Appointments

- [ ] Patient can book an appointment: `POST /api/v1/appointments`
- [ ] Double booking is prevented → 409
- [ ] Booking without auth → 401
- [ ] Patient can view their appointments: `GET /api/v1/appointments/my`
- [ ] Patient can cancel their appointment: `PUT /api/v1/appointments/:id/cancel`
- [ ] Doctor can complete appointment: `PUT /api/v1/appointments/:id/complete`
- [ ] Doctor can cancel appointment

---

## Payments

- [ ] `POST /api/v1/payments/create` creates a payment record
- [ ] `POST /api/v1/payments/mock-success` marks payment as paid
- [ ] `GET /api/v1/payments/status/:appointmentId` returns payment status
- [ ] Invalid provider returns 400
- [ ] Payment for another user's appointment returns 403

---

## Doctor Dashboard

- [ ] `GET /api/v1/doctor/dashboard/summary` returns counts (today, upcoming, completed, cancelled, revenue)
- [ ] `GET /api/v1/doctor/appointments` returns list with patient + payment details
- [ ] `GET /api/v1/doctor/appointments/:id` returns single appointment detail

---

## Admin Dashboard

- [ ] `GET /api/v1/admin/dashboard/summary` returns platform-wide stats
- [ ] `GET /api/v1/admin/doctors` returns all doctors
- [ ] `GET /api/v1/admin/patients` returns all patients
- [ ] `GET /api/v1/admin/appointments` supports status/doctor/date filters
- [ ] `GET /api/v1/admin/payments` supports status/provider filters

---

## Notifications

- [ ] Booking creates notification for both patient and doctor
- [ ] Cancellation creates notification for both
- [ ] Completion creates notification for patient
- [ ] Payment success creates notification for patient
- [ ] `GET /api/v1/notifications` returns paginated list
- [ ] `GET /api/v1/notifications/unread-count` returns count
- [ ] `PUT /api/v1/notifications/:id/read` marks as read
- [ ] `PUT /api/v1/notifications/read-all` marks all as read
- [ ] Unauthenticated access to notifications → 401

---

## Video Calls (Mock Mode)

- [ ] `GET /api/v1/appointments/:id/video-session` returns session with `isMock: true`
- [ ] Cancelled appointment → 403
- [ ] Completed appointment → 403
- [ ] Non-confirmed appointment → 403
- [ ] Unrelated user → 403
- [ ] Admin gets metadata only (no token)

---

## CORS & Security

- [ ] Frontend domain can make API calls (no CORS error)
- [ ] Random origin returns CORS error (in production)
- [ ] Helmet security headers present in response
- [ ] Rate limiting returns 429 after threshold
- [ ] Error responses do not contain stack traces
- [ ] Error responses follow `{ "error": "message" }` shape

---

## Flutter Web

- [ ] App loads without console errors
- [ ] Splash screen → auto-login (or login screen)
- [ ] Patient home screen loads with doctors
- [ ] Search screen finds doctors
- [ ] Booking flow works end-to-end
- [ ] Doctor dashboard loads with summary + appointments
- [ ] Admin dashboard loads with stats
- [ ] Notifications screen shows bell badge + notification list
- [ ] Video call screen opens in mock mode
- [ ] Logout works and redirects to login

---

## Database / Prisma

- [ ] `npx prisma migrate status` shows "Database schema is up to date!"
- [ ] No migration drift
- [ ] Seed data exists (test users, doctors, appointments)
- [ ] `npx prisma migrate deploy` runs successfully (no pending migrations)

---

## Build Verification (Local)

```bash
# Backend
cd server
npx prisma migrate status
npx tsc --noEmit
npm run build

# Mobile
cd mobile
flutter analyze
flutter build web --dart-define=API_BASE_URL=https://your-api-url.com/api/v1
```
