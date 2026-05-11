import { ChangeOperation, Prisma, SyncStatus } from '@prisma/client';
import { prisma } from '../../infra/database/prisma';
import { AppError } from '../../common/middleware/error-handler';
import { logger } from '../../common/utils/logger';

type BootstrapInput = {
  userId: string;
  deviceId?: string;
};

type Mutation = {
  entityType: string;
  operation: 'upsert' | 'delete';
  clientMutationId: string;
  payload?: Record<string, unknown>;
};

type PushInput = {
  userId: string;
  deviceId?: string;
  mutations: Mutation[];
};

type PullInput = {
  userId: string;
  deviceId?: string;
  sinceVersion: number;
};

type AckInput = {
  userId: string;
  deviceId?: string;
  entityType: string;
  version: number;
};

type SyncStateInput = {
  userId: string;
  deviceId?: string;
};

const getNextVersion = async (userId: string): Promise<number> => {
  const result = await prisma.entityChange.aggregate({
    where: { userId },
    _max: { version: true }
  });
  return (result._max.version ?? 0) + 1;
};

const upsertSyncState = async (
  userId: string,
  deviceId: string | undefined,
  entityType: string,
  status: SyncStatus,
  lastCursor?: string,
  lastError?: string
) => {
  return prisma.syncState.upsert({
    where: {
      userId_deviceId_entityType: {
        userId,
        deviceId: deviceId ?? '',
        entityType
      }
    },
    update: {
      status,
      lastSyncedAt: new Date(),
      ...(lastCursor !== undefined ? { lastCursor } : {}),
      ...(lastError !== undefined ? { lastError } : { lastError: null })
    },
    create: {
      userId,
      deviceId,
      entityType,
      status,
      lastSyncedAt: new Date(),
      lastCursor,
      lastError
    }
  });
};

