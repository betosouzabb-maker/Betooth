import { Request } from 'express';
import { prisma } from '../../infra/database/prisma';
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

export const searchService = {
  async search(userId: string, req: Request) {
    const { page, limit, skip } = getPagination(req);
    const { q, type } = req.query as { q?: string; type?: string };

    if (!q || q.trim().length === 0) {
      return {
        tracks: [],
        artists: [],
        albums: [],
        playlists: [],
        pagination: { page, limit, total: 0, totalPages: 0 },
      };
    }

    const query = q.trim();

    // Save search history (fire-and-forget)
    prisma.searchHistory
      .create({ data: { userId, query } })
      .catch(() => { /* ignore */ });

    const shouldSearchTracks = !type || type === 'track' || type === 'all';
    const shouldSearchArtists = !type || type === 'artist' || type === 'all';
    const shouldSearchAlbums = !type || type === 'album' || type === 'all';
    const shouldSearchPlaylists = !type || type === 'playlist' || type === 'all';

    const [tracks, artists, albums, playlists] = await Promise.all([
      shouldSearchTracks
        ? prisma.track.findMany({
            where: {
              status: 'PUBLISHED',
              OR: [
                { title: { contains: query, mode: 'insensitive' } },
                { artist: { name: { contains: query, mode: 'insensitive' } } },
                { album: { title: { contains: query, mode: 'insensitive' } } },
              ],
            },
            select: trackSelect,
            take: limit,
            skip,
          })
        : [],
      shouldSearchArtists
        ? prisma.artist.findMany({
            where: { name: { contains: query, mode: 'insensitive' } },
            select: { id: true, name: true, slug: true, imageUrl: true, artistType: true, isVerified: true },
            take: 10,
          })
        : [],
      shouldSearchAlbums
        ? prisma.album.findMany({
            where: {
              OR: [
                { title: { contains: query, mode: 'insensitive' } },
                { artist: { name: { contains: query, mode: 'insensitive' } } },
              ],
            },
            select: {
              id: true,
              title: true,
              slug: true,
              coverUrl: true,
              releaseDate: true,
              artist: { select: { id: true, name: true, slug: true } },
            },
            take: 10,
          })
        : [],
      shouldSearchPlaylists
        ? prisma.playlist.findMany({
            where: {
              visibility: 'PUBLIC',
              title: { contains: query, mode: 'insensitive' },
            },
            select: {
              id: true,
              title: true,
              slug: true,
              coverUrl: true,
              _count: { select: { items: true } },
              user: { select: { id: true, displayName: true } },
            },
            take: 10,
          })
        : [],
    ]);

    const total = tracks.length + artists.length + albums.length + playlists.length;

    return {
      tracks,
      artists,
      albums,
      playlists: playlists.map(p => ({ ...p, itemCount: p._count.items, _count: undefined })),
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  },

  async suggestions(q: string) {
    if (!q || q.trim().length < 2) return { suggestions: [] };

    const query = q.trim();
    const [tracks, artists] = await Promise.all([
      prisma.track.findMany({
        where: { status: 'PUBLISHED', title: { startsWith: query, mode: 'insensitive' } },
        select: { id: true, title: true },
        take: 5,
      }),
      prisma.artist.findMany({
        where: { name: { startsWith: query, mode: 'insensitive' } },
        select: { id: true, name: true },
        take: 5,
      }),
    ]);

    const suggestions = [
      ...tracks.map(t => ({ type: 'track', id: t.id, text: t.title })),
      ...artists.map(a => ({ type: 'artist', id: a.id, text: a.name })),
    ].slice(0, 8);

    return { suggestions };
  },

  async getHistory(userId: string) {
    const history = await prisma.searchHistory.findMany({
      where: { userId },
      select: { id: true, query: true, createdAt: true },
      orderBy: { createdAt: 'desc' },
      take: 20,
      distinct: ['query'],
    });

    return { history };
  },

  async clearHistory(userId: string) {
    await prisma.searchHistory.deleteMany({ where: { userId } });
    return { cleared: true };
  },
};
