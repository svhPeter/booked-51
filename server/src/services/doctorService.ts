import { prisma } from '../config/database';
import { AppError } from '../middleware/errorHandler';

export class DoctorService {
  async getAll(filters?: {
    specialty?: string;
    search?: string;
    page?: number;
    limit?: number;
  }) {
    const page = filters?.page || 1;
    const limit = filters?.limit || 20;
    const skip = (page - 1) * limit;

    const where: any = {
      role: 'doctor',
      isActive: true,
      doctor: { isApproved: true },
    };

    if (filters?.specialty) {
      where.doctor.specialty = {
        contains: filters.specialty,
        mode: 'insensitive',
      };
    }

    if (filters?.search) {
      where.OR = [
        { name: { contains: filters.search, mode: 'insensitive' } },
        { doctor: { specialty: { contains: filters.search, mode: 'insensitive' } } },
      ];
    }

    const [doctors, total] = await Promise.all([
      prisma.user.findMany({
        where,
        select: {
          id: true,
          name: true,
          email: true,
          phone: true,
          avatarUrl: true,
          doctor: {
            select: {
              specialty: true,
              qualification: true,
              experience: true,
              bio: true,
              consultationFee: true,
              yearsOfExperience: true,
              averageRating: true,
              totalReviews: true,
              hospital: {
                select: {
                  name: true,
                  address: true,
                  latitude: true,
                  longitude: true,
                },
              },
              availableDays: true,
              isAvailable: true,
            },
          },
        },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      prisma.user.count({ where }),
    ]);

    const mappedDoctors = doctors.map((doc) => ({
      id: doc.id,
      name: doc.name,
      email: doc.email,
      phone: doc.phone,
      avatarUrl: doc.avatarUrl,
      specialty: doc.doctor?.specialty || 'General',
      qualification: doc.doctor?.qualification,
      experience: doc.doctor?.experience,
      bio: doc.doctor?.bio,
      consultationFee: doc.doctor?.consultationFee || 0,
      yearsOfExperience: doc.doctor?.yearsOfExperience || 0,
      averageRating: doc.doctor?.averageRating || 0,
      totalReviews: doc.doctor?.totalReviews || 0,
      hospitalName: doc.doctor?.hospital?.name,
      hospitalAddress: doc.doctor?.hospital?.address,
      latitude: doc.doctor?.hospital?.latitude,
      longitude: doc.doctor?.hospital?.longitude,
      availableDays: doc.doctor?.availableDays || [],
      isAvailable: doc.doctor?.isAvailable ?? true,
    }));

    return {
      doctors: mappedDoctors,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getById(id: string) {
    const doc = await prisma.user.findFirst({
      where: { id, role: 'doctor', isActive: true, doctor: { isApproved: true } },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        avatarUrl: true,
        doctor: {
          select: {
            specialty: true,
            qualification: true,
            experience: true,
            bio: true,
            consultationFee: true,
            yearsOfExperience: true,
            averageRating: true,
            totalReviews: true,
            availableDays: true,
            isAvailable: true,
            hospital: {
              select: {
                id: true,
                name: true,
                address: true,
                latitude: true,
                longitude: true,
              },
            },
          },
        },
      },
    });

    if (!doc) {
      throw new AppError('Doctor not found', 404);
    }

    return {
      id: doc.id,
      name: doc.name,
      email: doc.email,
      phone: doc.phone,
      avatarUrl: doc.avatarUrl,
      specialty: doc.doctor?.specialty || 'General',
      qualification: doc.doctor?.qualification,
      experience: doc.doctor?.experience,
      bio: doc.doctor?.bio,
      consultationFee: doc.doctor?.consultationFee || 0,
      yearsOfExperience: doc.doctor?.yearsOfExperience || 0,
      averageRating: doc.doctor?.averageRating || 0,
      totalReviews: doc.doctor?.totalReviews || 0,
      hospitalName: doc.doctor?.hospital?.name,
      hospitalAddress: doc.doctor?.hospital?.address,
      latitude: doc.doctor?.hospital?.latitude,
      longitude: doc.doctor?.hospital?.longitude,
      availableDays: doc.doctor?.availableDays || [],
      isAvailable: doc.doctor?.isAvailable ?? true,
    };
  }

  async getAvailableSlots(doctorId: string, date: string) {
    const doctor = await prisma.doctor.findUnique({
      where: { userId: doctorId },
      select: { availableDays: true },
    });

    if (!doctor) {
      throw new AppError('Doctor not found', 404);
    }

    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const dateObj = new Date(date);
    const dayName = dayNames[dateObj.getDay()];

    if (!doctor.availableDays.includes(dayName)) {
      return { slots: [] };
    }

    // Generate slots (9 AM - 5 PM, 30 min intervals)
    const allSlots = this.generateTimeSlots();

    const bookedSlots = await prisma.appointment.findMany({
      where: {
        doctorId,
        date: dateObj,
        status: { in: ['pending', 'confirmed'] },
      },
      select: { timeSlot: true },
    });

    const bookedTimes = bookedSlots.map((b) => b.timeSlot);
    const available = allSlots.filter((slot) => !bookedTimes.includes(slot));

    return { slots: available };
  }

  async getSpecialties() {
    const specialties = await prisma.doctor.findMany({
      select: { specialty: true },
      distinct: ['specialty'],
      where: { specialty: { not: null } },
    });

    return [...new Set(specialties.map((s) => s.specialty).filter(Boolean))];
  }

  private generateTimeSlots(): string[] {
    const slots: string[] = [];
    for (let hour = 9; hour < 17; hour++) {
      slots.push(`${hour.toString().padStart(2, '0')}:00`);
      slots.push(`${hour.toString().padStart(2, '0')}:30`);
    }
    return slots;
  }
}
