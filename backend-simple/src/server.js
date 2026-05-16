const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { z } = require('zod');
const fs = require('fs');
const path = require('path');
const multer = require('multer');

// ==================== ENV ====================
const env = {
  NODE_ENV: process.env.NODE_ENV || 'development',
  PORT: parseInt(process.env.PORT || '3333', 10),
  API_PREFIX: process.env.API_PREFIX || '/api/v1',
  APP_NAME: process.env.APP_NAME || 'Betooth Simple Backend',
  APP_URL: process.env.APP_URL || 'http://localhost:3333',
  JWT_ACCESS_SECRET: process.env.JWT_ACCESS_SECRET || 'fallback-access-secret-change-me',
  JWT_REFRESH_SECRET: process.env.JWT_REFRESH_SECRET || 'fallback-refresh-secret-change-me',
  JWT_ACCESS_EXPIRES_IN: process.env.JWT_ACCESS_EXPIRES_IN || '15m',
  JWT_REFRESH_EXPIRES_IN: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
  RATE_LIMIT_WINDOW_MS: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000', 10),
  RATE_LIMIT_MAX_REQUESTS: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100', 10),
  ADMIN_MASTER_PASSWORD: process.env.ADMIN_MASTER_PASSWORD || 'admin123',
  MP_ACCESS_TOKEN: process.env.MP_ACCESS_TOKEN || '',
  MP_WEBHOOK_SECRET: process.env.MP_WEBHOOK_SECRET || '',
  MP_PLAN_PRICE_CENTS: parseInt(process.env.MP_PLAN_PRICE_CENTS || '999', 10),
  MP_PLAN_LABEL: process.env.MP_PLAN_LABEL || 'Betooth VIP Mensal',
  FREE_MONTHLY_DOWNLOAD_LIMIT: parseInt(process.env.FREE_MONTHLY_DOWNLOAD_LIMIT || '5', 10),
  VIP_CACHE_TTL_SECONDS: parseInt(process.env.VIP_CACHE_TTL_SECONDS || '300', 10),
};

// ==================== DATABASE ====================
const DATA_DIR = env.NODE_ENV === 'production' ? './data' : './.tmp';
const DB_FILE = path.join(DATA_DIR, 'betooth.json');

if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

function loadDb() {
  if (fs.existsSync(DB_FILE)) {
    return JSON.parse(fs.readFileSync(DB_FILE, 'utf-8'));
  }
  return {
    users: [], user_sessions: [], devices: [], tracks: [],
    user_library: [], playlists: [], playlist_tracks: [],
    favorites: [], play_history: [], search_history: [],
    downloads: [], subscriptions: [], notifications: [],
  };
}

let db = loadDb();

function saveDb() {
  fs.writeFileSync(DB_FILE, JSON.stringify(db, null, 2));
}

function initDatabase() {
  if (db.tracks.length === 0) {
    db.tracks = [
      { id: 'track-1', title: 'Bohemian Rhapsody', artist: 'Queen', album: 'A Night at the Opera', genre: 'Rock', duration: 354, cover_url: 'https://i.scdn.co/image/ab67616d0000b273e8b066f70c206551210d902b', audio_url: 'https://example.com/audio1.mp3', status: 'ACTIVE', play_count: 0, download_count: 0, created_at: new Date().toISOString() },
      { id: 'track-2', title: 'Hotel California', artist: 'Eagles', album: 'Hotel California', genre: 'Rock', duration: 391, cover_url: 'https://i.scdn.co/image/ab67616d0000b273b5d4c4c7c56f7b7e0e0d3b3b', audio_url: 'https://example.com/audio2.mp3', status: 'ACTIVE', play_count: 0, download_count: 0, created_at: new Date().toISOString() },
      { id: 'track-3', title: 'Imagine', artist: 'John Lennon', album: 'Imagine', genre: 'Pop', duration: 183, cover_url: 'https://i.scdn.co/image/ab67616d0000b273b5d4c4c7c56f7b7e0e0d3b3b', audio_url: 'https://example.com/audio3.mp3', status: 'ACTIVE', play_count: 0, download_count: 0, created_at: new Date().toISOString() },
      { id: 'track-4', title: 'Smells Like Teen Spirit', artist: 'Nirvana', album: 'Nevermind', genre: 'Grunge', duration: 301, cover_url: 'https://i.scdn.co/image/ab67616d0000b273b5d4c4c7c56f7b7e0e0d3b3b', audio_url: 'https://example.com/audio4.mp3', status: 'ACTIVE', play_count: 0, download_count: 0, created_at: new Date().toISOString() },
      { id: 'track-5', title: 'Billie Jean', artist: 'Michael Jackson', album: 'Thriller', genre: 'Pop', duration: 294, cover_url: 'https://i.scdn.co/image/ab67616d0000b273b5d4c4c7c56f7b7e0e0d3b3b', audio_url: 'https://example.com/audio5.mp3', status: 'ACTIVE', play_count: 0, download_count: 0, created_at: new Date().toISOString() },
    ];
    saveDb();
  }
  console.log('[DB] Database initialized');
}

