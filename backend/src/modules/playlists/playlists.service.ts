import { Request } from 'express';
import { Prisma } from '@prisma/client';
import { prisma } from '../../infra/database/prisma';
import { AppError } from '../../common/middleware/error-handler';
import { getPagination } from '../../common/utils/pagination';

const trackSelect = {
  id: true,
  title: true,
  slug: true,
  durationSeconds: true,
  isExplicit: true,
  status: true,
  coverUrl: true,
  artist: { select: { id: true, name: true, slug: true, imageUrl: true } },
  album: { select: { id: true, title: true, slug: true, coverUrl: true } },
  genre: { select: { id: true, name: true, slug: true } },
  versions: {
    where: { isPrimary: true },
    select: { id: true, audioUrl: true, bitrateKbps: true, codec: true, isLossless: true },
    take: 1,
  },
} as const;

const playlistSelect = {
  id: true,
  title: true,
  slug: true,
  description: true,
  coverUrl: true,
  visibility: true,
  isCollaborative: true,
  createdAt: true,
  updatedAt: true,
  _count: { select: { items: true } },
} as const;

function generateSlug(title: string): string {
  const base = title
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '')
    .trim()
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-');
  return `${base}-${Date.now()}`;
}

export const playlistsService = {
  async list(userId: string, req: Request) {
    const { page, limit, skip } = getPagination(req);

    const [playlists, total] = await Promise.all([
      prisma.playlist.findMany({
        where: { userId },
        select: playlistSelect,
        orderBy: { updatedAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.playlist.count({ where: { userId } }),
    ]);

    const items = playlists.map(p => ({
      ...p,
      itemCount: p._count.items,
      _count: undefined,
    }));

    return {
      items,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  },

  async create(
    userId: string,
    data: { name: string; description?: string; isPublic?: boolean }
  ) {
    const slug = generateSlug(data.name);
    const visibility = data.isPublic ? 'PUBLIC' : 'PRIVATE';

    const playlist = await prisma.playlist.create({
      data: {
        userId,
        title: data.name,
        slug,
        description: data.description ?? null,
        visibility: visibility as Prisma.EnumPlaylistVisibilityFilter extends never ? never : 'PUBLIC' | 'PRIVATE' | 'UNLISTED',
        isCollaborative: false,
      },
      select: playlistSelect,
    });

    return { ...playlist, itemCount: 0, _count: undefined };
  },

  async getById(id: string, userId: string) {
    const playlist = await prisma.playlist.findFirst({
      where: { id, userId },
      select: {
        id: true,
        title: true,
        slug: true,
        description: true,
        coverUrl: true,
        visibility: true,
        isCollaborative: true,
        createdAt: true,
        updatedAt: true,
        items: {
          select: {
            id: true,
            position: true,
            addedAt: true,
            track: { select: trackSelect },
          },
          orderBy: { position: 'asc' },
        },
      },
    });

    if (!playlist) throw new AppError('Playlist not found', 404, 'PLAYLIST_NOT_FOUND');
    return playlist;
  },

  async update(
    id: string,
    userId: string,
    data: { name?: string; description?: string; coverUrl?: string; isPublic?: boolean }
  ) {
    const playlist = await prisma.playlist.findFirst({ where: { id, userId } });
    if (!playlist) throw new AppError('Playlist not found', 404, 'PLAYLIST_NOT_FOUND');

    const updated = await prisma.playlist.update({
      where: { id },
      data: {
        ...(data.name ? { title: data.name } : {}),
        ...(data.description !== undefined ? { description: data.description } : {}),
        ...(data.coverUrl !== undefined ? { coverUrl: data.coverUrl } : {}),
        ...(data.isPublic !== undefined ? { visibility: data.isPublic ? 'PUBLIC' : 'PRIVATE' } : {}),
      },
      select: playlistSelect,
    });

    const itemCount = await prisma.playlistItem.count({ where: { playlistId: id } });
    return { ...updated, itemCount, _count: undefined };
  },

  async delete(id: string, userId: string) {
    const playlist = await prisma.playlist.findFirst({ where: { id, userId } });
    if (!playlist) throw new AppError('Playlist not found', 404, 'PLAYLIST_NOT_FOUND');

    await prisma.playlist.delete({ where: { id } });
    return { deleted: true };
  },

  async addItem(playlistId: string, userId: string, trackId: string, position?: number) {
    const playlist = await prisma.playlist.findFirst({ where: { id: playlistId, userId } });
    if (!playlist) throw new AppError('Playlist not found', 404, 'PLAYLIST_NOT_FOUND');

    const track = await prisma.track.findUnique({ where: { id: trackId } });
    if (!track) throw new AppError('Track not found', 404, 'TRACK_NOT_FOUND');

    // Find next position if not provided
    const nextPosition = position ?? ((await prisma.playlistItem.aggregate({
      where: { playlistId },
      _max: { position: true },
    }))._max.position ?? -1) + 1;

    // If position is taken, shift items up
    if (position !== undefined) {
      await prisma.playlistItem.updateMany({
        where: { playlistId, position: { gte: position } },
        data: { position: { increment: 1 } },
      });
    }

    const item = await prisma.playlistItem.create({
      data: {
        playlistId,
        trackId,
        addedById: userId,
        position: nextPosition,
      },
      select: {
        id: true,
        position: true,
        addedAt: true,
        track: { select: trackSelect },
      },
    });

    return item;
  },

  async reorderItems(playlistId: string, userId: string, orderedIds: string[]) {
    const playlist = await prisma.playlist.findFirst({
      where: { id: playlistId, userId },
      include: { items: true },
    });
    if (!playlist) throw new AppError('Playlist not found', 404, 'PLAYLIST_NOT_FOUND');

    const validIds = new Set(playlist.items.map(i => i.id));
    if (!orderedIds.every(id => validIds.has(id))) {
      throw new AppError('Invalid item IDs', 400, 'INVALID_ITEM_IDS');
    }

    // Use raw SQL CASE WHEN to update all positions atomically (avoids unique constraint issues)
    if (orderedIds.length > 0) {
      const caseFragments = orderedIds
        .map((id, i) => Prisma.sql`WHEN ${id} THEN ${i}`)
        .reduce((acc, frag) => Prisma.sql`${acc} ${frag}`);

      await prisma.$executeRaw`
        UPDATE "playlist_items"
        SET "position" = CASE "id" ${caseFragments} ELSE "position" END
        WHERE "playlistId" = ${playlistId}
      `;
    }

    return { reordered: true };
  },

  async removeItem(playlistId: string, userId: string, itemId: string) {
    const playlist = await prisma.playlist.findFirst({ where: { id: playlistId, userId } });
    if (!playlist) throw new AppError('Playlist not found', 404, 'PLAYLIST_NOT_FOUND');

    const item = await prisma.playlistItem.findFirst({ where: { id: itemId, playlistId } });
    if (!item) throw new AppError('Item not found', 404, 'PLAYLIST_ITEM_NOT_FOUND');

    await prisma.playlistItem.delete({ where: { id: itemId } });
    return { removed: true };
  },
};
