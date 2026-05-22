# Deployment Runbook — DocBook Platform

## Live Production URLs

| Component | URL |
|---|---|
| Backend API | `https://booked-51-production.up.railway.app/api/v1` |
| Health check | `https://booked-51-production.up.railway.app/api/v1/health` |
| Flutter web | `https://booked-51.vercel.app` |
| Database | Existing Neon PostgreSQL project |

Railway `FRONTEND_URL` must be set to `https://booked-51.vercel.app` in production.

## Deployment Order

```
1. Backend → Railway
2. Database migration (npx prisma migrate deploy)
3. Health check verification
4. Flutter web → Vercel
5. End-to-end QA against live instance
```

---

## Step 1: Backend — Railway

### Prerequisites
- GitHub repo pushed with latest code
- Railway account (railway.app)
- Neon database running and accessible

### Railway Setup

1. **Go to** https://railway.app → Dashboard → New Project
2. **Deploy from GitHub repo** → Select your repo
3. **Root Directory:** `server`
4. **Build Command:**
   ```bash
   npm install && npm run build
   ```
5. **Start Command:**
   ```bash
   npm start
   ```

### Environment Variables (Add All)

**Required — add these in Railway dashboard → Variables tab:**

| Variable | Value | Notes |
|---|---|---|
| `NODE_ENV` | `production` | Disables dev features, enables JSON logs |
| `PORT` | `3000` | Railway uses this internally |
| `DATABASE_URL` | `postgresql://...` | Pooled Neon URL (with `-pooler`) |
| `DIRECT_URL` | `postgresql://...` | Direct Neon URL (without `-pooler`) |
| `JWT_SECRET` | `<64-hex-chars>` | Generate: `openssl rand -hex 32` |
| `JWT_REFRESH_SECRET` | `<64-hex-chars>` | Different from JWT_SECRET |
| `FRONTEND_URL` | `https://your-app.vercel.app` | The Vercel deployment URL |

**Optional — add if configured:**

| Variable | Purpose |
|---|---|
| `REDIS_URL` | Redis for OTP storage (Upstash) |
| `SMTP_HOST` | Gmail SMTP or SendGrid |
| `SMTP_PORT` | Usually `587` |
| `SMTP_USER` | SMTP login email |
| `SMTP_PASS` | SMTP password / app password |
| `EMAIL_FROM` | Sender address |
| `STRIPE_SECRET_KEY` | Stripe live key |
| `STRIPE_WEBHOOK_SECRET` | Stripe webhook secret |
| `AGORA_APP_ID` | Agora App ID |
| `AGORA_APP_CERTIFICATE` | Agora certificate |
| `PAYFAST_API_KEY` | PayFast key |
| `PAYFAST_SECRET_KEY` | PayFast secret |
| `PAYFAST_BASE_URL` | PayFast endpoint |
| `FIREBASE_SERVICE_ACCOUNT_JSON_BASE64` | Future push notifications — Base64 of Firebase Admin SDK JSON (skippable now) |

### Firebase

Firebase is **fully optional** for the current deployment. All in-app notifications work without it.

When implementing server-side push notifications in the future:
1. Download service account JSON from Firebase Console → Project Settings → Service accounts
2. **Never commit the raw JSON file** (`.gitignore` blocks `*firebase-adminsdk*.json` and `*firebase-service-account*.json`)
3. Encode and set the Railway env var:
   ```bash
   cat firebase-service-account.json | base64
   # Copy output and set as FIREBASE_SERVICE_ACCOUNT_JSON_BASE64 in Railway Dashboard
   ```
4. The server decodes the JSON at runtime — no file upload required

### Run Migration

After Railway deploys, open **Railway Shell** and run:

```bash
npx prisma migrate deploy
```

Expected output:
```
2 migrations found in prisma/migrations
No pending migrations to apply.
```

If it shows `Already applied`, that's fine.

### Verify Health

```bash
curl https://booked-51-production.up.railway.app/api/v1/health
```

Expected:
```json
{"status":"ok","database":"healthy","uptime":123.45}
```

---

## Step 2: Database Migration (Neon)

No manual steps needed if Railway runs `prisma migrate deploy`. To verify:

```bash
# From local machine (not Railway)
cd server
npx prisma migrate status
```

Expected: `Database schema is up to date!`

**⚠️ Never run these on production Neon:**
- `prisma migrate reset` — **DROPS ALL DATA**
- `prisma db push` — **CAUSES MIGRATION DRIFT**

---

## Step 3: Frontend — Vercel

### Prerequisites
- Vercel account (vercel.com)
- GitHub repo pushed with latest code
- Backend deployed and health endpoint returning 200

### Vercel Setup

