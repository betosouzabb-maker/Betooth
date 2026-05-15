const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { z } = require('zod');
const { db, findOne, insert, update } = require('./database');
const { env } = require('./env');
const { AppError } = require('./error-handler');
const { validateBody } = require('./validator');
const { authGuard } = require('./auth-guard');
const { sendSuccess } = require('./response');

const router = express.Router();

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
  deviceId: z.string().optional(),
  deviceName: z.string().optional(),
  devicePlatform: z.enum(['ANDROID', 'IOS', 'WEB', 'UNKNOWN']).optional(),
  appVersion: z.string().optional(),
  osVersion: z.string().optional(),
  pushToken: z.string().optional(),
});

const registerSchema = z.object({
  name: z.string().min(2).max(100),
  email: z.string().email(),
  password: z.string().min(6).max(128),
  birthDate: z.string().datetime().optional(),
  phone: z.string().regex(/^\+?[1-9]\d{9,14}$/).optional(),
  deviceId: z.string().optional(),
  deviceName: z.string().optional(),
  devicePlatform: z.enum(['ANDROID', 'IOS', 'WEB', 'UNKNOWN']).optional(),
  appVersion: z.string().optional(),
  osVersion: z.string().optional(),
  pushToken: z.string().optional(),
});

const refreshSchema = z.object({
  refreshToken: z.string(),
});

function signAccessToken(user, sessionId) {
  return jwt.sign(
    { userId: user.id, email: user.email, role: user.role, sessionId, type: 'access' },
    env.JWT_ACCESS_SECRET,
    { expiresIn: env.JWT_ACCESS_EXPIRES_IN }
  );
}

function signRefreshToken(user, sessionId) {
  return jwt.sign(
    { userId: user.id, email: user.email, sessionId, type: 'refresh' },
    env.JWT_REFRESH_SECRET,
    { expiresIn: env.JWT_REFRESH_EXPIRES_IN }
  );
}

function createSession(user, context) {
  const sessionId = uuidv4();
  const refreshToken = signRefreshToken(user, sessionId);
  const accessToken = signAccessToken(user, sessionId);

  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + 7);

  insert('user_sessions', {
    id: sessionId,
    user_id: user.id,
    refresh_token_hash: bcrypt.hashSync(refreshToken, 8),
    expires_at: expiresAt.toISOString(),
    ip_address: context.ip,
    user_agent: context.userAgent,
    status: 'ACTIVE',
    revoked_at: null,
    created_at: new Date().toISOString(),
  });

  return { accessToken, refreshToken };
}

router.post('/register', validateBody(registerSchema), (req, res, next) => {
  try {
    const input = req.body;
    const email = input.email.toLowerCase().trim();

    const existing = findOne('users', u => u.email === email);
    if (existing) {
      throw new AppError('Email is already in use', 409, 'AUTH_EMAIL_IN_USE');
    }

    const passwordHash = bcrypt.hashSync(input.password, 12);
    const userId = uuidv4();

    const user = {
      id: userId,
      email,
      username: null,
      display_name: input.name.trim(),
      password_hash: passwordHash,
      birth_date: input.birthDate || null,
      phone: input.phone || null,
      avatar_url: null,
      bio: null,
      role: 'USER',
      status: 'ACTIVE',
      is_email_verified: 0,
      last_login_at: null,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      deleted_at: null,
    };

    insert('users', user);

    if (input.deviceId) {
      insert('devices', {
        id: uuidv4(),
        user_id: userId,
        device_identifier: input.deviceId,
        name: input.deviceName || null,
        platform: input.devicePlatform || 'UNKNOWN',
        app_version: input.appVersion || null,
        os_version: input.osVersion || null,
        push_token: input.pushToken || null,
        last_seen_at: new Date().toISOString(),
        created_at: new Date().toISOString(),
      });
    }

    const context = { ip: req.ip, userAgent: req.headers['user-agent'] };
    const session = createSession(user, context);

    return sendSuccess(res, {
      user: {
        id: user.id,
        email: user.email,
        name: user.display_name,
        role: user.role,
        status: user.status,
        isEmailVerified: !!user.is_email_verified,
        avatarUrl: user.avatar_url,
        birthDate: user.birth_date,
        phone: user.phone,
        createdAt: user.created_at,
      },
      ...session
    }, 201);
  } catch (error) {
    next(error);
  }
});

