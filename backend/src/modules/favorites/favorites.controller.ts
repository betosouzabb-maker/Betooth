import { NextFunction, Request, Response } from 'express';
import { sendSuccess } from '../../common/utils/response';
import { AppError } from '../../common/middleware/error-handler';
import { AuthenticatedRequest } from '../../common/types';
import { favoritesService } from './favorites.service';

export const favoritesController = {
  async list(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Unauthenticated', 401, 'AUTH_USER_MISSING');
      const result = await favoritesService.list(req.user.id, req);
      return sendSuccess(res, 200, result.items, { pagination: result.pagination });
    } catch (error) {
      return next(error);
    }
  },

  async add(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Unauthenticated', 401, 'AUTH_USER_MISSING');
      const { trackId } = req.params as { trackId: string };
      const result = await favoritesService.add(req.user.id, trackId);
      return sendSuccess(res, 201, result);
    } catch (error) {
      return next(error);
    }
  },

  async remove(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Unauthenticated', 401, 'AUTH_USER_MISSING');
      const { trackId } = req.params as { trackId: string };
      const result = await favoritesService.remove(req.user.id, trackId);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },
};
