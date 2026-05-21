import bcrypt from 'bcryptjs';
import { UserRole } from '@prisma/client';
import { prisma } from '../config/database';
import { logger } from '../config/logger';
import { generateTokens, verifyRefreshToken } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';
import { generateAndSendOtp, verifyOtp, canVerify } from './otpStore';
import { sendOtpEmail } from './emailService';

export class AuthService {
  async register(data: {
    name: string;
    email: string;
    phone: string;
    password: string;
    role?: string;
  }) {
    const existing = await prisma.user.findUnique({
      where: { email: data.email },
    });

    if (existing) {
      throw new AppError('Email already registered', 400);
    }

    const hashedPassword = await bcrypt.hash(data.password, 12);

    const user = await prisma.user.create({
      data: {
        name: data.name,
        email: data.email,
        phone: data.phone,
        password: hashedPassword,
        role: (data.role || 'patient') as UserRole,
      },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        role: true,
        createdAt: true,
      },
    });

    if (user.role === 'patient') {
      await prisma.patient.create({
        data: { userId: user.id },
      });
    }

    const otp = await generateAndSendOtp(data.email);

    logger.info('user_registered', { userId: user.id, email: user.email, role: user.role });

    return { user, message: 'OTP sent to email' };
  }

  async login(email: string, password: string) {
    const user = await prisma.user.findUnique({
      where: { email },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        role: true,
        avatarUrl: true,
        password: true,
        isActive: true,
      },
    });

    if (!user || !user.isActive) {
      logger.warn('user_login_failed', { email });
      throw new AppError('Invalid email or password', 401);
    }

    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) {
      logger.warn('user_login_failed', { email });
      throw new AppError('Invalid email or password', 401);
    }

    const tokens = generateTokens(user.id, user.role);

    logger.info('user_login_success', { userId: user.id, email: user.email, role: user.role });

    return {
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        avatarUrl: user.avatarUrl,
      },
      ...tokens,
    };
  }

  async verifyOtp(email: string, otp: string) {
    const ok = await canVerify(email);
    if (!ok) {
      throw new AppError('Too many failed attempts. Please request a new OTP.', 429);
    }

    const valid = await verifyOtp(email, otp);
    if (!valid) {
      throw new AppError('Invalid or expired OTP', 400);
    }

    await prisma.user.update({
      where: { email },
      data: { isVerified: true },
    });

    const user = await prisma.user.findUnique({
      where: { email },
      select: { id: true, name: true, email: true, phone: true, role: true, avatarUrl: true },
    });

    const tokens = generateTokens(user!.id, user!.role);

    return { user, ...tokens };
  }

  async refreshToken(token: string) {
    try {
      const decoded = verifyRefreshToken(token);
      const user = await prisma.user.findUnique({
        where: { id: decoded.userId },
        select: { id: true, role: true, isActive: true },
      });

      if (!user || !user.isActive) {
        throw new AppError('Invalid token', 401);
      }

      return generateTokens(user.id, user.role);
    } catch {
      throw new AppError('Invalid or expired refresh token', 401);
    }
  }

  async getProfile(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        role: true,
        avatarUrl: true,
        isActive: true,
        createdAt: true,
        patient: {
          select: { dob: true, gender: true, bloodGroup: true },
        },
        doctor: {
          select: {
            specialty: true,
            qualification: true,
            experience: true,
            consultationFee: true,
          },
        },
      },
    });

    if (!user) {
      throw new AppError('User not found', 404);
    }

    return user;
  }

  async resendOtp(email: string): Promise<void> {
    await generateAndSendOtp(email);
  }
}
