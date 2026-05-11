import path from 'path';
import cors from 'cors';
import express from 'express';
import { corsOptions } from './config/cors';
import { env } from './config/env';
import { defaultRateLimiter } from './common/middleware/rate-limiter';
import { errorHandler, notFoundHandler } from './common/middleware/error-handler';
import { httpLogger } from './common/utils/logger';
import { sendSuccess } from './common/utils/response';
import { authRoutes } from './modules/auth/auth.routes';
import { usersRoutes } from './modules/users/users.routes';
import { musicRoutes } from './modules/music/music.routes';
import { libraryRoutes } from './modules/library/library.routes';
import { playlistsRoutes } from './modules/playlists/playlists.routes';
import { favoritesRoutes } from './modules/favorites/favorites.routes';
import { searchRoutes } from './modules/search/search.routes';
import { historyRoutes } from './modules/history/history.routes';
import { uploadsRoutes } from './modules/uploads/uploads.routes';
import { tracksRoutes } from './modules/tracks/tracks.routes';
import { syncRoutes } from './modules/sync/sync.routes';
import { adminRoutes } from './modules/admin/admin.routes';
import { reportsRoutes } from './modules/reports/reports.routes';
import { notificationsRoutes } from './modules/notifications/notifications.routes';
import { subscriptionsRoutes } from './modules/subscriptions/subscriptions.routes';
import { downloadsRoutes } from './modules/downloads/downloads.routes';
import { appReleaseRoutes } from './modules/app-release/app-release.routes';

export const app = express();

app.disable('x-powered-by');
app.use(httpLogger);
app.use(cors(corsOptions));
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(defaultRateLimiter);

app.get(`${env.API_PREFIX}/health`, (_req, res) =>
  sendSuccess(res, 200, {
    status: 'ok',
    service: env.APP_NAME
  })
);

app.use(`${env.API_PREFIX}/auth`, authRoutes);
app.use(`${env.API_PREFIX}/users`, usersRoutes);
app.use(`${env.API_PREFIX}/music`, musicRoutes);
app.use(`${env.API_PREFIX}/library`, libraryRoutes);
app.use(`${env.API_PREFIX}/playlists`, playlistsRoutes);
app.use(`${env.API_PREFIX}/favorites`, favoritesRoutes);
app.use(`${env.API_PREFIX}/search`, searchRoutes);
app.use(`${env.API_PREFIX}/history`, historyRoutes);
app.use(`${env.API_PREFIX}/uploads`, uploadsRoutes);
app.use(`${env.API_PREFIX}/tracks`, tracksRoutes);
app.use(`${env.API_PREFIX}/sync`, syncRoutes);
app.use(`${env.API_PREFIX}/admin`, adminRoutes);
app.use(`${env.API_PREFIX}/reports`, reportsRoutes);
app.use(`${env.API_PREFIX}/notifications`, notificationsRoutes);
app.use(`${env.API_PREFIX}/subscriptions`, subscriptionsRoutes);
app.use(`${env.API_PREFIX}/downloads`, downloadsRoutes);
app.use(`${env.API_PREFIX}/app-release`, appReleaseRoutes);

// Servir a página de download diretamente pelo backend
// Acesso: http://localhost:3333/download/
app.use('/download', express.static(path.resolve(__dirname, '../../web/download')));

app.use(notFoundHandler);
app.use(errorHandler);
