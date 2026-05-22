import dotenv from 'dotenv';
import { isSmtpConfigured, maskEmail, safeEmailError, sendSmtpTestEmail } from '../src/services/emailService';

dotenv.config();

async function main() {
  const to = process.env.SMTP_TEST_TO?.trim();
  if (!to) {
    throw new Error('SMTP_TEST_TO is required. Example: SMTP_TEST_TO=you@example.com npm run smtp:test');
  }
  if (!isSmtpConfigured()) {
    throw new Error('SMTP is not configured. Set SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, and EMAIL_FROM.');
  }

  await sendSmtpTestEmail(to);
  console.log(`SMTP test email sent to ${maskEmail(to)}`);
}

main().catch((error) => {
  console.error('SMTP test failed', safeEmailError(error));
  process.exit(1);
});
