# Production Launch Safety

## Status

Phase 4E adds launch-safety controls before inviting real users. The product remains Pakistan-first and free to book: consultation fees are informational, and payment happens at the clinic or directly with the doctor.

## Admin Safety

Do not use `admin@docbook.com` / `password123` as a production admin.

Create or update a secure production admin from Railway Shell:

```bash
ADMIN_EMAIL=your-admin@example.com ADMIN_PASSWORD='<secure-password>' ADMIN_NAME='Platform Admin' npm run admin:upsert
```

Rules:

- `ADMIN_PASSWORD` must be at least 12 characters.
- `password123` is rejected.
- Existing non-admin users are not promoted by the script.
- Created/updated admins are marked `isDemo=false`, `isVerified=true`, and `isActive=true`.

## Demo Data Strategy

Demo users and profiles remain for presentation, but they are explicitly marked with `User.isDemo=true`.

Seeded demo accounts:

- `admin@docbook.com`
- `patient@test.com`
- `ahmed.khan@docbook.com`
- `fatima.ali@docbook.com`
- `usman.malik@docbook.com`
- `zara.hassan@docbook.com`
- `bilal.ahmed@docbook.com`

Production behavior:

- Demo admin login is blocked in production.
- Demo doctor/patient profiles can remain for presentations until explicitly deactivated.
- Optional deactivation command:
  ```bash
  CONFIRM_DEACTIVATE_DEMO_USERS=deactivate-demo-users npm run demo:deactivate
  ```

## Seed Safety

The seed script is not run automatically by deployment. `postinstall` only runs `prisma generate`.

The demo seed script refuses to run when `NODE_ENV=production` unless this is intentionally set:

```bash
ALLOW_DEMO_SEED=true
```

Do not set `ALLOW_DEMO_SEED=true` in production unless intentionally preparing a demo/staging environment.

## Signup Rules

Patient signup uses `/auth/register` and creates only patient users.

Doctor onboarding uses `/auth/register-doctor` and creates doctor users with:

- `isVerified=false` until OTP verification
- `Doctor.isApproved=false`
- `Doctor.isAvailable=false`

Admin approval is required before the doctor appears in public search or can receive bookings.

## Email Verification

Login rejects unverified users with:

```text
Please verify your email before logging in
```

Unverified users can request OTP resend. OTPs expire after 10 minutes and lock after 5 failed attempts.

## Forgot Password

Forgot password uses the same OTP delivery path:

- `POST /api/v1/auth/forgot-password`
- `POST /api/v1/auth/reset-password`

Forgot-password responses do not reveal whether an email exists. Reset requires a valid OTP and hashes the new password with bcrypt.

## Public Doctor Directory Guardrails

Doctor scraping/import is intentionally out of scope for Phase 4E.

Future directory expansion should follow these rules:

- Use source-based, auditable public data only.
- Do not scrape or publish sensitive/private doctor data blindly.
- Mark imported/unclaimed profiles clearly.
- Disable booking/chat on unclaimed profiles until verified or claimed.
- Give doctors a claim, update, and removal path.

## Launch Checklist

- Run `npx prisma migrate deploy` on Railway.
- Run `npm run admin:upsert` with a secure admin email/password.
- Confirm `admin@docbook.com` demo admin cannot log in in production.
- Confirm patient signup creates only patient users.
- Confirm doctor onboarding creates unapproved doctors.
- Confirm unapproved doctors are hidden from public listing.
- Confirm forgot/reset password works.
- Keep Firebase/Agora optional unless intentionally configured.
- Keep payment backend dormant in active UX.

## Production Email Delivery (Phase 5A)

Production email uses **Brevo HTTP API** — not SMTP.

Gmail SMTP and Brevo SMTP both time out from Railway due to SMTP port restrictions. The Brevo HTTP API sends transactional emails over standard HTTPS (port 443), which works reliably from Railway.

### Required Railway Environment Variables

```
EMAIL_PROVIDER=brevo
BREVO_API_KEY=<Brevo API key — NOT SMTP key>
EMAIL_FROM=<Brevo verified sender email>
EMAIL_FROM_NAME=DocBook
```

### Brevo Security Note

Brevo may block unknown IPs for API keys by default. For Railway (dynamic IPs), either:
- Disable "Unauthorized IP blocking" in Brevo → Settings → SMTP & API → Security
- Or add Railway outbound IPs if available

### Admin Diagnostic Endpoint

Test all email templates from production:

```bash
POST /api/v1/admin/email-diagnostic
Authorization: Bearer <admin_token>
Body: {"to": "test@example.com"}
```

Returns `sent`, `durationMs`, and `provider` per template. No secrets exposed.

### Health Endpoint

The health endpoint shows the active email provider:

```json
{"email": {"provider": "brevo", "configured": true}}
```

## Post-Testing Security Rotation

> ⚠️ After completing beta testing, rotate all secrets that were exposed during development:

| Secret | Action |
|--------|--------|
| `ADMIN_PASSWORD` | Change via `npm run admin:upsert` with a new secure password |
| `JWT_SECRET` | Generate new: `openssl rand -hex 32` — all existing tokens will be invalidated |
| `JWT_REFRESH_SECRET` | Generate new: `openssl rand -hex 32` — all refresh tokens will be invalidated |
| `BREVO_API_KEY` | Rotate in Brevo dashboard if exposed during testing |
| `SMTP_PASS` | Rotate Gmail app password if used during dev |
| Database password | Rotate in Neon dashboard if exposed |

Rotate all secrets in Railway env vars simultaneously, then redeploy. Users will need to log in again.
