import dotenv from 'dotenv';
import { getEmailProvider, maskEmail, sendSmtpTestEmail } from '../src/services/emailService';

dotenv.config();

async function main() {
  const to = process.env.SMTP_TEST_TO?.trim();
  if (!to) {
    throw new Error('SMTP_TEST_TO is required. Example: SMTP_TEST_TO=you@example.com npm run smtp:test');
  }

  const provider = getEmailProvider();
  if (provider === 'none') {
    throw new Error('No email provider configured. Set EMAIL_PROVIDER=brevo + BREVO_API_KEY, or configure SMTP.');
  }

  console.log(`Provider: ${provider}`);
  console.log(`Sending test email to ${maskEmail(to)}...`);
  const result = await sendSmtpTestEmail(to);

  if (result.sent) {
    console.log(`✅ Test email sent via ${result.provider} to ${maskEmail(to)} in ${result.durationMs}ms`);
  } else {
    console.error(`❌ Test email FAILED via ${result.provider} for ${maskEmail(to)} in ${result.durationMs}ms`);
    if (result.error) {
      console.error('Error:', result.error);
    }
    process.exit(1);
  }
}

main().catch((error) => {
  console.error('Email test failed:', error instanceof Error ? error.message : String(error));
  process.exit(1);
});
