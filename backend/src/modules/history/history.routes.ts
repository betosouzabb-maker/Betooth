import { Router } from 'express';
import { requireAuth } from '../auth/auth.middleware';
import { historyController } from './history.controller';

export const historyRoutes = Router();

historyRoutes.get('/', requireAuth, historyController.list);