import { Router } from 'express';
import { requireAuth } from '../auth/auth.middleware';
import { usersController } from './users.controller';

export const usersRoutes = Router();

usersRoutes.get('/', requireAuth, usersController.list);
usersRoutes.get('/me', requireAuth, usersController.me);
usersRoutes.get('/me/library', requireAuth, usersController.listLibrary);
usersRoutes.get('/me/favorites', requireAuth, usersController.listFavorites);
