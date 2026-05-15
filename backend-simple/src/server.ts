import express, { Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { env } from './config/env';
import { initDatabase } from './infra/database';
import { errorHandler, notFoundHandler } from './common/error-handler';
import authRoutes from './modules/auth/auth.routes';
import musicRoutes from './modules/music/music.routes';
import libraryRoutes from './modules/library/library.routes';
import downloadsRoutes from './modules/downloads/downloads.routes';
import subscriptionsRoutes from './modules/subscriptions/subscriptions.routes';
import adminRoutes from './modules/admin/admin.routes';

const app = express();

// Security middleware
app.use(helmet());
app.use(cors({ origin: '*' }));

// Rate limiting
app.use(rateLimit({
  windowMs: env.RATE_LIMIT_WINDOW_MS,
  max: env.RATE_LIMIT_MAX_REQUESTS,
  standardHeaders: true,
  legacyHeaders: false,
}));

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Trust proxy (for Render)
app.set('trust proxy', 1);

// Initialize database
initDatabase();

// Health check
app.get(`${env.API_PREFIX}/health`, (_req: Request, res: Response) => {
  return res.json({ success: true, data: { status: 'ok', service: env.APP_NAME } });
});

// Routes
app.use(`${env.API_PREFIX}/auth`, authRoutes);
app.use(`${env.API_PREFIX}/music`, musicRoutes);
app.use(`${env.API_PREFIX}/library`, libraryRoutes);
app.use(`${env.API_PREFIX}/downloads`, downloadsRoutes);
app.use(`${env.API_PREFIX}/subscriptions`, subscriptionsRoutes);
app.use(`${env.API_PREFIX}/admin`, adminRoutes);

// 404 handler
app.use(notFoundHandler);

// Error handler
app.use(errorHandler);

const PORT = env.PORT;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`[SERVER] ${env.APP_NAME} running on port ${PORT}`);
  console.log(`[SERVER] Health check: http://localhost:${PORT}${env.API_PREFIX}/health`);
});
