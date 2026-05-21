import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { getNotifications, markAsRead, markAllAsRead, getUnreadCount } from '../services/notificationService';

export const listNotifications = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;
    const result = await getNotifications(req.userId!, page, limit);
    res.json(result);
  } catch (error) {
    next(error);
  }
};

export const readNotification = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const notification = await markAsRead(req.params.id, req.userId!);
    res.json({ notification });
  } catch (error) {
    next(error);
  }
};

export const readAllNotifications = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    await markAllAsRead(req.userId!);
    res.json({ message: 'All notifications marked as read' });
  } catch (error) {
    next(error);
  }
};

export const unreadCount = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const result = await getUnreadCount(req.userId!);
    res.json(result);
  } catch (error) {
    next(error);
  }
};
