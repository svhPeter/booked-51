# Deployment Guide — Doctor Appointment Platform

## Recommended Deployment Strategy

For a solo developer, the simplest and most cost-effective setup:

| Component | Recommended Service | Why |
|---|---|---|
| **Backend API** | **Railway** or **Render** | Free tier available; zero-config Node/TypeScript deploys from GitHub; auto HTTPS; env var management |
| **Database** | **Neon** (already hosted) | Serverless PostgreSQL; generous free tier; point-in-time recovery; connection pooling |
| **Redis** (optional) | **Upstash** or **Redis Cloud** | Free tier (up to 30MB); serverless; no ops overhead |
| **Frontend (Flutter web)** | **Vercel** or **Cloudflare Pages** | Free tier; CDN edge delivery; instant rollback; custom domain + HTTPS |
| **Domain** | **Namecheap** / **Cloudflare** | Point to Vercel/Railway with CNAME records |

**Alternative:** Use **Fly.io** if you want both backend + Redis in one platform. Use **AWS ECS** only if scale requires it (overkill for solo dev).

---

## Backend Deployment (Railway / Render)

### Prerequisites

- Node 20+ runtime
- Git repository connected to Railway/Render
- Neon PostgreSQL database (already provisioned)
- (Optional) Upstash Redis instance

### Deployment Steps

1. **Push code to GitHub**

2. **In Railway/Render dashboard:**
   - Create new service → select your repo
   - Set **Root Directory**: `server`
   - Set **Build Command**: `npm install && npm run build`
   - Set **Start Command**: `npm start`

3. **Set environment variables** (see `docs/PRODUCTION_ENV_CHECKLIST.md`)

4. **Run migration:**
   ```bash
   # Either via Railway/Render shell:
   npx prisma migrate deploy

   # Or locally (if DIRECT_URL has access):
   cd server
   NODE_ENV=production npx prisma migrate deploy
   ```

5. **Verify health:**
   ```bash
   curl https://your-app.railway.app/api/v1/health
   # Expected: {"status":"ok","database":"healthy","uptime":...}
   ```

### Build Commands

```bash
cd server
npm install                   # Install deps + postinstall runs prisma generate
npm run build                 # tsc → compiles src/ to dist/
npx prisma migrate deploy     # Apply pending migrations (safe)
npm start                     # node dist/index.js
```

### Production Start Command

```bash
node dist/index.js
```

The compiled output is in `server/dist/`. The entry point is `dist/index.js`.

### Important: Prisma Client in Production

The `postinstall` script (`prisma generate`) automatically generates Prisma Client after `npm install`. If you skip `postinstall` (some platforms do), run explicitly:

```bash
npx prisma generate
```

---

## Flutter Web Deployment (Vercel / Cloudflare Pages)

### Strategy for API Base URL

The Flutter app reads the API base URL from a build-time `--dart-define` flag:

```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000/api/v1',
);
```

This means:
- **Local dev:** Defaults to `http://localhost:3000/api/v1` — no config needed
- **Production build:** Must pass `API_BASE_URL` explicitly

### Build for Production

```bash
cd mobile
flutter build web --dart-define=API_BASE_URL=https://your-api.railway.app/api/v1
```

The output is in `mobile/build/web/` — deploy this directory to Vercel/Cloudflare Pages.

### Vercel Setup

1. Install Vercel CLI or connect GitHub repo
2. Set **Build Command**: `flutter build web --dart-define=API_BASE_URL=https://your-api.railway.app/api/v1`
3. Set **Output Directory**: `build/web`
4. Set **Root Directory**: `mobile`
5. Deploy

### Cloudflare Pages Setup

1. Connect GitHub repo
2. Set **Build Command**: `flutter build web --dart-define=API_BASE_URL=https://your-api.railway.app/api/v1`
3. Set **Build Output**: `build/web`
4. Set **Root Directory**: `mobile`
5. Deploy

### Multiple Environments

For staging vs production, use different `--dart-define` values:

```bash
# Staging
flutter build web --dart-define=API_BASE_URL=https://staging-api.railway.app/api/v1

# Production
flutter build web --dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1
```

---

## Neon Database Setup

Neon is already provisioned. To create a new Neon project:

1. Go to https://console.neon.tech
2. Create project → select region closest to your users
3. Copy `DATABASE_URL` (pooled) and `DIRECT_URL` (direct connection)
4. Add to your deployment environment variables

### Firebase (Optional — Future Push Notifications)

Firebase is **not required** for deployment. Current in-app notifications work without it.

When ready for push notifications:
1. Download the Firebase Admin SDK service account JSON from Firebase Console
2. **Never commit the raw JSON** — it is blocked by `.gitignore`
3. For Railway: encode and set `FIREBASE_SERVICE_ACCOUNT_JSON_BASE64`:
   ```bash
   cat firebase-service-account.json | base64
   ```

### Connection URLs

```
DATABASE_URL="postgresql://user:password@ep-xxx-pooler.region.aws.neon.tech/dbname?sslmode=require"
DIRECT_URL="postgresql://user:password@ep-xxx.region.aws.neon.tech/dbname?sslmode=require"
```

- `DATABASE_URL` — Used by Prisma Client for queries (goes through Neon pooler)
- `DIRECT_URL` — Used by Prisma Migrate for schema changes (direct connection)

---

## Migration Command

Always use this for production:

```bash
# From the server/ directory
npx prisma migrate deploy
```

**Never** use these on production Neon:
- `prisma migrate reset` — **DROPS ALL DATA**
- `prisma db push` — **CAUSES MIGRATION DRIFT**

---

## Health Check

```
GET /api/v1/health
```

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2026-05-18T09:00:00.000Z",
  "database": "healthy",
  "uptime": 123.45
}
```

Use this URL for load balancer health checks or monitoring (e.g., UptimeRobot, Better Uptime).

---

## Post-Deploy Test Checklist

After deployment, verify:

- [ ] `GET /api/v1/health` returns `{"status":"ok","database":"healthy"}`
- [ ] `POST /api/v1/auth/login` works for test users
- [ ] `POST /api/v1/auth/register` creates user + OTP sent (or console)
- [ ] Patient can book appointment
- [ ] Doctor can view dashboard
- [ ] Admin can view dashboard
- [ ] Notifications are created on booking
- [ ] Video call mock mode works
- [ ] Flutter web app loads and can log in
- [ ] Flutter web app can make API calls to deployed backend
- [ ] CORS: frontend domain is allowed, other domains are blocked
- [ ] Rate limiting returns 429 after too many login attempts

---

## Rollback Notes

### Backend Rollback
- Railway/Render: Deploy previous commit or use **Point-in-time restore** for the service
- Database: Neon **point-in-time recovery** — restore to any point in the last 7 days

### Frontend Rollback
- Vercel: One-click rollback to any previous deployment
- Cloudflare Pages: Instant rollback via dashboard

### Database Migration Rollback
- `prisma migrate deploy` only applies forward migrations
- To revert: create a new migration that reverses the change, then deploy it
- Neon's PITR is the safety net for catastrophic schema errors
