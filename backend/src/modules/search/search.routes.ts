import { Router } from 'express';
import { requireAuth } from '../auth/auth.middleware';
import { searchController } from './search.controller';

export const searchRoutes = Router();

searchRoutes.get('/', requireAuth, searchController.search);
searchRoutes.get('/suggestions', searchController.suggestions);
searchRoutes.get('/recent', requireAuth, searchController.getHistory);
searchRoutes.delete('/recent', requireAuth, searchController.clearHistory);
