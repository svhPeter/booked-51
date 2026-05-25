import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  if (process.env.ALLOW_QA_RESET !== 'true') {
    console.error('SAFETY GUARD: Set ALLOW_QA_RESET=true to run destructive QA seed.');
    console.error('This will DELETE existing demo data and reseed.');
    process.exit(1);
  }

  console.log('=== QA RESET SEED ===');
  console.log('Deleting existing demo data...');

  await prisma.appointment.deleteMany({ where: { isDemo: true } });
  await prisma.payment.deleteMany({ where: { isDemo: true } });
  await prisma.review.deleteMany({ where: { isDemo: true } });
  await prisma.notification.deleteMany({ where: { isDemo: true } });
  await prisma.chatMessage.deleteMany({ where: { isDemo: true } });
  await prisma.conversation.deleteMany({ where: { isDemo: true } });
  await prisma.doctor.deleteMany({ where: { user: { isDemo: true } } });
  await prisma.patient.deleteMany({ where: { user: { isDemo: true } } });
  await prisma.admin.deleteMany({ where: { user: { isDemo: true } } });

  const demoUsers = await prisma.user.findMany({ where: { isDemo: true } });
  for (const u of demoUsers) {
    await prisma.session.deleteMany({ where: { userId: u.id } });
    await prisma.user.delete({ where: { id: u.id } });
  }

  console.log('Demo data cleared.');
  console.log('Seeding fresh QA data...\n');

  const hashedPassword = await bcrypt.hash('password123', 12);

  const admin = await prisma.user.upsert({
    where: { email: 'admin@docbook.com' },
    update: { isDemo: true, isVerified: true },
    create: {
      name: 'Admin User',
      email: 'admin@docbook.com',
      phone: '03000000000',
      password: hashedPassword,
      role: 'admin',
      isVerified: true,
      isDemo: true,
      admin: { create: {} },
    },
  });
  console.log('Admin:', admin.email);

  const hospital1 = await prisma.hospital.upsert({
    where: { id: 'hospital-1' },
    update: {},
    create: {
      id: 'hospital-1',
      name: 'City General Hospital',
      address: '123 Main Boulevard, Gulberg',
      city: 'Lahore',
      latitude: 31.5204,
      longitude: 74.3587,
      phone: '042-111-222-333',
    },
  });

  const hospital2 = await prisma.hospital.upsert({
    where: { id: 'hospital-2' },
    update: {},
    create: {
      id: 'hospital-2',
      name: 'Shifa International',
      address: '456 Park Road, F-8',
      city: 'Islamabad',
      latitude: 33.6938,
      longitude: 73.0653,
      phone: '051-444-555-666',
    },
  });

  const doctors = [
    {
      id: 'doctor-1', name: 'Ahmed Khan', email: 'ahmed.khan@docbook.com',
      specialty: 'Cardiologist', qualification: 'MBBS, FCPS (Cardiology) - King Edward Medical University',
      bio: 'Experienced cardiologist with 15+ years of practice. Specializing in preventive cardiology, heart failure management, and interventional procedures.',
      fee: 2500, experience: 15, hospitalId: 'hospital-1',
      days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    },
    {
      id: 'doctor-2', name: 'Fatima Ali', email: 'fatima.ali@docbook.com',
      specialty: 'Dermatologist', qualification: 'MBBS, FCPS (Dermatology) - Aga Khan University',
      bio: 'Board-certified dermatologist specializing in medical and cosmetic dermatology, skin cancer screening, and laser treatments.',
      fee: 2000, experience: 10, hospitalId: 'hospital-1',
      days: ['Mon', 'Wed', 'Fri', 'Sat'],
    },
    {
      id: 'doctor-3', name: 'Usman Malik', email: 'usman.malik@docbook.com',
      specialty: 'Pediatrician', qualification: 'MBBS, MCPS (Pediatrics) - Children Hospital Lahore',
      bio: 'Dedicated to providing comprehensive care for children from infancy through adolescence. Special interest in childhood nutrition and development.',
      fee: 1800, experience: 12, hospitalId: 'hospital-2',
      days: ['Tue', 'Thu', 'Sat', 'Sun'],
    },
    {
      id: 'doctor-4', name: 'Zara Hassan', email: 'zara.hassan@docbook.com',
      specialty: 'Neurologist', qualification: 'MBBS, FCPS (Neurology) - Jinnah Postgraduate Medical Centre',
      bio: 'Specialist in neurological disorders including migraines, epilepsy, stroke, and movement disorders.',
      fee: 3000, experience: 14, hospitalId: 'hospital-2',
      days: ['Mon', 'Tue', 'Wed', 'Thu'],
    },
    {
      id: 'doctor-5', name: 'Bilal Ahmed', email: 'bilal.ahmed@docbook.com',
      specialty: 'Orthopedic Surgeon', qualification: 'MBBS, FRCS (Orthopedics) - Royal College of Surgeons',
      bio: 'Orthopedic surgeon with expertise in joint replacement, sports injuries, and trauma surgery.',
      fee: 3500, experience: 18, hospitalId: 'hospital-1',
      days: ['Mon', 'Tue', 'Thu', 'Fri'],
    },
    {
      id: 'doctor-6', name: 'Sana Tariq', email: 'sana.tariq@docbook.com',
      specialty: 'Gynecologist', qualification: 'MBBS, FCPS (Obstetrics & Gynecology) - Lady Hardinge Medical College',
      bio: 'Compassionate gynecologist specializing in women\'s health, antenatal care, family planning, and minimally invasive gynecological surgery.',
      fee: 3000, experience: 11, hospitalId: 'hospital-2',
      days: ['Mon', 'Tue', 'Wed', 'Fri', 'Sat'],
    },
    {
      id: 'doctor-7', name: 'Imran Sheikh', email: 'imran.sheikh@docbook.com',
      specialty: 'General Physician', qualification: 'MBBS, MCPS (Internal Medicine) - Jinnah Hospital Lahore',
      bio: 'Experienced general physician providing comprehensive primary care, management of chronic diseases, and preventive health checkups.',
      fee: 1500, experience: 8, hospitalId: 'hospital-1',
      days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    },
  ];

  for (const doc of doctors) {
    await prisma.user.upsert({
      where: { email: doc.email },
      update: { isDemo: true, isVerified: true, doctor: { update: { isApproved: true } } },
      create: {
        id: doc.id,
        name: doc.name,
        email: doc.email,
        phone: `0300${Math.floor(10000000 + Math.random() * 90000000)}`,
        password: hashedPassword,
        role: 'doctor',
        isVerified: true,
        isDemo: true,
        doctor: {
          create: {
            specialty: doc.specialty,
            qualification: doc.qualification,
            bio: doc.bio,
            consultationFee: doc.fee,
            yearsOfExperience: doc.experience,
            averageRating: +(3.5 + Math.random() * 1.5).toFixed(1),
            totalReviews: Math.floor(20 + Math.random() * 80),
            availableDays: doc.days,
            isAvailable: true,
            isApproved: true,
            hospitalId: doc.hospitalId,
          },
        },
      },
    });
    console.log(`Doctor: ${doc.name} (${doc.specialty})`);
  }

  await prisma.user.upsert({
    where: { email: 'patient@test.com' },
    update: { isDemo: true, isVerified: true },
    create: {
      name: 'Test Patient',
      email: 'patient@test.com',
      phone: '03001112233',
      password: hashedPassword,
      role: 'patient',
      isVerified: true,
      isDemo: true,
      patient: { create: { dob: new Date('1995-06-15'), gender: 'female', bloodGroup: 'B+' } },
    },
  });
  console.log('Patient: patient@test.com / password123');

  console.log('\n=== QA seed complete ===');
  console.log('Login credentials (all use password123):');
  console.log('  Admin:    admin@docbook.com');
  console.log('  Patient:  patient@test.com');
  console.log('  Doctors:  [firstname].[lastname]@docbook.com (e.g., ahmed.khan@docbook.com)');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
