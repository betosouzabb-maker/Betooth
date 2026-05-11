import { createServer } from 'node:http';
import { app } from './app';
import { env } from './config/env';
import { prisma } from './infra/database/prisma';
import { redis } from './infra/redis/redis';
import { logger } from './common/utils/logger';

const server = createServer(app);

server.listen(env.PORT, () => {
  logger.info({ port: env.PORT, env: env.NODE_ENV }, 'Betooth backend listening');
});

const shutdown = async (signal: string): Promise<void> => {
  logger.info({ signal }, 'Graceful shutdown started');

  server.close(async () => {
    await prisma.$disconnect().catch(() => undefined);
    redis.disconnect(false);
    logger.info('Graceful shutdown completed');
    process.exit(0);
  });
};

process.on('SIGINT', () => {
  void shutdown('SIGINT');
});

process.on('SIGTERM', () => {
  void shutdown('SIGTERM');
});