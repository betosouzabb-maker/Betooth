import { Router } from 'express';
import { authGuard } from '../../common/middleware/auth-guard';
import { musicController } from './music.controller';

export const musicRoutes = Router();

musicRoutes.get('/tracks', musicController.listTracks);
musicRoutes.get('/genres', musicController.listGenres);
musicRoutes.get(
  '/tracks/:id/stream-metadata',
  authGuard,
  musicController.getStreamMetadata,
);