// ==================== HELPERS ====================
class AppError extends Error {
  constructor(message, statusCode = 500, code) {
    super(message);
    this.name = 'AppError';
    this.statusCode = statusCode;
    this.code = code;
  }
}

const sendSuccess = (res, data, statusCode = 200) => res.status(statusCode).json({ success: true, data });

const validateBody = (schema) => (req, res, next) => {
  const result = schema.safeParse(req.body);
  if (!result.success) {
    return res.status(422).json({ success: false, error: { message: 'Validation failed', code: 'VALIDATION_ERROR', details: result.error.flatten() } });
  }
  req.body = result.data;
  next();
};

const authGuard = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      throw new AppError('Unauthorized', 401, 'AUTH_UNAUTHORIZED');
    }
    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, env.JWT_ACCESS_SECRET);
    req.user = { id: decoded.userId, email: decoded.email, role: decoded.role || 'USER' };
    next();
  } catch (error) {
    return res.status(401).json({ success: false, error: { message: 'Unauthorized', code: 'AUTH_UNAUTHORIZED' } });
  }
};

const adminGuard = (req, res, next) => {
  if (req.user?.role !== 'ADMIN') {
    return res.status(403).json({ success: false, error: { message: 'Forbidden', code: 'ADMIN_REQUIRED' } });
  }
  next();
};

// ==================== AUTH ROUTES ====================
const authRouter = express.Router();

const loginSchema = z.object({ email: z.string().email(), password: z.string().min(6), deviceId: z.string().optional(), deviceName: z.string().optional(), devicePlatform: z.enum(['ANDROID', 'IOS', 'WEB', 'UNKNOWN']).optional(), appVersion: z.string().optional(), osVersion: z.string().optional(), pushToken: z.string().optional() });
const registerSchema = z.object({ name: z.string().min(2).max(100), email: z.string().email(), password: z.string().min(6).max(128), birthDate: z.string().optional(), phone: z.string().regex(/^\+?[1-9]\d{9,14}$/).optional(), deviceId: z.string().optional(), deviceName: z.string().optional(), devicePlatform: z.enum(['ANDROID', 'IOS', 'WEB', 'UNKNOWN']).optional(), appVersion: z.string().optional(), osVersion: z.string().optional(), pushToken: z.string().optional() });

function signAccessToken(user, sessionId) {
  return jwt.sign({ userId: user.id, email: user.email, role: user.role, sessionId, type: 'access' }, env.JWT_ACCESS_SECRET, { expiresIn: env.JWT_ACCESS_EXPIRES_IN });
}

function signRefreshToken(user, sessionId) {
  return jwt.sign({ userId: user.id, email: user.email, sessionId, type: 'refresh' }, env.JWT_REFRESH_SECRET, { expiresIn: env.JWT_REFRESH_EXPIRES_IN });
}

function createSession(user, context) {
  const sessionId = uuidv4();
  const refreshToken = signRefreshToken(user, sessionId);
  const accessToken = signAccessToken(user, sessionId);
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + 7);
  db.user_sessions.push({ id: sessionId, user_id: user.id, refresh_token_hash: bcrypt.hashSync(refreshToken, 8), expires_at: expiresAt.toISOString(), ip_address: context.ip, user_agent: context.userAgent, status: 'ACTIVE', revoked_at: null, created_at: new Date().toISOString() });
  saveDb();
  return { accessToken, refreshToken };
}

