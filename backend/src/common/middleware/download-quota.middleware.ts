import { NextFunction, Response } from 'express';
import { prisma } from '../../infra/database/prisma';
import { env } from '../../config/env';
import { AuthenticatedRequest } from '../types';
import { AppError } from './error-handler';
import { isUserVip } from './vip-guard';

function currentMonthKey(): string {
  const now = new Date();
  const y = now.getUTCFullYear();
  const m = String(now.getUTCMonth() + 1).padStart(2, '0');
  return `${y}-${m}`;
}

export const downloadQuotaMiddleware = async (
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

    if (vip) {
      return next();
    }

    const monthKey = currentMonthKey();
    const limit = env.FREE_MONTHLY_DOWNLOAD_LIMIT;

    const quota = await prisma.downloadQuota.upsert({
      where: { userId_monthKey: { userId: user.userId, monthKey } },
      create: { userId: user.userId, monthKey, usedCount: 0, limitCount: limit },
      update: {},
    });

    if (quota.usedCount >= quota.limitCount) {
      return next(
        new AppError(
          `Limite de ${quota.limitCount} downloads mensais atingido. Assine o VIP para downloads ilimitados.`,
          403,
          'DOWNLOAD_QUOTA_EXCEEDED',
          { used: quota.usedCount, limit: quota.limitCount, monthKey }
        )
      );
    }

    await prisma.downloadQuota.update({
      where: { userId_monthKey: { userId: user.userId, monthKey } },
      data: { usedCount: { increment: 1 } },
    });

    return next();
  } catch (error) {
    return next(error);
  }
};

/** Alias used by routes that need download quota enforcement. */
export const checkDownloadQuota = downloadQuotaMiddleware;
