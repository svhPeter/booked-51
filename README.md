# Doctor Appointment Platform

Full-stack online doctor appointment booking platform with patient and doctor portals.

## Quick Start

```bash
# Backend
cd server
cp .env.example .env              # Configure DATABASE_URL, JWT_SECRET, etc.
npm install
npx prisma generate
npx prisma migrate status        # Should show "Database schema is up to date!"
npm run seed                      # Seeds test data
npm run dev                       # Backend on http://localhost:3000
# OTP codes print to console (no SMTP/Redis required)

# Frontend (separate terminal)
cd mobile
flutter pub get
flutter run -d chrome             # Flutter web on http://localhost:8080
```

## Test Credentials

| Role | Email | Password |
|---|---|---|
| Patient | `patient@test.com` | `password123` |
| Doctor | `ahmed.khan@docbook.com` | `password123` |
| Admin | `admin@docbook.com` | `password123` |

## Project Status

**Current Phase: 3C (Final QA + Deployment) — Ready — Awaiting Manual Deploy**

- ✅ Phase 1: Project setup, auth, doctor list, booking
- ✅ Phase 1.5: Booking validation, real errors, cancel flow, routing stability
- ✅ Phase 2A: Payment foundation (mock/stripe/payfast)
- ✅ Phase 2B: Doctor dashboard (API + Flutter UI)
- ✅ Phase 2C: Admin dashboard (API + Flutter UI)
- ✅ Phase 2D: Video calls (Agora backend + Flutter placeholder)
- ✅ Phase 2D.1: Real Agora Flutter video engine integration
- ✅ Phase 2E: Notifications + Real Email OTP + Redis
- ✅ Phase 3A: Production hardening (env validation, CORS, rate limiting, logging, error handling)
- ✅ Phase 3B: Deployment preparation (build scripts, Flutter API config, deployment docs, QA checklists)
- ✅ Phase 3C: Final QA verified locally, deployment docs prepared (runbook + live QA checklist)
- ➡️ **Next: Execute deployment per DEPLOYMENT_RUNBOOK.md**

## Documentation

| Document | Description |
|---|---|---|
| [Project Handoff](docs/PROJECT_HANDOFF.md) | Architecture, tech stack, flows, setup |
| [Pipeline & Phases](docs/PIPELINE_AND_PHASES.md) | Completed/phased work and current status |
| [API Reference](docs/API_REFERENCE.md) | All endpoints with request/response examples |
| [Database & Migrations](docs/DATABASE_AND_MIGRATIONS.md) | DB setup, migration rules, drift fix |
| [Deployment Guide](docs/DEPLOYMENT_GUIDE.md) | Hosting strategy, build/start commands, migration flow |
| [Deployment Runbook](docs/DEPLOYMENT_RUNBOOK.md) | **Step-by-step deploy instructions for Railway + Vercel** |
| [Production Env Checklist](docs/PRODUCTION_ENV_CHECKLIST.md) | Required/optional env vars, secrets management |
| [Final QA Checklist](docs/FINAL_QA_CHECKLIST.md) | Post-deployment test plan |
| [Live QA Checklist](docs/LIVE_QA_CHECKLIST.md) | **Post-deployment verification checklist** |
| [Next Phase Scope](docs/NEXT_PHASE_SCOPE.md) | Next planned phases |

## Tech Stack

**Backend:** Node.js, TypeScript, Express, Prisma, PostgreSQL (Neon), JWT, Socket.io, Redis (optional fallback), Nodemailer, Stripe

**Frontend:** Flutter, Dart, Riverpod, GoRouter, Dio

## Commands

```bash
# Backend validation
cd server && npx prisma migrate status && npx tsc --noEmit

# Flutter validation
cd mobile && flutter analyze && flutter build web
```

## Notifications

In-app notifications are created automatically on appointment book, cancel, complete, and payment success. A bell icon with a red badge appears on patient home, doctor dashboard, and admin dashboard screens. The notifications screen shows type-based icons, time-ago timestamps, and supports tap-to-mark-read, mark-all-read, pull-to-refresh, and pagination.

**Push notifications** (Firebase) are not yet implemented — the in-app REST polling is the current delivery mechanism. Socket.io events are emitted but not yet consumed in Flutter.

## OTP & Email

New users register with an email OTP. In development (no SMTP configured), the 6-digit code prints to the server console. OTP resends are rate-limited to once per 60 seconds, and verification locks after 5 failed attempts.

