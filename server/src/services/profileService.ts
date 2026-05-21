import { prisma } from '../config/database';
import { AppError } from '../middleware/errorHandler';

export class ProfileService {
  async getPatientProfile(userId: string) {
    const user = await prisma.user.findFirst({
      where: { id: userId, role: 'patient' },
      include: { patient: true },
    });
    if (!user) throw new AppError('Patient not found', 404);
    return {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      avatarUrl: user.avatarUrl,
      dob: user.patient?.dob,
      gender: user.patient?.gender,
      bloodGroup: user.patient?.bloodGroup,
      address: user.patient?.address,
      city: user.patient?.city,
    };
  }

  async updatePatientProfile(
    userId: string,
    data: {
      name?: string;
      phone?: string;
      avatarUrl?: string;
      dob?: string;
      gender?: string;
      bloodGroup?: string;
      address?: string;
      city?: string;
    },
  ) {
    const user = await prisma.user.findFirst({
      where: { id: userId, role: 'patient' },
      include: { patient: true },
    });
    if (!user) throw new AppError('Patient not found', 404);

    await prisma.user.update({
      where: { id: userId },
      data: {
        name: data.name,
        phone: data.phone,
        avatarUrl: data.avatarUrl,
      },
    });

    if (user.patient) {
      await prisma.patient.update({
        where: { userId },
        data: {
          dob: data.dob ? new Date(data.dob) : undefined,
          gender: data.gender,
          bloodGroup: data.bloodGroup,
          address: data.address,
          city: data.city,
        },
      });
    }

    return this.getPatientProfile(userId);
  }

  async getDoctorProfile(userId: string) {
    const user = await prisma.user.findFirst({
      where: { id: userId, role: 'doctor' },
      include: {
        doctor: {
          include: { hospital: { select: { id: true, name: true, city: true, address: true } } },
        },
      },
    });
    if (!user?.doctor) throw new AppError('Doctor not found', 404);
    return {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      avatarUrl: user.avatarUrl,
      isApproved: user.doctor.isApproved,
      specialty: user.doctor.specialty,
      qualification: user.doctor.qualification,
      experience: user.doctor.experience,
      bio: user.doctor.bio,
      consultationFee: user.doctor.consultationFee,
      yearsOfExperience: user.doctor.yearsOfExperience,
      availableDays: user.doctor.availableDays,
      isAvailable: user.doctor.isAvailable,
      hospitalId: user.doctor.hospitalId,
      hospital: user.doctor.hospital,
    };
  }

  async updateDoctorProfile(
    userId: string,
    data: {
      name?: string;
      phone?: string;
      avatarUrl?: string;
      specialty?: string;
      qualification?: string;
      experience?: string;
      bio?: string;
      consultationFee?: number;
      yearsOfExperience?: number;
      availableDays?: string[];
      isAvailable?: boolean;
      hospitalId?: string | null;
    },
  ) {
    const user = await prisma.user.findFirst({
      where: { id: userId, role: 'doctor' },
      include: { doctor: true },
    });
    if (!user?.doctor) throw new AppError('Doctor not found', 404);

    await prisma.user.update({
      where: { id: userId },
      data: {
        name: data.name,
        phone: data.phone,
        avatarUrl: data.avatarUrl,
      },
    });

    await prisma.doctor.update({
      where: { userId },
      data: {
        specialty: data.specialty,
        qualification: data.qualification,
        experience: data.experience,
        bio: data.bio,
        consultationFee: data.consultationFee,
        yearsOfExperience: data.yearsOfExperience,
        availableDays: data.availableDays,
        isAvailable: data.isAvailable,
        hospitalId: data.hospitalId,
      },
    });

    return this.getDoctorProfile(userId);
  }
}
