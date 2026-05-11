import express, { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { requireAuth } from '../auth/auth.middleware';
import { requireVip } from '../../common/middleware/vip-guard';
import { AuthenticatedRequest } from '../../common/types';
import { uploadsController } from './uploads.controller';

export const uploadsRoutes = Router();

const uploadInitRateLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  limit: 10,
  keyGenerator: (req) => {
    const userId = (req as AuthenticatedRequest).user?.userId;
    return userId ?? (req.ip ?? 'unknown');
  },
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: {
    success: false,
    error: {
      message: 'Limite de 10 uploads por hora atingido.',
      code: 'UPLOAD_RATE_LIMIT_EXCEEDED',
    },
  },
});

uploadsRoutes.get('/', requireAuth, uploadsController.list);

uploadsRoutes.post('/init', requireAuth, requireVip, uploadInitRateLimiter, uploadsController.initUpload);

uploadsRoutes.put(
  '/:id/chunk',
  requireAuth,
  requireVip,
  express.raw({ type: 'application/octet-stream', limit: '10mb' }),
  uploadsController.uploadChunk
);

uploadsRoutes.post('/:id/complete', requireAuth, requireVip, uploadsController.completeUpload);

uploadsRoutes.get('/:id/status', requireAuth, uploadsController.getUploadStatus);

uploadsRoutes.post('/:id/cancel', requireAuth, uploadsController.cancelUpload);
