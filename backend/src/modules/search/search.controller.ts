import { NextFunction, Request, Response } from 'express';
import { sendSuccess } from '../../common/utils/response';
import { AppError } from '../../common/middleware/error-handler';
import { AuthenticatedRequest } from '../../common/types';
import { searchService } from './search.service';

export const searchController = {
  async search(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Unauthenticated', 401, 'AUTH_USER_MISSING');
      const result = await searchService.search(req.user.id, req);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async suggestions(req: Request, res: Response, next: NextFunction) {
    try {
      const { q } = req.query as { q?: string };
      const result = await searchService.suggestions(q ?? '');
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async getHistory(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Unauthenticated', 401, 'AUTH_USER_MISSING');
      const result = await searchService.getHistory(req.user.id);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async clearHistory(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Unauthenticated', 401, 'AUTH_USER_MISSING');
      const result = await searchService.clearHistory(req.user.id);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },
};