const applyMutation = async (
  userId: string,
  mutation: Mutation,
  version: number
): Promise<{ serverId: string | null; conflict: boolean; conflictReason?: string }> => {
  const { entityType, operation, payload } = mutation;

  try {
    switch (entityType) {
      case 'favorite': {
        if (operation === 'delete') {
          const favoriteId = payload?.id as string | undefined;
          if (!favoriteId) return { serverId: null, conflict: false };
          await prisma.favorite.deleteMany({ where: { id: favoriteId, userId } });
          await prisma.entityChange.create({
            data: {
              userId,
              entityType,
              entityId: favoriteId,
              operation: ChangeOperation.DELETED,
              payload: payload as Prisma.InputJsonValue,
              version
            }
          });
          return { serverId: favoriteId, conflict: false };
        } else {
          const type = payload?.type as string | undefined;
          const trackId = payload?.trackId as string | undefined;
          const albumId = payload?.albumId as string | undefined;
          const artistId = payload?.artistId as string | undefined;
          const playlistId = payload?.playlistId as string | undefined;
          if (!type) return { serverId: null, conflict: true, conflictReason: 'Missing favorite type' };

          const existing = await prisma.favorite.findFirst({
            where: { userId, type: type as never, trackId, albumId, artistId, playlistId }
          });

          let favorite;
          if (existing) {
            favorite = existing;
          } else {
            favorite = await prisma.favorite.create({
              data: {
                userId,
                type: type as never,
                trackId,
                albumId,
                artistId,
                playlistId
              }
            });
          }
          await prisma.entityChange.create({
            data: {
              userId,
              entityType,
              entityId: favorite.id,
              operation: existing ? ChangeOperation.UPDATED : ChangeOperation.CREATED,
              payload: { ...payload, serverId: favorite.id } as Prisma.InputJsonValue,
              version
            }
          });
          return { serverId: favorite.id, conflict: false };
        }
      }

      case 'library': {
        if (operation === 'delete') {
          const trackId = payload?.trackId as string | undefined;
          if (!trackId) return { serverId: null, conflict: false };
          await prisma.userLibrary.deleteMany({ where: { userId, trackId } });
          await prisma.entityChange.create({
            data: { userId, entityType, entityId: `${userId}_${trackId}`, operation: ChangeOperation.DELETED, payload: payload as Prisma.InputJsonValue, version }
          });
          return { serverId: `${userId}_${trackId}`, conflict: false };
        } else {
          const trackId = payload?.trackId as string | undefined;
          if (!trackId) return { serverId: null, conflict: true, conflictReason: 'Missing trackId' };
          const existing = await prisma.userLibrary.findUnique({ where: { userId_trackId: { userId, trackId } } });
          if (!existing) {
            await prisma.userLibrary.create({ data: { userId, trackId } });
          }
          const entityId = `${userId}_${trackId}`;
          await prisma.entityChange.create({
            data: { userId, entityType, entityId, operation: existing ? ChangeOperation.UPDATED : ChangeOperation.CREATED, payload: payload as Prisma.InputJsonValue, version }
          });
          return { serverId: entityId, conflict: false };
        }
      }

      case 'playlist': {
        if (operation === 'delete') {
          const playlistId = payload?.id as string | undefined;
          if (!playlistId) return { serverId: null, conflict: false };
          await prisma.playlist.deleteMany({ where: { id: playlistId, userId } });
          await prisma.entityChange.create({
            data: { userId, entityType, entityId: playlistId, operation: ChangeOperation.DELETED, payload: payload as Prisma.InputJsonValue, version }
          });
          return { serverId: playlistId, conflict: false };
        } else {
          const id = payload?.id as string | undefined;
          const title = payload?.title as string | undefined;
          const description = payload?.description as string | undefined;
          const visibility = (payload?.visibility as 'PRIVATE' | 'UNLISTED' | 'PUBLIC' | undefined) ?? 'PRIVATE';
          if (!title) return { serverId: null, conflict: true, conflictReason: 'Missing playlist title' };
          const slug = `${userId}-${title.toLowerCase().replace(/\s+/g, '-')}-${Date.now()}`;

          let playlist;
          if (id) {
            playlist = await prisma.playlist.upsert({
              where: { id },
              update: { title, description, visibility },
              create: { id, userId, title, slug, description, visibility }
            });
          } else {
            playlist = await prisma.playlist.create({ data: { userId, title, slug, description, visibility } });
          }
          await prisma.entityChange.create({
            data: {
              userId, entityType, entityId: playlist.id,
              operation: id ? ChangeOperation.UPDATED : ChangeOperation.CREATED,
              payload: { ...payload, serverId: playlist.id } as Prisma.InputJsonValue, version
            }
          });
          return { serverId: playlist.id, conflict: false };
        }
      }

      case 'play_history': {
        const trackId = payload?.trackId as string | undefined;
        if (!trackId || operation === 'delete') return { serverId: null, conflict: false };
        const history = await prisma.playHistory.create({
          data: {
            userId,
            trackId,
            playedAt: payload?.playedAt ? new Date(payload.playedAt as string) : new Date(),
            progressSeconds: payload?.progressSeconds as number | undefined,
            completed: payload?.completed as boolean | undefined,
            source: payload?.source as string | undefined
          }
        });
        await prisma.entityChange.create({
          data: { userId, entityType, entityId: history.id, operation: ChangeOperation.CREATED, payload: payload as Prisma.InputJsonValue, version }
        });
        return { serverId: history.id, conflict: false };
      }

      case 'settings': {
        const name = payload?.name as string | undefined;
        const avatarUrl = payload?.avatarUrl as string | undefined;
        const bio = payload?.bio as string | undefined;
        await prisma.user.update({
          where: { id: userId },
          data: {
            ...(name ? { displayName: name } : {}),
            ...(avatarUrl !== undefined ? { avatarUrl } : {}),
            ...(bio !== undefined ? { bio } : {})
          }
        });
        await prisma.entityChange.create({
          data: { userId, entityType, entityId: userId, operation: ChangeOperation.UPDATED, payload: payload as Prisma.InputJsonValue, version }
        });
        return { serverId: userId, conflict: false };
      }

      default:
        return { serverId: null, conflict: true, conflictReason: `Unknown entityType: ${entityType}` };
    }
  } catch (error) {
    logger.error({ error, mutation }, 'Error applying mutation');
    return { serverId: null, conflict: true, conflictReason: (error as Error).message };
  }
};

