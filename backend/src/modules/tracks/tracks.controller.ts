import { NextFunction, Request, Response } from 'express';
import { sendSuccess } from '../../common/utils/response';
import { AuthenticatedRequest } from '../../common/types';
import { tracksService } from './tracks.service';

export const tracksController = {
  async getDownloadUrl(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as AuthenticatedRequest).user!.userId;
      const { id } = req.params as { id: string };
      const result = await tracksService.getDownloadUrl(id, userId);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },
};
