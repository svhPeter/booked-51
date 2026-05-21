import { prisma } from '../config/database';
import { AppError } from '../middleware/errorHandler';

export class AdminService {
  async getDashboardSummary() {
    const doctorsCount = await prisma.user.count({ where: { role: 'doctor' } });
    const patientsCount = await prisma.user.count({ where: { role: 'patient' } });

    const totalAppointments = await prisma.appointment.count();
    const completedAppointments = await prisma.appointment.count({ where: { status: 'completed' } });
    const cancelledAppointments = await prisma.appointment.count({ where: { status: 'cancelled' } });

    const paidPayments = await prisma.payment.count({ where: { status: 'paid' } });
    const pendingPayments = await prisma.payment.count({ where: { status: 'pending' } });

    const paidPaymentsData = await prisma.payment.findMany({
      where: { status: 'paid' },
      select: { amount: true },
    });
    const totalRevenue = paidPaymentsData.reduce((sum, p) => sum + p.amount, 0);

    return {
      totalDoctors: doctorsCount,
      totalPatients: patientsCount,
      totalAppointments,
      completedAppointments,
      cancelledAppointments,
      paidPaymentsCount: paidPayments,
      pendingPaymentsCount: pendingPayments,
      totalRevenue,
    };
  }

  async listDoctors() {
    const doctors = await prisma.user.findMany({
      where: { role: 'doctor' },
      include: {
        doctor: {
          include: {
            hospital: { select: { name: true, city: true } },
          },
        },
      },
      orderBy: { name: 'asc' },
    });
    return doctors.map((u) => ({
      id: u.id,
      name: u.name,
      email: u.email,
      phone: u.phone ?? '',
      avatarUrl: u.avatarUrl,
      isActive: u.isActive,
      isVerified: u.isVerified,
      isApproved: u.doctor?.isApproved ?? false,
      createdAt: u.createdAt,
      specialty: u.doctor?.specialty ?? '',
      qualification: u.doctor?.qualification ?? '',
      experience: u.doctor?.experience ?? '',
      consultationFee: u.doctor?.consultationFee ?? 0,
      yearsOfExperience: u.doctor?.yearsOfExperience ?? 0,
      averageRating: u.doctor?.averageRating ?? 0,
      totalReviews: u.doctor?.totalReviews ?? 0,
      availableDays: u.doctor?.availableDays ?? [],
      hospitalName: u.doctor?.hospital?.name ?? '',
      hospitalCity: u.doctor?.hospital?.city ?? '',
    }));
  }

  async getDoctorById(doctorId: string) {
    const u = await prisma.user.findFirst({
      where: { id: doctorId, role: 'doctor' },
      include: {
        doctor: {
          include: {
            hospital: true,
          },
        },
      },
    });
    if (!u) throw new AppError('Doctor not found', 404);
    return {
      id: u.id,
      name: u.name,
      email: u.email,
      phone: u.phone ?? '',
      avatarUrl: u.avatarUrl,
      isActive: u.isActive,
      isVerified: u.isVerified,
      isApproved: u.doctor?.isApproved ?? false,
      bio: u.doctor?.bio ?? '',
      specialty: u.doctor?.specialty ?? '',
      qualification: u.doctor?.qualification ?? '',
      experience: u.doctor?.experience ?? '',
      consultationFee: u.doctor?.consultationFee ?? 0,
      yearsOfExperience: u.doctor?.yearsOfExperience ?? 0,
      averageRating: u.doctor?.averageRating ?? 0,
      totalReviews: u.doctor?.totalReviews ?? 0,
      availableDays: u.doctor?.availableDays ?? [],
      hospital: u.doctor?.hospital ?? null,
      createdAt: u.createdAt,
    };
  }

  async listPatients() {
    const patients = await prisma.user.findMany({
      where: { role: 'patient' },
      include: {
        patient: true,
      },
      orderBy: { name: 'asc' },
    });
    return patients.map((u) => ({
      id: u.id,
      name: u.name,
      email: u.email,
      phone: u.phone ?? '',
      avatarUrl: u.avatarUrl,
      isActive: u.isActive,
      isVerified: u.isVerified,
      createdAt: u.createdAt,
      dob: u.patient?.dob ?? null,
      gender: u.patient?.gender ?? '',
      bloodGroup: u.patient?.bloodGroup ?? '',
    }));
  }

  async getPatientById(patientId: string) {
    const u = await prisma.user.findFirst({
      where: { id: patientId, role: 'patient' },
      include: { patient: true },
    });
    if (!u) throw new AppError('Patient not found', 404);
    return {
      id: u.id,
      name: u.name,
      email: u.email,
      phone: u.phone ?? '',
      avatarUrl: u.avatarUrl,
      isActive: u.isActive,
      isVerified: u.isVerified,
      dob: u.patient?.dob ?? null,
      gender: u.patient?.gender ?? '',
      bloodGroup: u.patient?.bloodGroup ?? '',
      address: u.patient?.address ?? '',
      city: u.patient?.city ?? '',
      createdAt: u.createdAt,
    };
  }