export const syncService = {
  async bootstrap(input: BootstrapInput) {
    const { userId } = input;

    const [user, libraryItems, playlists, favorites] = await Promise.all([
      prisma.user.findUnique({
        where: { id: userId },
        select: { id: true, displayName: true, email: true, avatarUrl: true, bio: true, role: true, status: true }
      }),
      prisma.userLibrary.findMany({
        where: { userId },
        include: {
          track: {
            include: {
              artist: { select: { id: true, name: true, imageUrl: true } },
              genre: { select: { id: true, name: true } },
              versions: { where: { isPrimary: true }, take: 1 }
            }
          }
        },
        orderBy: { addedAt: 'desc' }
      }),
      prisma.playlist.findMany({
        where: { userId },
        include: {
          items: {
            include: { track: { select: { id: true, title: true, coverUrl: true, durationSeconds: true } } },
            orderBy: { position: 'asc' }
          }
        },
        orderBy: { createdAt: 'desc' }
      }),
      prisma.favorite.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' }
      })
    ]);

    if (!user) {
      throw new AppError('User not found', 404, 'SYNC_USER_NOT_FOUND');
    }

    const maxVersion = await prisma.entityChange.aggregate({
      where: { userId },
      _max: { version: true }
    });

    return {
      version: maxVersion._max?.version ?? 0,
      settings: user,
      library: libraryItems,
      playlists,
      favorites,
      syncedAt: new Date().toISOString()
    };
  },

  async push(input: PushInput) {
    const { userId, deviceId, mutations } = input;

    if (!Array.isArray(mutations) || mutations.length === 0) {
      return { applied: [], conflicts: [] };
    }

    const applied: Array<{ clientMutationId: string; serverId: string | null; version: number }> = [];
    const conflicts: Array<{ clientMutationId: string; reason: string }> = [];

    for (const mutation of mutations) {
      const version = await getNextVersion(userId);
      const result = await applyMutation(userId, mutation, version);

      if (result.conflict) {
        conflicts.push({ clientMutationId: mutation.clientMutationId, reason: result.conflictReason ?? 'Conflict' });
      } else {
        applied.push({ clientMutationId: mutation.clientMutationId, serverId: result.serverId, version });
      }
    }

    if (applied.length > 0) {
      const lastApplied = applied[applied.length - 1];
      const lastVersion = lastApplied?.version ?? 0;
      await upsertSyncState(userId, deviceId, 'all', SyncStatus.COMPLETED, String(lastVersion));
    }

    return { applied, conflicts };
  },

  async pull(input: PullInput) {
    const { userId, sinceVersion } = input;

    const changes = await prisma.entityChange.findMany({
      where: {
        userId,
        version: { gt: sinceVersion }
      },
      orderBy: { version: 'asc' },
      take: 500
    });

    const lastChange = changes.at(-1);
    const maxVersion = lastChange !== undefined ? lastChange.version : sinceVersion;

    return {
      changes: changes.map((c) => ({
        id: c.id,
        entityType: c.entityType,
        entityId: c.entityId,
        operation: c.operation,
        payload: c.payload,
        version: c.version,
        createdAt: c.createdAt.toISOString()
      })),
      currentVersion: maxVersion,
      hasMore: changes.length === 500
    };
  },

  async ack(input: AckInput) {
    const { userId, deviceId, entityType, version } = input;
    await upsertSyncState(userId, deviceId, entityType, SyncStatus.COMPLETED, String(version));
    return { acknowledged: true, entityType, version };
  },

  async getSyncState(input: SyncStateInput) {
    const { userId, deviceId } = input;
    const states = await prisma.syncState.findMany({
      where: { userId, ...(deviceId ? { deviceId } : {}) }
    });
    return { states };
  },

  async status() {
    return {
      pendingChanges: 0,
      lastSyncAt: null as string | null
    };
  }
};
