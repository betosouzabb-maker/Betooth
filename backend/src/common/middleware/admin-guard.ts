import { NextFunction, Response } from 'express';
import { AuthenticatedRequest } from '../types';
import { AppError } from './error-handler';

const ADMIN_ROLES = new Set(['ADMIN', 'SUPER_ADMIN']);

export const adminGuard = (req: AuthenticatedRequest, _res: Response, next: NextFunction): void => {
  const user = req.user;

  if (!user) {
    return next(new AppError('Authentication required', 401, 'AUTH_TOKEN_MISSING'));
  }

  if (!ADMIN_ROLES.has(user.role)) {
    return next(new AppError('Admin access required', 403, 'AUTH_FORBIDDEN'));
  }

  return next();
};
