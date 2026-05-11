import { Response } from 'express';
import { ApiErrorResponse, ApiSuccessResponse } from '../types';

export const sendSuccess = <T>(
  res: Response,
  statusCode: number,
  data: T,
  meta?: Record<string, unknown>
): Response<ApiSuccessResponse<T>> => {
  return res.status(statusCode).json({
    success: true,
    data,
    ...(meta ? { meta } : {})
  });
};

export const sendError = (
  res: Response,
  statusCode: number,
  message: string,
  code?: string,
  details?: unknown
): Response<ApiErrorResponse> => {
  return res.status(statusCode).json({
    success: false,
    error: {
      message,
      ...(code ? { code } : {}),
      ...(details ? { details } : {})
    }
  });
};