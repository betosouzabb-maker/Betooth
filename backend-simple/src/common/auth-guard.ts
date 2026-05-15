import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { AppError } from './error-handler';
import { db } from '../infra/database';

export interface AuthRequest extends Request {
  user?: { id: string; email: string; role: string };
}

export const authGuard = (req: AuthRequest, res: Response, next: NextFunction): void => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      throw new AppError('Unauthorized', 401, 'AUTH_UNAUTHORIZED');
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, env.JWT_ACCESS_SECRET) as any;

    req.user = {
      id: decoded.userId,
      email: decoded.email,
      role: decoded.role || 'USER'
    };

    next();
  } catch (error) {
    if (error instanceof AppError) {
      res.status(error.statusCode).json({ success: false, error: { message: error.message, code: error.code } });
      return;
    }
    res.status(401).json({ success: false, error: { message: 'Unauthorized', code: 'AUTH_UNAUTHORIZED' } });
  }
};

export const adminGuard = (req: AuthRequest, res: Response, next: NextFunction): void => {
  if (req.user?.role !== 'ADMIN') {
    res.status(403).json({ success: false, error: { message: 'Forbidden', code: 'ADMIN_REQUIRED' } });
    return;
  }
  next();
};

export const vipGuard = async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      throw new AppError('Unauthorized', 401, 'AUTH_UNAUTHORIZED');
    }

    const sub = db.prepare('SELECT * FROM subscriptions WHERE user_id = ? AND status = ?').get(userId, 'ACTIVE');
    if (!sub) {
      throw new AppError('VIP subscription required', 403, 'VIP_REQUIRED');
    }

    next();
  } catch (error) {
    if (error instanceof AppError) {
      res.status(error.statusCode).json({ success: false, error: { message: error.message, code: error.code } });
      return;
    }
    res.status(500).json({ success: false, error: { message: 'Internal server error', code: 'INTERNAL_SERVER_ERROR' } });
  }
};
