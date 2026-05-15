import { Router } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { db } from '../../infra/database';
import { authGuard, AuthRequest } from '../../common/auth-guard';
import { sendSuccess } from '../../common/response';
import { AppError } from '../../common/error-handler';

const router = Router();

// Library
router.get('/library', authGuard, (req: AuthRequest, res) => {
  const items = db.user_library
    .filter((ul: any) => ul.user_id === req.user!.id)
    .map((ul: any) => {
      const track = db.tracks.find((t: any) => t.id === ul.track_id && t.status === 'ACTIVE');
      return track;
    })
    .filter(Boolean);

  return sendSuccess(res, {
    tracks: items.map((t: any) => ({
      id: t.id,
      title: t.title,
      artist: t.artist,
      album: t.album,
      genre: t.genre,
      duration: t.duration,
      coverUrl: t.cover_url,
      audioUrl: t.audio_url,
    }))
  });
});

router.post('/library/:trackId', authGuard, (req: AuthRequest, res) => {
  const existing = db.user_library.find((ul: any) => ul.user_id === req.user!.id && ul.track_id === req.params.trackId);
  if (existing) {
    throw new AppError('Track already in library', 409, 'LIBRARY_DUPLICATE');
  }

  db.user_library.push({
    id: uuidv4(),
    user_id: req.user!.id,
    track_id: req.params.trackId,
    added_at: new Date().toISOString(),
  });

  return sendSuccess(res, { message: 'Added to library' }, 201);
});

router.delete('/library/:trackId', authGuard, (req: AuthRequest, res) => {
  db.user_library = db.user_library.filter((ul: any) => !(ul.user_id === req.user!.id && ul.track_id === req.params.trackId));
  return sendSuccess(res, { message: 'Removed from library' });
});

// Playlists
router.get('/playlists', authGuard, (req: AuthRequest, res) => {
  const playlists = db.playlists
    .filter((p: any) => p.user_id === req.user!.id)
    .sort((a: any, b: any) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());

  return sendSuccess(res, {
    playlists: playlists.map((p: any) => {
      const trackCount = db.playlist_tracks.filter((pt: any) => pt.playlist_id === p.id).length;
      return {
        id: p.id,
        name: p.name,
        description: p.description,
        coverUrl: p.cover_url,
        isPublic: !!p.is_public,
        trackCount,
        createdAt: p.created_at,
        updatedAt: p.updated_at,
      };
    })
  });
});

router.post('/playlists', authGuard, (req: AuthRequest, res) => {
  const { name, description, isPublic } = req.body;
  const id = uuidv4();

  db.playlists.push({
    id,
    user_id: req.user!.id,
    name,
    description: description || null,
    cover_url: null,
    is_public: isPublic ? 1 : 0,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  });

  return sendSuccess(res, { id, name, description, isPublic: !!isPublic }, 201);
});

router.get('/playlists/:id', authGuard, (req: AuthRequest, res) => {
  const playlist = db.playlists.find((p: any) => p.id === req.params.id);
  if (!playlist) {
    throw new AppError('Playlist not found', 404, 'PLAYLIST_NOT_FOUND');
  }

  const tracks = db.playlist_tracks
    .filter((pt: any) => pt.playlist_id === req.params.id)
    .sort((a: any, b: any) => a.position - b.position)
    .map((pt: any) => db.tracks.find((t: any) => t.id === pt.track_id))
    .filter(Boolean);

  return sendSuccess(res, {
    playlist: {
      id: playlist.id,
      name: playlist.name,
      description: playlist.description,
      coverUrl: playlist.cover_url,
      isPublic: !!playlist.is_public,
      createdAt: playlist.created_at,
      updatedAt: playlist.updated_at,
    },
    tracks: tracks.map((t: any) => ({
      id: t.id,
      title: t.title,
      artist: t.artist,
      album: t.album,
      duration: t.duration,
      coverUrl: t.cover_url,
      audioUrl: t.audio_url,
    }))
  });
});

