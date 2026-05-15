const jwt = require('jsonwebtoken');
const { env } = require('../config/env');
const { AppError } = require('./error-handler');

const authGuard = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      throw new AppError('Unauthorized', 401, 'AUTH_UNAUTHORIZED');
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, env.JWT_ACCESS_SECRET);

    req.user = {
      id: decoded.userId,
      email: decoded.email,
      role: decoded.role || 'USER'
    };

    next();
  } catch (error) {
    if (error instanceof AppError) {
      return res.status(error.statusCode).json({ success: false, error: { message: error.message, code: error.code } });
    }
    return res.status(401).json({ success: false, error: { message: 'Unauthorized', code: 'AUTH_UNAUTHORIZED' } });
  }
};

const adminGuard = (req, res, next) => {
  if (req.user?.role !== 'ADMIN') {
    return res.status(403).json({ success: false, error: { message: 'Forbidden', code: 'ADMIN_REQUIRED' } });
  }
  next();
};

const vipGuard = async (req, res, next) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      throw new AppError('Unauthorized', 401, 'AUTH_UNAUTHORIZED');
    }

    const { db } = require('../infra/database');
    const sub = db.subscriptions.find(s => s.user_id === userId && s.status === 'ACTIVE');
    if (!sub) {
      throw new AppError('VIP subscription required', 403, 'VIP_REQUIRED');
    }

    next();
  } catch (error) {
    if (error instanceof AppError) {
      return res.status(error.statusCode).json({ success: false, error: { message: error.message, code: error.code } });
    }
    return res.status(500).json({ success: false, error: { message: 'Internal server error', code: 'INTERNAL_SERVER_ERROR' } });
  }
};

module.exports = { authGuard, adminGuard, vipGuard };
