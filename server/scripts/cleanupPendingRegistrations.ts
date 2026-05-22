import dotenv from 'dotenv';
import { PrismaClient } from '@prisma/client';

dotenv.config();

const prisma = new PrismaClient();

async function main() {
  const result = await prisma.pendingRegistration.deleteMany({
    where: { otpExpiresAt: { lt: new Date() } },
  });

  console.log(`Expired pending registrations deleted: ${result.count}`);
}

main()
  .catch((error) => {
    console.error(error.message);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
