import { Router } from 'express';
import { requireAuth } from '../auth/auth.middleware';
import { favoritesController } from './favorites.controller';

export const favoritesRoutes = Router();

favoritesRoutes.get('/', requireAuth, favoritesController.list);
favoritesRoutes.post('/:trackId', requireAuth, favoritesController.add);
favoritesRoutes.delete('/:trackId', requireAuth, favoritesController.remove);
