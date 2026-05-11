import { NextFunction, Request, Response } from 'express';
import { sendSuccess } from '../../common/utils/response';
import { AppError } from '../../common/middleware/error-handler';
import { AuthenticatedRequest } from '../../common/types';
import { uploadsService } from './uploads.service';

export const uploadsController = {
  async list(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as AuthenticatedRequest).user!.userId;
      const result = await uploadsService.list(userId);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async initUpload(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as AuthenticatedRequest).user!.userId;
      const {
        fileName,
        mimeType,
        sizeBytes,
        checksum,
        title,
        artist,
        album,
        genre,
        privacy,
      } = req.body as Record<string, string | number | undefined>;

      if (!fileName || typeof fileName !== 'string') {
        throw new AppError('Campo fileName é obrigatório.', 400, 'MISSING_FIELD');
      }
      if (!mimeType || typeof mimeType !== 'string') {
        throw new AppError('Campo mimeType é obrigatório.', 400, 'MISSING_FIELD');
      }
      if (!sizeBytes || typeof sizeBytes !== 'number') {
        throw new AppError('Campo sizeBytes é obrigatório.', 400, 'MISSING_FIELD');
      }

      const result = await uploadsService.initUpload({
        userId,
        fileName,
        mimeType,
        sizeBytes,
        checksum: typeof checksum === 'string' ? checksum : undefined,
        title: typeof title === 'string' ? title : undefined,
        artist: typeof artist === 'string' ? artist : undefined,
        album: typeof album === 'string' ? album : undefined,
        genre: typeof genre === 'string' ? genre : undefined,
        privacy:
          privacy === 'private' || privacy === 'public' ? privacy : undefined,
      });

      return sendSuccess(res, 201, result);
    } catch (error) {
      return next(error);
    }
  },

  async uploadChunk(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as AuthenticatedRequest).user!.userId;
      const { id } = req.params as { id: string };
      const chunkBuffer = req.body as Buffer;

      if (!Buffer.isBuffer(chunkBuffer) || chunkBuffer.length === 0) {
        throw new AppError('Chunk inválido ou vazio.', 400, 'INVALID_CHUNK');
      }

      const result = await uploadsService.appendChunk(id, userId, chunkBuffer);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async completeUpload(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as AuthenticatedRequest).user!.userId;
      const { id } = req.params as { id: string };
      const { checksum } = req.body as { checksum?: string };

      if (!checksum || typeof checksum !== 'string') {
        throw new AppError('Campo checksum (SHA256) é obrigatório.', 400, 'MISSING_FIELD');
      }

      const result = await uploadsService.completeUpload({
        uploadId: id,
        userId,
        checksum,
      });

      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async getUploadStatus(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as AuthenticatedRequest).user!.userId;
      const { id } = req.params as { id: string };
      const result = await uploadsService.getUploadStatus(id, userId);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async cancelUpload(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as AuthenticatedRequest).user!.userId;
      const { id } = req.params as { id: string };
      const result = await uploadsService.cancelUpload(id, userId);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },
};
