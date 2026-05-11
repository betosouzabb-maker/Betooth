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

export const favoritesService = {
  async list(userId: string, req: Request) {
    const { page, limit, skip } = getPagination(req);

    const [items, total] = await Promise.all([
      prisma.favorite.findMany({
        where: { userId, type: 'TRACK', trackId: { not: null } },
        select: {
          id: true,
          createdAt: true,
          track: { select: trackSelect },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.favorite.count({ where: { userId, type: 'TRACK', trackId: { not: null } } }),
    ]);

    return {
      items,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  },

  async add(userId: string, trackId: string) {
    const track = await prisma.track.findUnique({ where: { id: trackId } });
    if (!track) throw new AppError('Track not found', 404, 'TRACK_NOT_FOUND');

    // Check if already favorited
    const existing = await prisma.favorite.findFirst({
      where: { userId, type: 'TRACK', trackId },
    });

    if (existing) return { ...existing, alreadyFavorited: true };

    const favorite = await prisma.favorite.create({
      data: { userId, type: 'TRACK', trackId },
      select: { id: true, createdAt: true, track: { select: trackSelect } },
    });

    return { ...favorite, alreadyFavorited: false };
  },

  async remove(userId: string, trackId: string) {
    const existing = await prisma.favorite.findFirst({
      where: { userId, type: 'TRACK', trackId },
    });
    if (!existing) throw new AppError('Track not in favorites', 404, 'FAVORITE_NOT_FOUND');

    await prisma.favorite.delete({ where: { id: existing.id } });
    return { removed: true };
  },

  async checkFavorite(userId: string, trackId: string) {
    const existing = await prisma.favorite.findFirst({
      where: { userId, type: 'TRACK', trackId },
    });
    return { isFavorited: !!existing };
  },
};
