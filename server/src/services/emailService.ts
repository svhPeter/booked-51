import nodemailer from 'nodemailer';
import type Mail from 'nodemailer/lib/mailer';
import { env } from '../config/env';
import { logger } from '../config/logger';

const SMTP_TIMEOUT_MS = 15_000;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

export function maskEmail(email: string): string {
  const [local, domain] = email.split('@');
  if (!local || !domain) return '***';
  const visible = local.length <= 2 ? local[0] : local.slice(0, 2);
  return `${visible}***@${domain}`;
}

export function isSmtpConfigured(): boolean {
  if (!env.smtpHost || !env.smtpUser || !env.smtpPass) return false;
  if (env.smtpUser.startsWith('your-') || env.smtpUser.startsWith('placeholder')) return false;
  if (env.smtpPass.startsWith('your-') || env.smtpPass.startsWith('placeholder')) return false;
  return true;
}

export function safeEmailError(error: unknown): Record<string, string> {
  if (!error || typeof error !== 'object') return { message: 'Unknown email error' };
  const e = error as { message?: string; code?: string; command?: string; responseCode?: number };
  return {
    message: e.message || 'Unknown email error',
    ...(e.code ? { code: e.code } : {}),
    ...(e.command ? { command: e.command } : {}),
    ...(e.responseCode ? { responseCode: String(e.responseCode) } : {}),
  };
}

// ---------------------------------------------------------------------------
// Singleton transporter — reuses TCP/TLS connections across calls
// ---------------------------------------------------------------------------

let _transporter: Mail | null = null;

function getTransporter(): Mail {
  if (_transporter) return _transporter;
  _transporter = nodemailer.createTransport({
    host: env.smtpHost,
    port: env.smtpPort,
    secure: env.smtpPort === 465,
    auth: { user: env.smtpUser, pass: env.smtpPass },
    pool: true,              // keep connections alive
    maxConnections: 3,
    maxMessages: 100,
    connectionTimeout: SMTP_TIMEOUT_MS,
    greetingTimeout: SMTP_TIMEOUT_MS,
    socketTimeout: SMTP_TIMEOUT_MS,
  });

  _transporter.on('error', (err) => {
    logger.warn('smtp_transporter_error', safeEmailError(err));
    _transporter = null;     // force reconnect next time
  });

  return _transporter;
}

// ---------------------------------------------------------------------------
// Email result type
// ---------------------------------------------------------------------------

export interface EmailSendResult {
  sent: boolean;
  fallback: boolean;
  durationMs: number;
  error?: Record<string, string>;
}

// ---------------------------------------------------------------------------
// Templates
// ---------------------------------------------------------------------------

type OtpTemplate = 'signup' | 'doctor_onboarding' | 'forgot_password' | 'resend';

function otpSubject(template: OtpTemplate): string {
  switch (template) {
    case 'signup':            return 'DocBook – Verify Your Account';
    case 'doctor_onboarding': return 'DocBook – Doctor Registration Verification';
    case 'forgot_password':   return 'DocBook – Password Reset Code';
    case 'resend':            return 'DocBook – Your New Verification Code';
  }
}

function otpHtml(otp: string, template: OtpTemplate): string {
  const heading: Record<OtpTemplate, string> = {
    signup: 'Verify Your Account',
    doctor_onboarding: 'Doctor Registration Verification',
    forgot_password: 'Password Reset Code',
    resend: 'Your New Verification Code',
  };
  const note: Record<OtpTemplate, string> = {
    signup: 'Use this code to complete your DocBook account registration.',
    doctor_onboarding: 'Use this code to complete your doctor registration on DocBook.',
    forgot_password: 'Use this code to reset your DocBook password.',
    resend: 'Here is a fresh verification code for your DocBook account.',
  };

  return `
    <div style="font-family: 'Segoe UI', sans-serif; max-width: 480px; margin: 0 auto; padding: 24px;">
      <h2 style="color: #2563eb; margin-bottom: 4px;">${heading[template]}</h2>
      <p style="color: #374151; margin-top: 4px;">${note[template]}</p>
      <div style="font-size: 32px; font-weight: bold; letter-spacing: 8px; padding: 16px; text-align: center; background: #f3f4f6; border-radius: 8px; margin: 16px 0;">
        ${otp}
      </div>
      <p style="color: #6b7280; font-size: 14px;">This code expires in 10 minutes.</p>
      <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 24px 0;" />
      <p style="color: #9ca3af; font-size: 12px;">If you did not request this, please ignore this email.</p>
    </div>
  `;
}

