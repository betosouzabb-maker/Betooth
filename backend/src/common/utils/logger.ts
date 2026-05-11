import pino from 'pino';
import pinoHttp from 'pino-http';
import { env } from '../../config/env';

export const logger = pino({
  level: env.LOG_LEVEL,
  name: env.APP_NAME,
  redact: {
    paths: ['req.headers.authorization', 'password', 'token'],
    remove: true
  },
  transport:
    env.NODE_ENV === 'development'
      ? {
          target: 'pino-pretty',
          options: {
            colorize: true
          }
        }
      : undefined
});

export const httpLogger = pinoHttp({
  logger,
  customSuccessMessage: (req, res) => `${req.method} ${req.url} completed with ${res.statusCode}`,
  customErrorMessage: (req, res, error) => `${req.method} ${req.url} failed with ${res.statusCode}: ${error.message}`
});