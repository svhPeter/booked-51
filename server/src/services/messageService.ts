import { prisma } from '../config/database';
import { AppError } from '../middleware/errorHandler';
import { io } from '../index';

const MAX_MESSAGE_LENGTH = 2000;
const CHAT_STATUSES = ['confirmed', 'completed'] as const;

export class MessageService {
  private async assertParticipant(appointmentId: string, userId: string, role: string) {
    const appointment = await prisma.appointment.findUnique({
      where: { id: appointmentId },
    });
    if (!appointment) throw new AppError('Appointment not found', 404);
    if (role === 'admin') {
      throw new AppError('Admins cannot access appointment chat messages', 403);
    }
    if (appointment.patientId !== userId && appointment.doctorId !== userId) {
      throw new AppError('Not authorized for this appointment chat', 403);
    }
    if (!CHAT_STATUSES.includes(appointment.status as typeof CHAT_STATUSES[number])) {
      throw new AppError('Chat is not available for this appointment status', 400);
    }
    return appointment;
  }

  private otherParticipantId(appointment: { patientId: string; doctorId: string }, senderId: string) {
    return appointment.patientId === senderId ? appointment.doctorId : appointment.patientId;
  }

  async listMessages(appointmentId: string, userId: string, role: string, limit = 50) {
    await this.assertParticipant(appointmentId, userId, role);
    const messages = await prisma.message.findMany({
      where: { appointmentId },
      orderBy: { createdAt: 'asc' },
      take: Math.min(limit, 100),
      include: {
        sender: { select: { id: true, name: true, avatarUrl: true } },
      },
    });
    return messages.map((m) => ({
      id: m.id,
      appointmentId: m.appointmentId,
      senderId: m.senderId,
      receiverId: m.receiverId,
      content: m.content,
      isRead: m.isRead,
      createdAt: m.createdAt,
      senderName: m.sender.name,
      senderAvatar: m.sender.avatarUrl,
    }));
  }

  async sendMessage(appointmentId: string, senderId: string, role: string, content: string) {
    const trimmed = content?.trim();
    if (!trimmed) throw new AppError('Message content is required', 400);
    if (trimmed.length > MAX_MESSAGE_LENGTH) {
      throw new AppError(`Message must be at most ${MAX_MESSAGE_LENGTH} characters`, 400);
    }

    const appointment = await this.assertParticipant(appointmentId, senderId, role);
    if (role === 'admin') throw new AppError('Admins cannot send chat messages', 403);

    const receiverId = this.otherParticipantId(appointment, senderId);

    const message = await prisma.message.create({
      data: {
        appointmentId,
        senderId,
        receiverId,
        content: trimmed,
      },
      include: {
        sender: { select: { id: true, name: true, avatarUrl: true } },
      },
    });

    const payload = {
      id: message.id,
      appointmentId: message.appointmentId,
      senderId: message.senderId,
      receiverId: message.receiverId,
      content: message.content,
      isRead: message.isRead,
      createdAt: message.createdAt,
      senderName: message.sender.name,
      senderAvatar: message.sender.avatarUrl,
    };

    io.to(`appointment:${appointmentId}`).emit('message:new', payload);
    io.to(`user:${receiverId}`).emit('message:new', payload);

    return payload;
  }

  async markRead(appointmentId: string, userId: string, role: string) {
    await this.assertParticipant(appointmentId, userId, role);
    await prisma.message.updateMany({
      where: {
        appointmentId,
        receiverId: userId,
        isRead: false,
      },
      data: { isRead: true },
    });
    io.to(`appointment:${appointmentId}`).emit('message:read', { appointmentId, readerId: userId });
    return { success: true };
  }

  async unreadCount(appointmentId: string, userId: string, role: string) {
    await this.assertParticipant(appointmentId, userId, role);
    const count = await prisma.message.count({
      where: {
        appointmentId,
        receiverId: userId,
        isRead: false,
      },
    });
    return { count };
  }

  async getChatMeta(appointmentId: string) {
    const appointment = await prisma.appointment.findUnique({
      where: { id: appointmentId },
      include: {
        patient: { select: { id: true, name: true } },
        doctor: { select: { id: true, name: true } },
      },
    });
    if (!appointment) throw new AppError('Appointment not found', 404);

    const count = await prisma.message.count({ where: { appointmentId } });
    const last = await prisma.message.findFirst({
      where: { appointmentId },
      orderBy: { createdAt: 'desc' },
      select: { createdAt: true },
    });

    return {
      appointmentId,
      messageCount: count,
      lastMessageAt: last?.createdAt ?? null,
      participants: [
        { id: appointment.patient.id, name: appointment.patient.name, role: 'patient' },
        { id: appointment.doctor.id, name: appointment.doctor.name, role: 'doctor' },
      ],
    };
  }
}
