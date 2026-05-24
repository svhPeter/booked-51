import { Router } from 'express';
import { authenticate, authorize } from '../middleware/auth';
import {
  getDashboardSummary,
  getMyAppointments,
  getAppointmentById,
  completeAppointment,
  cancelAppointment,
  confirmAppointment,
} from '../controllers/doctorDashboardController';

const router = Router();

router.use(authenticate);
router.use(authorize('doctor', 'admin'));

router.get('/dashboard/summary', getDashboardSummary);
router.get('/appointments', getMyAppointments);
router.get('/appointments/:id', getAppointmentById);
router.put('/appointments/:id/complete', completeAppointment);
router.put('/appointments/:id/cancel', cancelAppointment);
router.put('/appointments/:id/confirm', confirmAppointment);

export default router;
