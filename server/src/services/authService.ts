import bcrypt from 'bcryptjs';
import { prisma } from '../config/database';
import { env } from '../config/env';
import { logger } from '../config/logger';
import { generateTokens, verifyRefreshToken } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';
import { generateAndSendOtp, verifyOtp as verifyStoredOtp, canVerify as canVerifyStoredOtp } from './otpStore';
import { sendOtpEmail, maskEmail } from './emailService';
import type { EmailSendResult } from './emailService';

const OTP_TTL_MS = 10 * 60 * 1000;
const RESEND_COOLDOWN_MS = 60 * 1000;
const MAX_PENDING_ATTEMPTS = 5;

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

type PendingInput = {
  name: string;
  email: string;
  phone: string;
  city: string;
  passwordHash: string;
  role: 'patient' | 'doctor';
  specialty?: string | null;
  clinicName?: string | null;
  consultationFee?: number | null;
  pmdcRegistrationNumber?: string | null;
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

function generateOtp(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

function otpExpiry(): Date {
  return new Date(Date.now() + OTP_TTL_MS);
}

function publicSignupMessage(): string {
  return 'Verification code generated. If you do not receive email, try resend or contact support.';
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

    const passwordHash = await bcrypt.hash(data.password, 12);
    const emailResult = await this.createOrUpdatePendingRegistration({
      name,
      email,
      phone,
      city,
      passwordHash,
      role: 'patient',
    });

    logger.info('pending_patient_registration_created', {
      email: maskEmail(email),
      emailSent: emailResult.sent,
      emailFallback: emailResult.fallback,
      emailDurationMs: emailResult.durationMs,
    });

    return { email, message: publicSignupMessage() };
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

    const passwordHash = await bcrypt.hash(data.password, 12);
    const emailResult = await this.createOrUpdatePendingRegistration({
      name,
      email,
      phone,
      city,
      passwordHash,
      role: 'doctor',
      specialty,
      clinicName,
      consultationFee,
      pmdcRegistrationNumber: data.pmdcRegistrationNumber?.trim() || null,
    });

    logger.info('pending_doctor_registration_created', {
      email: maskEmail(email),
      emailSent: emailResult.sent,
      emailFallback: emailResult.fallback,
      emailDurationMs: emailResult.durationMs,
    });

    return { email, message: publicSignupMessage() };
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
    const pending = await prisma.pendingRegistration.findUnique({ where: { email: normalizedEmail } });

    if (!pending) {
      throw new AppError('No pending verification found. Please sign up again.', 400);
    }

    if (pending.otpExpiresAt < new Date()) {
      throw new AppError('OTP expired. Please request a new code.', 400);
    }

    if (pending.attempts >= MAX_PENDING_ATTEMPTS) {
      throw new AppError('Too many failed attempts. Please request a new code.', 429);
    }

    const valid = await bcrypt.compare(code, pending.otpHash);
    if (!valid) {
      await prisma.pendingRegistration.update({
        where: { email: normalizedEmail },
        data: { attempts: { increment: 1 } },
      });
      throw new AppError('Invalid or expired OTP', 400);
    }

    const existing = await prisma.user.findUnique({
      where: { email: normalizedEmail },
      select: { id: true, role: true, isVerified: true, isDemo: true },
    });

    if (existing?.isVerified) {
      await prisma.pendingRegistration.delete({ where: { email: normalizedEmail } });
      throw new AppError('Account already exists. Please sign in.', 400);
    }
    if (existing && (existing.isDemo || existing.role === 'admin')) {
      throw new AppError('Existing account requires admin review. Please contact support.', 400);
    }
    if (existing && existing.role !== pending.role) {
      throw new AppError('An unverified account already exists with a different role. Please contact support.', 400);
    }

    const user = await prisma.$transaction(async (tx) => {
      const finalUser = existing
        ? await tx.user.update({
            where: { id: existing.id },
            data: {
              name: pending.name,
              phone: pending.phone,
              password: pending.passwordHash,
              role: pending.role,
              isVerified: true,
              isActive: true,
            },
            select: { id: true, name: true, email: true, phone: true, role: true, avatarUrl: true, isActive: true, isVerified: true, isDemo: true },
          })
        : await tx.user.create({
            data: {
              name: pending.name,
              email: pending.email,
              phone: pending.phone,
              password: pending.passwordHash,
              role: pending.role,
              isVerified: true,
              isActive: true,
            },
            select: { id: true, name: true, email: true, phone: true, role: true, avatarUrl: true, isActive: true, isVerified: true, isDemo: true },
          });

      if (pending.role === 'patient') {
        await tx.patient.upsert({
          where: { userId: finalUser.id },
          update: { city: pending.city },
          create: { userId: finalUser.id, city: pending.city },
        });
      } else if (pending.role === 'doctor') {
        const hospital = await tx.hospital.create({
          data: {
            name: pending.clinicName || 'Clinic / Hospital',
            city: pending.city,
          },
        });
        await tx.doctor.upsert({
          where: { userId: finalUser.id },
          update: {
            specialty: pending.specialty,
            consultationFee: pending.consultationFee ?? 0,
            pmdcRegistrationNumber: pending.pmdcRegistrationNumber,
            isApproved: false,
            isAvailable: false,
            hospitalId: hospital.id,
          },
          create: {
            userId: finalUser.id,
            specialty: pending.specialty,
            consultationFee: pending.consultationFee ?? 0,
            pmdcRegistrationNumber: pending.pmdcRegistrationNumber,
            availableDays: [],
            isApproved: false,
            isAvailable: false,
            hospitalId: hospital.id,
          },
        });
      }

      await tx.pendingRegistration.delete({ where: { email: normalizedEmail } });
      return finalUser;
    });

    const tokens = generateTokens(user.id, user.role);
    logger.info('pending_registration_verified', { userId: user.id, email: user.email, role: user.role });

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
    const pending = await prisma.pendingRegistration.findUnique({ where: { email: normalizedEmail } });

    if (pending) {
      await this.resendPendingOtp(normalizedEmail, pending.lastResendAt);
      return;
    }

    const legacy = await this.findLegacyUnverifiedUser(normalizedEmail);
    if (legacy) {
      await this.createPendingFromLegacyUser(legacy);
      return;
    }

    const user = await prisma.user.findUnique({
      where: { email: normalizedEmail },
      select: { isVerified: true, isActive: true },
    });
    if (user?.isVerified) {
      throw new AppError('Account already exists. Please sign in.', 400);
    }
    if (user && !user.isActive) {
      throw new AppError('This account is inactive. Please contact support.', 403);
    }

    throw new AppError('No pending registration found. Please sign up first.', 404);
  }

  async forgotPassword(email: string): Promise<void> {
    const normalizedEmail = normalizeEmail(requireText(email, 'Email'));
    const user = await prisma.user.findUnique({
      where: { email: normalizedEmail },
      select: { id: true, isActive: true, isVerified: true },
    });

    if (user?.isActive && user.isVerified) {
      await generateAndSendOtp(normalizedEmail);
    }
  }

  async resetPassword(email: string, otp: string, newPassword: string): Promise<void> {
    const normalizedEmail = normalizeEmail(requireText(email, 'Email'));
    const code = requireText(otp, 'Reset code');
    validatePassword(newPassword);

    const ok = await canVerifyStoredOtp(normalizedEmail);
    if (!ok) {
      throw new AppError('Too many failed attempts. Please request a new code.', 429);
    }

    const valid = await verifyStoredOtp(normalizedEmail, code);
    if (!valid) {
      throw new AppError('Invalid or expired reset code', 400);
    }

    const user = await prisma.user.findUnique({
      where: { email: normalizedEmail },
      select: { id: true, isActive: true, isVerified: true },
    });

    if (!user?.isActive || !user.isVerified) {
      throw new AppError('Invalid or expired reset code', 400);
    }

    const hashedPassword = await bcrypt.hash(newPassword, 12);
    await prisma.user.update({
      where: { id: user.id },
      data: { password: hashedPassword },
    });

    logger.info('password_reset_completed', { userId: user.id, email: normalizedEmail });
  }

  private async createOrUpdatePendingRegistration(data: PendingInput): Promise<EmailSendResult> {
    const existingUser = await prisma.user.findUnique({
      where: { email: data.email },
      select: { id: true, role: true, isVerified: true, isDemo: true },
    });

    if (existingUser?.isVerified) {
      throw new AppError('Email already registered. Please sign in.', 400);
    }
    if (existingUser && (existingUser.isDemo || existingUser.role === 'admin')) {
      throw new AppError('Existing account requires admin review. Please contact support.', 400);
    }
    if (existingUser && existingUser.role !== data.role) {
      throw new AppError('An unverified account already exists with a different role. Please contact support.', 400);
    }

    const otp = generateOtp();
    const otpHash = await bcrypt.hash(otp, 12);
    const now = new Date();

    await prisma.pendingRegistration.upsert({
      where: { email: data.email },
      update: {
        name: data.name,
        phone: data.phone,
        city: data.city,
        passwordHash: data.passwordHash,
        role: data.role,
        specialty: data.specialty,
        clinicName: data.clinicName,
        consultationFee: data.consultationFee,
        pmdcRegistrationNumber: data.pmdcRegistrationNumber,
        otpHash,
        otpExpiresAt: otpExpiry(),
        attempts: 0,
        lastResendAt: now,
      },
      create: {
        email: data.email,
        name: data.name,
        phone: data.phone,
        city: data.city,
        passwordHash: data.passwordHash,
        role: data.role,
        specialty: data.specialty,
        clinicName: data.clinicName,
        consultationFee: data.consultationFee,
        pmdcRegistrationNumber: data.pmdcRegistrationNumber,
        otpHash,
        otpExpiresAt: otpExpiry(),
        attempts: 0,
        lastResendAt: now,
      },
    });

    const template = data.role === 'doctor' ? 'doctor_onboarding' as const : 'signup' as const;
    return sendOtpEmail(data.email, otp, template);
  }

  private async resendPendingOtp(email: string, lastResendAt: Date | null): Promise<void> {
    if (lastResendAt && Date.now() - lastResendAt.getTime() < RESEND_COOLDOWN_MS) {
      throw new AppError('Please wait before requesting another OTP', 429);
    }

    const otp = generateOtp();
    const otpHash = await bcrypt.hash(otp, 12);

    await prisma.pendingRegistration.update({
      where: { email },
      data: {
        otpHash,
        otpExpiresAt: otpExpiry(),
        attempts: 0,
        lastResendAt: new Date(),
      },
    });

    const result = await sendOtpEmail(email, otp, 'resend');
    logger.info('resend_otp_completed', {
      email: maskEmail(email),
      emailSent: result.sent,
      emailFallback: result.fallback,
      emailDurationMs: result.durationMs,
    });
  }

  private async findLegacyUnverifiedUser(email: string) {
    return prisma.user.findUnique({
      where: { email },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        password: true,
        role: true,
        isVerified: true,
        isDemo: true,
        patient: { select: { city: true } },
        doctor: {
          select: {
            specialty: true,
            consultationFee: true,
            pmdcRegistrationNumber: true,
            hospital: { select: { name: true, city: true } },
          },
        },
      },
    }).then((user) => {
      if (!user || user.isVerified || user.isDemo || user.role === 'admin') return null;
      if (user.role !== 'patient' && user.role !== 'doctor') return null;
      return user;
    });
  }

  private async createPendingFromLegacyUser(user: NonNullable<Awaited<ReturnType<AuthService['findLegacyUnverifiedUser']>>>): Promise<void> {
    await this.createOrUpdatePendingRegistration({
      name: user.name,
      email: user.email,
      phone: user.phone || '',
      city: user.patient?.city || user.doctor?.hospital?.city || '',
      passwordHash: user.password,
      role: user.role === 'doctor' ? 'doctor' : 'patient',
      specialty: user.doctor?.specialty,
      clinicName: user.doctor?.hospital?.name,
      consultationFee: user.doctor?.consultationFee,
      pmdcRegistrationNumber: user.doctor?.pmdcRegistrationNumber,
    });
  }
}
