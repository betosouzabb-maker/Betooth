import { Router } from 'express';
import { requireAuth } from '../auth/auth.middleware';
import { reportsController } from './reports.controller';

export const reportsRoutes = Router();

reportsRoutes.get('/', requireAuth, reportsController.list);