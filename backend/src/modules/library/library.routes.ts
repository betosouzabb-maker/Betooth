import { Router } from 'express';
import { requireAuth } from '../auth/auth.middleware';
import { libraryController } from './library.controller';

export const libraryRoutes = Router();

libraryRoutes.post('/tracks/:trackId/add', requireAuth, libraryController.add);
libraryRoutes.delete('/tracks/:trackId', requireAuth, libraryController.remove);
