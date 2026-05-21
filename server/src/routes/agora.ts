import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import { getAppointmentVideoSession } from '../controllers/agoraController';

const router = Router();

router.get('/appointments/:id/video-session', authenticate, getAppointmentVideoSession);

export default router;
