# Cost and Scale Plan

## Current stack (MVP deployed)

| Component | Provider | Typical monthly cost (low traffic) |
|-----------|----------|-----------------------------------|
| API | Railway | $5–20 (Hobby / usage) |
| Database | Neon PostgreSQL | $0 free tier → ~$19+ when limits hit |
| Frontend | Vercel (Flutter web static) | $0 Hobby |
| Redis (optional) | Upstash | $0 free tier |
| Email OTP | SMTP / Resend free tier | $0–15 |
| Video | Agora | Free minutes → usage-based |
| **Estimated total** | | **~$5–35/month** |

## What increases cost as traffic grows

| Driver | Effect |
|--------|--------|
| Railway CPU/egress | More API requests, always-on instance size |
| Neon storage & compute | More rows, connection time, branches |
| Vercel bandwidth | More Flutter web users |
| Agora | Real video minutes |
| SMTP/SMS | OTP and notification volume |
| Redis | When multi-instance or durable OTP required |

## When to add infrastructure

| Capability | Trigger | Recommendation |
|------------|---------|----------------|
| **Redis (Upstash)** | 2+ API instances OR OTP must survive restarts | `REDIS_URL` on Railway |
| **Sentry** | Production users reporting bugs | Free tier, DSN in env |
| **Object storage** | Avatar upload, prescription PDFs | Cloudflare R2 or Vercel Blob |
| **SMS/WhatsApp OTP** | Low email deliverability in PK | Twilio or local provider |
| **CDN/WAF** | Abuse or marketing spike | Cloudflare in front of Vercel |
| **Monitoring** | SLA expectations | UptimeRobot / Better Uptime (free) |

## Database indexing (add as load grows)

```sql
-- Recommended indexes (via Prisma @@index or migration)
appointments(doctorId, date, timeSlot, status)
notifications(userId, isRead, createdAt)
messages(appointmentId, createdAt)
messages(receiverId, isRead)
doctors(isApproved)  -- after Phase 4A
```

## Rate limiting

**Today:** Auth endpoints (login, register, resend-otp).

**Add when public launch scales:**

- `POST /appointments` — per patient
- `POST /appointments/:id/messages` — per user per appointment
- `GET /doctors` search — per IP

Use Redis-backed store when running multiple Railway replicas.

## Backups and monitoring

- **Neon:** Enable point-in-time recovery on paid plan; confirm backup retention.
- **Health:** `GET /api/v1/health` — monitor database field.
- **Logs:** Railway JSON logs; no secrets in logger (already redacted).
- **Alerts:** Uptime on health URL + Vercel deployment status.

## Scaling path (rough order)

1. **0–1k MAU** — Current stack, single Railway service, Neon free/hobby.
2. **1k–10k MAU** — Redis, DB indexes, Sentry, consider Neon scale plan.
3. **10k+ MAU** — Read replicas or connection pool tuning, dedicated Redis, SMS OTP, object storage for media.

## Payment infrastructure (dormant)

Stripe/PayFast env vars can remain unset. No webhook endpoint is required until online payments are activated. Activating payments adds:

- Stripe/PayFast fees per transaction
- Webhook endpoint + idempotency handling
- Support and reconciliation overhead
