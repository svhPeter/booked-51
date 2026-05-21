# Production Environment Checklist — DocBook

## 🔴 Required Environment Variables

These must be set for the backend to start. Missing any causes an immediate crash.

| Variable | Purpose | Example Placeholder |
|---|---|---|
| `DATABASE_URL` | Prisma pooled connection to Neon | `postgresql://user:pass@ep-xxx-pooler.region.aws.neon.tech/dbname?sslmode=require` |
| `DIRECT_URL` | Direct connection for Prisma Migrate | `postgresql://user:pass@ep-xxx.region.aws.neon.tech/dbname?sslmode=require` |
| `JWT_SECRET` | JWT signing key (64 hex chars) | `change-me-to-a-random-64-char-hex-string` |
| `JWT_REFRESH_SECRET` | Refresh token signing key (64 hex chars) | `change-me-to-another-random-64-char-hex-string` |
| `FRONTEND_URL` | Allowed CORS origin (comma-separated for multiple) | `https://my-app.vercel.app` |
| `NODE_ENV` | Must be `production` in production | `production` |
| `PORT` | Server port | `3000` |

### Generating JWT Secrets

```bash
openssl rand -hex 32
# Output: 46751cb0ae76cc358b2dfd2bb5f7148849119ce14954824e6625c9d9e7cdff26
```

Generate two unique values — one for `JWT_SECRET`, one for `JWT_REFRESH_SECRET`.

---

## 🟡 Optional Environment Variables

These enable additional features. The server starts without them, but functionality is limited.

| Variable | Purpose | Without It |
|---|---|---|
| `SMTP_HOST` | SMTP server for email OTP | OTP printed to server console |
| `SMTP_PORT` | SMTP port (default: 587) | — |
| `SMTP_USER` | SMTP login | OTP printed to server console |
| `SMTP_PASS` | SMTP password/app password | OTP printed to server console |
| `EMAIL_FROM` | Sender email address | `noreply@docbook.com` |
| `REDIS_URL` | Redis connection for OTP storage | In-memory OTP store (lost on restart) |
| `STRIPE_SECRET_KEY` | Stripe secret key | Mock payment only |
| `STRIPE_WEBHOOK_SECRET` | Stripe webhook signing secret | Stripe webhook verification skipped |
| `PAYFAST_API_KEY` | PayFast API key | Mock payment only |
| `PAYFAST_SECRET_KEY` | PayFast secret key | Mock payment only |
| `PAYFAST_BASE_URL` | PayFast API endpoint | `https://api.payfast.pk/v1` |
| `AGORA_APP_ID` | Agora App ID for video calls | Mock video only |
| `AGORA_APP_CERTIFICATE` | Agora certificate | Mock video only |

---

## 🔵 Optional (Future)

| Variable | Purpose | Status |
|---|---|---|
| `FIREBASE_SERVER_KEY` | Legacy FCM server key (kept for backward compatibility) | Not yet implemented server-side |
| `FIREBASE_SERVICE_ACCOUNT_JSON_BASE64` | Base64-encoded Firebase Admin SDK service account JSON | Future push notification feature |

---

## ⚠️ What Must Never Be Committed

- **`.env`** files (already in `.gitignore`)
- Real `DATABASE_URL` or `DIRECT_URL` with real passwords
- Real `JWT_SECRET` or `JWT_REFRESH_SECRET`
- Real `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`
- Real `SMTP_USER` / `SMTP_PASS`
- Real `AGORA_APP_ID` / `AGORA_APP_CERTIFICATE`
- Real `PAYFAST_API_KEY` / `PAYFAST_SECRET_KEY`
- Real `FIREBASE_SERVER_KEY`
- **Firebase Admin SDK service account JSON files** (matching `*firebase-adminsdk*.json`, `*firebase-service-account*.json`) — see `.gitignore`
- Google services config files: `GoogleService-Info.plist`, `google-services.json`
- **Real `FIREBASE_SERVICE_ACCOUNT_JSON_BASE64` value** — only set in Railway Dashboard, never in code

Only `.env.example` with placeholder values should be in version control.

---

## Firebase Service Account Notes

- Firebase is **optional**. Current in-app notifications work without it.
- When implementing push notifications in the future, download the Firebase Admin SDK service account JSON from Firebase Console → Project Settings → Service accounts.
- **Never commit the raw JSON file.** The `.gitignore` now blocks `*firebase-adminsdk*.json` and `*firebase-service-account*.json`.
- For Railway deployment: encode the JSON and set `FIREBASE_SERVICE_ACCOUNT_JSON_BASE64`:
  ```bash
  cat firebase-service-account.json | base64
  ```
- The server will decode this at runtime — no file upload needed.

---

## Secret Rotation Notes

- **JWT secrets:** Rotate immediately if compromised. Changing invalidates all existing tokens (users must re-login).
- **Stripe keys:** Rotate from Stripe dashboard. Webhook secrets must match.
- **SMTP passwords:** Gmail App Passwords can be revoked from Google Account settings.
- **Database passwords:** Change from Neon dashboard, update `DATABASE_URL` and `DIRECT_URL`.
- **Firebase service account:** Rotate from Firebase Console → Service accounts → Generate new key. Old key continues until you delete it.

---

## Example `.env` for Production

```bash
NODE_ENV=production
PORT=3000

DATABASE_URL="postgresql://user:password@ep-xxx-pooler.region.aws.neon.tech/dbname?sslmode=require"
DIRECT_URL="postgresql://user:password@ep-xxx.region.aws.neon.tech/dbname?sslmode=require"

JWT_SECRET=<random-64-hex-chars>
JWT_REFRESH_SECRET=<random-64-hex-chars-different>
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

FRONTEND_URL=https://my-app.vercel.app

# Optional — uncomment if configured
# REDIS_URL=redis://...
# SMTP_HOST=smtp.gmail.com
# SMTP_PORT=587
# SMTP_USER=your-email@gmail.com
# SMTP_PASS=your-app-password
# EMAIL_FROM=noreply@docbook.com
# STRIPE_SECRET_KEY=sk_live_...
# STRIPE_WEBHOOK_SECRET=whsec_...
# AGORA_APP_ID=...
# AGORA_APP_CERTIFICATE=...

# Firebase (optional — future push notifications)
# FIREBASE_SERVICE_ACCOUNT_JSON_BASE64=<base64-of-service-account-json>
```
