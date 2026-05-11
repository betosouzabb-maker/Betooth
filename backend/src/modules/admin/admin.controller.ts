import { NextFunction, Request, Response } from 'express';
import { sendSuccess } from '../../common/utils/response';
import { AuthenticatedRequest } from '../../common/types';
import { AppError } from '../../common/middleware/error-handler';
import { adminService } from './admin.service';

export const adminController = {
  async loginMaster(req: Request, res: Response, next: NextFunction) {
    try {
      const { password } = req.body as { password: string };
      if (!password) throw new AppError('Password is required', 400, 'ADMIN_PASSWORD_REQUIRED');
      const result = await adminService.loginMaster({ password });
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async dashboard(_req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const result = await adminService.getDashboard();
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async listUsers(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const page = parseInt((req.query.page as string) ?? '1', 10) || 1;
      const limit = Math.min(parseInt((req.query.limit as string) ?? '20', 10) || 20, 100);
      const result = await adminService.getUsers({
        page,
        limit,
        search: req.query.search as string | undefined,
        status: req.query.status as string | undefined
      });
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async blockUser(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Authenticated user not found', 401, 'AUTH_USER_MISSING');
      const result = await adminService.blockUser(req.user.userId, req.params['id'] as string);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async unblockUser(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Authenticated user not found', 401, 'AUTH_USER_MISSING');
      const result = await adminService.unblockUser(req.user.userId, req.params['id'] as string);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async deleteUser(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Authenticated user not found', 401, 'AUTH_USER_MISSING');
      const result = await adminService.deleteUser(req.user.userId, req.params['id'] as string);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async listTracks(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const page = parseInt((req.query.page as string) ?? '1', 10) || 1;
      const limit = Math.min(parseInt((req.query.limit as string) ?? '20', 10) || 20, 100);
      const result = await adminService.getTracks({
        page,
        limit,
        privacy: req.query.privacy as string | undefined,
        status: req.query.status as string | undefined
      });
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async blockTrack(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Authenticated user not found', 401, 'AUTH_USER_MISSING');
      const result = await adminService.blockTrack(req.user.userId, req.params['id'] as string);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async deleteTrack(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Authenticated user not found', 401, 'AUTH_USER_MISSING');
      const result = await adminService.deleteTrack(req.user.userId, req.params['id'] as string);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async listReports(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const result = await adminService.getReports(req.query.status as string | undefined);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async resolveReport(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Authenticated user not found', 401, 'AUTH_USER_MISSING');
      const { status, reason } = req.body as { status: string; reason?: string };
      if (!status) throw new AppError('status is required', 400, 'ADMIN_STATUS_REQUIRED');
      const result = await adminService.resolveReport({
        adminId: req.user.userId,
        reportId: req.params['id'] as string,
        status,
        reason
      });
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async listUploads(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const result = await adminService.getUploads(req.query.status as string | undefined);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async listAuditLogs(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const page = parseInt((req.query.page as string) ?? '1', 10) || 1;
      const limit = Math.min(parseInt((req.query.limit as string) ?? '20', 10) || 20, 100);
      const result = await adminService.getAuditLogs({ page, limit });
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async stats(_req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const result = await adminService.getStats();
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async overview(_req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const result = await adminService.overview();
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  }
};