authRouter.post('/register', validateBody(registerSchema), (req, res, next) => {
  try {
    const input = req.body;
    const email = input.email.toLowerCase().trim();
    if (db.users.find(u => u.email === email)) {
      throw new AppError('Email is already in use', 409, 'AUTH_EMAIL_IN_USE');
    }
    const passwordHash = bcrypt.hashSync(input.password, 12);
    const userId = uuidv4();
    const user = { id: userId, email, username: null, display_name: input.name.trim(), password_hash: passwordHash, birth_date: input.birthDate || null, phone: input.phone || null, avatar_url: null, bio: null, role: 'USER', status: 'ACTIVE', is_email_verified: 0, last_login_at: null, created_at: new Date().toISOString(), updated_at: new Date().toISOString(), deleted_at: null };
    db.users.push(user);
    if (input.deviceId) {
      db.devices.push({ id: uuidv4(), user_id: userId, device_identifier: input.deviceId, name: input.deviceName || null, platform: input.devicePlatform || 'UNKNOWN', app_version: input.appVersion || null, os_version: input.osVersion || null, push_token: input.pushToken || null, last_seen_at: new Date().toISOString(), created_at: new Date().toISOString() });
    }
    saveDb();
    const session = createSession(user, { ip: req.ip, userAgent: req.headers['user-agent'] });
    return sendSuccess(res, { user: { id: user.id, email: user.email, name: user.display_name, role: user.role, status: user.status, isEmailVerified: !!user.is_email_verified, avatarUrl: user.avatar_url, birthDate: user.birth_date, phone: user.phone, createdAt: user.created_at }, ...session }, 201);
  } catch (error) { next(error); }
});

authRouter.post('/login', validateBody(loginSchema), (req, res, next) => {
  try {
    const input = req.body;
    const email = input.email.toLowerCase().trim();
    const user = db.users.find(u => u.email === email && u.deleted_at === null);
    if (!user) throw new AppError('Invalid email or password', 401, 'AUTH_INVALID_CREDENTIALS');
    if (user.status === 'SUSPENDED') throw new AppError('Account is suspended', 403, 'AUTH_ACCOUNT_SUSPENDED');
    if (user.status === 'BANNED') throw new AppError('Account is banned', 403, 'AUTH_ACCOUNT_BANNED');
    if (!bcrypt.compareSync(input.password, user.password_hash)) throw new AppError('Invalid email or password', 401, 'AUTH_INVALID_CREDENTIALS');
    user.last_login_at = new Date().toISOString();
    saveDb();
    const session = createSession(user, { ip: req.ip, userAgent: req.headers['user-agent'] });
    return sendSuccess(res, { user: { id: user.id, email: user.email, name: user.display_name, role: user.role, status: user.status, isEmailVerified: !!user.is_email_verified, avatarUrl: user.avatar_url, birthDate: user.birth_date, phone: user.phone, createdAt: user.created_at }, ...session });
  } catch (error) { next(error); }
});

authRouter.post('/refresh', (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    const payload = jwt.verify(refreshToken, env.JWT_REFRESH_SECRET);
    if (payload.type !== 'refresh' || !payload.sessionId) throw new AppError('Invalid refresh token', 401, 'AUTH_REFRESH_INVALID');
    const session = db.user_sessions.find(s => s.id === payload.sessionId);
    if (!session || session.status !== 'ACTIVE' || new Date(session.expires_at) <= new Date()) throw new AppError('Invalid refresh token', 401, 'AUTH_REFRESH_INVALID');
    const user = db.users.find(u => u.id === session.user_id);
    if (!user) throw new AppError('User not found', 401, 'AUTH_REFRESH_INVALID');
    return sendSuccess(res, { accessToken: signAccessToken(user, session.id) });
  } catch (error) { next(error); }
});

authRouter.post('/logout', authGuard, (req, res, next) => {
  try {
    const token = req.headers.authorization.split(' ')[1];
    const payload = jwt.verify(token, env.JWT_ACCESS_SECRET);
    const session = db.user_sessions.find(s => s.id === payload.sessionId);
    if (session) { session.status = 'REVOKED'; session.revoked_at = new Date().toISOString(); saveDb(); }
    return sendSuccess(res, { message: 'Logged out successfully' });
  } catch (error) { next(error); }
});

