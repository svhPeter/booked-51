# Database & Migrations

## Connection

The database is a **Neon Serverless PostgreSQL** instance hosted on AWS (ap-southeast-1). Prisma connects to it, the Flutter app never connects directly.

### Connection URLs

Prisma requires two URLs:

- `DATABASE_URL` — Pooled connection (for running Prisma Client queries via the Neon pooler)
- `DIRECT_URL` — Direct connection (for migrations via `prisma migrate`)

Example (template — do not use with real secrets):

```
DATABASE_URL="postgresql://user:password@ep-xxx-pooler.region.aws.neon.tech/dbname?sslmode=require"
DIRECT_URL="postgresql://user:password@ep-xxx.region.aws.neon.tech/dbname?sslmode=require"
```

These are set in `server/.env`. Do not commit real secrets. Use `.env.example` with placeholder values for version control.

---

## Prisma Commands

All commands must run from the `server/` directory.

### Common Commands

```bash
# Generate Prisma Client (after pulling schema changes)
npx prisma generate

# Check if schema matches database
npx prisma migrate status

# Apply pending migrations
npx prisma migrate deploy

# Create a new migration from schema changes
npx prisma migrate dev --name describe_change

# Reset database (LOCAL ONLY — do not use on shared Neon DB)
npx prisma migrate reset
```

### Seed

```bash
npx prisma db seed
```

The seed script creates:
- Admin user: `admin@docbook.com` / `password123` (role=admin)
- Test doctor: `ahmed.khan@docbook.com` / `password123` (role=doctor, id=doctor-1)
- 4 more doctors with different specialties
- Test patient: `patient@test.com` / `password123`

---

## Migration Rules

### ⚠️ IMPORTANT WARNINGS

1. **DO NOT run `prisma migrate reset` on the shared Neon database.** This drops all tables and deletes all data. This command is safe only for local development databases.

2. **DO NOT use `npx prisma db push` in production.** This bypasses the migration system and applies changes directly, causing migration drift. It was used once during Phase 2A to add enum values quickly and required manual cleanup (see below). Always use `prisma migrate dev` followed by `prisma migrate deploy`.

### Migration Workflow

```bash
# 1. Edit schema.prisma

# 2. Create migration locally
npx prisma migrate dev --name describe_your_change

# 3. Verify
npx prisma migrate status

# 4. Deploy to production/Neon
npx prisma migrate deploy
```

### When `prisma migrate dev` Fails Non-Interactively

If you run `npx prisma migrate dev` and it says "database is not empty" or asks for confirmation to reset, you may need to:

1. Create the migration SQL manually:
```bash
npx prisma migrate diff --from-empty --to-schema-datamodel prisma/schema.prisma --script > prisma/migrations/XXX_name/migration.sql
```

2. Mark it as applied:
```bash
npx prisma migrate resolve --applied XXX_name
```

---

### No New Migrations for Phase 2E

Phase 2E (Notifications + OTP + Redis) did **not** require any schema changes. The `Notification` model and `NotificationType` enum already existed in the initial Prisma schema. OTP is stored in Redis or in-memory (not in the database). No new migrations were created.

---

## Enum Drift Fix (Completed May 16, 2026)

### What Happened

During Phase 2A, `mock` (PaymentProvider) and `paid` (PaymentStatus) enum values were added via `npx prisma db push`. This updated the database schema but did not create a migration file. Subsequent `prisma migrate status` reported drift: "The `public.PaymentProvider` enum has new values: `mock`" and "The `public.PaymentStatus` enum has new values: `paid`".

### The Fix

A manual no-op migration was created and marked as applied:

1. **Created** `prisma/migrations/20260516015934_fix_enum_drift/migration.sql` containing `SELECT 1;` (an intentional no-op, since the enum values already exist in the database)

2. **Applied** via:
```bash
npx prisma migrate resolve --applied 20260516015934_fix_enum_drift
```

3. **Verified** with `npx prisma migrate status` → "Database schema is up to date!"

### Why a No-Op?

The enum values `mock` and `paid` already existed in the Neon database from the earlier `db push`. Re-running `ALTER TYPE ... ADD VALUE` would fail because the values already exist. A no-op migration simply records the migration as applied so the migration history is consistent.

### How to Never Hit This Again

Always use `prisma migrate dev` to create migrations, never `prisma db push`. If you need to add a new enum value:

```bash
# Correct way:
npx prisma migrate dev --name add_new_enum_value
```

---

## Schema Summary

| Model | Table | Key Relations |
|---|---|---|
| User | `users` | has-one Patient, Doctor, or Admin |
| Patient | `patients` | belongs-to User |
| Doctor | `doctors` | belongs-to User, belongs-to Hospital, has-many Slot |
| Admin | `admins` | belongs-to User |
| Hospital | `hospitals` | has-many Doctor, has-many Appointment |
| Appointment | `appointments` | belongs-to Patient (User), belongs-to Doctor (User), has-one Payment |
| Slot | `slots` | belongs-to Doctor |
| Payment | `payments` | belongs-to Appointment, belongs-to User |
| Notification | `notifications` | belongs-to User; created on appointment book/cancel/complete, payment success |
| Message | `messages` | belongs-to sender/receiver User |
| Prescription | `prescriptions` | belongs-to Appointment |
| Review | `reviews` | belongs-to Appointment, User, Doctor |

### Enums

| Enum | Values |
|---|---|
| UserRole | `patient`, `doctor`, `admin` |
| AppointmentStatus | `pending`, `confirmed`, `cancelled`, `completed` |
| PaymentProvider | `stripe`, `payfast`, `mock` |
| PaymentStatus | `pending`, `paid`, `succeeded`, `failed`, `refunded` |
| NotificationType | `appointment_booked`, `appointment_cancelled`, `appointment_completed`, `payment_paid` |
