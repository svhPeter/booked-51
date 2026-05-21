import { Router } from 'express';
import { AppointmentController } from '../controllers/appointmentController';
import { authenticate, authorize } from '../middleware/auth';

const router = Router();
const controller = new AppointmentController();

router.post('/', authenticate, authorize('patient'), controller.book.bind(controller));
router.get('/my', authenticate, controller.getMyAppointments.bind(controller));
router.get('/doctor', authenticate, authorize('doctor'), controller.getDoctorAppointments.bind(controller));
router.put('/:id/cancel', authenticate, controller.cancel.bind(controller));
router.put('/:id/complete', authenticate, authorize('doctor'), controller.complete.bind(controller));

export default router;
