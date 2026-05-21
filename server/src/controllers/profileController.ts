import { Response, NextFunction } from 'express';
import { ProfileService } from '../services/profileService';
import { AuthRequest } from '../middleware/auth';

const profileService = new ProfileService();

export class ProfileController {
  async getPatientProfile(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const profile = await profileService.getPatientProfile(req.userId!);
      res.json({ profile });
    } catch (error) {
      next(error);
    }
  }

  async updatePatientProfile(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const profile = await profileService.updatePatientProfile(req.userId!, req.body);
      res.json({ profile });
    } catch (error) {
      next(error);
    }
  }

  async getDoctorProfile(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const profile = await profileService.getDoctorProfile(req.userId!);
      res.json({ profile });
    } catch (error) {
      next(error);
    }
  }

  async updateDoctorProfile(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const profile = await profileService.updateDoctorProfile(req.userId!, req.body);
      res.json({ profile });
    } catch (error) {
      next(error);
    }
  }
}