authRouter.get('/me', authGuard, (req, res, next) => {
  try {
    const user = db.users.find(u => u.id === req.user.id);
    if (!user) throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    return sendSuccess(res, { id: user.id, email: user.email, name: user.display_name, role: user.role, status: user.status, isEmailVerified: !!user.is_email_verified, avatarUrl: user.avatar_url, birthDate: user.birth_date, phone: user.phone, createdAt: user.created_at });
  } catch (error) { next(error); }
});

// ==================== MUSIC ROUTES ====================
const musicRouter = express.Router();

musicRouter.get('/tracks', (req, res) => {
  const { q, page = 1, limit = 20, genre } = req.query;
  const offset = (page - 1) * limit;
  let tracks = db.tracks.filter(t => t.status === 'ACTIVE');
  if (q) {
    const like = q.toLowerCase();
    tracks = tracks.filter(t => t.title?.toLowerCase().includes(like) || t.artist?.toLowerCase().includes(like) || t.album?.toLowerCase().includes(like));
  }
  if (genre) tracks = tracks.filter(t => t.genre === genre);
  const total = tracks.length;
  tracks = tracks.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()).slice(offset, offset + limit);
  return sendSuccess(res, { tracks: tracks.map(t => ({ id: t.id, title: t.title, artist: t.artist, album: t.album, genre: t.genre, duration: t.duration, coverUrl: t.cover_url, audioUrl: t.audio_url, playCount: t.play_count, downloadCount: t.download_count })), meta: { pagination: { page: parseInt(page), limit: parseInt(limit), total, totalPages: Math.ceil(total / limit) } } });
});

musicRouter.get('/tracks/:id', authGuard, (req, res, next) => {
  try {
    const track = db.tracks.find(t => t.id === req.params.id && t.status === 'ACTIVE');
    if (!track) throw new AppError('Track not found', 404, 'TRACK_NOT_FOUND');
    track.play_count = (track.play_count || 0) + 1; saveDb();
    return sendSuccess(res, { id: track.id, title: track.title, artist: track.artist, album: track.album, genre: track.genre, duration: track.duration, coverUrl: track.cover_url, audioUrl: track.audio_url, playCount: track.play_count, downloadCount: track.download_count });
  } catch (error) { next(error); }
});

musicRouter.get('/genres', (req, res) => {
  const genres = [...new Set(db.tracks.filter(t => t.status === 'ACTIVE' && t.genre).map(t => t.genre))];
  return sendSuccess(res, { genres });
});

// ==================== LIBRARY ROUTES ====================
const libraryRouter = express.Router();

libraryRouter.get('/library', authGuard, (req, res) => {
  const items = db.user_library.filter(ul => ul.user_id === req.user.id).map(ul => db.tracks.find(t => t.id === ul.track_id && t.status === 'ACTIVE')).filter(Boolean);
  return sendSuccess(res, { tracks: items.map(t => ({ id: t.id, title: t.title, artist: t.artist, album: t.album, genre: t.genre, duration: t.duration, coverUrl: t.cover_url, audioUrl: t.audio_url })) });
});

libraryRouter.post('/library/:trackId', authGuard, (req, res, next) => {
  try {
    if (db.user_library.find(ul => ul.user_id === req.user.id && ul.track_id === req.params.trackId)) {
      throw new AppError('Track already in library', 409, 'LIBRARY_DUPLICATE');
    }
    db.user_library.push({ id: uuidv4(), user_id: req.user.id, track_id: req.params.trackId, added_at: new Date().toISOString() }); saveDb();
    return sendSuccess(res, { message: 'Added to library' }, 201);
  } catch (error) { next(error); }
});

libraryRouter.delete('/library/:trackId', authGuard, (req, res) => {
  db.user_library = db.user_library.filter(ul => !(ul.user_id === req.user.id && ul.track_id === req.params.trackId)); saveDb();
  return sendSuccess(res, { message: 'Removed from library' });
});

libraryRouter.get('/playlists', authGuard, (req, res) => {
  const playlists = db.playlists.filter(p => p.user_id === req.user.id).sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
  return sendSuccess(res, { playlists: playlists.map(p => ({ id: p.id, name: p.name, description: p.description, coverUrl: p.cover_url, isPublic: !!p.is_public, trackCount: db.playlist_tracks.filter(pt => pt.playlist_id === p.id).length, createdAt: p.created_at, updatedAt: p.updated_at })) });
});

