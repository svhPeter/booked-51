CREATE TABLE "pending_registrations" (
  "id" TEXT NOT NULL,
  "email" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "phone" TEXT NOT NULL,
  "city" TEXT NOT NULL,
  "passwordHash" TEXT NOT NULL,
  "role" "UserRole" NOT NULL,
  "specialty" TEXT,
  "clinicName" TEXT,
  "consultationFee" DOUBLE PRECISION,
  "pmdcRegistrationNumber" TEXT,
  "otpHash" TEXT NOT NULL,
  "otpExpiresAt" TIMESTAMP(3) NOT NULL,
  "attempts" INTEGER NOT NULL DEFAULT 0,
  "lastResendAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,

  CONSTRAINT "pending_registrations_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "pending_registrations_email_key" ON "pending_registrations"("email");
CREATE INDEX "pending_registrations_otpExpiresAt_idx" ON "pending_registrations"("otpExpiresAt");
