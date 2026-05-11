import { Router } from 'express';
import { requireAuth } from '../auth/auth.middleware';
import { checkDownloadQuota } from '../../common/middleware/download-quota.middleware';
import { tracksController } from './tracks.controller';

export const tracksRoutes = Router();

tracksRoutes.get('/:id/download-url', requireAuth, checkDownloadQuota, tracksController.getDownloadUrl);
