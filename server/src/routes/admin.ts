import { Router } from 'express';
import { authenticate, authorize } from '../middleware/auth';
import {
  getDashboardSummary,
  listDoctors,
  getDoctorById,
  listPatients,
  getPatientById,
  listAppointments,
  getAppointmentById,
  listPayments,
  approveDoctor,
  rejectDoctor,
  setDoctorActive,
  getAppointmentChatMeta,
} from '../controllers/adminController';

const router = Router();

router.use(authenticate);
router.use(authorize('admin'));

router.get('/dashboard/summary', getDashboardSummary);
router.get('/doctors', listDoctors);
router.put('/doctors/:id/approve', approveDoctor);
router.put('/doctors/:id/reject', rejectDoctor);
router.put('/doctors/:id/active', setDoctorActive);
router.get('/doctors/:id', getDoctorById);
router.get('/patients', listPatients);
router.get('/patients/:id', getPatientById);
router.get('/appointments', listAppointments);
router.get('/appointments/:id/chat-meta', getAppointmentChatMeta);
router.get('/appointments/:id', getAppointmentById);
router.get('/payments', listPayments);

export default router;
