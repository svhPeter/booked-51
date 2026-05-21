import { Router } from 'express';
import { DoctorController } from '../controllers/doctorController';

const router = Router();
const controller = new DoctorController();

router.get('/', controller.getAll.bind(controller));
router.get('/search', controller.search.bind(controller));
router.get('/specialties', controller.getSpecialties.bind(controller));
router.get('/:id', controller.getById.bind(controller));
router.get('/:id/slots', controller.getSlots.bind(controller));

export default router;
