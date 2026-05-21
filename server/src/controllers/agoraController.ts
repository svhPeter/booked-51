import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { getVideoSession } from '../services/agoraService';

export const getAppointmentVideoSession = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const session = await getVideoSession(req.params.id, req.userId!, req.userRole!);
    res.json({ success: true, session });
  } catch (error) {
    next(error);
  }
};
