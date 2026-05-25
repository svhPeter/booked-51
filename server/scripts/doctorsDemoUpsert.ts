import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

interface DoctorSeed {
  email: string;
  name: string;
  specialty: string;
  qualification: string;
  bio: string;
  fee: number;
  experience: number;
  pmdc: string;
  days: string[];
  hospitalId: string;
}

const hospitals = [
  { id: 'h-karachi-1', name: 'Aga Khan University Hospital', address: 'Stadium Road', city: 'Karachi', phone: '021-111-911-911' },
  { id: 'h-karachi-2', name: 'Liaquat National Hospital', address: 'National Stadium Road', city: 'Karachi', phone: '021-344-122-22' },
  { id: 'h-lahore-1', name: 'Shaukat Khanum Memorial', address: 'Johar Town', city: 'Lahore', phone: '042-359-050-00' },
  { id: 'h-lahore-2', name: 'Hameed Latif Hospital', address: '72-A, Gulberg III', city: 'Lahore', phone: '042-111-110-110' },
  { id: 'h-islamabad-1', name: 'Shifa International Hospital', address: 'H-8/4', city: 'Islamabad', phone: '051-846-400-0' },
  { id: 'h-islamabad-2', name: 'Ali Medical Centre', address: 'F-8 Markaz', city: 'Islamabad', phone: '051-111-444-555' },
  { id: 'h-rawalpindi-1', name: 'Rawalpindi Medical College', address: 'Tipu Road', city: 'Rawalpindi', phone: '051-933-000-0' },
  { id: 'h-faisalabad-1', name: 'Allied Hospital Faisalabad', address: 'Jail Road', city: 'Faisalabad', phone: '041-921-010-0' },
];

