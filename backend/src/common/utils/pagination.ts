import { Request } from 'express';

export type PaginationParams = {
  page: number;
  limit: number;
  skip: number;
};

export const getPagination = (req: Request): PaginationParams => {
  const rawPage = Number(req.query.page ?? 1);
  const rawLimit = Number(req.query.limit ?? 20);

  const page = Number.isFinite(rawPage) && rawPage > 0 ? Math.floor(rawPage) : 1;
  const limit = Number.isFinite(rawLimit) && rawLimit > 0 ? Math.min(Math.floor(rawLimit), 100) : 20;

  return {
    page,
    limit,
    skip: (page - 1) * limit
  };
};