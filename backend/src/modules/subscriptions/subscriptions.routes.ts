import express, { Router } from 'express';
import { requireAuth } from '../auth/auth.middleware';
import { subscriptionsController } from './subscriptions.controller';

export const subscriptionsRoutes = Router();

// Capture raw body for webhook HMAC validation
subscriptionsRoutes.post(
  '/webhook',
  express.raw({ type: 'application/json' }),
  (req, _res, next) => {
    if (Buffer.isBuffer(req.body)) {
      (req as unknown as Record<string, unknown>).rawBody = req.body.toString('utf8');
      req.body = JSON.parse((req as unknown as { rawBody: string }).rawBody);
    }
    next();
  },
  subscriptionsController.webhook
);

subscriptionsRoutes.get('/mp-return', subscriptionsController.mpReturn);

subscriptionsRoutes.get('/me', requireAuth, subscriptionsController.getMe);

subscriptionsRoutes.post('/checkout', requireAuth, subscriptionsController.checkout);

subscriptionsRoutes.delete('/me', requireAuth, subscriptionsController.cancel);

subscriptionsRoutes.post('/coupon/redeem', requireAuth, subscriptionsController.redeemCoupon);

subscriptionsRoutes.get(
  '/coupon/:code/validate',
  requireAuth,
  subscriptionsController.validateCoupon
);