**Real email:** Set `SMTP_HOST`, `SMTP_USER`, `SMTP_PASS` in `server/.env` with valid credentials.

## Redis (Optional)

Redis is used to store OTP codes with TTL expiry. If `REDIS_URL` is not set or Redis is unreachable, the server falls back to an in-memory Map (OTPs are lost on restart).

## Video Calls (Agora)

**Mock mode** works locally without Agora keys — the Join Call button on confirmed appointments opens a simulated call UI.

**Real Agora (mobile):** Set `AGORA_APP_ID` and `AGORA_APP_CERTIFICATE` in `server/.env` to enable real video/audio on Android/iOS.

**Real Agora (web):** In addition to the env keys, add the Agora Web SDK script to `mobile/web/index.html`:
```html
<script src="iris-web-rtc_n450_w4220_0.8.6.js"></script>
```
(Download from https://download.agora.io/sdk/release/iris-web-rtc_n450_w4220_0.8.6.js)

The web integration is in **alpha stage** — mock mode works on all platforms without any setup.

## Features

| Feature | Status |
|---|---|
| Patient registration + email OTP | ✅ |
| Doctor search by name/specialty | ✅ |
| Appointment booking (date/time slot, double-book prevention) | ✅ |
| Payment (Mock / Stripe / PayFast) | ✅ |
| Doctor dashboard (summary, appointments, complete/cancel) | ✅ |
| Admin dashboard (stats, manage doctors/patients/appointments/payments) | ✅ |
| Video calls (Agora mock mode, real Agora with keys) | ✅ |
| In-app notifications (bell + badge + list) | ✅ |
| OTP resend rate limit + max attempts lockout | ✅ |
| Redis optional fallback (OTP storage) | ✅ |
| Email SMTP optional fallback (console OTP) | ✅ |
| Prescriptions | ⏳ Schema only |
| Reviews & ratings | ⏳ Schema + read only |
| Chat/messaging | ⏳ Schema only |
| Push notifications | ⏳ Wired, no server integration |
| Tests | ❌ Not written |

## Production Hardening (Phase 3A)

### Environment Validation
The backend validates required env vars at startup. Missing `DATABASE_URL`, `DIRECT_URL`, `JWT_SECRET`, or `JWT_REFRESH_SECRET` causes an immediate crash with a clear message. In production mode, placeholder values for JWT secrets are also rejected.

### CORS
In development, all origins are allowed. In production (`NODE_ENV=production`), only origins listed in the comma-separated `FRONTEND_URL` env var are permitted.

### Rate Limiting
| Endpoint | Limit |
|---|---|
| `POST /auth/login` | 10 requests/minute |
| `POST /auth/register` | 5 requests/minute |
| `POST /auth/resend-otp` | 5 requests/minute |

### Logging
Structured logging via `config/logger.ts`:
- **Production:** JSON-formatted logs (ready for log aggregation)
- **Development:** Human-readable with color
- **Secrets redacted:** Passwords, tokens, secrets, authorization headers are automatically sanitized

### Error Handling
- Prisma errors mapped to proper HTTP codes (409 unique, 404 not found, 400 foreign key, 503 connection)
- Stack traces shown in dev only; generic messages in production
- Standardized `{ error: string }` response shape

### Request Size
Limited to 1mb (down from 10mb) to prevent abuse.

---

## Deployment

See the [Deployment Guide](docs/DEPLOYMENT_GUIDE.md) for detailed instructions.

### Quick Deployment Summary

| Component | Service | Build Command | Start Command |
|---|---|---|---|
| Backend | Railway / Render | `npm install && npm run build` | `npm start` |
| Flutter web | Vercel / Cloudflare | `flutter build web --dart-define=API_BASE_URL=...` | Serve `build/web/` |
| Database | Neon (existing) | `npx prisma migrate deploy` | — |

### Migration (Production)
```bash
cd server
npx prisma migrate deploy
```
⚠️ Never use `prisma migrate reset` or `prisma db push` on production.

### Flutter Web Production Build
```bash
cd mobile
flutter build web --dart-define=API_BASE_URL=https://your-api.com/api/v1
```

### Environment Variables
See [Production Env Checklist](docs/PRODUCTION_ENV_CHECKLIST.md) for the complete list.

---

## Important

- Do not run `prisma migrate reset` on shared Neon database
- Do not use `npx prisma db push` — always create proper migrations
- See [Database & Migrations](docs/DATABASE_AND_MIGRATIONS.md) for details
