import { createHmac } from 'node:crypto';
import { prisma } from '../../infra/database/prisma';
import { AppError } from '../../common/middleware/error-handler';
import { invalidateVipCache, isUserVip } from '../../common/middleware/vip-guard';
import { env } from '../../config/env';
import { logger } from '../../common/utils/logger';
import { PaymentGateway, SubscriptionStatus } from '@prisma/client';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function addDays(date: Date, days: number): Date {
  const d = new Date(date);
  d.setDate(d.getDate() + days);
  return d;
}

function currentMonthKey(): string {
  const now = new Date();
  const y = now.getUTCFullYear();
  const m = String(now.getUTCMonth() + 1).padStart(2, '0');
  return `${y}-${m}`;
}

// ---------------------------------------------------------------------------
// Mercado Pago helper (minimal — no extra SDK needed)
// ---------------------------------------------------------------------------

async function createMpPreference(userId: string): Promise<{ checkoutUrl: string; preferenceId: string }> {
  const accessToken = env.MP_ACCESS_TOKEN;

  if (!accessToken) {
    throw new AppError(
      'Gateway de pagamento não configurado. Configure MP_ACCESS_TOKEN.',
      503,
      'PAYMENT_GATEWAY_UNAVAILABLE'
    );
  }

  const body = {
    items: [
      {
        id: 'vip-monthly',
        title: env.MP_PLAN_LABEL,
        quantity: 1,
        unit_price: env.MP_PLAN_PRICE_CENTS / 100,
        currency_id: 'BRL',
      },
    ],
    external_reference: userId,
    back_urls: {
      success: `${env.APP_URL}/api/v1/subscriptions/mp-return?status=success&userId=${userId}`,
      failure: `${env.APP_URL}/api/v1/subscriptions/mp-return?status=failure&userId=${userId}`,
      pending: `${env.APP_URL}/api/v1/subscriptions/mp-return?status=pending&userId=${userId}`,
    },
    auto_return: 'approved',
    notification_url: `${env.APP_URL}/api/v1/subscriptions/webhook`,
  };

  const response = await fetch('https://api.mercadopago.com/checkout/preferences', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const err = await response.text().catch(() => 'unknown');
    logger.error({ status: response.status, err }, 'MercadoPago preference creation failed');
    throw new AppError('Falha ao criar preferência de pagamento.', 502, 'PAYMENT_GATEWAY_ERROR');
  }

  const data = await response.json() as { id: string; init_point: string };

  return { checkoutUrl: data.init_point, preferenceId: data.id };
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

export const subscriptionsService = {
  // -------------------------------------------------------------------------
  // GET /me — status da assinatura
  // -------------------------------------------------------------------------
  async getMySubscription(userId: string) {
    const [sub, vip] = await Promise.all([
      prisma.subscription.findUnique({
        where: { userId },
        select: {
          id: true,
          status: true,
          plan: true,
          gateway: true,
          currentPeriodStart: true,
          currentPeriodEnd: true,
          trialEndsAt: true,
          cancelledAt: true,
        },
      }),
      isUserVip(userId),
    ]);

    const quota = await prisma.downloadQuota.findUnique({
      where: { userId_monthKey: { userId, monthKey: currentMonthKey() } },
      select: { usedCount: true, limitCount: true },
    });

    return {
      isVip: vip,
      subscription: sub ?? null,
      downloadQuota: quota
        ? { used: quota.usedCount, limit: quota.limitCount, monthKey: currentMonthKey() }
        : { used: 0, limit: env.FREE_MONTHLY_DOWNLOAD_LIMIT, monthKey: currentMonthKey() },
    };
  },

  // -------------------------------------------------------------------------
  // GET /quota — somente quota de downloads
  // -------------------------------------------------------------------------
  async getDownloadQuota(userId: string) {
    const [vip, quota] = await Promise.all([
      isUserVip(userId),
      prisma.downloadQuota.findUnique({
        where: { userId_monthKey: { userId, monthKey: currentMonthKey() } },
        select: { usedCount: true, limitCount: true },
      }),
    ]);

    const monthKey = currentMonthKey();
    const resetAt = new Date();
    resetAt.setUTCMonth(resetAt.getUTCMonth() + 1, 1);
    resetAt.setUTCHours(0, 0, 0, 0);

    return {
      isVip: vip,
      used: vip ? 0 : (quota?.usedCount ?? 0),
      limit: vip ? null : (quota?.limitCount ?? env.FREE_MONTHLY_DOWNLOAD_LIMIT),
      monthKey,
      resetAt: resetAt.toISOString(),
    };
  },

  // -------------------------------------------------------------------------
  // POST /checkout — inicia pagamento no Mercado Pago
  // -------------------------------------------------------------------------
  async checkout(userId: string) {
    const { checkoutUrl, preferenceId } = await createMpPreference(userId);

    return { checkoutUrl, preferenceId };
  },

  // -------------------------------------------------------------------------
  // DELETE /me — solicita cancelamento
  // -------------------------------------------------------------------------
  async cancelSubscription(userId: string) {
    const sub = await prisma.subscription.findUnique({ where: { userId } });

    if (!sub) {
      throw new AppError('Você não possui uma assinatura ativa.', 404, 'SUBSCRIPTION_NOT_FOUND');
    }

    if (sub.status === SubscriptionStatus.CANCELLED) {
      throw new AppError('Assinatura já foi cancelada.', 409, 'SUBSCRIPTION_ALREADY_CANCELLED');
    }

    const updated = await prisma.subscription.update({
      where: { userId },
      data: {
        status: SubscriptionStatus.CANCELLED,
        cancelledAt: new Date(),
        cancelReason: 'user_request',
      },
    });

    await invalidateVipCache(userId);

    return {
      message: 'Assinatura cancelada. O acesso VIP permanece até o fim do período atual.',
      currentPeriodEnd: updated.currentPeriodEnd,
    };
  },

  // -------------------------------------------------------------------------
  // POST /coupon/redeem — resgata cupom FREE_VIP_DAYS
  // -------------------------------------------------------------------------
  async redeemCoupon(userId: string, code: string) {
    const coupon = await prisma.coupon.findUnique({
      where: { code: code.toUpperCase() },
    });

    if (!coupon || !coupon.isActive) {
      throw new AppError('Cupom inválido ou inativo.', 400, 'COUPON_INVALID');
    }

    if (coupon.expiresAt && coupon.expiresAt < new Date()) {
      throw new AppError('Este cupom expirou.', 400, 'COUPON_EXPIRED');
    }

    if (coupon.maxUses !== null && coupon.usedCount >= coupon.maxUses) {
      throw new AppError('Este cupom atingiu o limite de usos.', 400, 'COUPON_MAX_USES_REACHED');
    }

    // Verifica se usuário já usou este cupom
    const alreadyUsed = await prisma.couponRedemption.findUnique({
      where: { couponId_userId: { couponId: coupon.id, userId } },
    });

    if (alreadyUsed) {
      throw new AppError('Você já utilizou este cupom.', 409, 'COUPON_ALREADY_USED');
    }

    if (coupon.type !== 'FREE_VIP_DAYS' || !coupon.freeDays) {
      throw new AppError('Tipo de cupom não suportado neste endpoint.', 400, 'COUPON_TYPE_UNSUPPORTED');
    }

    const now = new Date();
    const existingSub = await prisma.subscription.findUnique({ where: { userId } });

    // Calcula nova data de expiração: estende se já tem assinatura ativa, senão cria do zero
    const baseDate =
      existingSub &&
      existingSub.status === SubscriptionStatus.ACTIVE &&
      existingSub.currentPeriodEnd > now
        ? existingSub.currentPeriodEnd
        : now;

    const newEnd = addDays(baseDate, coupon.freeDays);

    await prisma.$transaction([
      prisma.subscription.upsert({
        where: { userId },
        create: {
          userId,
          status: SubscriptionStatus.ACTIVE,
          plan: 'MONTHLY',
          gateway: PaymentGateway.MERCADO_PAGO,
          currentPeriodStart: now,
          currentPeriodEnd: newEnd,
          trialEndsAt: newEnd,
        },
        update: {
          status: SubscriptionStatus.ACTIVE,
          currentPeriodStart: now,
          currentPeriodEnd: newEnd,
          trialEndsAt: newEnd,
          cancelledAt: null,
          cancelReason: null,
        },
      }),
      prisma.couponRedemption.create({
        data: { couponId: coupon.id, userId },
      }),
      prisma.coupon.update({
        where: { id: coupon.id },
        data: { usedCount: { increment: 1 } },
      }),
    ]);

    await invalidateVipCache(userId);

    return {
      message: `Cupom aplicado com sucesso! Você tem acesso VIP por ${coupon.freeDays} dias.`,
      vipUntil: newEnd.toISOString(),
    };
  },

  // -------------------------------------------------------------------------
  // GET /coupon/:code/validate — pré-valida cupom sem consumir
  // -------------------------------------------------------------------------
  async validateCoupon(userId: string, code: string) {
    const coupon = await prisma.coupon.findUnique({
      where: { code: code.toUpperCase() },
      select: {
        id: true,
        type: true,
        freeDays: true,
        discountPct: true,
        discountCents: true,
        isActive: true,
        expiresAt: true,
        maxUses: true,
        usedCount: true,
      },
    });

    if (!coupon || !coupon.isActive) {
      return { valid: false, reason: 'COUPON_INVALID' };
    }

    if (coupon.expiresAt && coupon.expiresAt < new Date()) {
      return { valid: false, reason: 'COUPON_EXPIRED' };
    }

    if (coupon.maxUses !== null && coupon.usedCount >= coupon.maxUses) {
      return { valid: false, reason: 'COUPON_MAX_USES_REACHED' };
    }

    const alreadyUsed = await prisma.couponRedemption.findUnique({
      where: { couponId_userId: { couponId: coupon.id, userId } },
    });

    if (alreadyUsed) {
      return { valid: false, reason: 'COUPON_ALREADY_USED' };
    }

    return {
      valid: true,
      coupon: {
        type: coupon.type,
        freeDays: coupon.freeDays,
        discountPct: coupon.discountPct,
        discountCents: coupon.discountCents,
      },
    };
  },

  // -------------------------------------------------------------------------
  // POST /webhook — Mercado Pago notification
  // -------------------------------------------------------------------------
  async handleWebhook(body: unknown, xSignature: string | undefined, rawBody: string) {
    const secret = env.MP_WEBHOOK_SECRET;

    if (secret) {
      const expected = createHmac('sha256', secret).update(rawBody).digest('hex');
      if (!xSignature || xSignature !== expected) {
        throw new AppError('Invalid webhook signature', 401, 'WEBHOOK_SIGNATURE_INVALID');
      }
    }

    const payload = body as Record<string, unknown>;

    if (payload.type !== 'payment') {
      return { received: true };
    }

    const paymentId = String((payload.data as Record<string, unknown>)?.id ?? '');

    if (!paymentId) {
      return { received: true };
    }

    const accessToken = env.MP_ACCESS_TOKEN;
    if (!accessToken) return { received: true };

    try {
      const mpRes = await fetch(`https://api.mercadopago.com/v1/payments/${paymentId}`, {
        headers: { Authorization: `Bearer ${accessToken}` },
      });

      if (!mpRes.ok) {
        logger.warn({ paymentId, status: mpRes.status }, 'Failed to fetch payment from MP');
        return { received: true };
      }

      const mpPayment = await mpRes.json() as {
        id: number;
        status: string;
        external_reference: string;
        transaction_amount: number;
        date_approved: string | null;
      };

      const userId = mpPayment.external_reference;
      const mpStatus = mpPayment.status;

      const paymentStatus =
        mpStatus === 'approved' ? 'APPROVED' :
        mpStatus === 'rejected' ? 'REJECTED' :
        mpStatus === 'refunded' ? 'REFUNDED' :
        mpStatus === 'cancelled' ? 'CANCELLED' :
        'IN_PROCESS';

      const now = new Date();
      const periodEnd = addDays(now, 30);

      await prisma.$transaction(async (tx) => {
        await tx.payment.upsert({
          where: { externalPayId: String(mpPayment.id) },
          create: {
            userId,
            gateway: PaymentGateway.MERCADO_PAGO,
            externalPayId: String(mpPayment.id),
            status: paymentStatus as never,
            amountCents: Math.round(mpPayment.transaction_amount * 100),
            currency: 'BRL',
            gatewayPayload: mpPayment as never,
            paidAt: mpPayment.date_approved ? new Date(mpPayment.date_approved) : undefined,
          },
          update: {
            status: paymentStatus as never,
            gatewayPayload: mpPayment as never,
            paidAt: mpPayment.date_approved ? new Date(mpPayment.date_approved) : undefined,
          },
        });

        if (mpStatus === 'approved') {
          await tx.subscription.upsert({
            where: { userId },
            create: {
              userId,
              status: SubscriptionStatus.ACTIVE,
              plan: 'MONTHLY',
              gateway: PaymentGateway.MERCADO_PAGO,
              currentPeriodStart: now,
              currentPeriodEnd: periodEnd,
            },
            update: {
              status: SubscriptionStatus.ACTIVE,
              currentPeriodStart: now,
              currentPeriodEnd: periodEnd,
              cancelledAt: null,
              cancelReason: null,
            },
          });
        }
      });

      await invalidateVipCache(userId);

      logger.info({ paymentId, userId, mpStatus }, 'Webhook processed');
    } catch (err) {
      logger.error({ err, paymentId }, 'Error processing MP webhook');
    }

    return { received: true };
  },
};
