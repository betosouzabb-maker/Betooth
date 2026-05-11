import { prisma } from '../../infra/database/prisma';
import { AppError } from '../../common/middleware/error-handler';
import { generatePresignedDownloadUrl } from '../../common/utils/storage';

export const tracksService = {
  async getDownloadUrl(trackId: string, userId: string) {
    const track = await prisma.track.findFirst({
      where: { id: trackId, status: 'PUBLISHED' },
      include: {
        versions: {
          where: { isPrimary: true },
          take: 1,
        },
      },
    });

    if (!track) {
      throw new AppError('Faixa não encontrada.', 404, 'TRACK_NOT_FOUND');
    }

    const primaryVersion = track.versions[0];
    if (!primaryVersion) {
      throw new AppError(
        'Nenhuma versão de áudio disponível para download.',
        404,
        'NO_VERSION_AVAILABLE'
      );
    }

    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);
    const url = await generatePresignedDownloadUrl(primaryVersion.audioUrl, 900);

    await prisma.download.create({
      data: {
        userId,
        trackId,
        status: 'REQUESTED',
        quality: primaryVersion.versionName,
        expiresAt,
      },
    });

    return {
      url,
      expiresAt: expiresAt.toISOString(),
      track: {
        id: track.id,
        title: track.title,
        durationSeconds: track.durationSeconds,
      },
      version: {
        id: primaryVersion.id,
        name: primaryVersion.versionName,
        bitrateKbps: primaryVersion.bitrateKbps,
        codec: primaryVersion.codec,
        isLossless: primaryVersion.isLossless,
      },
    };
  },
};
