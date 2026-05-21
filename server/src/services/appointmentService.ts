import { prisma } from '../config/database';
import { AppError } from '../middleware/errorHandler';
import { logger } from '../config/logger';
import { io } from '../index';
import { getPaymentProvider } from './paymentService';
import { createNotification } from './notificationService';

export class AppointmentService {
  async book(data: {
    patientId: string;
    doctorId: string;
    date: string;
    timeSlot: string;
    hospitalId?: string;
    paymentProvider?: string;
  }) {
    const doctor = await prisma.user.findFirst({
      where: {
        id: data.doctorId,
        role: 'doctor',
        isActive: true,
        doctor: { isApproved: true },
      },
      include: {
        doctor: {
          select: { availableDays: true, consultationFee: true },
        },
      },
    });

    if (!doctor) {
      throw new AppError('Doctor not found', 404);
    }

    const appointmentDate = new Date(data.date);
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const dayName = dayNames[appointmentDate.getDay()];
    const availableDays = doctor.doctor?.availableDays ?? [];

    if (!availableDays.includes(dayName)) {
      throw new AppError(`Doctor is not available on ${dayName}s`, 400);
    }

    this.validateTimeSlot(data.timeSlot);

    const existing = await prisma.appointment.findFirst({
      where: {
        doctorId: data.doctorId,
        date: appointmentDate,
        timeSlot: data.timeSlot,
        status: { in: ['pending', 'confirmed'] },
      },
    });

    if (existing) {
      throw new AppError('Time slot already booked', 409);
    }

    const appointment = await prisma.appointment.create({
      data: {
        patientId: data.patientId,
        doctorId: data.doctorId,
        date: appointmentDate,
        timeSlot: data.timeSlot,
        hospitalId: data.hospitalId,
        status: 'confirmed',
      },
      include: {
        patient: {
          select: { name: true, avatarUrl: true },
        },
        doctor: {
          include: {
            doctor: {
              select: { specialty: true, consultationFee: true },
            },
          },
        },
        hospital: {
          select: { name: true, address: true },
        },
      },
    });

    if (data.paymentProvider) {
      const fee = doctor.doctor?.consultationFee ?? 0;
      const provider = getPaymentProvider(data.paymentProvider);
      const result = await provider.createPayment(fee, 'PKR', {
        appointmentId: appointment.id,
        userId: data.patientId,
      });

      await prisma.payment.create({
        data: {
          appointmentId: appointment.id,
          userId: data.patientId,
          amount: fee,
          currency: 'PKR',
          provider: data.paymentProvider as any,
          providerTxnId: result.providerTxnId!,
          status: 'pending',
        },
      });
    }

    // Create notifications
    const doctorName = appointment.doctor?.name ?? 'Doctor';
    const patientName = appointment.patient?.name ?? 'Patient';
    createNotification({
      userId: data.doctorId,
      title: 'New Appointment',
      body: `New appointment booked with ${patientName} on ${appointmentDate.toLocaleDateString()} at ${data.timeSlot}`,
      type: 'appointment_booked',
      data: { appointmentId: appointment.id },
    }).catch(() => {});
    createNotification({
      userId: data.patientId,
      title: 'Appointment Confirmed',
      body: `Your appointment with ${doctorName} on ${appointmentDate.toLocaleDateString()} at ${data.timeSlot} has been confirmed`,
      type: 'appointment_booked',
      data: { appointmentId: appointment.id },
    }).catch(() => {});

    logger.info('appointment_booked', {
      appointmentId: appointment.id,
      patientId: data.patientId,
      doctorId: data.doctorId,
      date: data.date,
      timeSlot: data.timeSlot,
    });

    io.to(`user:${data.doctorId}`).emit('new-appointment', appointment);
    io.to(`user:${data.patientId}`).emit('appointment-booked', appointment);

    return this.mapPatientAppointment(appointment);
  }

