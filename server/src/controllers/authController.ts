import { Request, Response, NextFunction } from 'express';
import { AuthService } from '../services/authService';
import { AuthRequest } from '../middleware/auth';

const authService = new AuthService();

export class AuthController {
  async register(req: Request, res: Response, next: NextFunction) {
    try {
      const { name, email, phone, password, city, role } = req.body;
      const result = await authService.register({ name, email, phone, password, city, role });
      res.status(201).json(result);
    } catch (error) {
      next(error);
    }
  }

  async registerDoctor(req: Request, res: Response, next: NextFunction) {
    try {
      const {
        name,
        email,
        phone,
        password,
        specialty,
        city,
        clinicName,
        consultationFee,
        pmdcRegistrationNumber,
      } = req.body;
      const result = await authService.registerDoctor({
        name,
        email,
        phone,
        password,
        specialty,
        city,
        clinicName,
        consultationFee,
        pmdcRegistrationNumber,
      });
      res.status(201).json(result);
    } catch (error) {
      next(error);
    }
  }

  async login(req: Request, res: Response, next: NextFunction) {
    try {
      const { email, password } = req.body;
      const result = await authService.login(email, password);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async verifyOtp(req: Request, res: Response, next: NextFunction) {
    try {
      const { email, otp } = req.body;
      const result = await authService.verifyOtp(email, otp);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async resendOtp(req: Request, res: Response, next: NextFunction) {
    try {
      const { email } = req.body;
      await authService.resendOtp(email);
      res.json({ message: 'OTP resent successfully' });
    } catch (error) {
      next(error);
    }
  }

  async forgotPassword(req: Request, res: Response, next: NextFunction) {
    try {
      const { email } = req.body;
      await authService.forgotPassword(email);
      res.json({ message: 'If an account exists for this email, a reset code has been sent.' });
    } catch (error) {
      next(error);
    }
  }

  async resetPassword(req: Request, res: Response, next: NextFunction) {
    try {
      const { email, otp, newPassword } = req.body;
      await authService.resetPassword(email, otp, newPassword);
      res.json({ message: 'Password reset successfully' });
    } catch (error) {
      next(error);
    }
  }

  async refreshToken(req: Request, res: Response, next: NextFunction) {
    try {
      const { refreshToken } = req.body;
      const tokens = await authService.refreshToken(refreshToken);
      res.json(tokens);
    } catch (error) {
      next(error);
    }
  }

  async getProfile(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const profile = await authService.getProfile(req.userId!);
      res.json({ user: profile });
    } catch (error) {
      next(error);
    }
  }

  async logout(_req: Request, res: Response) {
    res.json({ message: 'Logged out successfully' });
  }
}
