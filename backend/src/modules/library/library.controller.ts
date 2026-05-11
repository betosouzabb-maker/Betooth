import { NextFunction, Response } from 'express';
import { sendSuccess } from '../../common/utils/response';
import { AppError } from '../../common/middleware/error-handler';
import { AuthenticatedRequest } from '../../common/types';
import { libraryService } from './library.service';

export const libraryController = {
  async list(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Unauthenticated', 401, 'AUTH_USER_MISSING');
      const result = await libraryService.list(req.user.id, req);
      return sendSuccess(res, 200, result.items, { pagination: result.pagination });
    } catch (error) {
      return next(error);
    }
  },

  async add(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Unauthenticated', 401, 'AUTH_USER_MISSING');
      const { trackId } = req.params as { trackId: string };
      const result = await libraryService.add(req.user.id, trackId);
      return sendSuccess(res, 201, result);
    } catch (error) {
      return next(error);
    }
  },

  async remove(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Unauthenticated', 401, 'AUTH_USER_MISSING');
      const { trackId } = req.params as { trackId: string };
      const result = await libraryService.remove(req.user.id, trackId);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },
};
