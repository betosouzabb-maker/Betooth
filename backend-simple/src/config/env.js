require('dotenv').config();

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

module.exports = { env };
