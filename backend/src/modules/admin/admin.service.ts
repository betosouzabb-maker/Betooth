import { AdminActionType, SessionStatus, TrackStatus, UploadStatus, UserStatus } from '@prisma/client';
import jwt, { SignOptions } from 'jsonwebtoken';
import { prisma } from '../../infra/database/prisma';
import { AppError } from '../../common/middleware/error-handler';
import { env } from '../../config/env';

type LoginMasterInput = { password: string };
type ListUsersInput = { page: number; limit: number; search?: string; status?: string };
type ListTracksInput = { page: number; limit: number; privacy?: string; status?: string };
type ResolveReportInput = { adminId: string; reportId: string; status: string; reason?: string };
type ListUploadsInput = { status?: string };
type ListLogsInput = { page: number; limit: number };

const logAdminAction = async (
  actorId: string,
  actionType: AdminActionType,
  entityType: string,
  entityId?: string,
  targetUserId?: string,
  reason?: string,
  reportId?: string
) => {
  await prisma.adminAction.create({
    data: { actorId, actionType, entityType, entityId, targetUserId, reason, reportId }
  });
};

export const adminService = {
  async loginMaster(input: LoginMasterInput) {
    if (input.password !== env.ADMIN_MASTER_PASSWORD) {
      throw new AppError('Invalid master password', 401, 'ADMIN_INVALID_PASSWORD');
    }

    const options: SignOptions = { expiresIn: '8h' };
    const token = jwt.sign(
      {
        id: 'admin_master',
        userId: 'admin_master',
        email: 'admin@betooth.internal',
        role: 'SUPER_ADMIN',
        type: 'access'
      },
      env.JWT_ACCESS_SECRET,
      options
    );

    return { token, role: 'SUPER_ADMIN', expiresIn: '8h' };
  },

  async getDashboard() {
    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

    const [
      totalUsers,
      totalTracks,
      uploadsToday,
      publicTracks,
      privateTracks,
      activeUsers,
      pendingReports,
      pendingUploads
    ] = await Promise.all([
      prisma.user.count({ where: { deletedAt: null } }),
      prisma.track.count({ where: { status: { not: TrackStatus.ARCHIVED } } }),
      prisma.upload.count({ where: { createdAt: { gte: startOfDay } } }),
      prisma.track.count({ where: { status: TrackStatus.PUBLISHED } }),
      prisma.track.count({ where: { status: { notIn: [TrackStatus.PUBLISHED, TrackStatus.ARCHIVED] } } }),
      prisma.user.count({ where: { lastLoginAt: { gte: sevenDaysAgo }, deletedAt: null } }),
      prisma.report.count({ where: { status: 'OPEN' } }),
      prisma.upload.count({ where: { status: { in: [UploadStatus.PENDING, UploadStatus.PROCESSING] } } })
    ]);

    return {
      totalUsers,
      totalTracks,
      uploadsToday,
      publicTracks,
      privateTracks,
      activeUsers7d: activeUsers,
      pendingReports,
      pendingUploads
    };
  },

  async getUsers(input: ListUsersInput) {
    const { page, limit, search, status } = input;
    const skip = (page - 1) * limit;

    const where = {
      ...(search
        ? {
            OR: [
              { email: { contains: search, mode: 'insensitive' as const } },
              { displayName: { contains: search, mode: 'insensitive' as const } },
              { username: { contains: search, mode: 'insensitive' as const } }
            ]
          }
        : {}),
      ...(status ? { status: status as UserStatus } : {})
    };

    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where,
        select: {
          id: true,
          email: true,
          displayName: true,
          username: true,
          role: true,
          status: true,
          lastLoginAt: true,
          createdAt: true,
          deletedAt: true
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit
      }),
      prisma.user.count({ where })
    ]);

    return {
      users,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit), hasMore: skip + limit < total }
    };
  },

  async blockUser(adminId: string, userId: string) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new AppError('User not found', 404, 'ADMIN_USER_NOT_FOUND');

    await prisma.$transaction([
      prisma.user.update({ where: { id: userId }, data: { status: UserStatus.SUSPENDED } }),
      prisma.userSession.updateMany({
        where: { userId, status: SessionStatus.ACTIVE },
        data: { status: SessionStatus.REVOKED, revokedAt: new Date() }
      })
    ]);

    await logAdminAction(adminId, AdminActionType.USER_SUSPENDED, 'user', userId, userId);
    return { blocked: true, userId };
  },

  async unblockUser(adminId: string, userId: string) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new AppError('User not found', 404, 'ADMIN_USER_NOT_FOUND');

    await prisma.user.update({ where: { id: userId }, data: { status: UserStatus.ACTIVE } });
    await logAdminAction(adminId, AdminActionType.USER_RESTORED, 'user', userId, userId);
    return { unblocked: true, userId };
  },

  async deleteUser(adminId: string, userId: string) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new AppError('User not found', 404, 'ADMIN_USER_NOT_FOUND');

    await prisma.$transaction([
      prisma.user.update({ where: { id: userId }, data: { status: UserStatus.DELETED, deletedAt: new Date() } }),
      prisma.userSession.updateMany({
        where: { userId, status: SessionStatus.ACTIVE },
        data: { status: SessionStatus.REVOKED, revokedAt: new Date() }
      })
    ]);

    await logAdminAction(adminId, AdminActionType.OTHER, 'user', userId, userId, 'Admin soft delete');
    return { deleted: true, userId };
  },

  async getTracks(input: ListTracksInput) {
    const { page, limit, privacy, status } = input;
    const skip = (page - 1) * limit;

    const where = {
      ...(status ? { status: status as TrackStatus } : { status: { not: TrackStatus.ARCHIVED } }),
      ...(privacy === 'public' ? { status: TrackStatus.PUBLISHED } : {}),
      ...(privacy === 'private' ? { status: { notIn: [TrackStatus.PUBLISHED, TrackStatus.ARCHIVED] } } : {})
    };

    const [tracks, total] = await Promise.all([
      prisma.track.findMany({
        where,
        include: {
          artist: { select: { id: true, name: true } },
          genre: { select: { id: true, name: true } }
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit
      }),
      prisma.track.count({ where })
    ]);

    return {
      tracks,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit), hasMore: skip + limit < total }
    };
  },

  async blockTrack(adminId: string, trackId: string) {
    const track = await prisma.track.findUnique({ where: { id: trackId } });
    if (!track) throw new AppError('Track not found', 404, 'ADMIN_TRACK_NOT_FOUND');

    await prisma.track.update({ where: { id: trackId }, data: { status: TrackStatus.BLOCKED } });
    await logAdminAction(adminId, AdminActionType.TRACK_BLOCKED, 'track', trackId);
    return { blocked: true, trackId };
  },

  async deleteTrack(adminId: string, trackId: string) {
    const track = await prisma.track.findUnique({ where: { id: trackId } });
    if (!track) throw new AppError('Track not found', 404, 'ADMIN_TRACK_NOT_FOUND');

    await prisma.track.update({ where: { id: trackId }, data: { status: TrackStatus.ARCHIVED } });
    await logAdminAction(adminId, AdminActionType.OTHER, 'track', trackId, undefined, 'Admin soft delete');
    return { deleted: true, trackId };
  },

  async getReports(status?: string) {
    const where = status ? { status: status as never } : {};
    const reports = await prisma.report.findMany({
      where,
      include: {
        reporter: { select: { id: true, displayName: true, email: true } },
        track: { select: { id: true, title: true } },
        assignedTo: { select: { id: true, displayName: true } }
      },
      orderBy: { createdAt: 'desc' },
      take: 200
    });
    return { reports };
  },

  async resolveReport(input: ResolveReportInput) {
    const { adminId, reportId, status, reason } = input;
    const report = await prisma.report.findUnique({ where: { id: reportId } });
    if (!report) throw new AppError('Report not found', 404, 'ADMIN_REPORT_NOT_FOUND');

    await prisma.report.update({
      where: { id: reportId },
      data: {
        status: status as never,
        resolution: reason,
        resolvedAt: new Date(),
        assignedToId: adminId === 'admin_master' ? undefined : adminId
      }
    });

    await logAdminAction(
      adminId,
      AdminActionType.REPORT_RESOLVED,
      'report',
      reportId,
      report.reporterId,
      reason,
      reportId
    );

    return { resolved: true, reportId };
  },

  async getUploads(status?: string) {
    const where = status ? { status: status as UploadStatus } : {};
    const uploads = await prisma.upload.findMany({
      where,
      include: {
        user: { select: { id: true, displayName: true, email: true } }
      },
      orderBy: { createdAt: 'desc' },
      take: 200
    });
    return { uploads };
  },

  async getAuditLogs(input: ListLogsInput) {
    const { page, limit } = input;
    const skip = (page - 1) * limit;

    const [logs, total] = await Promise.all([
      prisma.adminAction.findMany({
        include: {
          actor: { select: { id: true, displayName: true, email: true } },
          targetUser: { select: { id: true, displayName: true, email: true } }
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit
      }),
      prisma.adminAction.count()
    ]);

    return {
      logs,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit), hasMore: skip + limit < total }
    };
  },

  async getStats() {
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

    const [uploadsByDay, topArtists, storageResult] = await Promise.all([
      prisma.$queryRaw<Array<{ date: Date; count: bigint }>>`
        SELECT DATE_TRUNC('day', "created_at") as date, COUNT(*) as count
        FROM uploads
        WHERE "created_at" >= ${thirtyDaysAgo}
        GROUP BY DATE_TRUNC('day', "created_at")
        ORDER BY date ASC
      `,
      prisma.artist.findMany({
        include: { _count: { select: { tracks: true } } },
        orderBy: { tracks: { _count: 'desc' } },
        take: 10
      }),
      prisma.upload.aggregate({
        _sum: { sizeBytes: true },
        where: { status: 'COMPLETED' }
      })
    ]);

    return {
      uploadsByDay: uploadsByDay.map((r) => ({
        date: r.date.toISOString().split('T').at(0) ?? r.date.toISOString(),
        count: Number(r.count)
      })),
      topArtists: topArtists.map((a) => ({
        id: a.id,
        name: a.name,
        trackCount: a._count.tracks
      })),
      storageUsedBytes: storageResult._sum.sizeBytes?.toString() ?? '0'
    };
  },

  async overview() {
    return {
      users: 0,
      reports: 0,
      uploadsPending: 0
    };
  }
};
