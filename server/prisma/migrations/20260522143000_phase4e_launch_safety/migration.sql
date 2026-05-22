ALTER TABLE "users" ADD COLUMN "isDemo" BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE "doctors" ADD COLUMN "pmdcRegistrationNumber" TEXT;

UPDATE "users"
SET "isDemo" = true
WHERE "email" IN (
  'admin@docbook.com',
  'patient@test.com',
  'ahmed.khan@docbook.com',
  'fatima.ali@docbook.com',
  'usman.malik@docbook.com',
  'zara.hassan@docbook.com',
  'bilal.ahmed@docbook.com'
);