const doctors: DoctorSeed[] = [
  {
    email: 'sana.tariq@docbook.com', name: 'Dr. Sana Tariq',
    specialty: 'Gynecologist', qualification: 'MBBS, FCPS (Obstetrics & Gynecology) - College of Physicians & Surgeons Pakistan',
    bio: 'Consultant gynecologist specializing in high-risk pregnancies, minimally invasive laparoscopic surgery, and adolescent gynecology. Dedicated to compassionate women\'s healthcare across all ages.',
    fee: 3000, experience: 14, pmdc: '56789-P',
    days: ['Mon', 'Tue', 'Wed', 'Fri', 'Sat'],
    hospitalId: 'h-lahore-1',
  },
  {
    email: 'maryam.ikram@docbook.com', name: 'Dr. Maryam Ikram',
    specialty: 'Gynecologist', qualification: 'MBBS, MCPS (Obstetrics & Gynecology) - Dow University of Health Sciences',
    bio: 'Specialist in reproductive health, family planning, and prenatal care. Provides comprehensive well-woman exams and menopause management with a patient-first approach.',
    fee: 2500, experience: 10, pmdc: '54321-P',
    days: ['Mon', 'Tue', 'Wed', 'Thu', 'Sat'],
    hospitalId: 'h-karachi-1',
  },
  {
    email: 'imran.sheikh@docbook.com', name: 'Dr. Imran Sheikh',
    specialty: 'General Physician', qualification: 'MBBS, MCPS (Internal Medicine) - Jinnah Postgraduate Medical Centre',
    bio: 'Experienced general physician providing comprehensive primary care, chronic disease management (diabetes, hypertension), preventive health checkups, and acute illness management.',
    fee: 1500, experience: 9, pmdc: '61234-P',
    days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    hospitalId: 'h-islamabad-1',
  },
  {
    email: 'fatima.ali@docbook.com', name: 'Dr. Fatima Ali',
    specialty: 'Dermatologist', qualification: 'MBBS, FCPS (Dermatology) - Aga Khan University Hospital',
    bio: 'Board-certified dermatologist specializing in medical dermatology, skin cancer screening, laser treatments, and cosmetic dermatology. Focused on evidence-based skin health.',
    fee: 2000, experience: 12, pmdc: '59876-P',
    days: ['Mon', 'Wed', 'Fri', 'Sat'],
    hospitalId: 'h-karachi-2',
  },
  {
    email: 'ahmed.khan@docbook.com', name: 'Dr. Ahmed Khan',
    specialty: 'Cardiologist', qualification: 'MBBS, FCPS (Cardiology) - King Edward Medical University',
    bio: 'Senior cardiologist with expertise in preventive cardiology, heart failure management, interventional procedures, and cardiac rehabilitation. Fellow of the Pakistan Cardiac Society.',
    fee: 3500, experience: 18, pmdc: '45678-P',
    days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    hospitalId: 'h-lahore-2',
  },
  {
    email: 'usman.malik@docbook.com', name: 'Dr. Usman Malik',
    specialty: 'Pediatrician', qualification: 'MBBS, MCPS (Pediatrics) - The Children\'s Hospital Lahore',
    bio: 'Dedicated pediatrician providing comprehensive care from infancy through adolescence. Special interests in childhood nutrition, developmental screening, and adolescent health.',
    fee: 2000, experience: 13, pmdc: '52345-P',
    days: ['Tue', 'Thu', 'Sat', 'Sun'],
    hospitalId: 'h-rawalpindi-1',
  },
  {
    email: 'zara.hassan@docbook.com', name: 'Dr. Zara Hassan',
    specialty: 'Neurologist', qualification: 'MBBS, FCPS (Neurology) - Jinnah Postgraduate Medical Centre',
    bio: 'Specialist in neurological disorders including migraine management, epilepsy, stroke, multiple sclerosis, and movement disorders. Committed to evidence-based neurological care.',
    fee: 3000, experience: 15, pmdc: '53456-P',
    days: ['Mon', 'Tue', 'Wed', 'Thu'],
    hospitalId: 'h-islamabad-2',
  },
  {
    email: 'farhan.raza@docbook.com', name: 'Dr. Farhan Raza',
    specialty: 'Psychiatrist', qualification: 'MBBS, FCPS (Psychiatry) - Institute of Psychiatry Rawalpindi',
    bio: 'Consultant psychiatrist specializing in anxiety disorders, depression, bipolar disorder, OCD, and addiction psychiatry. Provides compassionate mental health care with a holistic approach.',
    fee: 2800, experience: 11, pmdc: '57890-P',
    days: ['Mon', 'Tue', 'Thu', 'Fri'],
    hospitalId: 'h-rawalpindi-1',
  },
  {
    email: 'asim.hussain@docbook.com', name: 'Dr. Asim Hussain',
    specialty: 'ENT Specialist', qualification: 'MBBS, FCPS (Otorhinolaryngology) - Dow Medical College',
    bio: 'Experienced ENT surgeon specializing in sinus surgery, hearing disorders, thyroid conditions, and head & neck procedures. Provides complete ear, nose, and throat care.',
    fee: 2200, experience: 14, pmdc: '58765-P',
    days: ['Mon', 'Wed', 'Fri'],
    hospitalId: 'h-faisalabad-1',
  },
  {
    email: 'bilal.ahmed@docbook.com', name: 'Dr. Bilal Ahmed',
    specialty: 'Orthopedic Surgeon', qualification: 'MBBS, FRCS (Orthopedics) - Royal College of Surgeons, Edinburgh',
    bio: 'Orthopedic surgeon with expertise in joint replacement (hip & knee), sports medicine, arthroscopy, and trauma surgery. Fellowship-trained in minimally invasive orthopedic procedures.',
    fee: 4000, experience: 19, pmdc: '44567-P',
    days: ['Mon', 'Tue', 'Thu', 'Fri'],
    hospitalId: 'h-lahore-1',
  },
  {
    email: 'hira.shah@docbook.com', name: 'Dr. Hira Shah',
    specialty: 'Nutritionist', qualification: 'MSc Clinical Nutrition, RD - University of Karachi',
    bio: 'Registered clinical nutritionist specializing in therapeutic diets for diabetes, cardiovascular health, weight management, and eating disorders. Evidence-based nutritional counseling.',
    fee: 1500, experience: 7, pmdc: '61235-N',
    days: ['Mon', 'Tue', 'Wed', 'Thu', 'Sat'],
    hospitalId: 'h-karachi-1',
  },
];