libraryRouter.post('/playlists', authGuard, (req, res, next) => {
  try {
    const { name, description, isPublic } = req.body;
    const id = uuidv4();
    db.playlists.push({ id, user_id: req.user.id, name, description: description || null, cover_url: null, is_public: isPublic ? 1 : 0, created_at: new Date().toISOString(), updated_at: new Date().toISOString() }); saveDb();
    return sendSuccess(res, { id, name, description, isPublic: !!isPublic }, 201);
  } catch (error) { next(error); }
});

libraryRouter.get('/favorites', authGuard, (req, res) => {
  const tracks = db.favorites.filter(f => f.user_id === req.user.id).map(f => db.tracks.find(t => t.id === f.track_id && t.status === 'ACTIVE')).filter(Boolean);
  return sendSuccess(res, { tracks: tracks.map(t => ({ id: t.id, title: t.title, artist: t.artist, album: t.album, duration: t.duration, coverUrl: t.cover_url, audioUrl: t.audio_url })) });
});

libraryRouter.post('/favorites/:trackId', authGuard, (req, res, next) => {
  try {
    if (db.favorites.find(f => f.user_id === req.user.id && f.track_id === req.params.trackId)) {
      throw new AppError('Track already favorited', 409, 'FAVORITE_DUPLICATE');
    }
    db.favorites.push({ id: uuidv4(), user_id: req.user.id, track_id: req.params.trackId, created_at: new Date().toISOString() }); saveDb();
    return sendSuccess(res, { message: 'Added to favorites' }, 201);
  } catch (error) { next(error); }
});

libraryRouter.delete('/favorites/:trackId', authGuard, (req, res) => {
  db.favorites = db.favorites.filter(f => !(f.user_id === req.user.id && f.track_id === req.params.trackId)); saveDb();
  return sendSuccess(res, { message: 'Removed from favorites' });
});

// ==================== DOWNLOADS ROUTES ====================
const downloadsRouter = express.Router();

function getDownloadCount(userId, month, year) {
  const start = new Date(year, month - 1, 1).toISOString();
  const end = new Date(year, month, 1).toISOString();
  return db.downloads.filter(d => d.user_id === userId && d.downloaded_at >= start && d.downloaded_at < end).length;
}

function isVip(userId) {
  const sub = db.subscriptions.find(s => s.user_id === userId && s.status === 'ACTIVE');
  return sub && new Date(sub.expires_at) > new Date();
}

downloadsRouter.post('/:trackId', authGuard, (req, res, next) => {
  try {
    const track = db.tracks.find(t => t.id === req.params.trackId && t.status === 'ACTIVE');
    if (!track) throw new AppError('Track not found', 404, 'TRACK_NOT_FOUND');
    const now = new Date();
    const downloadCount = getDownloadCount(req.user.id, now.getMonth() + 1, now.getFullYear());
    if (!isVip(req.user.id) && downloadCount >= env.FREE_MONTHLY_DOWNLOAD_LIMIT) {
      throw new AppError('Download limit reached. Upgrade to VIP.', 403, 'DOWNLOAD_LIMIT_REACHED');
    }
    db.downloads.push({ id: uuidv4(), user_id: req.user.id, track_id: req.params.trackId, downloaded_at: new Date().toISOString(), expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString() });
    track.download_count = (track.download_count || 0) + 1; saveDb();
    return sendSuccess(res, { message: 'Download authorized', track: { id: track.id, title: track.title, artist: track.artist, audioUrl: track.audio_url } });
  } catch (error) { next(error); }
});

downloadsRouter.get('/quota', authGuard, (req, res) => {
  const now = new Date();
  const used = getDownloadCount(req.user.id, now.getMonth() + 1, now.getFullYear());
  const vip = isVip(req.user.id);
  return sendSuccess(res, { used, limit: env.FREE_MONTHLY_DOWNLOAD_LIMIT, remaining: Math.max(0, env.FREE_MONTHLY_DOWNLOAD_LIMIT - used), isVip: vip, unlimited: vip });
});

// ==================== SUBSCRIPTIONS ROUTES ====================
const subscriptionsRouter = express.Router();

