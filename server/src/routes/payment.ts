import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import { createPayment, mockPaymentSuccess, getPaymentStatus } from '../controllers/paymentController';

const router = Router();

router.post('/create', authenticate, createPayment);
router.post('/mock-success', authenticate, mockPaymentSuccess);
router.get('/status/:appointmentId', authenticate, getPaymentStatus);

export default router;
