import { Router } from 'express';
import { AppointmentController } from '../controllers/appointmentController';
import { MessageController } from '../controllers/messageController';
import { authenticate, authorize } from '../middleware/auth';

const router = Router();
const controller = new AppointmentController();
const messageController = new MessageController();

router.post('/', authenticate, authorize('patient'), controller.book.bind(controller));
router.get('/my', authenticate, controller.getMyAppointments.bind(controller));
router.get('/doctor', authenticate, authorize('doctor'), controller.getDoctorAppointments.bind(controller));
router.get('/conversations/active', authenticate, messageController.conversations.bind(messageController));
router.get('/:id/messages/unread-count', authenticate, messageController.unreadCount.bind(messageController));
router.get('/:id/messages', authenticate, messageController.list.bind(messageController));
router.post('/:id/messages', authenticate, messageController.send.bind(messageController));
router.put('/:id/messages/read', authenticate, messageController.markRead.bind(messageController));
router.get('/:id', authenticate, controller.getById.bind(controller));
router.put('/:id/cancel', authenticate, controller.cancel.bind(controller));
router.put('/:id/complete', authenticate, authorize('doctor'), controller.complete.bind(controller));

export default router;
