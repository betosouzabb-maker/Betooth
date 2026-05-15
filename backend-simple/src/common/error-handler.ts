import { Request, Response, NextFunction } from 'express';

export class AppError extends Error {
  public readonly statusCode: number;
  public readonly code?: string;

  constructor(message: string, statusCode = 500, code?: string) {
    super(message);
    this.name = 'AppError';
    this.statusCode = statusCode;
    this.code = code;
  }
}

export const errorHandler = (error: Error, req: Request, res: Response, _next: NextFunction): Response => {
  if (error instanceof AppError) {
    return res.status(error.statusCode).json({
      success: false,
      error: { message: error.message, code: error.code || 'UNKNOWN_ERROR' }
    });
  }

  console.error('[ERROR]', req.method, req.originalUrl, error.message, error.stack);

  return res.status(500).json({
    success: false,
    error: { message: 'Internal server error', code: 'INTERNAL_SERVER_ERROR' }
  });
};

export const notFoundHandler = (req: Request, res: Response): Response => {
  return res.status(404).json({
    success: false,
    error: { message: `Route ${req.method} ${req.originalUrl} not found`, code: 'ROUTE_NOT_FOUND' }
  });
};
