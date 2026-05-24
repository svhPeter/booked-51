import { Response, NextFunction } from 'express';
import { MessageService } from '../services/messageService';
import { AuthRequest } from '../middleware/auth';

const messageService = new MessageService();

export class MessageController {
  async list(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const limit = req.query.limit ? parseInt(String(req.query.limit), 10) : 50;
      const messages = await messageService.listMessages(
        req.params.id,
        req.userId!,
        req.userRole!,
        limit,
      );
      res.json({ messages });
    } catch (error) {
      next(error);
    }
  }

  async send(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const message = await messageService.sendMessage(
        req.params.id,
        req.userId!,
        req.userRole!,
        req.body.content,
      );
      res.status(201).json({ message });
    } catch (error) {
      next(error);
    }
  }

  async markRead(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const result = await messageService.markRead(
        req.params.id,
        req.userId!,
        req.userRole!,
      );
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async unreadCount(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const result = await messageService.unreadCount(
        req.params.id,
        req.userId!,
        req.userRole!,
      );
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async conversations(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const list = await messageService.listConversations(
        req.userId!,
        req.userRole!
      );
      res.json({ conversations: list });
    } catch (error) {
      next(error);
    }
  }
}
