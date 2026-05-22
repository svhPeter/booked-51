import dotenv from 'dotenv';
import { PrismaClient } from '@prisma/client';

dotenv.config();

const prisma = new PrismaClient();

async function main() {
  if (process.env.CONFIRM_DEACTIVATE_DEMO_USERS !== 'deactivate-demo-users') {
    throw new Error('Set CONFIRM_DEACTIVATE_DEMO_USERS=deactivate-demo-users to deactivate demo users.');
  }

  const result = await prisma.user.updateMany({
    where: { isDemo: true },
    data: { isActive: false },
  });

  console.log(`Demo users deactivated: ${result.count}`);
}

main()
  .catch((error) => {
    console.error(error.message);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