  async listAppointments(filters?: { status?: string; doctorId?: string; dateFrom?: string; dateTo?: string }) {
    const where: any = {};
    if (filters?.status) where.status = filters.status;
    if (filters?.doctorId) where.doctorId = filters.doctorId;
    if (filters?.dateFrom || filters?.dateTo) {
      where.date = {};
      if (filters.dateFrom) where.date.gte = new Date(filters.dateFrom);
      if (filters.dateTo) where.date.lte = new Date(filters.dateTo);
    }

    const rows = await prisma.appointment.findMany({
      where,
      include: {
        patient: { select: { name: true, email: true, phone: true } },
        doctor: { select: { name: true, email: true } },
        hospital: { select: { name: true } },
        payment: { select: { id: true, amount: true, currency: true, provider: true, status: true, createdAt: true } },
      },
      orderBy: { date: 'desc' },
    });
    return rows.map((a) => ({
      id: a.id,
      patientId: a.patientId,
      doctorId: a.doctorId,
      date: a.date,
      timeSlot: a.timeSlot,
      status: a.status,
      meetingLink: a.meetingLink,
      notes: a.notes,
      createdAt: a.createdAt,
      updatedAt: a.updatedAt,
      patientName: a.patient?.name ?? '',
      patientEmail: a.patient?.email ?? '',
      patientPhone: a.patient?.phone ?? '',
      doctorName: a.doctor?.name ?? '',
      doctorEmail: a.doctor?.email ?? '',
      hospitalName: a.hospital?.name ?? '',
      payment: a.payment
        ? {
            id: a.payment.id,
            amount: a.payment.amount,
            currency: a.payment.currency,
            provider: a.payment.provider,
            status: a.payment.status,
            createdAt: a.payment.createdAt,
          }
        : null,
    }));
  }

  async getAppointmentById(appointmentId: string) {
    const row = await prisma.appointment.findUnique({
      where: { id: appointmentId },
      include: {
        patient: { select: { name: true, email: true, phone: true, avatarUrl: true } },
        doctor: { select: { name: true, email: true } },
        hospital: true,
        payment: true,
      },
    });
    if (!row) throw new AppError('Appointment not found', 404);
    return {
      id: row.id,
      patientId: row.patientId,
      doctorId: row.doctorId,
      date: row.date,
      timeSlot: row.timeSlot,
      status: row.status,
      meetingLink: row.meetingLink,
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      patientName: row.patient?.name ?? '',
      patientEmail: row.patient?.email ?? '',
      patientPhone: row.patient?.phone ?? '',
      doctorName: row.doctor?.name ?? '',
      doctorEmail: row.doctor?.email ?? '',
      hospital: row.hospital ?? null,
      payment: row.payment ?? null,
    };
  }

  async listPayments(filters?: { status?: string; provider?: string }) {
    const where: any = {};
    if (filters?.status) where.status = filters.status;
    if (filters?.provider) where.provider = filters.provider;

    const rows = await prisma.payment.findMany({
      where,
      include: {
        appointment: {
          select: { date: true, timeSlot: true, status: true },
        },
        user: { select: { name: true, email: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((p) => ({
      id: p.id,
      appointmentId: p.appointmentId,
      userId: p.userId,
      amount: p.amount,
      currency: p.currency,
      provider: p.provider,
      providerTxnId: p.providerTxnId,
      status: p.status,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
      userName: p.user?.name ?? '',
      userEmail: p.user?.email ?? '',
      appointmentDate: p.appointment?.date ?? null,
      appointmentTimeSlot: p.appointment?.timeSlot ?? '',
      appointmentStatus: p.appointment?.status ?? '',
    }));
  }

  async approveDoctor(doctorUserId: string) {
    const user = await prisma.user.findFirst({
      where: { id: doctorUserId, role: 'doctor' },
      include: { doctor: true },
    });
    if (!user?.doctor) throw new AppError('Doctor not found', 404);
    await prisma.doctor.update({
      where: { userId: doctorUserId },
      data: { isApproved: true, isAvailable: true },
    });
    return { id: doctorUserId, isApproved: true };
  }

  async rejectDoctor(doctorUserId: string) {
    const user = await prisma.user.findFirst({
      where: { id: doctorUserId, role: 'doctor' },
      include: { doctor: true },
    });
    if (!user?.doctor) throw new AppError('Doctor not found', 404);
    await prisma.doctor.update({
      where: { userId: doctorUserId },
      data: { isApproved: false },
    });
    return { id: doctorUserId, isApproved: false };
  }

  async setDoctorActive(doctorUserId: string, isActive: boolean) {
    const user = await prisma.user.findFirst({
      where: { id: doctorUserId, role: 'doctor' },
    });
    if (!user) throw new AppError('Doctor not found', 404);
    await prisma.user.update({
      where: { id: doctorUserId },
      data: { isActive },
    });
    return { id: doctorUserId, isActive };
  }
}
