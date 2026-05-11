import { NextFunction, Request, Response } from 'express';
import { sendSuccess } from '../../common/utils/response';
import { AuthenticatedRequest } from '../../common/types';
import { AppError } from '../../common/middleware/error-handler';
import { authService } from './auth.service';

export const authController = {
  async login(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await authService.login(req.body as { email: string; password: string }, {
        ipAddress: req.ip,
        userAgent: req.get('user-agent') ?? null
      });
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },
  async register(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await authService.register(req.body as Parameters<typeof authService.register>[0], {
        ipAddress: req.ip,
        userAgent: req.get('user-agent') ?? null
      });
      return sendSuccess(res, 201, result);
    } catch (error) {
      return next(error);
    }
  },
  async refresh(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await authService.refresh(
        req.body as { refreshToken: string },
        {
          ipAddress: req.ip,
          userAgent: req.get('user-agent') ?? null
        }
      );
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },
  async logout(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await authService.logout(req.body as { refreshToken: string });
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },
  async forgotPassword(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await authService.forgotPassword(req.body as { email: string });
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },
  async resetPassword(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await authService.resetPassword(req.body as { token: string; password: string });
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },
  async me(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) {
        throw new AppError('Authenticated user not found', 401, 'AUTH_USER_MISSING');
      }

      const result = await authService.me(req.user.id);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },
  async updateMe(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) {
        throw new AppError('Authenticated user not found', 401, 'AUTH_USER_MISSING');
      }

      const result = await authService.updateMe(req.user.id, req.body as Parameters<typeof authService.updateMe>[1]);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  }
};