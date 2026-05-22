import nodemailer from 'nodemailer';
import { env } from '../config/env';

const SMTP_TIMEOUT_MS = 10_000;

function isSmtpConfigured(): boolean {
  if (!env.smtpHost || !env.smtpUser || !env.smtpPass) return false;
  if (env.smtpUser.startsWith('your-') || env.smtpUser.startsWith('placeholder')) return false;
  if (env.smtpPass.startsWith('your-') || env.smtpPass.startsWith('placeholder')) return false;
  return true;
}

function maskEmail(email: string): string {
  const [local, domain] = email.split('@');
  if (!local || !domain) return '***';
  const visible = local.length <= 2 ? local[0] : local.slice(0, 2);
  return `${visible}***@${domain}`;
}

function createTransporter() {
  return nodemailer.createTransport({
    host: env.smtpHost,
    port: env.smtpPort,
    secure: env.smtpPort === 465,
    auth: { user: env.smtpUser, pass: env.smtpPass },
    connectionTimeout: SMTP_TIMEOUT_MS,
    greetingTimeout: SMTP_TIMEOUT_MS,
    socketTimeout: SMTP_TIMEOUT_MS,
  });
}

function safeEmailError(error: unknown): Record<string, string> {
  if (!error || typeof error !== 'object') return { message: 'Unknown email error' };
  const e = error as { message?: string; code?: string; command?: string; responseCode?: number };
  return {
    message: e.message || 'Unknown email error',
    ...(e.code ? { code: e.code } : {}),
    ...(e.command ? { command: e.command } : {}),
    ...(e.responseCode ? { responseCode: String(e.responseCode) } : {}),
  };
}

async function sendOtpEmail(to: string, otp: string): Promise<void> {
  if (!isSmtpConfigured()) {
    console.log(`[OTP_FALLBACK] SMTP not configured. OTP for ${maskEmail(to)}: ${otp}`);
    return;
  }

  try {
    const transporter = createTransporter();

    await transporter.sendMail({
      from: env.emailFrom,
      to,
      subject: 'DocBook - Your OTP Code',
      html: `
        <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
          <h2 style="color: #2563eb;">DocBook OTP Verification</h2>
          <p>Your one-time code is:</p>
          <div style="font-size: 32px; font-weight: bold; letter-spacing: 8px; padding: 16px; text-align: center; background: #f3f4f6; border-radius: 8px; margin: 16px 0;">
            ${otp}
          </div>
          <p style="color: #6b7280; font-size: 14px;">This code expires in 10 minutes.</p>
          <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 24px 0;" />
          <p style="color: #9ca3af; font-size: 12px;">If you did not request this, please ignore this email.</p>
        </div>
      `,
    });
  } catch (error) {
    console.warn(`[EMAIL] Failed to send OTP to ${maskEmail(to)}; falling back to OTP log`, safeEmailError(error));
    console.log(`[OTP_FALLBACK] OTP for ${maskEmail(to)}: ${otp}`);
  }
}

async function sendSmtpTestEmail(to: string): Promise<void> {
  if (!isSmtpConfigured()) {
    throw new Error('SMTP is not configured. Set SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, and EMAIL_FROM.');
  }
  if (!to || !to.includes('@')) {
    throw new Error('SMTP_TEST_TO must be a valid email address.');
  }

  const transporter = createTransporter();
  await transporter.sendMail({
    from: env.emailFrom,
    to,
    subject: 'DocBook SMTP Test',
    html: `
      <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
        <h2>DocBook SMTP Test</h2>
        <p>This confirms production SMTP is configured and can send email.</p>
      </div>
    `,
  });
}

export { sendOtpEmail, sendSmtpTestEmail, isSmtpConfigured, maskEmail, safeEmailError };
