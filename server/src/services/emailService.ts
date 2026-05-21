import nodemailer from 'nodemailer';
import { env } from '../config/env';

function isSmtpConfigured(): boolean {
  if (!env.smtpHost || !env.smtpUser || !env.smtpPass) return false;
  if (env.smtpUser.startsWith('your-') || env.smtpUser.startsWith('placeholder')) return false;
  if (env.smtpPass.startsWith('your-') || env.smtpPass.startsWith('placeholder')) return false;
  return true;
}

async function sendOtpEmail(to: string, otp: string): Promise<void> {
  if (!isSmtpConfigured()) {
    console.log(`[DEV] OTP for ${to}: ${otp}`);
    return;
  }

  try {
    const transporter = nodemailer.createTransport({
      host: env.smtpHost,
      port: env.smtpPort,
      secure: env.smtpPort === 465,
      auth: { user: env.smtpUser, pass: env.smtpPass },
    });

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
    console.warn(`[EMAIL] Failed to send OTP to ${to}, falling back to console:`, error);
    console.log(`[DEV] OTP for ${to}: ${otp}`);
  }
}

export { sendOtpEmail, isSmtpConfigured };
