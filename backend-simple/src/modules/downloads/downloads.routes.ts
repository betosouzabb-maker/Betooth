import { Router } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { db } from '../../infra/database';
import { authGuard, AuthRequest } from '../../common/auth-guard';
import { sendSuccess } from '../../common/response';
import { AppError } from '../../common/error-handler';
import { env } from '../../config/env';

const router = Router();

function getDownloadCount(userId: string, month: number, year: number): number {
  const start = new Date(year, month - 1, 1).toISOString();
  const end = new Date(year, month, 1).toISOString();
  return db.downloads.filter((d: any) =>
    d.user_id === userId && d.downloaded_at >= start && d.downloaded_at < end
  ).length;
}

function isVip(userId: string): boolean {
  const sub = db.subscriptions.find((s: any) => s.user_id === userId && s.status === 'ACTIVE');
  if (!sub) return false;
  return new Date(sub.expires_at) > new Date();
}

router.post('/:trackId', authGuard, (req: AuthRequest, res) => {
  const userId = req.user!.id;
  const trackId = req.params.trackId;

  const track = db.tracks.find((t: any) => t.id === trackId && t.status === 'ACTIVE');
  if (!track) {
    throw new AppError('Track not found', 404, 'TRACK_NOT_FOUND');
  }

  const now = new Date();
  const downloadCount = getDownloadCount(userId, now.getMonth() + 1, now.getFullYear());

  if (!isVip(userId) && downloadCount >= env.FREE_MONTHLY_DOWNLOAD_LIMIT) {
    throw new AppError('Download limit reached. Upgrade to VIP.', 403, 'DOWNLOAD_LIMIT_REACHED');
  }

  db.downloads.push({
    id: uuidv4(),
    user_id: userId,
    track_id: trackId,
    downloaded_at: new Date().toISOString(),
    expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
  });

  track.download_count = (track.download_count || 0) + 1;

  return sendSuccess(res, {
    message: 'Download authorized',
    track: {
      id: track.id,
      title: track.title,
      artist: track.artist,
      audioUrl: track.audio_url,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
    }
  });
});

router.get('/quota', authGuard, (req: AuthRequest, res) => {
  const userId = req.user!.id;
  const now = new Date();
  const used = getDownloadCount(userId, now.getMonth() + 1, now.getFullYear());
  const vip = isVip(userId);

  return sendSuccess(res, {
    used,
    limit: env.FREE_MONTHLY_DOWNLOAD_LIMIT,
    remaining: Math.max(0, env.FREE_MONTHLY_DOWNLOAD_LIMIT - used),
    isVip: vip,
    unlimited: vip,
  });
});

export default router;