subscriptionsRouter.get('/status', authGuard, (req, res) => {
  const sub = db.subscriptions.find(s => s.user_id === req.user.id);
  if (!sub || sub.status !== 'ACTIVE') return sendSuccess(res, { isVip: false, status: sub?.status || 'INACTIVE', plan: null, expiresAt: null });
  return sendSuccess(res, { isVip: true, status: sub.status, plan: { priceCents: sub.plan_price_cents, label: env.MP_PLAN_LABEL }, expiresAt: sub.expires_at, startedAt: sub.started_at });
});

subscriptionsRouter.post('/webhook', (req, res) => {
  console.log('[WEBHOOK] Received:', req.body.type, JSON.stringify(req.body.data));
  return sendSuccess(res, { received: true });
});

subscriptionsRouter.post('/create', authGuard, (req, res, next) => {
  try {
    const existing = db.subscriptions.find(s => s.user_id === req.user.id);
    if (existing && existing.status === 'ACTIVE') throw new AppError('Already subscribed', 409, 'SUBSCRIPTION_ACTIVE');
    const now = new Date();
    const expiresAt = new Date();
    expiresAt.setMonth(expiresAt.getMonth() + 1);
    if (existing) {
      existing.status = 'ACTIVE'; existing.mp_subscription_id = 'mock-mp-id'; existing.plan_price_cents = env.MP_PLAN_PRICE_CENTS; existing.started_at = now.toISOString(); existing.expires_at = expiresAt.toISOString(); existing.updated_at = now.toISOString();
    } else {
      db.subscriptions.push({ id: uuidv4(), user_id: req.user.id, mp_subscription_id: 'mock-mp-id', status: 'ACTIVE', plan_price_cents: env.MP_PLAN_PRICE_CENTS, started_at: now.toISOString(), expires_at: expiresAt.toISOString(), cancelled_at: null, created_at: now.toISOString(), updated_at: now.toISOString() });
    }
    saveDb();
    return sendSuccess(res, { message: 'Subscription created', expiresAt: expiresAt.toISOString() }, 201);
  } catch (error) { next(error); }
});

subscriptionsRouter.post('/cancel', authGuard, (req, res) => {
  const sub = db.subscriptions.find(s => s.user_id === req.user.id);
  if (sub) { sub.status = 'CANCELLED'; sub.cancelled_at = new Date().toISOString(); sub.updated_at = new Date().toISOString(); saveDb(); }
  return sendSuccess(res, { message: 'Subscription cancelled' });
});

// ==================== ADMIN ROUTES ====================
const adminRouter = express.Router();

// Special endpoint to promote user to admin (using master password)
adminRouter.post('/make-admin', (req, res, next) => {
  try {
    const { email, masterPassword } = req.body;
    if (masterPassword !== env.ADMIN_MASTER_PASSWORD) {
      throw new AppError('Invalid master password', 403, 'FORBIDDEN');
    }
    const user = db.users.find(u => u.email === email && u.deleted_at === null);
    if (!user) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }
    user.role = 'ADMIN';
    user.updated_at = new Date().toISOString();
    saveDb();
    return sendSuccess(res, { message: 'User promoted to admin', user: { id: user.id, email: user.email, role: user.role } });
  } catch (error) { next(error); }
});

adminRouter.post('/tracks/upload', authGuard, adminGuard, upload.single('audio'), (req, res, next) => {
  try {
    if (!req.file) {
      throw new AppError('No audio file provided', 400, 'NO_FILE');
    }

    const { title, artist, album, genre } = req.body;
    if (!title || !artist) {
      throw new AppError('Title and artist are required', 422, 'VALIDATION_ERROR');
    }

    const id = uuidv4();
    const audioUrl = `${env.APP_URL}/uploads/${req.file.filename}`;

    db.tracks.push({
      id,
      title,
      artist,
      album: album || null,
      genre: genre || null,
      duration: 0,
      cover_url: null,
      audio_url: audioUrl,
      file_size: req.file.size,
      bitrate: null,
      sample_rate: null,
      lyrics: null,
      is_explicit: 0,
      play_count: 0,
      download_count: 0,
      status: 'ACTIVE',
      uploaded_by: req.user.id,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    });
    saveDb();

    return sendSuccess(res, { id, title, artist, audioUrl, message: 'Track uploaded successfully' }, 201);
  } catch (error) { next(error); }
});

