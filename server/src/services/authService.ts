import bcrypt from 'bcryptjs';
import { prisma } from '../config/database';
import { env } from '../config/env';
import { logger } from '../config/logger';
import { generateTokens, verifyRefreshToken } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';
import { generateAndSendOtp, verifyOtp, canVerify } from './otpStore';

type RegisterPatientInput = {
  name: string;
  email: string;
  phone: string;
  password: string;
  confirmPassword?: string;
  city: string;
  role?: string;
};

type RegisterDoctorInput = {
  name: string;
  email: string;
  phone: string;
  password: string;
  specialty: string;
  city: string;
  clinicName: string;
  consultationFee: number | string;
  pmdcRegistrationNumber?: string;
};

function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

function requireText(value: string | undefined, label: string): string {
  const trimmed = value?.trim();
  if (!trimmed) throw new AppError(`${label} is required`, 400);
  return trimmed;
}

function validatePassword(password: string): void {
  if (!password || password.length < 8) {
    throw new AppError('Password must be at least 8 characters', 400);
  }
}

export class AuthService {
  async register(data: RegisterPatientInput) {
    const requestedRole = data.role?.trim().toLowerCase();
    if (requestedRole === 'admin') {
      throw new AppError('Admin registration is not public', 403);
    }
    if (requestedRole === 'doctor') {
      throw new AppError('Use doctor onboarding to create a doctor account', 400);
    }
    if (requestedRole && requestedRole !== 'patient') {
      throw new AppError('Invalid registration role', 400);
    }

    const name = requireText(data.name, 'Name');
    const email = normalizeEmail(requireText(data.email, 'Email'));
    const phone = requireText(data.phone, 'Phone');
    const city = requireText(data.city, 'City');
    validatePassword(data.password);
    if (data.confirmPassword !== undefined && data.confirmPassword !== data.password) {
      throw new AppError('Passwords do not match', 400);
    }

    const existing = await prisma.user.findUnique({
      where: { email },
    });

    if (existing) {
      throw new AppError('Email already registered', 400);
    }

    const hashedPassword = await bcrypt.hash(data.password, 12);

    const user = await prisma.user.create({
      data: {
        name,
        email,
        phone,
        password: hashedPassword,
        role: 'patient',
        patient: { create: { city } },
      },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        role: true,
        isVerified: true,
        isActive: true,
        isDemo: true,
        createdAt: true,
      },
    });

    await generateAndSendOtp(email);

    logger.info('user_registered', { userId: user.id, email: user.email, role: user.role });

