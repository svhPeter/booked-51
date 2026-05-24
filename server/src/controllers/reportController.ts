import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { prisma } from '../config/database';
import { createNotification } from '../services/notificationService';
import { logger } from '../config/logger';

const VALID_REASONS = [
  'wrong_doctor_info',
  'wrong_clinic_address',
  'appointment_issue',
  'doctor_unavailable',
  'other',
] as const;

export const submitReport = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId;
    const { reason, description, doctorId, appointmentId } = req.body;

    if (!userId) {
      res.status(401).json({ error: 'Unauthorized.' });
      return;
    }

    if (!reason || !VALID_REASONS.includes(reason)) {
      res.status(400).json({ error: `Invalid reason. Must be one of: ${VALID_REASONS.join(', ')}` });
      return;
    }
    if (!description || typeof description !== 'string' || description.trim().length < 5) {
      res.status(400).json({ error: 'Description must be at least 5 characters.' });
      return;
    }

    // Find admin users to notify
    const admins = await prisma.user.findMany({
      where: { role: 'admin', isActive: true },
      select: { id: true },
    });

    const reporter = await prisma.user.findUnique({
      where: { id: userId },
      select: { name: true, email: true, role: true },
    });

    const reportData = {
      reason,
      description: description.trim(),
      reporterName: reporter?.name ?? 'Unknown',
      reporterEmail: reporter?.email ?? '',
      reporterRole: reporter?.role ?? 'patient',
      ...(doctorId ? { doctorId } : {}),
      ...(appointmentId ? { appointmentId } : {}),
    };

    // Send notification to each admin
    for (const admin of admins) {
      await createNotification({
        userId: admin.id,
        title: `User Report: ${reason.replace(/_/g, ' ')}`,
        body: `${reporter?.name} (${reporter?.email}) reported: ${description.trim().substring(0, 200)}`,
        type: 'user_report',
        data: reportData,
      });
    }

    logger.info('user_report_submitted', { userId, reason, doctorId, appointmentId });

    res.status(201).json({
      success: true,
      message: 'Report submitted. Our team will review it shortly.',
    });
  } catch (error) {
    next(error);
  }
};

export const listReports = async (_req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const reports = await prisma.notification.findMany({
      where: { type: 'user_report' },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
    res.json({ success: true, reports });
  } catch (error) {
    next(error);
  }
};
