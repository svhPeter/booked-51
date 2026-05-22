import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';
import { PrismaClient } from '@prisma/client';

dotenv.config();

const prisma = new PrismaClient();

function required(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`${name} is required`);
  }
  return value;
}

async function main() {
  const email = required('ADMIN_EMAIL').toLowerCase();
  const password = required('ADMIN_PASSWORD');
  const name = process.env.ADMIN_NAME?.trim() || 'Production Admin';
  const phone = process.env.ADMIN_PHONE?.trim() || null;

  if (password.length < 12) {
    throw new Error('ADMIN_PASSWORD must be at least 12 characters');
  }
  if (password === 'password123') {
    throw new Error('ADMIN_PASSWORD cannot be the demo seed password');
  }

  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing && existing.role !== 'admin') {
    throw new Error('Refusing to promote an existing non-admin user. Use a dedicated admin email.');
  }

  const hashedPassword = await bcrypt.hash(password, 12);
  const user = existing
    ? await prisma.user.update({
        where: { email },
        data: {
          name,
          phone,
          password: hashedPassword,
          role: 'admin',
          isVerified: true,
          isActive: true,
          isDemo: false,
        },
      })
    : await prisma.user.create({
        data: {
          name,
          email,
          phone,
          password: hashedPassword,
          role: 'admin',
          isVerified: true,
          isActive: true,
          isDemo: false,
        },
      });

  await prisma.admin.upsert({
    where: { userId: user.id },
    update: {},
    create: { userId: user.id },
  });

  console.log(`Production admin ready: ${user.email}`);
}

main()
  .catch((error) => {
    console.error(error.message);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