adminRouter.get('/stats', authGuard, adminGuard, (req, res) => {
  return sendSuccess(res, {
    totalUsers: db.users.filter(u => u.deleted_at === null).length,
    totalTracks: db.tracks.length,
    totalDownloads: db.downloads.length,
    activeSubscriptions: db.subscriptions.filter(s => s.status === 'ACTIVE').length,
  });
});

adminRouter.get('/users', authGuard, adminGuard, (req, res) => {
  return sendSuccess(res, { users: db.users.filter(u => u.deleted_at === null).sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()).map(u => ({ id: u.id, email: u.email, display_name: u.display_name, role: u.role, status: u.status, created_at: u.created_at })) });
});

adminRouter.patch('/users/:id/status', authGuard, adminGuard, (req, res) => {
  const user = db.users.find(u => u.id === req.params.id);
  if (user) { user.status = req.body.status; user.updated_at = new Date().toISOString(); saveDb(); }
  return sendSuccess(res, { message: 'User status updated' });
});

adminRouter.get('/notifications', authGuard, (req, res) => {
  return sendSuccess(res, { notifications: db.notifications.filter(n => n.user_id === req.user.id).sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()).slice(0, 50).map(n => ({ id: n.id, title: n.title, body: n.body, type: n.type, isRead: !!n.is_read, createdAt: n.created_at })) });
});

adminRouter.post('/notifications/:id/read', authGuard, (req, res) => {
  const notif = db.notifications.find(n => n.id === req.params.id && n.user_id === req.user.id);
  if (notif) { notif.is_read = 1; saveDb(); }
  return sendSuccess(res, { message: 'Notification marked as read' });
});

// ==================== UPLOAD CONFIG ====================
const UPLOAD_DIR = path.join(DATA_DIR, 'uploads');
if (!fs.existsSync(UPLOAD_DIR)) {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, UPLOAD_DIR);
  },
  filename: (req, file, cb) => {
    const uniqueName = `${uuidv4()}-${file.originalname}`;
    cb(null, uniqueName);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 100 * 1024 * 1024 }, // 100MB
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['audio/mpeg', 'audio/mp3', 'audio/mp4', 'audio/m4a', 'audio/wav', 'audio/flac', 'audio/ogg', 'audio/x-m4a'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new AppError('Invalid file type. Only audio files allowed.', 400, 'INVALID_FILE_TYPE'), false);
    }
  }
});

// ==================== APP ====================
const app = express();

app.use(helmet());
app.use(cors({ origin: '*' }));
app.use(rateLimit({ windowMs: env.RATE_LIMIT_WINDOW_MS, max: env.RATE_LIMIT_MAX_REQUESTS, standardHeaders: true, legacyHeaders: false }));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.set('trust proxy', 1);

// Serve uploaded files statically
app.use('/uploads', express.static(UPLOAD_DIR));

initDatabase();

app.get(`${env.API_PREFIX}/health`, (req, res) => {
  return res.json({ success: true, data: { status: 'ok', service: env.APP_NAME } });
});

app.use(`${env.API_PREFIX}/auth`, authRouter);
app.use(`${env.API_PREFIX}/music`, musicRouter);
app.use(`${env.API_PREFIX}/library`, libraryRouter);
app.use(`${env.API_PREFIX}/downloads`, downloadsRouter);
app.use(`${env.API_PREFIX}/subscriptions`, subscriptionsRouter);
app.use(`${env.API_PREFIX}/admin`, adminRouter);

app.use((req, res) => {
  return res.status(404).json({ success: false, error: { message: `Route ${req.method} ${req.originalUrl} not found`, code: 'ROUTE_NOT_FOUND' } });
});

app.use((error, req, res, _next) => {
  if (error instanceof AppError) {
    return res.status(error.statusCode).json({ success: false, error: { message: error.message, code: error.code || 'UNKNOWN_ERROR' } });
  }
  console.error('[ERROR]', req.method, req.originalUrl, error.message, error.stack);
  return res.status(500).json({ success: false, error: { message: 'Internal server error', code: 'INTERNAL_SERVER_ERROR' } });
});

const PORT = env.PORT;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`[SERVER] ${env.APP_NAME} running on port ${PORT}`);
  console.log(`[SERVER] Health check: http://localhost:${PORT}${env.API_PREFIX}/health`);
});
