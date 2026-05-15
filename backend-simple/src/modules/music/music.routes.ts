import { Router } from 'express';
import { z } from 'zod';
import { db, findAll } from '../../infra/database';
import { authGuard, AuthRequest } from '../../common/auth-guard';
import { validateQuery } from '../../common/validator';
import { sendSuccess } from '../../common/response';
import { AppError } from '../../common/error-handler';

const router = Router();

const searchSchema = z.object({
  q: z.string().min(1).optional(),
  page: z.string().transform(Number).pipe(z.number().min(1)).optional().default('1'),
  limit: z.string().transform(Number).pipe(z.number().min(1).max(100)).optional().default('20'),
  genre: z.string().optional(),
});

router.get('/tracks', validateQuery(searchSchema), (req: AuthRequest, res) => {
  const { q, page, limit, genre } = req.query as any;
  const offset = (page - 1) * limit;

  let tracks = db.tracks.filter((t: any) => t.status === 'ACTIVE');

  if (q) {
    const like = q.toLowerCase();
    tracks = tracks.filter((t: any) =>
      t.title?.toLowerCase().includes(like) ||
      t.artist?.toLowerCase().includes(like) ||
      t.album?.toLowerCase().includes(like)
    );
  }

  if (genre) {
    tracks = tracks.filter((t: any) => t.genre === genre);
  }

  const total = tracks.length;
  tracks = tracks.sort((a: any, b: any) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
  tracks = tracks.slice(offset, offset + limit);

  return sendSuccess(res, {
    tracks: tracks.map((t: any) => ({
      id: t.id,
      title: t.title,
      artist: t.artist,
      album: t.album,
      genre: t.genre,
      duration: t.duration,
      coverUrl: t.cover_url,
      audioUrl: t.audio_url,
      fileSize: t.file_size,
      bitrate: t.bitrate,
      sampleRate: t.sample_rate,
      lyrics: t.lyrics,
      isExplicit: !!t.is_explicit,
      playCount: t.play_count,
      downloadCount: t.download_count,
      status: t.status,
      uploadedBy: t.uploaded_by,
      createdAt: t.created_at,
      updatedAt: t.updated_at,
    })),
    meta: {
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) }
    }
  });
});

router.get('/tracks/:id', authGuard, (req: AuthRequest, res) => {
  const track = db.tracks.find((t: any) => t.id === req.params.id && t.status === 'ACTIVE');
  if (!track) {
    throw new AppError('Track not found', 404, 'TRACK_NOT_FOUND');
  }

  track.play_count = (track.play_count || 0) + 1;

  return sendSuccess(res, {
    id: track.id,
    title: track.title,
    artist: track.artist,
    album: track.album,
    genre: track.genre,
    duration: track.duration,
    coverUrl: track.cover_url,
    audioUrl: track.audio_url,
    fileSize: track.file_size,
    bitrate: track.bitrate,
    sampleRate: track.sample_rate,
    lyrics: track.lyrics,
    isExplicit: !!track.is_explicit,
    playCount: track.play_count,
    downloadCount: track.download_count,
    status: track.status,
    uploadedBy: track.uploaded_by,
    createdAt: track.created_at,
    updatedAt: track.updated_at,
  });
});

router.get('/genres', (req, res) => {
  const genres = [...new Set(db.tracks.filter((t: any) => t.status === 'ACTIVE' && t.genre).map((t: any) => t.genre))];
  return sendSuccess(res, { genres });
});

router.get('/search', authGuard, validateQuery(searchSchema), (req: AuthRequest, res) => {
  const { q, page, limit } = req.query as any;
  if (!q) {
    return sendSuccess(res, { tracks: [], meta: { pagination: { page, limit, total: 0, totalPages: 0 } } });
  }

  const offset = (page - 1) * limit;
  const like = q.toLowerCase();

  let tracks = db.tracks.filter((t: any) =>
    t.status === 'ACTIVE' && (
      t.title?.toLowerCase().includes(like) ||
      t.artist?.toLowerCase().includes(like) ||
      t.album?.toLowerCase().includes(like)
    )
  );

  const total = tracks.length;
  tracks = tracks.sort((a: any, b: any) => (b.play_count || 0) - (a.play_count || 0));
  tracks = tracks.slice(offset, offset + limit);

  // Save search history
  if (req.user?.id) {
    db.search_history.push({
      id: crypto.randomUUID(),
      user_id: req.user.id,
      query: q,
      searched_at: new Date().toISOString(),
    });
  }

  return sendSuccess(res, {
    tracks: tracks.map((t: any) => ({
      id: t.id,
      title: t.title,
      artist: t.artist,
      album: t.album,
      genre: t.genre,
      duration: t.duration,
      coverUrl: t.cover_url,
      audioUrl: t.audio_url,
      playCount: t.play_count,
      downloadCount: t.download_count,
    })),
    meta: {
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) }
    }
  });
});

export default router;
