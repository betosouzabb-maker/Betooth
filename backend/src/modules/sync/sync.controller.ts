import { NextFunction, Response } from 'express';
import { sendSuccess } from '../../common/utils/response';
import { AuthenticatedRequest } from '../../common/types';
import { AppError } from '../../common/middleware/error-handler';
import { syncService } from './sync.service';

export const syncController = {
  async bootstrap(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Authenticated user not found', 401, 'AUTH_USER_MISSING');
      const result = await syncService.bootstrap({
        userId: req.user.userId,
        deviceId: req.query.deviceId as string | undefined
      });
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async push(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Authenticated user not found', 401, 'AUTH_USER_MISSING');
      const { mutations, deviceId } = req.body as { mutations: unknown[]; deviceId?: string };
      if (!Array.isArray(mutations)) {
        throw new AppError('mutations must be an array', 400, 'SYNC_INVALID_MUTATIONS');
      }
      const result = await syncService.push({
        userId: req.user.userId,
        deviceId,
        mutations: mutations as never
      });
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async pull(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Authenticated user not found', 401, 'AUTH_USER_MISSING');
      const sinceVersion = parseInt((req.query.sinceVersion as string) ?? '0', 10);
      if (isNaN(sinceVersion) || sinceVersion < 0) {
        throw new AppError('sinceVersion must be a non-negative integer', 400, 'SYNC_INVALID_VERSION');
      }
      const result = await syncService.pull({
        userId: req.user.userId,
        deviceId: req.query.deviceId as string | undefined,
        sinceVersion
      });
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async ack(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Authenticated user not found', 401, 'AUTH_USER_MISSING');
      const { deviceId, entityType, version } = req.body as { deviceId?: string; entityType: string; version: number };
      if (!entityType || version == null) {
        throw new AppError('entityType and version are required', 400, 'SYNC_INVALID_ACK');
      }
      const result = await syncService.ack({
        userId: req.user.userId,
        deviceId,
        entityType,
        version
      });
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async state(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('Authenticated user not found', 401, 'AUTH_USER_MISSING');
      const result = await syncService.getSyncState({
        userId: req.user.userId,
        deviceId: req.query.deviceId as string | undefined
      });
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async status(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const result = await syncService.status();
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  }
};
