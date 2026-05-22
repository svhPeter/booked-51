import dotenv from 'dotenv';
import { PrismaClient } from '@prisma/client';
import { maskEmail } from '../src/services/emailService';

dotenv.config();

const prisma = new PrismaClient();

async function main() {
  const users = await prisma.user.findMany({
    where: { isVerified: false },
    select: {
      id: true,
      email: true,
      role: true,
      isActive: true,
      isDemo: true,
      createdAt: true,
    },
    orderBy: { createdAt: 'desc' },
  });

  console.log(`Unverified final users found: ${users.length}`);
  for (const user of users) {
    console.log(JSON.stringify({
      id: user.id,
      email: maskEmail(user.email),
      role: user.role,
      isActive: user.isActive,
      isDemo: user.isDemo,
      createdAt: user.createdAt,
    }));
  }
}

main()
  .catch((error) => {
    console.error(error.message);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
