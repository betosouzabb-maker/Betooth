import { Router } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { db } from '../../infra/database';
import { authGuard, AuthRequest, adminGuard } from '../../common/auth-guard';
import { sendSuccess } from '../../common/response';
import { AppError } from '../../common/error-handler';

const router = Router();

// Admin stats
router.get('/stats', authGuard, adminGuard, (req, res) => {
  const totalUsers = db.users.filter((u: any) => u.deleted_at === null).length;
  const totalTracks = db.tracks.length;
  const totalDownloads = db.downloads.length;
  const activeSubs = db.subscriptions.filter((s: any) => s.status === 'ACTIVE').length;

  return sendSuccess(res, {
    totalUsers,
    totalTracks,
    totalDownloads,
    activeSubscriptions: activeSubs,
  });
});

// Admin list users
router.get('/users', authGuard, adminGuard, (req, res) => {
  const users = db.users
    .filter((u: any) => u.deleted_at === null)
    .sort((a: any, b: any) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());

  return sendSuccess(res, {
    users: users.map((u: any) => ({
      id: u.id,
      email: u.email,
      display_name: u.display_name,
      role: u.role,
      status: u.status,
      created_at: u.created_at,
    }))
  });
});

// Admin update user status
router.patch('/users/:id/status', authGuard, adminGuard, (req, res) => {
  const { status } = req.body;
  const user = db.users.find((u: any) => u.id === req.params.id);
  if (user) {
    user.status = status;
    user.updated_at = new Date().toISOString();
  }
  return sendSuccess(res, { message: 'User status updated' });
});

// Admin add track
router.post('/tracks', authGuard, adminGuard, (req, res) => {
  const { title, artist, album, genre, duration, coverUrl, audioUrl } = req.body;
  const id = uuidv4();

  db.tracks.push({
    id,
    title,
    artist,
    album: album || null,
    genre: genre || null,
    duration: duration || 0,
    cover_url: coverUrl || null,
    audio_url: audioUrl,
    file_size: null,
    bitrate: null,
    sample_rate: null,
    lyrics: null,
    is_explicit: 0,
    play_count: 0,
    download_count: 0,
    status: 'ACTIVE',
    uploaded_by: null,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  });

  return sendSuccess(res, { id, message: 'Track added' }, 201);
});

// Admin delete track
router.delete('/tracks/:id', authGuard, adminGuard, (req, res) => {
  db.tracks = db.tracks.filter((t: any) => t.id !== req.params.id);
  return sendSuccess(res, { message: 'Track deleted' });
});

// Notifications
router.get('/notifications', authGuard, (req: AuthRequest, res) => {
  const notifications = db.notifications
    .filter((n: any) => n.user_id === req.user!.id)
    .sort((a: any, b: any) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
    .slice(0, 50);

  return sendSuccess(res, {
    notifications: notifications.map((n: any) => ({
      id: n.id,
      title: n.title,
      body: n.body,
      type: n.type,
      isRead: !!n.is_read,
      createdAt: n.created_at,
    }))
  });
});

router.post('/notifications/:id/read', authGuard, (req: AuthRequest, res) => {
  const notif = db.notifications.find((n: any) => n.id === req.params.id && n.user_id === req.user!.id);
  if (notif) {
    notif.is_read = 1;
  }
  return sendSuccess(res, { message: 'Notification marked as read' });
});

router.post('/notifications', authGuard, adminGuard, (req, res) => {
  const { userId, title, body, type } = req.body;
  db.notifications.push({
    id: uuidv4(),
    user_id: userId,
    title,
    body,
    type: type || 'GENERAL',
    data: null,
    is_read: 0,
    created_at: new Date().toISOString(),
  });

  return sendSuccess(res, { message: 'Notification sent' }, 201);
});

export default router;
