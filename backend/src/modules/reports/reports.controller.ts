import { NextFunction, Request, Response } from 'express';
import { sendSuccess } from '../../common/utils/response';
import { reportsService } from './reports.service';

export const reportsController = {
  async list(_req: Request, res: Response, next: NextFunction) {
    try {
      const result = await reportsService.list();
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  }
};