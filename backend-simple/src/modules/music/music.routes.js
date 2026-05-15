const express = require('express');
const { z } = require('zod');
const { db } = require('../../infra/database');
const { authGuard } = require('../../common/auth-guard');
const { validateQuery } = require('../../common/validator');
const { sendSuccess } = require('../../common/response');
const { AppError } = require('../../common/error-handler');

const router = express.Router();

const searchSchema = z.object({
  q: z.string().min(1).optional(),
  page: z.string().transform(Number).pipe(z.number().min(1)).optional().default('1'),
  limit: z.string().transform(Number).pipe(z.number().min(1).max(100)).optional().default('20'),
  genre: z.string().optional(),
});

router.get('/tracks', validateQuery(searchSchema), (req, res) => {
  const { q, page, limit, genre } = req.query;
  const offset = (page - 1) * limit;

  let tracks = db.tracks.filter(t => t.status === 'ACTIVE');

  if (q) {
    const like = q.toLowerCase();
    tracks = tracks.filter(t =>
      t.title?.toLowerCase().includes(like) ||
      t.artist?.toLowerCase().includes(like) ||
      t.album?.toLowerCase().includes(like)
    );
  }

  if (genre) {
    tracks = tracks.filter(t => t.genre === genre);
  }

  const total = tracks.length;
  tracks = tracks.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
  tracks = tracks.slice(offset, offset + limit);

  return sendSuccess(res, {
    tracks: tracks.map(t => ({
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

router.get('/tracks/:id', authGuard, (req, res, next) => {
  try {
    const track = db.tracks.find(t => t.id === req.params.id && t.status === 'ACTIVE');
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
  } catch (error) {
    next(error);
  }
});

router.get('/genres', (req, res) => {
  const genres = [...new Set(db.tracks.filter(t => t.status === 'ACTIVE' && t.genre).map(t => t.genre))];
  return sendSuccess(res, { genres });
});

router.get('/search', authGuard, validateQuery(searchSchema), (req, res) => {
  const { q, page, limit } = req.query;
  if (!q) {
    return sendSuccess(res, { tracks: [], meta: { pagination: { page, limit, total: 0, totalPages: 0 } } });
  }

  const offset = (page - 1) * limit;
  const like = q.toLowerCase();

  let tracks = db.tracks.filter(t =>
    t.status === 'ACTIVE' && (
      t.title?.toLowerCase().includes(like) ||
      t.artist?.toLowerCase().includes(like) ||
      t.album?.toLowerCase().includes(like)
    )
  );

  const total = tracks.length;
  tracks = tracks.sort((a, b) => (b.play_count || 0) - (a.play_count || 0));
  tracks = tracks.slice(offset, offset + limit);

  if (req.user?.id) {
    db.search_history.push({
      id: require('crypto').randomUUID(),
      user_id: req.user.id,
      query: q,
      searched_at: new Date().toISOString(),
    });
  }

  return sendSuccess(res, {
    tracks: tracks.map(t => ({
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

module.exports = router;
