import { Router } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { db } from '../../infra/database';
import { authGuard, AuthRequest } from '../../common/auth-guard';
import { sendSuccess } from '../../common/response';
import { AppError } from '../../common/error-handler';
import { env } from '../../config/env';

const router = Router();

router.get('/status', authGuard, (req: AuthRequest, res) => {
  const sub = db.subscriptions.find((s: any) => s.user_id === req.user!.id);

  if (!sub || sub.status !== 'ACTIVE') {
    return sendSuccess(res, {
      isVip: false,
      status: sub?.status || 'INACTIVE',
      plan: null,
      expiresAt: null,
    });
  }

  return sendSuccess(res, {
    isVip: true,
    status: sub.status,
    plan: {
      priceCents: sub.plan_price_cents,
      label: env.MP_PLAN_LABEL,
    },
    expiresAt: sub.expires_at,
    startedAt: sub.started_at,
  });
});

router.post('/webhook', (req, res) => {
  const { type, data } = req.body;
  console.log('[WEBHOOK] Received:', type, JSON.stringify(data));
  return sendSuccess(res, { received: true });
});

router.post('/create', authGuard, (req: AuthRequest, res) => {
  const userId = req.user!.id;
  const existing = db.subscriptions.find((s: any) => s.user_id === userId);

  if (existing && existing.status === 'ACTIVE') {
    throw new AppError('Already subscribed', 409, 'SUBSCRIPTION_ACTIVE');
  }

  const now = new Date();
  const expiresAt = new Date();
  expiresAt.setMonth(expiresAt.getMonth() + 1);

  if (existing) {
    existing.status = 'ACTIVE';
    existing.mp_subscription_id = 'mock-mp-id';
    existing.plan_price_cents = env.MP_PLAN_PRICE_CENTS;
    existing.started_at = now.toISOString();
    existing.expires_at = expiresAt.toISOString();
    existing.updated_at = now.toISOString();
  } else {
    db.subscriptions.push({
      id: uuidv4(),
      user_id: userId,
      mp_subscription_id: 'mock-mp-id',
      status: 'ACTIVE',
      plan_price_cents: env.MP_PLAN_PRICE_CENTS,
      started_at: now.toISOString(),
      expires_at: expiresAt.toISOString(),
      cancelled_at: null,
      created_at: now.toISOString(),
      updated_at: now.toISOString(),
    });
  }

  return sendSuccess(res, {
    message: 'Subscription created',
    expiresAt: expiresAt.toISOString(),
  }, 201);
});

router.post('/cancel', authGuard, (req: AuthRequest, res) => {
  const sub = db.subscriptions.find((s: any) => s.user_id === req.user!.id);
  if (sub) {
    sub.status = 'CANCELLED';
    sub.cancelled_at = new Date().toISOString();
    sub.updated_at = new Date().toISOString();
  }

  return sendSuccess(res, { message: 'Subscription cancelled' });
});

export default router;
