import { Request, Response, NextFunction } from 'express';
import { DoctorService } from '../services/doctorService';

const doctorService = new DoctorService();

export class DoctorController {
  async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const { specialty, search, page, limit } = req.query;
      const result = await doctorService.getAll({
        specialty: specialty as string,
        search: search as string,
        page: page ? parseInt(page as string) : undefined,
        limit: limit ? parseInt(limit as string) : undefined,
      });
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async getById(req: Request, res: Response, next: NextFunction) {
    try {
      const doctor = await doctorService.getById(req.params.id);
      res.json(doctor);
    } catch (error) {
      next(error);
    }
  }

  async search(req: Request, res: Response, next: NextFunction) {
    try {
      const { q, specialty } = req.query;
      const result = await doctorService.getAll({
        search: q as string,
        specialty: specialty as string,
      });
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async getSlots(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const { date } = req.query;
      const slots = await doctorService.getAvailableSlots(id, date as string);
      res.json(slots);
    } catch (error) {
      next(error);
    }
  }

  async getSpecialties(_req: Request, res: Response, next: NextFunction) {
    try {
      const specialties = await doctorService.getSpecialties();
      res.json({ specialties });
    } catch (error) {
      next(error);
    }
  }
}
