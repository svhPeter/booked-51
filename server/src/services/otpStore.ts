import { getRedisClient } from '../config/redis';
import { sendOtpEmail } from './emailService';
import { AppError } from '../middleware/errorHandler';

const OTP_TTL_SECONDS = 600;
const RESEND_COOLDOWN_SECONDS = 60;
const MAX_VERIFY_ATTEMPTS = 5;

interface OtpEntry {
  otp: string;
  expiry: number;
  attempts: number;
  lastResendAt: number;
}

const memoryStore = new Map<string, OtpEntry>();

function redisKey(email: string): string {
  return `otp:${email.toLowerCase()}`;
}

function rateLimitKey(email: string): string {
  return `otp:rl:${email.toLowerCase()}`;
}

function attemptsKey(email: string): string {
  return `otp:attempts:${email.toLowerCase()}`;
}

export async function storeOtp(email: string, otp: string): Promise<void> {
  const redis = getRedisClient();
  const normalized = email.toLowerCase();
  const now = Date.now();

  if (redis) {
    try {
      await redis.setex(redisKey(normalized), OTP_TTL_SECONDS, otp);
      await redis.del(attemptsKey(normalized));
      return;
    } catch {
      // fall through to memory
    }
  }

  memoryStore.set(normalized, {
    otp,
    expiry: now + OTP_TTL_SECONDS * 1000,
    attempts: 0,
    lastResendAt: 0,
  });
}

export async function getStoredOtp(email: string): Promise<string | null> {
  const redis = getRedisClient();
  const normalized = email.toLowerCase();

  if (redis) {
    try {
      return await redis.get(redisKey(normalized));
    } catch {
      // fall through to memory
    }
  }

  const entry = memoryStore.get(normalized);
  if (!entry) return null;
  if (Date.now() > entry.expiry) {
    memoryStore.delete(normalized);
    return null;
  }
  return entry.otp;
}

export async function deleteOtp(email: string): Promise<void> {
  const redis = getRedisClient();
  const normalized = email.toLowerCase();

  if (redis) {
    try {
      await redis.del(redisKey(normalized));
      await redis.del(attemptsKey(normalized));
      return;
    } catch {
      // fall through
    }
  }

  memoryStore.delete(normalized);
}

async function getAttempts(email: string): Promise<number> {
  const redis = getRedisClient();
  const normalized = email.toLowerCase();

  if (redis) {
    try {
      const val = await redis.get(attemptsKey(normalized));
      return val ? parseInt(val, 10) : 0;
    } catch {
      // fall through
    }
  }

  const entry = memoryStore.get(normalized);
  return entry?.attempts ?? 0;
}

async function incrementAttempts(email: string): Promise<number> {
  const redis = getRedisClient();
  const normalized = email.toLowerCase();

  if (redis) {
    try {
      const val = await redis.incr(attemptsKey(normalized));
      return val;
    } catch {
      // fall through
    }
  }

  const entry = memoryStore.get(normalized);
  if (entry) {
    entry.attempts += 1;
    return entry.attempts;
  }
  return 1;
}

export async function canVerify(email: string): Promise<boolean> {
  const attempts = await getAttempts(email);
  return attempts < MAX_VERIFY_ATTEMPTS;
}

export async function verifyOtp(email: string, otp: string): Promise<boolean> {
  const attempts = await incrementAttempts(email);
  if (attempts > MAX_VERIFY_ATTEMPTS) {
    return false;
  }

  const stored = await getStoredOtp(email);
  if (!stored || stored !== otp) {
    return false;
  }

  await deleteOtp(email);
  return true;
}

async function canResend(email: string): Promise<boolean> {
  const redis = getRedisClient();
  const normalized = email.toLowerCase();

  if (redis) {
    try {
      const ttl = await redis.ttl(rateLimitKey(normalized));
      return ttl <= 0;
    } catch {
      // fall through
    }
  }

  const entry = memoryStore.get(normalized);
  if (!entry) return true;
  return Date.now() - entry.lastResendAt >= RESEND_COOLDOWN_SECONDS * 1000;
}

async function markResend(email: string): Promise<void> {
  const redis = getRedisClient();
  const normalized = email.toLowerCase();

  if (redis) {
    try {
      await redis.setex(rateLimitKey(normalized), RESEND_COOLDOWN_SECONDS, '1');
      return;
    } catch {
      // fall through
    }
  }

  const entry = memoryStore.get(normalized);
  if (entry) {
    entry.lastResendAt = Date.now();
  }
}

export async function generateAndSendOtp(email: string): Promise<string> {
  const normalized = email.toLowerCase();

  const ok = await canResend(normalized);
  if (!ok) {
    throw new AppError('Please wait before requesting another OTP', 429);
  }

  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  await storeOtp(normalized, otp);
  await markResend(normalized);
  await sendOtpEmail(normalized, otp);
  return otp;
}