router.post('/playlists/:id/tracks', authGuard, (req: AuthRequest, res) => {
  const { trackId } = req.body;
  const maxPos = db.playlist_tracks
    .filter((pt: any) => pt.playlist_id === req.params.id)
    .reduce((max: number, pt: any) => Math.max(max, pt.position || 0), 0);

  db.playlist_tracks.push({
    id: uuidv4(),
    playlist_id: req.params.id,
    track_id: trackId,
    position: maxPos + 1,
    added_at: new Date().toISOString(),
  });

  return sendSuccess(res, { message: 'Track added to playlist' }, 201);
});

router.delete('/playlists/:id/tracks/:trackId', authGuard, (req: AuthRequest, res) => {
  db.playlist_tracks = db.playlist_tracks.filter((pt: any) => !(pt.playlist_id === req.params.id && pt.track_id === req.params.trackId));
  return sendSuccess(res, { message: 'Track removed from playlist' });
});

router.delete('/playlists/:id', authGuard, (req: AuthRequest, res) => {
  db.playlists = db.playlists.filter((p: any) => !(p.id === req.params.id && p.user_id === req.user!.id));
  db.playlist_tracks = db.playlist_tracks.filter((pt: any) => pt.playlist_id !== req.params.id);
  return sendSuccess(res, { message: 'Playlist deleted' });
});

// Favorites
router.get('/favorites', authGuard, (req: AuthRequest, res) => {
  const tracks = db.favorites
    .filter((f: any) => f.user_id === req.user!.id)
    .map((f: any) => db.tracks.find((t: any) => t.id === f.track_id && t.status === 'ACTIVE'))
    .filter(Boolean);

  return sendSuccess(res, {
    tracks: tracks.map((t: any) => ({
      id: t.id,
      title: t.title,
      artist: t.artist,
      album: t.album,
      duration: t.duration,
      coverUrl: t.cover_url,
      audioUrl: t.audio_url,
    }))
  });
});

router.post('/favorites/:trackId', authGuard, (req: AuthRequest, res) => {
  const existing = db.favorites.find((f: any) => f.user_id === req.user!.id && f.track_id === req.params.trackId);
  if (existing) {
    throw new AppError('Track already favorited', 409, 'FAVORITE_DUPLICATE');
  }

  db.favorites.push({
    id: uuidv4(),
    user_id: req.user!.id,
    track_id: req.params.trackId,
    created_at: new Date().toISOString(),
  });

  return sendSuccess(res, { message: 'Added to favorites' }, 201);
});

router.delete('/favorites/:trackId', authGuard, (req: AuthRequest, res) => {
  db.favorites = db.favorites.filter((f: any) => !(f.user_id === req.user!.id && f.track_id === req.params.trackId));
  return sendSuccess(res, { message: 'Removed from favorites' });
});

// History
router.get('/history', authGuard, (req: AuthRequest, res) => {
  const history = db.play_history
    .filter((ph: any) => ph.user_id === req.user!.id)
    .sort((a: any, b: any) => new Date(b.played_at).getTime() - new Date(a.played_at).getTime())
    .slice(0, 50)
    .map((ph: any) => {
      const track = db.tracks.find((t: any) => t.id === ph.track_id);
      return track ? { ...track, played_at: ph.played_at, duration_played: ph.duration_played, completed: ph.completed } : null;
    })
    .filter(Boolean);

  return sendSuccess(res, {
    history: history.map((h: any) => ({
      id: h.id,
      title: h.title,
      artist: h.artist,
      album: h.album,
      duration: h.duration,
      coverUrl: h.cover_url,
      playedAt: h.played_at,
      durationPlayed: h.duration_played,
      completed: !!h.completed,
    }))
  });
});

router.post('/history', authGuard, (req: AuthRequest, res) => {
  const { trackId, durationPlayed, completed } = req.body;
  db.play_history.push({
    id: uuidv4(),
    user_id: req.user!.id,
    track_id: trackId,
    played_at: new Date().toISOString(),
    duration_played: durationPlayed || 0,
    completed: completed ? 1 : 0,
  });

  return sendSuccess(res, { message: 'History recorded' }, 201);
});

export default router;