router.post('/login', validateBody(loginSchema), (req, res, next) => {
  try {
    const input = req.body;
    const email = input.email.toLowerCase().trim();

    const user = findOne('users', u => u.email === email && u.deleted_at === null);
    if (!user) {
      throw new AppError('Invalid email or password', 401, 'AUTH_INVALID_CREDENTIALS');
    }

    if (user.status === 'SUSPENDED') {
      throw new AppError('Account is suspended', 403, 'AUTH_ACCOUNT_SUSPENDED');
    }
    if (user.status === 'BANNED') {
      throw new AppError('Account is banned', 403, 'AUTH_ACCOUNT_BANNED');
    }

    const valid = bcrypt.compareSync(input.password, user.password_hash);
    if (!valid) {
      throw new AppError('Invalid email or password', 401, 'AUTH_INVALID_CREDENTIALS');
    }

    update('users', u => u.id === user.id, u => ({ ...u, last_login_at: new Date().toISOString() }));

    if (input.deviceId) {
      const existingDevice = findOne('devices', d => d.device_identifier === input.deviceId);
      if (existingDevice) {
        update('devices', d => d.device_identifier === input.deviceId, d => ({
          ...d,
          user_id: user.id,
          name: input.deviceName || d.name,
          platform: input.devicePlatform || d.platform,
          app_version: input.appVersion || d.app_version,
          os_version: input.osVersion || d.os_version,
          push_token: input.pushToken || d.push_token,
          last_seen_at: new Date().toISOString(),
        }));
      } else {
        insert('devices', {
          id: uuidv4(),
          user_id: user.id,
          device_identifier: input.deviceId,
          name: input.deviceName || null,
          platform: input.devicePlatform || 'UNKNOWN',
          app_version: input.appVersion || null,
          os_version: input.osVersion || null,
          push_token: input.pushToken || null,
          last_seen_at: new Date().toISOString(),
          created_at: new Date().toISOString(),
        });
      }
    }

    const context = { ip: req.ip, userAgent: req.headers['user-agent'] };
    const session = createSession(user, context);

    return sendSuccess(res, {
      user: {
        id: user.id,
        email: user.email,
        name: user.display_name,
        role: user.role,
        status: user.status,
        isEmailVerified: !!user.is_email_verified,
        avatarUrl: user.avatar_url,
        birthDate: user.birth_date,
        phone: user.phone,
        createdAt: user.created_at,
      },
      ...session
    });
  } catch (error) {
    next(error);
  }
});

router.post('/refresh', validateBody(refreshSchema), (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    const payload = jwt.verify(refreshToken, env.JWT_REFRESH_SECRET);

    if (payload.type !== 'refresh' || !payload.sessionId) {
      throw new AppError('Invalid refresh token', 401, 'AUTH_REFRESH_INVALID');
    }

    const session = findOne('user_sessions', s => s.id === payload.sessionId);
    if (!session || session.status !== 'ACTIVE' || new Date(session.expires_at) <= new Date()) {
      throw new AppError('Invalid refresh token', 401, 'AUTH_REFRESH_INVALID');
    }

    const user = findOne('users', u => u.id === session.user_id);
    if (!user) {
      throw new AppError('User not found', 401, 'AUTH_REFRESH_INVALID');
    }

    const newAccessToken = signAccessToken(user, session.id);

    return sendSuccess(res, { accessToken: newAccessToken });
  } catch (error) {
    next(error);
  }
});

router.post('/logout', authGuard, (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    const token = authHeader.split(' ')[1];
    const payload = jwt.verify(token, env.JWT_ACCESS_SECRET);

    update('user_sessions', s => s.id === payload.sessionId, s => ({
      ...s,
      status: 'REVOKED',
      revoked_at: new Date().toISOString(),
    }));

    return sendSuccess(res, { message: 'Logged out successfully' });
  } catch (error) {
    next(error);
  }
});

router.get('/me', authGuard, (req, res, next) => {
  try {
    const user = findOne('users', u => u.id === req.user.id);
    if (!user) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }

    return sendSuccess(res, {
      id: user.id,
      email: user.email,
      name: user.display_name,
      role: user.role,
      status: user.status,
      isEmailVerified: !!user.is_email_verified,
      avatarUrl: user.avatar_url,
      birthDate: user.birth_date,
      phone: user.phone,
      createdAt: user.created_at,
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
