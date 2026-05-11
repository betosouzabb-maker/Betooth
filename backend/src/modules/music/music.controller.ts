import { NextFunction, Request, Response } from 'express';
import { sendSuccess } from '../../common/utils/response';
import { musicService } from './music.service';

export const musicController = {
  async listTracks(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await musicService.listTracks(req);
      return sendSuccess(res, 200, result.items, { pagination: result.pagination });
    } catch (error) {
      return next(error);
    }
  },

  async listGenres(_req: Request, res: Response, next: NextFunction) {
    try {
      const result = await musicService.listGenres();
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async getStreamMetadata(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params as { id: string };
      const result = await musicService.getStreamMetadata(id);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },
};