// ---------------------------------------------------------------------------
// Unified OTP email sender — ALL paths must use this
// ---------------------------------------------------------------------------

export async function sendOtpEmail(
  to: string,
  otp: string,
  template: OtpTemplate = 'signup',
): Promise<EmailSendResult> {
  const startMs = Date.now();
  const masked = maskEmail(to);

  if (!isSmtpConfigured()) {
    const durationMs = Date.now() - startMs;
    logger.warn('otp_email_fallback', {
      event: 'OTP_FALLBACK',
      reason: 'SMTP not configured',
      template,
      email: masked,
      durationMs,
    });
    return { sent: false, fallback: true, durationMs };
  }

  try {
    const transporter = getTransporter();
    await transporter.sendMail({
      from: env.emailFrom,
      to,
      subject: otpSubject(template),
      html: otpHtml(otp, template),
    });

    const durationMs = Date.now() - startMs;
    logger.info('otp_email_sent', {
      template,
      email: masked,
      sent: true,
      durationMs,
    });
    return { sent: true, fallback: false, durationMs };

  } catch (error) {
    const durationMs = Date.now() - startMs;
    const safeErr = safeEmailError(error);

    logger.warn('otp_email_failed', {
      event: 'OTP_FALLBACK',
      reason: 'SMTP send failed',
      template,
      email: masked,
      sent: false,
      durationMs,
      ...safeErr,
    });

    // Force transporter reconnect on next attempt
    _transporter = null;

    return { sent: false, fallback: true, durationMs, error: safeErr };
  }
}

// ---------------------------------------------------------------------------
// SMTP test email (used by smtp:test script and admin diagnostic endpoint)
// ---------------------------------------------------------------------------

export async function sendSmtpTestEmail(to: string): Promise<EmailSendResult> {
  const startMs = Date.now();

  if (!isSmtpConfigured()) {
    throw new Error('SMTP is not configured. Set SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, and EMAIL_FROM.');
  }
  if (!to || !to.includes('@')) {
    throw new Error('Recipient must be a valid email address.');
  }

  try {
    const transporter = getTransporter();
    await transporter.sendMail({
      from: env.emailFrom,
      to,
      subject: 'DocBook SMTP Test',
      html: `
        <div style="font-family: 'Segoe UI', sans-serif; max-width: 480px; margin: 0 auto; padding: 24px;">
          <h2 style="color: #2563eb;">DocBook SMTP Test</h2>
          <p>This confirms production SMTP is configured and can send email.</p>
          <p style="color: #6b7280; font-size: 12px;">Sent at ${new Date().toISOString()}</p>
        </div>
      `,
    });
    const durationMs = Date.now() - startMs;
    return { sent: true, fallback: false, durationMs };
  } catch (error) {
    const durationMs = Date.now() - startMs;
    _transporter = null;
    return { sent: false, fallback: false, durationMs, error: safeEmailError(error) };
  }
}

// ---------------------------------------------------------------------------
// Admin diagnostic: send a test email using each OTP template
// ---------------------------------------------------------------------------

export async function sendDiagnosticEmails(to: string): Promise<Record<OtpTemplate, EmailSendResult>> {
  const testOtp = '000000'; // not a real OTP, purely for template render testing
  const templates: OtpTemplate[] = ['signup', 'doctor_onboarding', 'forgot_password', 'resend'];
  const results = {} as Record<OtpTemplate, EmailSendResult>;

  for (const tpl of templates) {
    results[tpl] = await sendOtpEmail(to, testOtp, tpl);
  }

  return results;
}
