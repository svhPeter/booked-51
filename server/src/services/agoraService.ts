import { env } from '../config/env';
import { prisma } from '../config/database';
import { logger } from '../config/logger';
import { AppError } from '../middleware/errorHandler';

const AGORA_APP_ID = env.agoraAppId;
const AGORA_CERTIFICATE = env.agoraCertificate;

function generateChannelName(appointmentId: string): string {
  return `appt_${appointmentId}`;
}

function generateMockToken(channelName: string): string {
  return `mock_token_${channelName}_${Date.now()}`;
}

async function generateRealToken(channelName: string, uid: number): Promise<string> {
  const { RtcTokenBuilder, RtcRole } = await import('agora-access-token');
  const expirationTimeInSeconds = 3600;
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

  const token = RtcTokenBuilder.buildTokenWithUid(
    AGORA_APP_ID,
    AGORA_CERTIFICATE,
    channelName,
    uid,
    RtcRole.PUBLISHER,
    privilegeExpiredTs,
  );
  return token;
}

function isMockMode(): boolean {
  return !AGORA_APP_ID || AGORA_APP_ID.startsWith('your-') || !AGORA_CERTIFICATE || AGORA_CERTIFICATE.startsWith('your-');
}

export async function getVideoSession(appointmentId: string, userId: string, userRole: string) {
  const appointment = await prisma.appointment.findUnique({
    where: { id: appointmentId },
    select: {
      id: true,
      patientId: true,
      doctorId: true,
      status: true,
      date: true,
      timeSlot: true,
    },
  });

  if (!appointment) {
    throw new AppError('Appointment not found', 404);
  }

  if (appointment.status === 'cancelled') {
    throw new AppError('Cannot join video session: appointment is cancelled', 403);
  }
  if (appointment.status === 'completed') {
    throw new AppError('Cannot join video session: appointment is completed', 403);
  }
  if (appointment.status !== 'confirmed') {
    throw new AppError('Cannot join video session: appointment is not confirmed', 403);
  }

  const isPatient = appointment.patientId === userId;
  const isDoctor = appointment.doctorId === userId;
  const isAdmin = userRole === 'admin';

  if (!isPatient && !isDoctor && !isAdmin) {
    throw new AppError('Access denied: you are not a participant in this appointment', 403);
  }

  const channelName = generateChannelName(appointmentId);

  if (isAdmin) {
    logger.info('video_session_admin', { appointmentId, channelName });
    return {
      appId: AGORA_APP_ID || 'mock_app_id',
      channelName,
      token: '',
      isMock: true,
      message: 'Admin view: video session metadata only',
    };
  }

  const isMock = isMockMode();
  const uid = userId === appointment.patientId ? 1 : 2;

  let token: string;
  if (isMock) {
    token = generateMockToken(channelName);
  } else {
    token = await generateRealToken(channelName, uid);
  }

  logger.info('video_session_created', { appointmentId, userId, uid, isMock });

  return {
    appId: isMock ? 'mock_app_id' : AGORA_APP_ID,
    channelName,
    token,
    uid,
    isMock,
  };
}