async function main() {
  const mode = process.argv[2] || 'upsert';

  if (mode === 'report') {
    console.log('=== DEMO DOCTORS REPORT ===\n');
    for (const doc of doctors) {
      const existing = await prisma.user.findUnique({ where: { email: doc.email }, include: { doctor: true } });
      if (existing) {
        console.log(`EXISTS: ${doc.name} (${doc.email}) - ${existing.doctor ? `Doctor ID: ${existing.doctor.id}` : 'No doctor profile'}`);
      } else {
        console.log(`MISSING: ${doc.name} (${doc.email}) - will be created`);
      }
    }
    const existingDemoDoctors = await prisma.user.findMany({ where: { isDemo: true, role: 'doctor' }, include: { doctor: true } });
    console.log(`\nTotal demo doctor users in DB: ${existingDemoDoctors.length}`);
    console.log('=== REPORT END ===');
    return;
  }

  if (process.env.ALLOW_DEMO_DOCTOR_RESET !== 'true') {
    console.error('SAFETY GUARD: Set ALLOW_DEMO_DOCTOR_RESET=true to upsert demo doctors.');
    console.error('Usage: ALLOW_DEMO_DOCTOR_RESET=true npx tsx scripts/doctorsDemoUpsert.ts');
    console.error('       ALLOW_DEMO_DOCTOR_RESET=true npx tsx scripts/doctorsDemoUpsert.ts report');
    process.exit(1);
  }

  console.log('=== DEMO DOCTOR UPSERT ===');
  console.log('No patients will be deleted or modified.\n');

  const hashedPassword = await bcrypt.hash('password123', 12);

  for (const h of hospitals) {
    await prisma.hospital.upsert({
      where: { id: h.id },
      update: { name: h.name, address: h.address, city: h.city, phone: h.phone },
      create: { id: h.id, name: h.name, address: h.address, city: h.city, phone: h.phone },
    });
  }
  console.log(`Hospitals ready (${hospitals.length})`);

  for (const doc of doctors) {
    const existingUser = await prisma.user.findUnique({ where: { email: doc.email } });

    if (existingUser && !existingUser.isDemo) {
      console.warn(`SKIPPING ${doc.email}: real user exists (not demo). Cannot overwrite.`);
      continue;
    }

    await prisma.user.upsert({
      where: { email: doc.email },
      update: {
        name: doc.name,
        isDemo: true,
        isVerified: true,
        doctor: {
          upsert: {
            create: {
              specialty: doc.specialty,
              qualification: doc.qualification,
              bio: doc.bio,
              consultationFee: doc.fee,
              yearsOfExperience: doc.experience,
              pmdcRegistrationNumber: doc.pmdc,
              availableDays: doc.days,
              isAvailable: true,
              isApproved: true,
              hospitalId: doc.hospitalId,
              averageRating: 4.5,
              totalReviews: Math.floor(30 + Math.random() * 70),
            },
            update: {
              specialty: doc.specialty,
              qualification: doc.qualification,
              bio: doc.bio,
              consultationFee: doc.fee,
              yearsOfExperience: doc.experience,
              pmdcRegistrationNumber: doc.pmdc,
              availableDays: doc.days,
              isAvailable: true,
              isApproved: true,
              hospitalId: doc.hospitalId,
            },
          },
        },
      },
      create: {
        email: doc.email,
        name: doc.name,
        phone: `0300${String(10000000 + Math.floor(Math.random() * 80000000)).padStart(8, '0')}`,
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
            pmdcRegistrationNumber: doc.pmdc,
            availableDays: doc.days,
            isAvailable: true,
            isApproved: true,
            hospitalId: doc.hospitalId,
            averageRating: 4.5,
            totalReviews: Math.floor(30 + Math.random() * 70),
          },
        },
      },
    });

    const hospital = hospitals.find(h => h.id === doc.hospitalId);
    console.log(`${doc.name.padEnd(25)} ${doc.specialty.padEnd(20)} PKR ${doc.fee}  ${hospital?.city || ''}`);
  }

  const count = await prisma.user.count({ where: { isDemo: true, role: 'doctor' } });
  console.log(`\nTotal demo doctors in DB: ${count}`);
  console.log('=== DONE ===');
  console.log('Logins: [email] / password123');
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
