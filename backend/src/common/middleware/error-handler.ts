import { NextFunction, Request, Response } from 'express';
import { logger } from '../utils/logger';
import { sendError } from '../utils/response';

export class AppError extends Error {
  public readonly statusCode: number;
  public readonly code?: string;
  public readonly details?: unknown;

  constructor(message: string, statusCode = 500, code?: string, details?: unknown) {
    super(message);
    this.name = 'AppError';
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
  }
}

export const notFoundHandler = (req: Request, res: Response): Response => {
  return sendError(res, 404, `Route ${req.method} ${req.originalUrl} not found`, 'ROUTE_NOT_FOUND');
};

export const errorHandler = (error: Error, req: Request, res: Response, _next: NextFunction): Response => {
  if (error instanceof AppError) {
    return sendError(res, error.statusCode, error.message, error.code, error.details);
  }

  logger.error(
    {
      err: error,
      path: req.originalUrl,
      method: req.method
    },
    'Unhandled application error'
  );

  // eslint-disable-next-line no-console
  console.error('[ERROR]', req.method, req.originalUrl, error.message, error.stack);

  return sendError(res, 500, 'Internal server error', 'INTERNAL_SERVER_ERROR');
};