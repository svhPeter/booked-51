import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { createServer } from 'http';
import { Server } from 'socket.io';
import { env } from './config/env';
import { connectDatabase } from './config/database';
import { logger } from './config/logger';
import { errorHandler, notFoundHandler } from './middleware/errorHandler';
import authRoutes from './routes/auth';
import doctorRoutes from './routes/doctor';
import appointmentRoutes from './routes/appointment';
import paymentRoutes from './routes/payment';
import doctorDashboardRoutes from './routes/doctorDashboard';
import adminRoutes from './routes/admin';
import agoraRoutes from './routes/agora';
import notificationRoutes from './routes/notification';
import profileRoutes from './routes/profile';
import reportRoutes from './routes/report';
import uploadRoutes from './routes/upload';
import { isSmtpConfigured, getEmailProvider } from './services/emailService';
import path from 'path';

const app = express();
const httpServer = createServer(app);

const io = new Server(httpServer, {
  cors: {
    origin: env.frontendUrls,
    methods: ['GET', 'POST'],
  },
});

app.use(helmet({
  contentSecurityPolicy: env.nodeEnv === 'production' ? undefined : false,
}));

app.use(cors({
  origin: env.nodeEnv === 'development'
    ? true
    : env.frontendUrls,
  credentials: true,
}));

app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static(path.join(process.cwd(), 'uploads')));

app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    logger.info('request', {
      method: req.method,
      path: req.path,
      status: res.statusCode,
      duration: Date.now() - start,
    });
  });
  next();
});

const authLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests. Please try again later.' },
});

const strictLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests. Please try again later.' },
});

app.use('/api/v1/auth/login', authLimiter);
app.use('/api/v1/auth/register', strictLimiter);
app.use('/api/v1/auth/register-doctor', strictLimiter);
app.use('/api/v1/auth/resend-otp', strictLimiter);
app.use('/api/v1/auth/forgot-password', strictLimiter);

app.get('/api/v1/health', async (_req, res) => {
  let dbStatus = 'unknown';
  try {
    const { prisma } = await import('./config/database');
    await prisma.$queryRaw`SELECT 1`;
    dbStatus = 'healthy';
  } catch {
    dbStatus = 'unhealthy';
  }
  const provider = getEmailProvider();
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    database: dbStatus,
    uptime: process.uptime(),
    email: {
      provider,
      configured: provider !== 'none',
    },
  });
});

app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/doctors', doctorRoutes);
app.use('/api/v1/appointments', appointmentRoutes);
app.use('/api/v1/payments', paymentRoutes);
app.use('/api/v1/doctor', doctorDashboardRoutes);
app.use('/api/v1/admin', adminRoutes);
app.use('/api/v1', agoraRoutes);
app.use('/api/v1/notifications', notificationRoutes);
app.use('/api/v1', profileRoutes);
app.use('/api/v1/reports', reportRoutes);
app.use('/api/v1/uploads', uploadRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

io.on('connection', (socket) => {
  socket.on('join', (userId: string) => {
    socket.join(`user:${userId}`);
  });

  socket.on('join-appointment', async (payload: { appointmentId: string; userId: string }) => {
    try {
      const { prisma } = await import('./config/database');
      const appointment = await prisma.appointment.findUnique({
        where: { id: payload.appointmentId },
      });
      if (
        appointment &&
        (appointment.patientId === payload.userId || appointment.doctorId === payload.userId)
      ) {
        socket.join(`appointment:${payload.appointmentId}`);
      }
    } catch {
      // ignore invalid join
    }
  });

  socket.on('disconnect', () => {
  });
});

export { io };

async function start() {
  await connectDatabase();
  const provider = getEmailProvider();
  logger.info('server_start', { port: env.port, nodeEnv: env.nodeEnv });
  logger.info('email_provider', { provider });
  if (env.nodeEnv === 'production' && provider === 'none') {
    logger.warn('email_not_configured', {
      message: 'No email provider configured. Set EMAIL_PROVIDER=brevo + BREVO_API_KEY for production.',
    });
  }

  httpServer.listen(env.port, () => {
    logger.info('server_listening', { port: env.port, nodeEnv: env.nodeEnv });
  });
}

start().catch((err) => {
  logger.error('server_start_failed', { message: (err as Error).message });
  process.exit(1);
});
