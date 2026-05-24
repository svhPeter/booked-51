import { Response, NextFunction } from 'express';
import { AppointmentService } from '../services/appointmentService';
import { AuthRequest } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';

const appointmentService = new AppointmentService();

export const getDashboardSummary = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const doctorId = req.userId!;
    const summary = await appointmentService.getDoctorDashboardSummary(doctorId);
    res.json({ success: true, summary });
  } catch (error) {
    next(error);
  }
};

export const getMyAppointments = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const doctorId = req.userId!;
    const appointments = await appointmentService.getDoctorAppointments(doctorId);
    res.json({ success: true, appointments });
  } catch (error) {
    next(error);
  }
};

export const getAppointmentById = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const doctorId = req.userId!;
    const appointment = await appointmentService.getDoctorAppointmentById(req.params.id, doctorId);
    if (!appointment) {
      throw new AppError('Appointment not found', 404);
    }
    res.json({ success: true, appointment });
  } catch (error) {
    next(error);
  }
};

export const completeAppointment = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const doctorId = req.userId!;
    const appointment = await appointmentService.getDoctorAppointmentById(req.params.id, doctorId);
    if (!appointment) {
      throw new AppError('Appointment not found', 404);
    }
    const updated = await appointmentService.complete(req.params.id);
    res.json({ success: true, appointment: updated });
  } catch (error) {
    next(error);
  }
};

export const cancelAppointment = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const doctorId = req.userId!;
    const role = req.userRole!;
    const appointment = await appointmentService.cancel(req.params.id, doctorId, role);
    res.json({ success: true, appointment });
  } catch (error) {
    next(error);
  }
};

export const confirmAppointment = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const doctorId = req.userId!;
    const { date, timeSlot } = req.body;
    if (!date || !timeSlot) {
      throw new AppError('Date and time slot are required', 400);
    }
    const updated = await appointmentService.confirm(req.params.id, doctorId, { date, timeSlot });
    res.json({ success: true, appointment: updated });
  } catch (error) {
    next(error);
  }
};
