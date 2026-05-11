import { Router } from 'express';
import { requireAuth } from '../auth/auth.middleware';
import { validate } from '../../common/middleware/validator';
import { z } from 'zod';
import { playlistsController } from './playlists.controller';

export const playlistsRoutes = Router();

const createSchema = z.object({
  body: z.object({
    name: z.string().min(1).max(100),
    description: z.string().max(500).optional(),
    isPublic: z.boolean().optional().default(false),
  }),
});

const updateSchema = z.object({
  body: z.object({
    name: z.string().min(1).max(100).optional(),
    description: z.string().max(500).nullable().optional(),
    coverUrl: z.string().url().nullable().optional(),
    isPublic: z.boolean().optional(),
  }),
});

const addItemSchema = z.object({
  body: z.object({
    trackId: z.string().min(1),
    position: z.number().int().min(0).optional(),
  }),
});

const reorderSchema = z.object({
  body: z.object({
    orderedIds: z.array(z.string().min(1)).min(1),
  }),
});

playlistsRoutes.get('/', requireAuth, playlistsController.list);
playlistsRoutes.post('/', requireAuth, validate(createSchema), playlistsController.create);
playlistsRoutes.get('/:id', requireAuth, playlistsController.getById);
playlistsRoutes.patch('/:id', requireAuth, validate(updateSchema), playlistsController.update);
playlistsRoutes.delete('/:id', requireAuth, playlistsController.delete);
playlistsRoutes.post('/:id/items', requireAuth, validate(addItemSchema), playlistsController.addItem);
playlistsRoutes.patch('/:id/items/reorder', requireAuth, validate(reorderSchema), playlistsController.reorderItems);
playlistsRoutes.delete('/:id/items/:itemId', requireAuth, playlistsController.removeItem);
