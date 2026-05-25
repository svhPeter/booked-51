import dotenv from 'dotenv';
dotenv.config();

function missing(name: string): never {
  console.error(`[FATAL] Missing required environment variable: ${name}`);
  console.error(`  Set ${name} in server/.env before starting.`);
  process.exit(1);
}

function isPlaceholder(v: string): boolean {
  return v.startsWith('your-') || v === 'fallback-secret' || v === 'fallback-refresh-secret' || v === 'redis://localhost:6379';
}

const nodeEnv = process.env.NODE_ENV || 'development';
const isProd = nodeEnv === 'production';

const databaseUrl = process.env.DATABASE_URL;
const directUrl = process.env.DIRECT_URL;
const jwtSecret = process.env.JWT_SECRET;
const jwtRefreshSecret = process.env.JWT_REFRESH_SECRET;

if (!databaseUrl) missing('DATABASE_URL');
if (!directUrl) missing('DIRECT_URL');
if (!jwtSecret) missing('JWT_SECRET');
if (!jwtRefreshSecret) missing('JWT_REFRESH_SECRET');

if (isProd) {
  if (isPlaceholder(jwtSecret)) {
    console.error('[FATAL] JWT_SECRET is set to a placeholder value in production mode.');
    process.exit(1);
  }
  if (isPlaceholder(jwtRefreshSecret)) {
    console.error('[FATAL] JWT_REFRESH_SECRET is set to a placeholder value in production mode.');
    process.exit(1);
  }
}

if (!isProd) {
  if (!process.env.SMTP_HOST || !process.env.SMTP_USER || !process.env.SMTP_PASS) {
    console.log('[DEV] SMTP not configured — OTP codes will be printed to console');
  }
  if (!process.env.REDIS_URL) {
    console.log('[DEV] REDIS_URL not set — using in-memory OTP storage');
  }
  if (!process.env.STRIPE_SECRET_KEY || process.env.STRIPE_SECRET_KEY.startsWith('sk_test_your-')) {
    console.log('[DEV] Stripe not configured — use "mock" payment provider for local dev');
  }
  if (!process.env.AGORA_APP_ID || process.env.AGORA_APP_ID.startsWith('your-')) {
    console.log('[DEV] Agora not configured — video calls will use mock mode');
  }
}

export const env = {
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv,

  databaseUrl,
  directUrl,

  jwtSecret,
  jwtRefreshSecret,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '15m',
  jwtRefreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',

  redisUrl: process.env.REDIS_URL || '',

  smtpHost: process.env.SMTP_HOST || '',
  smtpPort: parseInt(process.env.SMTP_PORT || '587', 10),
  smtpUser: process.env.SMTP_USER || '',
  smtpPass: process.env.SMTP_PASS || '',
  emailFrom: process.env.EMAIL_FROM || 'noreply@docbook.com',
  emailFromName: process.env.EMAIL_FROM_NAME || 'DocBook',
  emailProvider: (process.env.EMAIL_PROVIDER || 'smtp').toLowerCase(),
  brevoApiKey: process.env.BREVO_API_KEY || '',

  stripeSecretKey: process.env.STRIPE_SECRET_KEY || '',
  stripeWebhookSecret: process.env.STRIPE_WEBHOOK_SECRET || '',

  payfastApiKey: process.env.PAYFAST_API_KEY || '',
  payfastSecretKey: process.env.PAYFAST_SECRET_KEY || '',
  payfastBaseUrl: process.env.PAYFAST_BASE_URL || '',

  agoraAppId: process.env.AGORA_APP_ID || '',
  agoraCertificate: process.env.AGORA_APP_CERTIFICATE || process.env.AGORA_CERTIFICATE || '',

  firebaseServerKey: process.env.FIREBASE_SERVER_KEY || '',

  frontendUrls: (process.env.FRONTEND_URL || 'http://localhost:8080').split(',').map(s => s.trim()),
};
