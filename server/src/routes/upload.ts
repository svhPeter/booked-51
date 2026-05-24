import { Router, Response } from 'express';
import fs from 'fs';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';
import { authenticate } from '../middleware/auth';
import { AuthRequest } from '../middleware/auth';

const router = Router();

router.post('/audio', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const filename = `${uuidv4()}.m4a`;
    const uploadsDir = path.join(process.cwd(), 'uploads');
    const uploadPath = path.join(uploadsDir, filename);

    // Ensure uploads directory exists
    fs.mkdirSync(uploadsDir, { recursive: true });

    const writeStream = fs.createWriteStream(uploadPath);
    req.pipe(writeStream);

    writeStream.on('finish', () => {
      const fileUrl = `${req.protocol}://${req.get('host')}/uploads/${filename}`;
      res.status(201).json({ url: fileUrl });
    });

    writeStream.on('error', (err) => {
      res.status(500).json({ error: `Write failed: ${err.message}` });
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

export default router;
