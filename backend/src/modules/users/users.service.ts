import { Request } from 'express';
import { prisma } from '../../infra/database/prisma';
import { AppError } from '../../common/middleware/error-handler';
import { getPagination } from '../../common/utils/pagination';
import { libraryService } from '../library/library.service';
import { favoritesService } from '../favorites/favorites.service';

export const usersService = {
  async list(querySource: Parameters<typeof getPagination>[0]) {
    const pagination = getPagination(querySource);
    return { items: [], pagination };
  },

  async getProfile(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        username: true,
        displayName: true,
        avatarUrl: true,
        bio: true,
        role: true,
        status: true,
        createdAt: true,
      },
    });
    if (!user) throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    return user;
  },

  async listLibrary(userId: string, req: Request) {
    return libraryService.list(userId, req);
  },

  async listFavorites(userId: string, req: Request) {
    return favoritesService.list(userId, req);
  },
};
