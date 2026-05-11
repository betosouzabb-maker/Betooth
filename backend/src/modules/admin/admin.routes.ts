import { Router } from 'express';
import { requireAuth } from '../auth/auth.middleware';
import { adminGuard } from '../../common/middleware/admin-guard';
import { adminController } from './admin.controller';

export const adminRoutes = Router();

// Public: master login
adminRoutes.post('/login-master', adminController.loginMaster);

// Protected: require valid JWT + admin role
adminRoutes.get('/dashboard', requireAuth, adminGuard, adminController.dashboard);
adminRoutes.get('/users', requireAuth, adminGuard, adminController.listUsers);
adminRoutes.patch('/users/:id/block', requireAuth, adminGuard, adminController.blockUser);
adminRoutes.patch('/users/:id/unblock', requireAuth, adminGuard, adminController.unblockUser);
adminRoutes.delete('/users/:id', requireAuth, adminGuard, adminController.deleteUser);
adminRoutes.get('/tracks', requireAuth, adminGuard, adminController.listTracks);
adminRoutes.patch('/tracks/:id/block', requireAuth, adminGuard, adminController.blockTrack);
adminRoutes.delete('/tracks/:id', requireAuth, adminGuard, adminController.deleteTrack);
adminRoutes.get('/reports', requireAuth, adminGuard, adminController.listReports);
adminRoutes.patch('/reports/:id/resolve', requireAuth, adminGuard, adminController.resolveReport);
adminRoutes.get('/uploads', requireAuth, adminGuard, adminController.listUploads);
adminRoutes.get('/audit-logs', requireAuth, adminGuard, adminController.listAuditLogs);
adminRoutes.get('/stats', requireAuth, adminGuard, adminController.stats);
adminRoutes.get('/overview', requireAuth, adminGuard, adminController.overview);
