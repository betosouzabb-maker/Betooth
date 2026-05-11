import { NextFunction, Request, Response } from 'express';
import { sendSuccess } from '../../common/utils/response';
import { historyService } from './history.service';

export const historyController = {
  async list(_req: Request, res: Response, next: NextFunction) {
    try {
      const result = await historyService.list();
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  }
};