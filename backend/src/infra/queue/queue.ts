import { Queue } from 'bullmq';
import { env } from '../../config/env';

export const appQueue = new Queue('betooth-default', {
  prefix: env.QUEUE_PREFIX,
  connection: {
    host: env.REDIS_HOST,
    port: env.REDIS_PORT,
    username: env.REDIS_USERNAME || undefined,
    password: env.REDIS_PASSWORD || undefined,
    db: env.REDIS_DB
  }
});