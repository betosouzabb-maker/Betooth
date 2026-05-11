import { NextFunction, Request, Response } from 'express';
import { sendSuccess } from '../../common/utils/response';
import { AuthenticatedRequest } from '../../common/types';
import { AppError } from '../../common/middleware/error-handler';
import { usersService } from './users.service';

export const usersController = {
  async list(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await usersService.list(req);
      return sendSuccess(res, 200, result.items, { pagination: result.pagination });
    } catch (error) {
      return next(error);
    }
  },

  async me(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Authenticated user not found', 401, 'AUTH_USER_MISSING');
      const result = await usersService.getProfile(req.user.id);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async listLibrary(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Unauthenticated', 401, 'AUTH_USER_MISSING');
      const result = await usersService.listLibrary(req.user.id, req);
      return sendSuccess(res, 200, result.items, { pagination: result.pagination });
    } catch (error) {
      return next(error);
    }
  },

  async listFavorites(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Unauthenticated', 401, 'AUTH_USER_MISSING');
      const result = await usersService.listFavorites(req.user.id, req);
      return sendSuccess(res, 200, result.items, { pagination: result.pagination });
    } catch (error) {
      return next(error);
    }
  },
};
