import { Router } from 'express';
import { requireAuth } from '../auth/auth.middleware';
import { syncController } from './sync.controller';

export const syncRoutes = Router();

syncRoutes.get('/bootstrap', requireAuth, syncController.bootstrap);
syncRoutes.post('/push', requireAuth, syncController.push);
syncRoutes.get('/pull', requireAuth, syncController.pull);
syncRoutes.post('/ack', requireAuth, syncController.ack);
syncRoutes.get('/state', requireAuth, syncController.state);
syncRoutes.get('/status', requireAuth, syncController.status);
