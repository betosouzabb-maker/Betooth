import { NextFunction, Response } from 'express';
import { SubscriptionStatus } from '@prisma/client';
import { prisma } from '../../infra/database/prisma';
import { redis } from '../../infra/redis/redis';
import { env } from '../../config/env';
import { AuthenticatedRequest } from '../types';
import { AppError } from './error-handler';

const VIP_CACHE_PREFIX = 'vip:';

const VIP_STATUSES = new Set<SubscriptionStatus>([
  SubscriptionStatus.ACTIVE,
  SubscriptionStatus.TRIAL,
]);

export async function isUserVip(userId: string): Promise<boolean> {
  const cacheKey = `${VIP_CACHE_PREFIX}${userId}`;

  const cached = await redis.get(cacheKey).catch(() => null);
  if (cached !== null) {
    return cached === '1';
  }

  const subscription = await prisma.subscription.findUnique({
    where: { userId },
    select: { status: true, currentPeriodEnd: true },
  });

  const vip =
    subscription !== null &&
    VIP_STATUSES.has(subscription.status) &&
    subscription.currentPeriodEnd > new Date();

  await redis
    .set(cacheKey, vip ? '1' : '0', 'EX', env.VIP_CACHE_TTL_SECONDS)
    .catch(() => null);

  return vip;
}

export async function invalidateVipCache(userId: string): Promise<void> {
  await redis.del(`${VIP_CACHE_PREFIX}${userId}`).catch(() => null);
}

export const vipGuard = async (
  req: AuthenticatedRequest,
  _res: Response,
  next: NextFunction
): Promise<void> => {
  const user = req.user;

  if (!user) {
    return next(new AppError('Authentication required', 401, 'AUTH_TOKEN_MISSING'));
  }

  try {
    const vip = await isUserVip(user.userId);

    if (!vip) {
      return next(
        new AppError(
          'Recurso exclusivo para assinantes VIP.',
          403,
          'VIP_REQUIRED'
        )
      );
    }

    return next();
  } catch (error) {
    return next(error);
  }
};

/** Alias used by routes that need VIP access. */
export const requireVip = vipGuard;