    return { user, message: 'OTP sent to email' };
  }

  async registerDoctor(data: RegisterDoctorInput) {
    const name = requireText(data.name, 'Name');
    const email = normalizeEmail(requireText(data.email, 'Email'));
    const phone = requireText(data.phone, 'Phone');
    const specialty = requireText(data.specialty, 'Specialty');
    const city = requireText(data.city, 'City');
    const clinicName = requireText(data.clinicName, 'Clinic or hospital name');
    validatePassword(data.password);

    const consultationFee = typeof data.consultationFee === 'number'
      ? data.consultationFee
      : parseFloat(String(data.consultationFee));
    if (!Number.isFinite(consultationFee) || consultationFee < 0) {
      throw new AppError('Consultation fee must be a valid number', 400);
    }

    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) {
      throw new AppError('Email already registered', 400);
    }

    const hashedPassword = await bcrypt.hash(data.password, 12);
    const user = await prisma.$transaction(async (tx) => {
      const hospital = await tx.hospital.create({
        data: {
          name: clinicName,
          city,
        },
      });

      return tx.user.create({
        data: {
          name,
          email,
          phone,
          password: hashedPassword,
          role: 'doctor',
          doctor: {
            create: {
              specialty,
              consultationFee,
              pmdcRegistrationNumber: data.pmdcRegistrationNumber?.trim() || null,
              availableDays: [],
              isAvailable: false,
              isApproved: false,
              hospital: { connect: { id: hospital.id } },
            },
          },
        },
        select: {
          id: true,
          name: true,
          email: true,
          phone: true,
          role: true,
          isVerified: true,
          isActive: true,
          isDemo: true,
          createdAt: true,
        },
      });
    });

    await generateAndSendOtp(email);

    logger.info('doctor_registered_pending', { userId: user.id, email: user.email });

    return {
      user,
      message: 'Doctor onboarding submitted. Verify your email, then wait for admin approval before public listing.',
    };
  }

  async login(email: string, password: string) {
    const normalizedEmail = normalizeEmail(requireText(email, 'Email'));
    if (!password) throw new AppError('Password is required', 400);
    const user = await prisma.user.findUnique({
      where: { email: normalizedEmail },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        role: true,
        avatarUrl: true,
        password: true,
        isActive: true,
        isVerified: true,
        isDemo: true,
      },
    });

    if (!user || !user.isActive) {
      logger.warn('user_login_failed', { email: normalizedEmail });
      throw new AppError('Invalid email or password', 401);
    }

    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) {
      logger.warn('user_login_failed', { email: normalizedEmail });
      throw new AppError('Invalid email or password', 401);
    }

    if (!user.isVerified) {
      logger.warn('user_login_unverified', { userId: user.id, email: user.email });
      throw new AppError('Please verify your email before logging in', 403);
    }

    if (env.nodeEnv === 'production' && user.role === 'admin' && user.isDemo) {
      logger.warn('demo_admin_login_blocked', { userId: user.id, email: user.email });
      throw new AppError('Demo admin is disabled in production. Use a secure admin account.', 403);
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
        isActive: user.isActive,
        isVerified: user.isVerified,
        isDemo: user.isDemo,
      },
      ...tokens,
    };
  }

  async verifyOtp(email: string, otp: string) {
    const normalizedEmail = normalizeEmail(requireText(email, 'Email'));
    const code = requireText(otp, 'OTP');
    const ok = await canVerify(normalizedEmail);
    if (!ok) {
      throw new AppError('Too many failed attempts. Please request a new OTP.', 429);
    }

    const valid = await verifyOtp(normalizedEmail, code);
    if (!valid) {
      throw new AppError('Invalid or expired OTP', 400);
    }

    await prisma.user.update({
      where: { email: normalizedEmail },
      data: { isVerified: true },
    });

    const user = await prisma.user.findUnique({
      where: { email: normalizedEmail },
      select: { id: true, name: true, email: true, phone: true, role: true, avatarUrl: true, isActive: true, isVerified: true, isDemo: true },
    });

    const tokens = generateTokens(user!.id, user!.role);

    return { user, ...tokens };
  }

  async refreshToken(token: string) {
    try {
      const decoded = verifyRefreshToken(token);
      const user = await prisma.user.findUnique({
        where: { id: decoded.userId },
        select: { id: true, role: true, isActive: true, isVerified: true, isDemo: true },
      });

      if (!user || !user.isActive || !user.isVerified) {
        throw new AppError('Invalid token', 401);
      }

      if (env.nodeEnv === 'production' && user.role === 'admin' && user.isDemo) {
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
        isVerified: true,
        isDemo: true,
        createdAt: true,
        patient: {
          select: { dob: true, gender: true, bloodGroup: true, city: true },
        },
        doctor: {
          select: {
            specialty: true,
            qualification: true,
            experience: true,
            consultationFee: true,
            pmdcRegistrationNumber: true,
            isApproved: true,
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
    const normalizedEmail = normalizeEmail(requireText(email, 'Email'));
    const user = await prisma.user.findUnique({
      where: { email: normalizedEmail },
      select: { isActive: true, isVerified: true },
    });

    if (user?.isActive && !user.isVerified) {
      await generateAndSendOtp(normalizedEmail);
    }
  }

  async forgotPassword(email: string): Promise<void> {
    const normalizedEmail = normalizeEmail(requireText(email, 'Email'));
    const user = await prisma.user.findUnique({
      where: { email: normalizedEmail },
      select: { id: true, isActive: true },
    });

    if (user?.isActive) {
      await generateAndSendOtp(normalizedEmail);
    }
  }

  async resetPassword(email: string, otp: string, newPassword: string): Promise<void> {
    const normalizedEmail = normalizeEmail(requireText(email, 'Email'));
    const code = requireText(otp, 'Reset code');
    validatePassword(newPassword);

    const ok = await canVerify(normalizedEmail);
    if (!ok) {
      throw new AppError('Too many failed attempts. Please request a new code.', 429);
    }

    const valid = await verifyOtp(normalizedEmail, code);
    if (!valid) {
      throw new AppError('Invalid or expired reset code', 400);
    }

    const user = await prisma.user.findUnique({
      where: { email: normalizedEmail },
      select: { id: true, isActive: true },
    });

    if (!user?.isActive) {
      throw new AppError('Invalid or expired reset code', 400);
    }

    const hashedPassword = await bcrypt.hash(newPassword, 12);
    await prisma.user.update({
      where: { id: user.id },
      data: {
        password: hashedPassword,
        isVerified: true,
      },
    });

    logger.info('password_reset_completed', { userId: user.id, email: normalizedEmail });
  }
}
