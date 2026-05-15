const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { db } = require('../../infra/database');
const { authGuard } = require('../../common/auth-guard');
const { sendSuccess } = require('../../common/response');
const { AppError } = require('../../common/error-handler');

const router = express.Router();

// Library
router.get('/library', authGuard, (req, res) => {
  const items = db.user_library
    .filter(ul => ul.user_id === req.user.id)
    .map(ul => db.tracks.find(t => t.id === ul.track_id && t.status === 'ACTIVE'))
    .filter(Boolean);

  return sendSuccess(res, {
    tracks: items.map(t => ({
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

router.post('/library/:trackId', authGuard, (req, res, next) => {
  try {
    const existing = db.user_library.find(ul => ul.user_id === req.user.id && ul.track_id === req.params.trackId);
    if (existing) {
      throw new AppError('Track already in library', 409, 'LIBRARY_DUPLICATE');
    }

    db.user_library.push({
      id: uuidv4(),
      user_id: req.user.id,
      track_id: req.params.trackId,
      added_at: new Date().toISOString(),
    });

    return sendSuccess(res, { message: 'Added to library' }, 201);
  } catch (error) {
    next(error);
  }
});

router.delete('/library/:trackId', authGuard, (req, res) => {
  db.user_library = db.user_library.filter(ul => !(ul.user_id === req.user.id && ul.track_id === req.params.trackId));
  return sendSuccess(res, { message: 'Removed from library' });
});

// Playlists
router.get('/playlists', authGuard, (req, res) => {
  const playlists = db.playlists
    .filter(p => p.user_id === req.user.id)
    .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());

  return sendSuccess(res, {
    playlists: playlists.map(p => {
      const trackCount = db.playlist_tracks.filter(pt => pt.playlist_id === p.id).length;
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

router.post('/playlists', authGuard, (req, res, next) => {
  try {
    const { name, description, isPublic } = req.body;
    const id = uuidv4();

    db.playlists.push({
      id,
      user_id: req.user.id,
      name,
      description: description || null,
      cover_url: null,
      is_public: isPublic ? 1 : 0,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    });

    return sendSuccess(res, { id, name, description, isPublic: !!isPublic }, 201);
  } catch (error) {
    next(error);
  }
});

router.get('/playlists/:id', authGuard, (req, res, next) => {
  try {
    const playlist = db.playlists.find(p => p.id === req.params.id);
    if (!playlist) {
      throw new AppError('Playlist not found', 404, 'PLAYLIST_NOT_FOUND');
    }

    const tracks = db.playlist_tracks
      .filter(pt => pt.playlist_id === req.params.id)
      .sort((a, b) => a.position - b.position)
      .map(pt => db.tracks.find(t => t.id === pt.track_id))
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
      tracks: tracks.map(t => ({
        id: t.id,
        title: t.title,
        artist: t.artist,
        album: t.album,
        duration: t.duration,
        coverUrl: t.cover_url,
        audioUrl: t.audio_url,
      }))
    });
  } catch (error) {
    next(error);
  }
});

router.post('/playlists/:id/tracks', authGuard, (req, res, next) => {
  try {
    const { trackId } = req.body;
    const maxPos = db.playlist_tracks
      .filter(pt => pt.playlist_id === req.params.id)
      .reduce((max, pt) => Math.max(max, pt.position || 0), 0);

    db.playlist_tracks.push({
      id: uuidv4(),
      playlist_id: req.params.id,
      track_id: trackId,
      position: maxPos + 1,
      added_at: new Date().toISOString(),
    });

    return sendSuccess(res, { message: 'Track added to playlist' }, 201);
  } catch (error) {
    next(error);
  }
});

router.delete('/playlists/:id/tracks/:trackId', authGuard, (req, res) => {
  db.playlist_tracks = db.playlist_tracks.filter(pt => !(pt.playlist_id === req.params.id && pt.track_id === req.params.trackId));
  return sendSuccess(res, { message: 'Track removed from playlist' });
});

router.delete('/playlists/:id', authGuard, (req, res) => {
  db.playlists = db.playlists.filter(p => !(p.id === req.params.id && p.user_id === req.user.id));
  db.playlist_tracks = db.playlist_tracks.filter(pt => pt.playlist_id !== req.params.id);
  return sendSuccess(res, { message: 'Playlist deleted' });
});

// Favorites
router.get('/favorites', authGuard, (req, res) => {
  const tracks = db.favorites
    .filter(f => f.user_id === req.user.id)
    .map(f => db.tracks.find(t => t.id === f.track_id && t.status === 'ACTIVE'))
    .filter(Boolean);

  return sendSuccess(res, {
    tracks: tracks.map(t => ({
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

router.post('/favorites/:trackId', authGuard, (req, res, next) => {
  try {
    const existing = db.favorites.find(f => f.user_id === req.user.id && f.track_id === req.params.trackId);
    if (existing) {
      throw new AppError('Track already favorited', 409, 'FAVORITE_DUPLICATE');
    }

    db.favorites.push({
      id: uuidv4(),
      user_id: req.user.id,
      track_id: req.params.trackId,
      created_at: new Date().toISOString(),
    });

    return sendSuccess(res, { message: 'Added to favorites' }, 201);
  } catch (error) {
    next(error);
  }
});

router.delete('/favorites/:trackId', authGuard, (req, res) => {
  db.favorites = db.favorites.filter(f => !(f.user_id === req.user.id && f.track_id === req.params.trackId));
  return sendSuccess(res, { message: 'Removed from favorites' });
});

// History
router.get('/history', authGuard, (req, res) => {
  const history = db.play_history
    .filter(ph => ph.user_id === req.user.id)
    .sort((a, b) => new Date(b.played_at).getTime() - new Date(a.played_at).getTime())
    .slice(0, 50)
    .map(ph => {
      const track = db.tracks.find(t => t.id === ph.track_id);
      return track ? { ...track, played_at: ph.played_at, duration_played: ph.duration_played, completed: ph.completed } : null;
    })
    .filter(Boolean);

  return sendSuccess(res, {
    history: history.map(h => ({
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

router.post('/history', authGuard, (req, res, next) => {
  try {
    const { trackId, durationPlayed, completed } = req.body;
    db.play_history.push({
      id: uuidv4(),
      user_id: req.user.id,
      track_id: trackId,
      played_at: new Date().toISOString(),
      duration_played: durationPlayed || 0,
      completed: completed ? 1 : 0,
    });

    return sendSuccess(res, { message: 'History recorded' }, 201);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
