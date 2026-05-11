import { NextFunction, Request, Response } from 'express';
import { sendSuccess } from '../../common/utils/response';
import { notificationsService } from './notifications.service';

export const notificationsController = {
  async list(_req: Request, res: Response, next: NextFunction) {
    try {
      const result = await notificationsService.list();
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  }
};