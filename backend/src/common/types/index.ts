import { Request } from 'express';

export type RequestUser = {
  id: string;
  userId: string;
  email: string;
  role: string;
};

export type AuthenticatedRequest = Request & {
  user?: RequestUser;
};

export type ApiSuccessResponse<T> = {
  success: true;
  data: T;
  meta?: Record<string, unknown>;
};

export type ApiErrorResponse = {
  success: false;
  error: {
    message: string;
    code?: string;
    details?: unknown;
  };
};