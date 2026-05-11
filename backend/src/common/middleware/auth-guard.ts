import { NextFunction, Response } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../../config/env';
import { AuthenticatedRequest, RequestUser } from '../types';
import { AppError } from './error-handler';

type JwtPayload = RequestUser & {
  type?: string;
  iat?: number;
  exp?: number;
};

export const authGuard = (req: AuthenticatedRequest, _res: Response, next: NextFunction): void => {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith('Bearer ')) {
    return next(new AppError('Authentication token is missing', 401, 'AUTH_TOKEN_MISSING'));
  }

  const token = authHeader.replace('Bearer ', '').trim();

  try {
    const payload = jwt.verify(token, env.JWT_ACCESS_SECRET) as JwtPayload;

    if (payload.type && payload.type !== 'access') {
      return next(new AppError('Authentication token is invalid', 401, 'AUTH_TOKEN_INVALID'));
    }

    req.user = {
      id: payload.userId ?? payload.id,
      userId: payload.userId ?? payload.id,
      email: payload.email,
      role: payload.role
    };

    return next();
  } catch (error) {
    return next(new AppError('Authentication token is invalid', 401, 'AUTH_TOKEN_INVALID', error));
  }
};