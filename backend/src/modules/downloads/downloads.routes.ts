import { Router } from 'express';
import { requireAuth } from '../auth/auth.middleware';
import { subscriptionsController } from '../subscriptions/subscriptions.controller';

export const downloadsRoutes = Router();

downloadsRoutes.get('/quota', requireAuth, subscriptionsController.getQuota);
