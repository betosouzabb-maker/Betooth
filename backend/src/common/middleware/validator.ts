import { NextFunction, Request, Response } from 'express';
import { ZodTypeAny } from 'zod';
import { AppError } from './error-handler';

export const validate =
  (schema: ZodTypeAny) =>
  (req: Request, _res: Response, next: NextFunction): void => {
    const parsed = schema.safeParse({
      body: req.body,
      params: req.params,
      query: req.query
    });

    if (!parsed.success) {
      return next(new AppError('Validation failed', 422, 'VALIDATION_ERROR', parsed.error.flatten()));
    }

    req.body = parsed.data.body;
    req.params = parsed.data.params as Request['params'];
    req.query = parsed.data.query as Request['query'];

    return next();
  };