import { Request, Response } from 'express';

export const sendSuccess = <T>(res: Response, data: T, statusCode = 200): Response => {
  return res.status(statusCode).json({ success: true, data });
};

export const sendError = (res: Response, statusCode: number, message: string, code?: string): Response => {
  return res.status(statusCode).json({
    success: false,
    error: { message, code: code || 'UNKNOWN_ERROR' }
  });
};
