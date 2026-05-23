import dotenv from 'dotenv';
import { isSmtpConfigured, maskEmail, sendSmtpTestEmail } from '../src/services/emailService';

dotenv.config();

async function main() {
  const to = process.env.SMTP_TEST_TO?.trim();
  if (!to) {
    throw new Error('SMTP_TEST_TO is required. Example: SMTP_TEST_TO=you@example.com npm run smtp:test');
  }
  if (!isSmtpConfigured()) {
    throw new Error('SMTP is not configured. Set SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, and EMAIL_FROM.');
  }

  console.log(`Sending SMTP test email to ${maskEmail(to)}...`);
  const result = await sendSmtpTestEmail(to);

  if (result.sent) {
    console.log(`✅ SMTP test email sent to ${maskEmail(to)} in ${result.durationMs}ms`);
  } else {
    console.error(`❌ SMTP test email FAILED for ${maskEmail(to)} in ${result.durationMs}ms`);
    if (result.error) {
      console.error('Error:', result.error);
    }
    process.exit(1);
  }
}

main().catch((error) => {
  console.error('SMTP test failed:', error instanceof Error ? error.message : String(error));
  process.exit(1);
});
