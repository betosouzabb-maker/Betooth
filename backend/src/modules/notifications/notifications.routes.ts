import { Router } from 'express';
import { requireAuth } from '../auth/auth.middleware';
import { notificationsController } from './notifications.controller';

export const notificationsRoutes = Router();

notificationsRoutes.get('/', requireAuth, notificationsController.list);