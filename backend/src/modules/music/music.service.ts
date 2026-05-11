import { Request } from 'express';
import { getPagination } from '../../common/utils/pagination';
import { generateSignedUrl } from '../../infra/storage/s3';

const SIGNED_URL_TTL_SECONDS = 3600; // 1 hour

export const musicService = {
  async listTracks(req: Request) {
    const pagination = getPagination(req);
    return { items: [], pagination };
  },

  async listGenres() {
    return [];
  },

  /**
   * Returns a temporary signed URL that the client can use to stream or
   * download the audio file directly from S3.
   *
   * NOTE: In a production implementation this would look up the track's
   * S3 key in the database (via Prisma). The key derivation below assumes
   * a conventional path of "tracks/<id>.mp3"; update once the Track model
   * is wired.
   */
  async getStreamMetadata(trackId: string) {
    const s3Key = `tracks/${trackId}.mp3`;
    const url = await generateSignedUrl(s3Key, SIGNED_URL_TTL_SECONDS);

    return {
      trackId,
      url,
      expiresIn: SIGNED_URL_TTL_SECONDS,
      expiresAt: new Date(Date.now() + SIGNED_URL_TTL_SECONDS * 1000).toISOString(),
    };
  },
};
