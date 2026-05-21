import { Response, NextFunction } from 'express';
import { getPaymentProvider } from '../services/paymentService';
import { AppError } from '../middleware/errorHandler';
import { AuthRequest } from '../middleware/auth';
import { prisma } from '../config/database';
import { logger } from '../config/logger';
import { createNotification } from '../services/notificationService';

export const createPayment = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { appointmentId, provider } = req.body;
    const userId = req.userId!;

    if (!appointmentId || !provider) {
      throw new AppError('appointmentId and provider are required', 400);
    }

    if (!['stripe', 'payfast', 'mock'].includes(provider)) {
      throw new AppError('Invalid payment provider. Must be stripe, payfast, or mock', 400);
    }

    const appointment = await prisma.appointment.findUnique({
      where: { id: appointmentId },
      include: {
        doctor: {
          include: {
            doctor: { select: { consultationFee: true } },
          },
        },
      },
    });

    if (!appointment) {
      throw new AppError('Appointment not found', 404);
    }

    if (appointment.patientId !== userId) {
      throw new AppError('Unauthorized to make payment for this appointment', 403);
    }

    if (appointment.status !== 'confirmed') {
      throw new AppError('Cannot pay for an appointment that is not confirmed', 400);
    }

    const existingPayment = await prisma.payment.findUnique({
      where: { appointmentId },
    });

    if (existingPayment && existingPayment.status === 'paid') {
      throw new AppError('Payment already completed for this appointment', 400);
    }

    const amount = appointment.doctor?.doctor?.consultationFee ?? 0;
    const currency = 'PKR';

    const paymentProvider = getPaymentProvider(provider);
    const result = await paymentProvider.createPayment(amount, currency, {
      appointmentId: appointment.id,
      userId,
    });

    const payment = await prisma.payment.upsert({
      where: { appointmentId },
      update: {
        provider: provider as any,
        providerTxnId: result.providerTxnId,
        status: 'pending',
        amount,
        currency,
      },
      create: {
        appointmentId,
        userId,
        amount,
        currency,
        provider: provider as any,
        providerTxnId: result.providerTxnId!,
        status: 'pending',
      },
    });

    res.json({
      success: true,
      payment: {
        id: payment.id,
        amount: payment.amount,
        currency: payment.currency,
        provider: payment.provider,
        status: payment.status,
        providerTxnId: payment.providerTxnId,
        clientSecret: result.message,
      },
    });
  } catch (error) {
    next(error);
  }
};

export const mockPaymentSuccess = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { paymentId } = req.body;
    const userId = req.userId!;

    if (!paymentId) {
      throw new AppError('paymentId is required', 400);
    }

    const payment = await prisma.payment.findUnique({
      where: { id: paymentId },
      include: { appointment: true },
    });

    if (!payment) {
      throw new AppError('Payment not found', 404);
    }

    if (payment.appointment.patientId !== userId) {
      throw new AppError('Unauthorized', 403);
    }

    if (payment.provider !== 'mock') {
      throw new AppError('This endpoint is only for mock payments', 400);
    }

    if (payment.status === 'paid') {
      throw new AppError('Payment already completed', 400);
    }

    const paymentProvider = getPaymentProvider('mock');
    const verification = await paymentProvider.verifyPayment(payment.providerTxnId!);

    if (!verification.success) {
      throw new AppError('Payment verification failed', 400);
    }

    const updatedPayment = await prisma.payment.update({
      where: { id: paymentId },
      data: { status: 'paid' },
    });

    logger.info('payment_paid', {
      paymentId: payment.id,
      appointmentId: payment.appointmentId,
      userId: payment.userId,
      amount: payment.amount,
      provider: payment.provider,
    });

    createNotification({
      userId: payment.appointment.patientId,
      title: 'Payment Successful',
      body: `Your payment of PKR ${payment.amount} for appointment on ${payment.appointment.date.toLocaleDateString()} at ${payment.appointment.timeSlot} has been completed`,
      type: 'payment_paid',
      data: { appointmentId: payment.appointmentId, paymentId: payment.id },
    }).catch(() => {});

    res.json({
      success: true,
      payment: updatedPayment,
    });
  } catch (error) {
    next(error);
  }
};

export const getPaymentStatus = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { appointmentId } = req.params;
    const userId = req.userId!;

    const appointment = await prisma.appointment.findUnique({
      where: { id: appointmentId },
      select: { patientId: true },
    });

    if (!appointment) {
      throw new AppError('Appointment not found', 404);
    }

    if (appointment.patientId !== userId) {
      throw new AppError('Unauthorized', 403);
    }

    const payment = await prisma.payment.findUnique({
      where: { appointmentId },
    });

    res.json({
      success: true,
      payment: payment || null,
    });
  } catch (error) {
    next(error);
  }
};
