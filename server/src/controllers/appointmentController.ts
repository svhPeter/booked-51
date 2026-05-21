import { Response, NextFunction } from 'express';
import { AppointmentService } from '../services/appointmentService';
import { AuthRequest } from '../middleware/auth';

const appointmentService = new AppointmentService();

export class AppointmentController {
  async book(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { doctorId, date, timeSlot, hospitalId, paymentProvider } = req.body;
      const appointment = await appointmentService.book({
        patientId: req.userId!,
        doctorId,
        date,
        timeSlot,
        hospitalId,
        paymentProvider,
      });
      res.status(201).json(appointment);
    } catch (error) {
      next(error);
    }
  }

  async getMyAppointments(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const appointments = await appointmentService.getPatientAppointments(req.userId!);
      res.json({ appointments });
    } catch (error) {
      next(error);
    }
  }

  async getDoctorAppointments(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const appointments = await appointmentService.getDoctorAppointments(req.userId!);
      res.json({ appointments });
    } catch (error) {
      next(error);
    }
  }

  async cancel(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const appointment = await appointmentService.cancel(
        req.params.id,
        req.userId!,
        req.userRole!
      );
      res.json(appointment);
    } catch (error) {
      next(error);
    }
  }

  async complete(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const appointment = await appointmentService.complete(req.params.id);
      res.json(appointment);
    } catch (error) {
      next(error);
    }
  }
}