1. **Go to** https://vercel.com → Dashboard → Add New → Project
2. **Import GitHub repo** → Select your repo
3. **Root Directory:** `mobile`
4. **Framework Preset:** Other
5. **Install Command:**
   ```bash
   if [ ! -d "$HOME/flutter" ]; then git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"; fi && "$HOME/flutter/bin/flutter" config --enable-web && "$HOME/flutter/bin/flutter" pub get
   ```
6. **Build Command:**
   ```bash
   "$HOME/flutter/bin/flutter" build web --release --dart-define=API_BASE_URL=https://booked-51-production.up.railway.app/api/v1
   ```
7. **Output Directory:** `build/web`
8. **Environment Variables (if needed for build):** None required
9. Click **Deploy**

### After Deploy

1. Vercel provides a URL like `https://your-app.vercel.app`
2. Update Railway's `FRONTEND_URL` to this value
3. Test the app loads and can log in

### Custom Domain (Optional)

- Add your domain in Vercel dashboard → Domains
- Configure CNAME record with your DNS provider

---

## Step 4: Post-Deploy QA

Run `docs/LIVE_QA_CHECKLIST.md` against the live instance.

### Phase 4 Post-Deploy Result

Verified on 2026-05-22:

- Backend health returned `status: "ok"` and `database: "healthy"`
- Vercel served the Flutter web shell
- Compiled Flutter web build contains `API_BASE_URL=https://booked-51-production.up.railway.app/api/v1`
- Railway CORS allows `https://booked-51.vercel.app`
- Random non-production origin did not receive an allowed CORS origin header
- Patient, doctor, and admin login flows worked with seeded demo credentials
- Patient booking created a `confirmed` appointment and no payment record
- Patient appointment detail, notifications, appointment chat, doctor dashboard, admin dashboard, admin chat metadata, mock video, role blocking, and logout endpoints were verified

### Post-Deploy Safety Notes

- Phase 4E marks seeded users as demo data. Demo admin login is blocked in production after `20260522143000_phase4e_launch_safety` is deployed.
- Create or update a secure production admin from Railway Shell:
  ```bash
  ADMIN_EMAIL=your-admin@example.com ADMIN_PASSWORD='<secure-password>' ADMIN_NAME='Platform Admin' npm run admin:upsert
  ```
- Do not keep `admin@docbook.com` with the seed password as a production admin.
- Keep seeded patient/doctor accounts as demo-only, or deactivate/remove them before inviting real users.
- The seed script is not automatically run by production deploy. `postinstall` only runs `prisma generate`.
- The seed script is blocked in `NODE_ENV=production` unless `ALLOW_DEMO_SEED=true` is set intentionally.
- Do not commit `.env`, Firebase service account JSON, Google service files, or real Base64 Firebase service account values.
- Firebase and Agora are optional for current production. In-app notifications and mock video work without them.
- Payment backend endpoints exist but the active Phase 4 UX is direct booking/pay-at-clinic; booking does not create a payment record.

### Critical Checks

1. ✅ Health endpoint returns `database: "healthy"`
2. ✅ Login works for patient, doctor, admin
3. ✅ Patient can book appointment
4. ✅ Active booking flow stays pay-at-clinic and creates no payment record
5. ✅ Notifications appear after booking
6. ✅ Doctor dashboard loads
7. ✅ Admin dashboard loads
8. ✅ Video mock mode returns session
9. ✅ CORS: frontend works, random origin blocked
10. ✅ Role guards: patient blocked from doctor routes

---

## Rollback Plan

### Backend Rollback
1. **Railway:** Click **Deploy previous commit** or redeploy a specific commit
2. **Database:** Neon **Point-in-Time Recovery** — restore to any point in last 7 days

### Frontend Rollback
1. **Vercel:** Go to **Deployments** → click **...** → **Promote to Production** on previous deployment
2. Redeploy takes ~30 seconds

### Full Rollback
```
1. Vercel: Promote previous deployment
2. Railway: Deploy previous commit
3. Database: Only if schema migration broke — use Neon PITR
```

---

## Common Errors and Fixes

| Error | Cause | Fix |
|---|---|---|
| `DATABASE_URL is missing` | Env var not set | Add `DATABASE_URL` and `DIRECT_URL` to Railway vars |
| `database: "unhealthy"` | DB unreachable | Check Neon status, verify connection strings |
| `prisma migrate deploy fails` | `DIRECT_URL` missing or wrong | Ensure `DIRECT_URL` is set (needed for migrations) |
| `CORS error in browser` | `FRONTEND_URL` doesn't match Vercel URL | Update Railway's `FRONTEND_URL` env var |
| 401 on all requests | `JWT_SECRET` changed after deploy | Must use same secret, or all tokens invalidated |
| Flutter build fails | Missing Flutter SDK on Vercel | Use the Install Command above to clone Flutter stable and run `flutter pub get` |
| `module not found` | Wrong root directory | Ensure Railway root = `server`, Vercel root = `mobile` |
