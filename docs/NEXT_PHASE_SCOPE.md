# Next Phase Scope

## ✅ Phase 3A — Production Hardening (Completed)

### Completed in Phase 3A

| Area | Status |
|---|---|
| Environment variable validation | ✅ Fail-fast on missing DATABASE_URL, DIRECT_URL, JWT_SECRET, JWT_REFRESH_SECRET; dev warnings for optional unconfigured services |
| CORS lockdown | ✅ Supports comma-separated `FRONTEND_URL` env var; open origin only in dev mode |
| Helmet security headers | ✅ Already present; CSP disabled in dev, enabled in production |
| Rate limiting | ✅ `express-rate-limit` on login (10/min), register (5/min), resend-otp (5/min) |
| Request size limit | ✅ Reduced from 10mb to 1mb |
| Structured logging | ✅ `config/logger.ts` — JSON logs in production, human-readable in dev; no secrets logged |
| Request logging middleware | ✅ Logs method, path, status, duration on every request |
| Event logging | ✅ Login success/failure, registration, appointment book/cancel/complete, payment paid, video session, notification created |
| Prisma error handling | ✅ Handles P2002 (unique), P2025 (not found), P2003 (foreign key), validation/connection errors |
| Dev vs prod error responses | ✅ Stack traces in dev only; generic "Internal server error" in production |
| Health check enhanced | ✅ `/api/v1/health` now returns `database` status (healthy/unhealthy) + `uptime` |
| `.env.example` created | ✅ Documented all env vars with required/optional labels and placeholder values |
| Secret sanitization | ✅ Logger redacts password, token, secret, authorization, cookie headers |
| Prisma migration confirmed | ✅ No drift, 2 migrations, database schema is up to date |

## ✅ Phase 3B — Deployment Preparation (Completed)

### Completed in Phase 3B

| Area | Status |
|---|---|
| Package.json scripts | ✅ `build`, `start`, `dev`, `db:migrate:deploy`, `postinstall` (auto prisma generate) |
| Flutter API base URL strategy | ✅ `String.fromEnvironment('API_BASE_URL')` with localhost default; production passed via `--dart-define` |
| DEPLOYMENT_GUIDE.md | ✅ Created with hosting recommendations, build/start/migration commands, health check, rollback |
| PRODUCTION_ENV_CHECKLIST.md | ✅ Created with required/optional vars, secrets generation, rotation notes |
| FINAL_QA_CHECKLIST.md | ✅ Created with 50+ test items |
| CORS docs | ✅ `FRONTEND_URL` supports multiple origins (comma-separated), open-origin disabled in production |

## Recommended Next: Phase 3C — Final QA + Deployment

### Goal
Deploy the platform to production. Run the full QA checklist against the live instance, fix any issues, and launch v1.0.

---

### 1. Deploy Backend to Railway / Render

- [ ] Push code to GitHub
- [ ] Create Railway service from repo (root dir: `server`)
- [ ] Set build command: `npm install && npm run build`
- [ ] Set start command: `npm start`
- [ ] Add all required env vars (see PRODUCTION_ENV_CHECKLIST.md)
- [ ] Run `npx prisma migrate deploy` in Railway shell
- [ ] Verify `GET /api/v1/health` returns `database: "healthy"`
- [ ] Run QA checklist against live backend

### 2. Deploy Flutter Web to Vercel / Cloudflare

- [ ] Connect repo to Vercel (root dir: `mobile`)
- [ ] Set build command: `flutter build web --dart-define=API_BASE_URL=https://your-api.railway.app/api/v1`
- [ ] Set output dir: `build/web`
- [ ] Deploy
- [ ] Verify app loads and can log in
- [ ] Verify API calls work (no CORS errors)
- [ ] Run QA checklist against live app

### 3. Post-Deploy Verification

- [ ] Run `docs/FINAL_QA_CHECKLIST.md` against production
- [ ] Test all 3 user roles (patient, doctor, admin)
- [ ] Test booking + payment flow end-to-end
- [ ] Test notifications
- [ ] Test video mock mode
- [ ] Test rate limiting
- [ ] Test role access control
- [ ] Verify logs are JSON and contain no secrets
- [ ] Verify error responses have no stack traces

### 4. Production Readiness

- [ ] Custom domain configured (backend + frontend)
- [ ] SSL/HTTPS working
- [ ] Database backup confirmed (Neon PITR)
- [ ] Monitor set up (UptimeRobot / Better Uptime)
- [ ] (Optional) Sentry error monitoring
- [ ] (Optional) Dockerfile for future containerized deployment

---

## Future Feature Phases (After Phase 3)

### Phase 2F — Prescriptions & Reviews

- **Backend:**
  - CRUD endpoints for Prescription (doctor creates per appointment)
  - Review endpoints (patient creates per completed appointment)
  - Update doctor average rating on new review
- **Flutter:**
  - Prescription upload/view screen (PDF upload + notes)
  - Review/rating screen after completed appointment
  - Display reviews on doctor profile

### Phase 2G — Chat/Messaging

- **Backend:**
  - Socket.io-based messaging between patient and doctor per appointment
  - Message history endpoints
  - Mark as read/unread
- **Flutter:**
  - Chat UI using Socket.io client
  - Real-time message delivery
  - Unread message badge on appointment cards

### Phase 4 — Mobile Native (iOS/Android)

- Enable Agora real video on mobile (Android/iOS) — fully wired in Phase 2D.1
- Firebase push notifications via FCM
- Platform-specific permissions (camera, microphone, notifications)
- App store deployment readiness
