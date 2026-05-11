import { NextFunction, Request, Response } from 'express';
import { sendSuccess } from '../../common/utils/response';
import { AppError } from '../../common/middleware/error-handler';
import { AuthenticatedRequest } from '../../common/types';
import { playlistsService } from './playlists.service';

export const playlistsController = {
  async list(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Unauthenticated', 401, 'AUTH_USER_MISSING');
      const result = await playlistsService.list(req.user.id, req);
      return sendSuccess(res, 200, result.items, { pagination: result.pagination });
    } catch (error) {
      return next(error);
    }
  },

  async create(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Unauthenticated', 401, 'AUTH_USER_MISSING');
      const result = await playlistsService.create(req.user.id, req.body as { name: string; description?: string; isPublic?: boolean });
      return sendSuccess(res, 201, result);
    } catch (error) {
      return next(error);
    }
  },

  async getById(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Unauthenticated', 401, 'AUTH_USER_MISSING');
      const { id } = req.params as { id: string };
      const result = await playlistsService.getById(id, req.user.id);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async update(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Unauthenticated', 401, 'AUTH_USER_MISSING');
      const { id } = req.params as { id: string };
      const result = await playlistsService.update(id, req.user.id, req.body as { name?: string; description?: string; coverUrl?: string; isPublic?: boolean });
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async delete(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Unauthenticated', 401, 'AUTH_USER_MISSING');
      const { id } = req.params as { id: string };
      const result = await playlistsService.delete(id, req.user.id);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async addItem(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Unauthenticated', 401, 'AUTH_USER_MISSING');
      const { id } = req.params as { id: string };
      const { trackId, position } = req.body as { trackId: string; position?: number };
      const result = await playlistsService.addItem(id, req.user.id, trackId, position);
      return sendSuccess(res, 201, result);
    } catch (error) {
      return next(error);
    }
  },

  async reorderItems(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Unauthenticated', 401, 'AUTH_USER_MISSING');
      const { id } = req.params as { id: string };
      const { orderedIds } = req.body as { orderedIds: string[] };
      const result = await playlistsService.reorderItems(id, req.user.id, orderedIds);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async removeItem(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Unauthenticated', 401, 'AUTH_USER_MISSING');
      const { id, itemId } = req.params as { id: string; itemId: string };
      const result = await playlistsService.removeItem(id, req.user.id, itemId);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },
};
