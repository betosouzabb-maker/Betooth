import { NextFunction, Request, Response } from 'express';
import { sendSuccess } from '../../common/utils/response';
import { AuthenticatedRequest } from '../../common/types';
import { AppError } from '../../common/middleware/error-handler';
import { subscriptionsService } from './subscriptions.service';
import { redeemCouponSchema } from './subscriptions.validator';

export const subscriptionsController = {
  async getMe(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as AuthenticatedRequest).user!.userId;
      const result = await subscriptionsService.getMySubscription(userId);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async getQuota(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as AuthenticatedRequest).user!.userId;
      const result = await subscriptionsService.getDownloadQuota(userId);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async checkout(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as AuthenticatedRequest).user!.userId;
      const result = await subscriptionsService.checkout(userId);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async cancel(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as AuthenticatedRequest).user!.userId;
      const result = await subscriptionsService.cancelSubscription(userId);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async redeemCoupon(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as AuthenticatedRequest).user!.userId;
      const parsed = redeemCouponSchema.safeParse(req.body);

      if (!parsed.success) {
        throw new AppError('Código do cupom é obrigatório.', 400, 'VALIDATION_ERROR', parsed.error.issues);
      }

      const result = await subscriptionsService.redeemCoupon(userId, parsed.data.code);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async validateCoupon(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as AuthenticatedRequest).user!.userId;
      const { code } = req.params as { code: string };
      const result = await subscriptionsService.validateCoupon(userId, code);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async webhook(req: Request, res: Response, next: NextFunction) {
    try {
      const xSignature = req.headers['x-signature'] as string | undefined;
      const rawBody = (req as unknown as { rawBody?: string }).rawBody ?? JSON.stringify(req.body);
      const result = await subscriptionsService.handleWebhook(req.body, xSignature, rawBody);
      return sendSuccess(res, 200, result);
    } catch (error) {
      return next(error);
    }
  },

  async mpReturn(req: Request, res: Response) {
    const status = req.query['status'] ?? 'unknown';
    return res.json({ received: true, status });
  },
};
