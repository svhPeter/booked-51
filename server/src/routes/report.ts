import { Router } from 'express';
import { authenticate, authorize } from '../middleware/auth';
import { submitReport, listReports } from '../controllers/reportController';

const router = Router();

// Any authenticated user can submit a report
router.post('/', authenticate, submitReport);

// Admin-only: view reports
router.get('/', authenticate, authorize('admin'), listReports);

export default router;
