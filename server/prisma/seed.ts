import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database...');

  const hashedPassword = await bcrypt.hash('password123', 12);

  // Create admin
  const admin = await prisma.user.upsert({
    where: { email: 'admin@docbook.com' },
    update: {},
    create: {
      name: 'Admin User',
      email: 'admin@docbook.com',
      phone: '03000000000',
      password: hashedPassword,
      role: 'admin',
      isVerified: true,
      admin: { create: {} },
    },
  });
  console.log('Admin created:', admin.email);

  // Create hospitals
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
  console.log('Hospitals created');

  // Create doctors
  const doctors = [
    {
      id: 'doctor-1',
      name: 'Ahmed Khan',
      email: 'ahmed.khan@docbook.com',
      specialty: 'Cardiologist',
      qualification: 'MBBS, FCPS (Cardiology) - King Edward Medical University',
      bio: 'Experienced cardiologist with 15+ years of practice. Specializing in preventive cardiology, heart failure management, and interventional procedures.',
      fee: 2500,
      experience: 15,
      hospitalId: 'hospital-1',
      days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    },
    {
      id: 'doctor-2',
      name: 'Fatima Ali',
      email: 'fatima.ali@docbook.com',
      specialty: 'Dermatologist',
      qualification: 'MBBS, FCPS (Dermatology) - Aga Khan University',
      bio: 'Board-certified dermatologist specializing in medical and cosmetic dermatology, skin cancer screening, and laser treatments.',
      fee: 2000,
      experience: 10,
      hospitalId: 'hospital-1',
      days: ['Mon', 'Wed', 'Fri', 'Sat'],
    },
    {
      id: 'doctor-3',
      name: 'Usman Malik',
      email: 'usman.malik@docbook.com',
      specialty: 'Pediatrician',
      qualification: 'MBBS, MCPS (Pediatrics) - Children Hospital Lahore',
      bio: 'Dedicated to providing comprehensive care for children from infancy through adolescence. Special interest in childhood nutrition and development.',
      fee: 1800,
      experience: 12,
      hospitalId: 'hospital-2',
      days: ['Tue', 'Thu', 'Sat', 'Sun'],
    },
    {
      id: 'doctor-4',
      name: 'Zara Hassan',
      email: 'zara.hassan@docbook.com',
      specialty: 'Neurologist',
      qualification: 'MBBS, FCPS (Neurology) - Jinnah Postgraduate Medical Centre',
      bio: 'Specialist in neurological disorders including migraines, epilepsy, stroke, and movement disorders. Committed to evidence-based care.',
      fee: 3000,
      experience: 14,
      hospitalId: 'hospital-2',
      days: ['Mon', 'Tue', 'Wed', 'Thu'],
    },
    {
      id: 'doctor-5',
      name: 'Bilal Ahmed',
      email: 'bilal.ahmed@docbook.com',
      specialty: 'Orthopedic Surgeon',
      qualification: 'MBBS, FRCS (Orthopedics) - Royal College of Surgeons',
      bio: 'Orthopedic surgeon with expertise in joint replacement, sports injuries, and trauma surgery. Fellowship-trained in arthroscopic surgery.',
      fee: 3500,
      experience: 18,
      hospitalId: 'hospital-1',
      days: ['Mon', 'Tue', 'Thu', 'Fri'],
    },
  ];

  for (const doc of doctors) {
    const user = await prisma.user.upsert({
      where: { email: doc.email },
      update: {
        doctor: {
          update: { isApproved: true },
        },
      },
      create: {
        id: doc.id,
        name: doc.name,
        email: doc.email,
        phone: `0300${Math.floor(10000000 + Math.random() * 90000000)}`,
        password: hashedPassword,
        role: 'doctor',
        isVerified: true,
        avatarUrl: null,
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
    console.log(`Doctor created: ${doc.name} (${doc.specialty})`);
  }

  // Create a test patient
  await prisma.user.upsert({
    where: { email: 'patient@test.com' },
    update: {},
    create: {
      name: 'Test Patient',
      email: 'patient@test.com',
      phone: '03001112233',
      password: hashedPassword,
      role: 'patient',
      isVerified: true,
      patient: {
        create: {
          dob: new Date('1995-06-15'),
          gender: 'male',
          bloodGroup: 'B+',
        },
      },
    },
  });
  console.log('Test patient created: patient@test.com / password123');

  console.log('Seed completed!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
