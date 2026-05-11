import { PrismaClient } from '@prisma/client';

declare global {
  var __betoothPrisma__: PrismaClient | undefined;
}

export const prisma =
  global.__betoothPrisma__ ??
  new PrismaClient({
    log: ['warn', 'error']
  });

if (process.env.NODE_ENV !== 'production') {
  global.__betoothPrisma__ = prisma;
}