import { Router } from 'express';
import { AuthController } from '../controllers/authController';
import { authenticate } from '../middleware/auth';

const router = Router();
const controller = new AuthController();

router.post('/register', controller.register.bind(controller));
router.post('/login', controller.login.bind(controller));
router.post('/verify-otp', controller.verifyOtp.bind(controller));
router.post('/resend-otp', controller.resendOtp.bind(controller));
router.post('/refresh', controller.refreshToken.bind(controller));
router.post('/logout', controller.logout.bind(controller));
router.get('/me', authenticate, controller.getProfile.bind(controller));

export default router;
