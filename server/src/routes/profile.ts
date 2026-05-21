import { Router } from 'express';
import { ProfileController } from '../controllers/profileController';
import { authenticate, authorize } from '../middleware/auth';

const router = Router();
const controller = new ProfileController();

router.get('/patients/me', authenticate, authorize('patient'), controller.getPatientProfile.bind(controller));
router.put('/patients/me', authenticate, authorize('patient'), controller.updatePatientProfile.bind(controller));
router.get('/doctor/profile', authenticate, authorize('doctor', 'admin'), controller.getDoctorProfile.bind(controller));
router.put('/doctor/profile', authenticate, authorize('doctor'), controller.updateDoctorProfile.bind(controller));

export default router;