  async getByIdForUser(appointmentId: string, userId: string, role: string) {
    const row = await prisma.appointment.findUnique({
      where: { id: appointmentId },
      include: {
        doctor: {
          include: {
            doctor: {
              select: { specialty: true, consultationFee: true },
            },
          },
        },
        patient: {
          select: { name: true, email: true, phone: true, avatarUrl: true },
        },
        hospital: {
          select: { name: true, address: true },
        },
      },
    });

    if (!row) {
      throw new AppError('Appointment not found', 404);
    }

    const isParticipant =
      row.patientId === userId || row.doctorId === userId || role === 'admin';

    if (!isParticipant) {
      throw new AppError('Not authorized to view this appointment', 403);
    }

    if (role === 'patient') {
      return this.mapPatientAppointment(row);
    }

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
      patientAvatar: row.patient?.avatarUrl,
      doctorName: row.doctor?.name ?? '',
      specialty: row.doctor?.doctor?.specialty ?? '',
      fee: row.doctor?.doctor?.consultationFee ?? 0,
      hospitalName: row.hospital?.name,
      hospitalAddress: row.hospital?.address,
    };
  }

  private mapPatientAppointment(a: {
    id: string;
    patientId: string;
    doctorId: string;
    date: Date;
    timeSlot: string;
    status: string;
    meetingLink: string | null;
    notes: string | null;
    createdAt: Date;
    updatedAt: Date;
    doctor?: {
      name: string;
      avatarUrl: string | null;
      doctor?: { specialty: string | null; consultationFee: number } | null;
    } | null;
    hospital?: { name: string | null; address: string | null } | null;
  }) {
    return {
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
      doctorName: a.doctor?.name ?? '',
      doctorAvatar: a.doctor?.avatarUrl,
      specialty: a.doctor?.doctor?.specialty ?? '',
      fee: a.doctor?.doctor?.consultationFee ?? 0,
      hospitalName: a.hospital?.name,
    };
  }

  async getPatientAppointments(patientId: string) {
    const rows = await prisma.appointment.findMany({
      where: { patientId },
      include: {
        doctor: {
          include: {
            doctor: {
              select: { specialty: true, consultationFee: true },
            },
          },
        },
        hospital: {
          select: { name: true, address: true },
        },
      },
      orderBy: { date: 'desc' },
    });
    return rows.map((a) => this.mapPatientAppointment(a));
  }

  async getDoctorAppointments(doctorId: string) {
    const rows = await prisma.appointment.findMany({
      where: { doctorId },
      include: {
        patient: {
          select: { name: true, email: true, phone: true, avatarUrl: true },
        },
        hospital: {
          select: { name: true },
        },
        payment: {
          select: {
            id: true,
            amount: true,
            currency: true,
            provider: true,
            status: true,
            providerTxnId: true,
          },
        },
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
      patientAvatar: a.patient?.avatarUrl,
      hospitalName: a.hospital?.name,
      payment: a.payment
        ? {
            id: a.payment.id,
            amount: a.payment.amount,
            currency: a.payment.currency,
            provider: a.payment.provider,
            status: a.payment.status,
            providerTxnId: a.payment.providerTxnId,
          }
        : null,
    }));
  }

  async getDoctorAppointmentById(appointmentId: string, doctorId: string) {
    const row = await prisma.appointment.findFirst({
      where: { id: appointmentId, doctorId },
      include: {
        patient: {
          select: { name: true, email: true, phone: true, avatarUrl: true },
        },
        hospital: {
          select: { name: true, address: true },
        },
        payment: {
          select: {
            id: true,
            amount: true,
            currency: true,
            provider: true,
            status: true,
            providerTxnId: true,
            createdAt: true,
          },
        },
      },
    });

    if (!row) return null;

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
      patientAvatar: row.patient?.avatarUrl,
      hospitalName: row.hospital?.name,
      hospitalAddress: row.hospital?.address,
      payment: row.payment
        ? {
            id: row.payment.id,
            amount: row.payment.amount,
            currency: row.payment.currency,
            provider: row.payment.provider,
            status: row.payment.status,
            providerTxnId: row.payment.providerTxnId,
            createdAt: row.payment.createdAt,
          }
        : null,
    };
  }

  async getDoctorDashboardSummary(doctorId: string) {
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const todayEnd = new Date();
    todayEnd.setHours(23, 59, 59, 999);

    const allAppointments = await prisma.appointment.findMany({
      where: { doctorId },
      include: {
        payment: {
          select: { status: true, amount: true },
        },
      },
    });

    const todayAppointments = allAppointments.filter(
      (a) => a.date >= todayStart && a.date <= todayEnd,
    );

    const upcoming = allAppointments.filter(
      (a) => a.date > todayEnd && a.status !== 'cancelled' && a.status !== 'completed',
    );

    const completed = allAppointments.filter((a) => a.status === 'completed');
    const cancelled = allAppointments.filter((a) => a.status === 'cancelled');

    const uniquePatientIds = new Set(allAppointments.map((a) => a.patientId));

    const paidPayments = allAppointments.filter((a) => a.payment?.status === 'paid');
    const pendingPayments = allAppointments.filter((a) => a.payment?.status === 'pending');
    const totalRevenue = paidPayments.reduce((sum, a) => sum + (a.payment?.amount ?? 0), 0);

    return {
      todayCount: todayAppointments.length,
      todayAppointments: todayAppointments.map((a) => ({
        id: a.id,
        patientId: a.patientId,
        date: a.date,
        timeSlot: a.timeSlot,
        status: a.status,
      })),
      upcomingCount: upcoming.length,
      completedCount: completed.length,
      cancelledCount: cancelled.length,
      totalPatients: uniquePatientIds.size,
      paidPaymentsCount: paidPayments.length,
      pendingPaymentsCount: pendingPayments.length,
      totalRevenue,
    };
  }

  async cancel(appointmentId: string, userId: string, role: string) {
    const appointment = await prisma.appointment.findUnique({
      where: { id: appointmentId },
    });

    if (!appointment) {
      throw new AppError('Appointment not found', 404);
    }

    if (appointment.patientId !== userId && appointment.doctorId !== userId && role !== 'admin') {
      throw new AppError('Not authorized to cancel this appointment', 403);
    }

    if (appointment.status === 'cancelled') {
      throw new AppError('Appointment already cancelled', 400);
    }

    const updated = await prisma.appointment.update({
      where: { id: appointmentId },
      data: { status: 'cancelled' },
      include: {
        doctor: {
          include: {
            doctor: {
              select: { specialty: true, consultationFee: true },
            },
          },
        },
        hospital: {
          select: { name: true, address: true },
        },
      },
    });

    createNotification({
      userId: appointment.patientId,
      title: 'Appointment Cancelled',
      body: `Your appointment with ${updated.doctor?.name ?? 'Doctor'} on ${appointment.date.toLocaleDateString()} at ${appointment.timeSlot} has been cancelled`,
      type: 'appointment_cancelled',
      data: { appointmentId: appointment.id },
    }).catch(() => {});
    createNotification({
      userId: appointment.doctorId,
      title: 'Appointment Cancelled',
      body: `Appointment with ${appointment.patientId} on ${appointment.date.toLocaleDateString()} at ${appointment.timeSlot} was cancelled`,
      type: 'appointment_cancelled',
      data: { appointmentId: appointment.id },
    }).catch(() => {});

    logger.info('appointment_cancelled', {
      appointmentId: appointment.id,
      patientId: appointment.patientId,
      doctorId: appointment.doctorId,
      byUserId: userId,
    });

    io.to(`user:${appointment.patientId}`).emit('appointment-cancelled', updated);
    io.to(`user:${appointment.doctorId}`).emit('appointment-cancelled', updated);

    return {
      id: updated.id,
      patientId: updated.patientId,
      doctorId: updated.doctorId,
      date: updated.date,
      timeSlot: updated.timeSlot,
      status: updated.status,
      meetingLink: updated.meetingLink,
      notes: updated.notes,
      createdAt: updated.createdAt,
      updatedAt: updated.updatedAt,
      doctorName: updated.doctor?.name ?? '',
      doctorAvatar: updated.doctor?.avatarUrl,
      specialty: updated.doctor?.doctor?.specialty ?? '',
      fee: updated.doctor?.doctor?.consultationFee ?? 0,
      hospitalName: updated.hospital?.name,
    };
  }

  async complete(appointmentId: string) {
    const appointment = await prisma.appointment.findUnique({
      where: { id: appointmentId },
      include: {
        doctor: { select: { name: true } },
      },
    });

    if (!appointment) {
      throw new AppError('Appointment not found', 404);
    }

    const updated = await prisma.appointment.update({
      where: { id: appointmentId },
      data: { status: 'completed' },
    });

    createNotification({
      userId: appointment.patientId,
      title: 'Appointment Completed',
      body: `Your appointment with ${appointment.doctor?.name ?? 'Doctor'} on ${appointment.date.toLocaleDateString()} at ${appointment.timeSlot} has been marked as completed`,
      type: 'appointment_completed',
      data: { appointmentId: appointment.id },
    }).catch(() => {});

    logger.info('appointment_completed', {
      appointmentId: appointment.id,
      patientId: appointment.patientId,
      doctorId: appointment.doctorId,
    });

    io.to(`user:${appointment.patientId}`).emit('appointment-completed', updated);

    return updated;
  }

  private validateTimeSlot(slot: string): void {
    const validSlots = this.generateTimeSlots();
    if (!validSlots.includes(slot)) {
      throw new AppError(`Invalid time slot "${slot}". Choose from: ${validSlots.join(', ')}`, 400);
    }
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
