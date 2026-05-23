import { Response, NextFunction } from 'express';
import { AdminService } from '../services/adminService';
import { MessageService } from '../services/messageService';
import { AuthRequest } from '../middleware/auth';

const adminService = new AdminService();
const messageService = new MessageService();

export const getDashboardSummary = async (_req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const summary = await adminService.getDashboardSummary();
    res.json({ success: true, summary });
  } catch (error) {
    next(error);
  }
};

export const listDoctors = async (_req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const doctors = await adminService.listDoctors();
    res.json({ success: true, doctors });
  } catch (error) {
    next(error);
  }
};

export const getDoctorById = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const doctor = await adminService.getDoctorById(req.params.id);
    res.json({ success: true, doctor });
  } catch (error) {
    next(error);
  }
};

export const listPatients = async (_req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const patients = await adminService.listPatients();
    res.json({ success: true, patients });
  } catch (error) {
    next(error);
  }
};

export const getPatientById = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const patient = await adminService.getPatientById(req.params.id);
    res.json({ success: true, patient });
  } catch (error) {
    next(error);
  }
};

export const listAppointments = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { status, doctorId, dateFrom, dateTo } = req.query as any;
    const appointments = await adminService.listAppointments({ status, doctorId, dateFrom, dateTo });
    res.json({ success: true, appointments });
  } catch (error) {
    next(error);
  }
};

export const getAppointmentById = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const appointment = await adminService.getAppointmentById(req.params.id);
    res.json({ success: true, appointment });
  } catch (error) {
    next(error);
  }
};

export const listPayments = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { status, provider } = req.query as any;
    const payments = await adminService.listPayments({ status, provider });
    res.json({ success: true, payments });
  } catch (error) {
    next(error);
  }
};

export const approveDoctor = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const result = await adminService.approveDoctor(req.params.id);
    res.json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};

export const rejectDoctor = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const result = await adminService.rejectDoctor(req.params.id);
    res.json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};

export const setDoctorActive = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { isActive } = req.body;
    const result = await adminService.setDoctorActive(req.params.id, Boolean(isActive));
    res.json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};

export const getAppointmentChatMeta = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const meta = await messageService.getChatMeta(req.params.id);
    res.json({ success: true, meta });
  } catch (error) {
    next(error);
  }
};

export const emailDiagnostic = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { sendDiagnosticEmails, getEmailProvider, maskEmail } = await import('../services/emailService');
    const to = (req.body.to as string)?.trim();

    if (!to || !to.includes('@')) {
      res.status(400).json({ error: 'Valid "to" email address required in request body.' });
      return;
    }

    const provider = getEmailProvider();
    if (provider === 'none') {
      res.json({
        success: false,
        provider,
        configured: false,
        message: 'No email provider configured. Set EMAIL_PROVIDER=brevo + BREVO_API_KEY, or configure SMTP.',
      });
      return;
    }

    const results = await sendDiagnosticEmails(to);
    // Only return sent/durationMs/provider per template — never expose secrets
    const safe: Record<string, { sent: boolean; durationMs: number; provider: string; error?: string }> = {};
    for (const [tpl, r] of Object.entries(results)) {
      safe[tpl] = {
        sent: r.sent,
        durationMs: r.durationMs,
        provider: r.provider,
        ...(r.error ? { error: r.error.message } : {}),
      };
    }

    res.json({
      success: true,
      provider,
      configured: true,
      recipientMasked: maskEmail(to),
      templates: safe,
    });
  } catch (error) {
    next(error);
  }
};
