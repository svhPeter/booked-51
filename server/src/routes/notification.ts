import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import { listNotifications, readNotification, readAllNotifications, unreadCount } from '../controllers/notificationController';

const router = Router();

router.get('/', authenticate, listNotifications);
router.put('/:id/read', authenticate, readNotification);
router.put('/read-all', authenticate, readAllNotifications);
router.get('/unread-count', authenticate, unreadCount);

export default router;
