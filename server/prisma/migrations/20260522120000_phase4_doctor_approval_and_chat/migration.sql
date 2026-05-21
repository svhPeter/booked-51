-- Phase 4: Doctor approval for public listing + appointment-scoped chat

-- Doctor approval gate
ALTER TABLE "doctors" ADD COLUMN IF NOT EXISTS "isApproved" BOOLEAN NOT NULL DEFAULT false;

-- Approve existing seeded doctors in production
UPDATE "doctors" SET "isApproved" = true WHERE "isApproved" = false;

-- Appointment-scoped messages (table may be empty on fresh deploys)
ALTER TABLE "messages" ADD COLUMN IF NOT EXISTS "appointmentId" TEXT;

-- Remove orphan messages without appointment (none expected in MVP)
DELETE FROM "messages" WHERE "appointmentId" IS NULL;

ALTER TABLE "messages" ALTER COLUMN "appointmentId" SET NOT NULL;

ALTER TABLE "messages" ADD CONSTRAINT "messages_appointmentId_fkey"
  FOREIGN KEY ("appointmentId") REFERENCES "appointments"("id") ON DELETE CASCADE ON UPDATE CASCADE;

CREATE INDEX IF NOT EXISTS "messages_appointmentId_createdAt_idx" ON "messages"("appointmentId", "createdAt");
CREATE INDEX IF NOT EXISTS "messages_receiverId_isRead_idx" ON "messages"("receiverId", "isRead");
CREATE INDEX IF NOT EXISTS "appointments_doctorId_date_timeSlot_status_idx" ON "appointments"("doctorId", "date", "timeSlot", "status");
