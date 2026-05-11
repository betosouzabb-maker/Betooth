import { Request } from 'express';
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

export const libraryService = {
  async list(userId: string, req: Request) {
    const { page, limit, skip } = getPagination(req);
    const query = req.query as Record<string, string | undefined>;
    const { sort, artistId, albumId, genreId, filter } = query;

    const trackFilter: Record<string, unknown> = {};
    if (artistId) trackFilter['artistId'] = artistId;
    if (albumId) trackFilter['albumId'] = albumId;
    if (genreId) trackFilter['genreId'] = genreId;

    let baseWhere: Record<string, unknown> = { userId };

    if (filter === 'favorites') {
      baseWhere = {
        ...baseWhere,
        track: {
          ...trackFilter,
          favorites: { some: { userId, type: 'TRACK' } },
        },
      };
    } else if (Object.keys(trackFilter).length > 0) {
      baseWhere = { ...baseWhere, track: trackFilter };
    }

    let orderBy: object;
    switch (sort) {
      case 'title':
        orderBy = { track: { title: 'asc' } };
        break;
      case 'artist':
        orderBy = { track: { artist: { name: 'asc' } } };
        break;
      case 'oldest':
        orderBy = { addedAt: 'asc' };
        break;
      default:
        orderBy = { addedAt: 'desc' };
    }

    const [items, total] = await Promise.all([
      prisma.userLibrary.findMany({
        where: baseWhere,
        select: { id: true, addedAt: true, source: true, track: { select: trackSelect } },
        orderBy,
        skip,
        take: limit,
      }),
      prisma.userLibrary.count({ where: baseWhere }),
    ]);

    return {
      items,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  },

  async add(userId: string, trackId: string) {
    const track = await prisma.track.findUnique({ where: { id: trackId } });
    if (!track) throw new AppError('Track not found', 404, 'TRACK_NOT_FOUND');

    const item = await prisma.userLibrary.upsert({
      where: { userId_trackId: { userId, trackId } },
      create: { userId, trackId, source: 'MANUAL' },
      update: {},
      select: { id: true, addedAt: true, track: { select: trackSelect } },
    });

    return item;
  },

  async remove(userId: string, trackId: string) {
    const existing = await prisma.userLibrary.findUnique({
      where: { userId_trackId: { userId, trackId } },
    });
    if (!existing) throw new AppError('Track not in library', 404, 'LIBRARY_ITEM_NOT_FOUND');

    await prisma.userLibrary.delete({ where: { userId_trackId: { userId, trackId } } });
    return { removed: true };
  },
};
