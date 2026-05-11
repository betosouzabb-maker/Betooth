import { createHash, randomUUID } from 'node:crypto';
import { createReadStream } from 'node:fs';
import { access, appendFile, readFile, unlink, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { extname, join } from 'node:path';
import { prisma } from '../../infra/database/prisma';
import { AppError } from '../../common/middleware/error-handler';
import { uploadToS3 } from '../../common/utils/storage';
import { logger } from '../../common/utils/logger';

const ALLOWED_MIME_TYPES = new Set([
  'audio/mpeg',
  'audio/mp3',
  'audio/mp4',
  'audio/x-m4a',
  'audio/wav',
  'audio/x-wav',
  'audio/flac',
  'audio/x-flac',
  'audio/ogg',
  'audio/vorbis',
  'video/mp4',
]);

const ALLOWED_EXTENSIONS = new Set(['.mp3', '.mp4', '.m4a', '.wav', '.flac', '.ogg']);

const MAX_FILE_SIZE = 100 * 1024 * 1024;

type InitUploadInput = {
  userId: string;
  fileName: string;
  mimeType: string;
  sizeBytes: number;
  checksum?: string;
  title?: string;
  artist?: string;
  album?: string;
  genre?: string;
  privacy?: 'public' | 'private';
};

type CompleteUploadInput = {
  uploadId: string;
  userId: string;
  checksum: string;
};

type UserMetadata = {
  title?: string;
  artist?: string;
  album?: string;
  genre?: string;
  privacy?: string;
};

function slugify(text: string): string {
  return text
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9\s-]/g, '')
    .trim()
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .slice(0, 80);
}

function getTempFilePath(uploadId: string): string {
  return join(tmpdir(), `betooth-upload-${uploadId}.tmp`);
}

function getMetaFilePath(uploadId: string): string {
  return join(tmpdir(), `betooth-meta-${uploadId}.json`);
}

async function validateMagicBytes(filePath: string, declaredMime: string): Promise<boolean> {
  return new Promise((resolve) => {
    const stream = createReadStream(filePath, { start: 0, end: 11 });
    const chunks: Buffer[] = [];
    stream.on('data', (chunk) =>
      chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk))
    );
    stream.on('end', () => {
      const header = Buffer.concat(chunks);
      const mime = declaredMime.toLowerCase();

      if (mime.includes('mpeg') || mime.includes('mp3')) {
        const isId3 = header.subarray(0, 3).equals(Buffer.from([0x49, 0x44, 0x33]));
        const isMpegSync =
          header.readUInt8(0) === 0xff && (header.readUInt8(1) & 0xe0) === 0xe0;
        if (isId3 || isMpegSync) return resolve(true);
      }

      if (mime.includes('mp4') || mime.includes('m4a')) {
        if (header.subarray(4, 8).equals(Buffer.from([0x66, 0x74, 0x79, 0x70]))) {
          return resolve(true);
        }
      }

      if (mime.includes('wav')) {
        if (header.subarray(0, 4).equals(Buffer.from([0x52, 0x49, 0x46, 0x46]))) {
          return resolve(true);
        }
      }

      if (mime.includes('flac')) {
        if (header.subarray(0, 4).equals(Buffer.from([0x66, 0x4c, 0x61, 0x43]))) {
          return resolve(true);
        }
      }

      if (mime.includes('ogg') || mime.includes('vorbis')) {
        if (header.subarray(0, 4).equals(Buffer.from([0x4f, 0x67, 0x67, 0x53]))) {
          return resolve(true);
        }
      }

      resolve(false);
    });
    stream.on('error', () => resolve(false));
  });
}

async function computeFileChecksum(filePath: string): Promise<string> {
  return new Promise((resolve, reject) => {
    const hash = createHash('sha256');
    const stream = createReadStream(filePath);
    stream.on('data', (data) => hash.update(data));
    stream.on('end', () => resolve(hash.digest('hex')));
    stream.on('error', reject);
  });
}

export const uploadsService = {
  async list(userId: string) {
    return prisma.upload.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 50,
      select: {
        id: true,
        originalName: true,
        mimeType: true,
        sizeBytes: true,
        status: true,
        errorMessage: true,
        createdAt: true,
        completedAt: true,
        trackId: true,
      },
    });
  },

  async initUpload(input: InitUploadInput) {
    const { userId, fileName, mimeType, sizeBytes } = input;

    const normalizedMime = mimeType.toLowerCase().trim();
    if (!ALLOWED_MIME_TYPES.has(normalizedMime)) {
      throw new AppError('Tipo de arquivo não permitido.', 400, 'INVALID_MIME_TYPE');
    }

    const ext = extname(fileName).toLowerCase();
    if (!ALLOWED_EXTENSIONS.has(ext)) {
      throw new AppError('Extensão de arquivo não permitida.', 400, 'INVALID_EXTENSION');
    }

    if (sizeBytes > MAX_FILE_SIZE) {
      throw new AppError('Arquivo excede o tamanho máximo de 100 MB.', 400, 'FILE_TOO_LARGE');
    }

    const storageKey = `audio/${userId}/${randomUUID()}${ext}`;

    const upload = await prisma.upload.create({
      data: {
        userId,
        originalName: fileName,
        mimeType: normalizedMime,
        sizeBytes: BigInt(sizeBytes),
        storageKey,
        status: 'PENDING',
        ...(input.checksum ? { checksum: input.checksum } : {}),
      },
    });

    const userMeta: UserMetadata = {
      title: input.title,
      artist: input.artist,
      album: input.album,
      genre: input.genre,
      privacy: input.privacy,
    };
    await writeFile(getMetaFilePath(upload.id), JSON.stringify(userMeta), 'utf-8');

    return { uploadId: upload.id, storageKey };
  },

  async appendChunk(uploadId: string, userId: string, chunkBuffer: Buffer) {
    const upload = await prisma.upload.findFirst({
      where: { id: uploadId, userId },
    });

    if (!upload) {
      throw new AppError('Upload não encontrado.', 404, 'UPLOAD_NOT_FOUND');
    }

    if (upload.status !== 'PENDING') {
      throw new AppError(
        'Upload não está em estado válido para receber chunks.',
        400,
        'INVALID_UPLOAD_STATE'
      );
    }

    await appendFile(getTempFilePath(uploadId), chunkBuffer);

    return { uploadId, received: true };
  },

  async completeUpload(input: CompleteUploadInput) {
    const { uploadId, userId, checksum } = input;

    const upload = await prisma.upload.findFirst({
      where: { id: uploadId, userId },
    });

    if (!upload) {
      throw new AppError('Upload não encontrado.', 404, 'UPLOAD_NOT_FOUND');
    }

    if (upload.status !== 'PENDING') {
      throw new AppError(
        'Upload já foi concluído ou está em estado inválido.',
        400,
        'INVALID_UPLOAD_STATE'
      );
    }

    const tmpPath = getTempFilePath(uploadId);

    try {
      await access(tmpPath);
    } catch {
      throw new AppError(
        'Arquivo temporário não encontrado. O upload pode ter expirado.',
        400,
        'TEMP_FILE_NOT_FOUND'
      );
    }

    const isMagicValid = await validateMagicBytes(tmpPath, upload.mimeType);
    if (!isMagicValid) {
      await unlink(tmpPath).catch(() => {});
      await prisma.upload.update({
        where: { id: uploadId },
        data: { status: 'REJECTED', errorMessage: 'Assinatura do arquivo inválida.' },
      });
      throw new AppError(
        'Assinatura do arquivo inválida (magic bytes).',
        400,
        'INVALID_FILE_SIGNATURE'
      );
    }

    const computedChecksum = await computeFileChecksum(tmpPath);
    if (computedChecksum !== checksum) {
      await unlink(tmpPath).catch(() => {});
      await prisma.upload.update({
        where: { id: uploadId },
        data: { status: 'FAILED', errorMessage: 'Checksum SHA256 inválido.' },
      });
      throw new AppError(
        'Checksum SHA256 não corresponde ao arquivo recebido.',
        400,
        'CHECKSUM_MISMATCH'
      );
    }

    await prisma.upload.update({
      where: { id: uploadId },
      data: { status: 'PROCESSING' },
    });

    try {
      const mm = await import('music-metadata');
      const metadata = await mm.parseFile(tmpPath, { skipCovers: true });

      let userMeta: UserMetadata = {};
      const metaPath = getMetaFilePath(uploadId);
      try {
        const raw = await readFile(metaPath, 'utf-8');
        userMeta = JSON.parse(raw) as UserMetadata;
        await unlink(metaPath).catch(() => {});
      } catch {
        // no user metadata file
      }

      const title =
        userMeta.title ??
        metadata.common.title ??
        upload.originalName.replace(/\.[^.]+$/, '');
      const artistName = userMeta.artist ?? metadata.common.artist ?? 'Desconhecido';
      const genreName = userMeta.genre ?? metadata.common.genre?.[0];
      const durationSeconds = metadata.format.duration
        ? Math.round(metadata.format.duration)
        : 0;
      const bitrateKbps = metadata.format.bitrate
        ? Math.round(metadata.format.bitrate / 1000)
        : null;
      const sampleRateHz = metadata.format.sampleRate ?? null;
      const codec = metadata.format.codec ?? null;
      const isLossless = ['flac', 'alac', 'wav', 'pcm'].some((c) =>
        (codec ?? '').toLowerCase().includes(c)
      );

      await uploadToS3(tmpPath, upload.storageKey, upload.mimeType);
      await unlink(tmpPath).catch(() => {});

      const baseSlug = slugify(artistName);
      let artist = await prisma.artist.findUnique({ where: { slug: baseSlug } });
      if (!artist) {
        const uniqueSlug = `${baseSlug}-${randomUUID().slice(0, 8)}`;
        artist = await prisma.artist.create({
          data: { name: artistName, slug: uniqueSlug },
        });
      }

      let genreId: string | undefined;
      if (genreName) {
        const genreSlug = slugify(genreName);
        const genre = await prisma.genre.upsert({
          where: { slug: genreSlug },
          update: {},
          create: { name: genreName, slug: genreSlug },
        });
        genreId = genre.id;
      }

      const trackSlug = `${slugify(title)}-${randomUUID().slice(0, 8)}`;
      const isPrivate = userMeta.privacy === 'private';

      const track = await prisma.track.create({
        data: {
          artistId: artist.id,
          ...(genreId ? { genreId } : {}),
          title,
          slug: trackSlug,
          durationSeconds,
          status: isPrivate ? 'DRAFT' : 'PUBLISHED',
          versions: {
            create: {
              versionName: 'original',
              audioUrl: upload.storageKey,
              fileSizeBytes: upload.sizeBytes,
              ...(bitrateKbps !== null ? { bitrateKbps } : {}),
              ...(sampleRateHz !== null ? { sampleRateHz } : {}),
              ...(codec !== null ? { codec } : {}),
              isLossless,
              isPrimary: true,
              uploadStatus: 'COMPLETED',
            },
          },
        },
      });

      await prisma.upload.update({
        where: { id: uploadId },
        data: {
          status: 'COMPLETED',
          trackId: track.id,
          checksum: computedChecksum,
          completedAt: new Date(),
        },
      });

      await prisma.userLibrary
        .create({ data: { userId, trackId: track.id, source: 'upload' } })
        .catch(() => {});

      logger.info({ uploadId, trackId: track.id }, 'Upload concluído com sucesso');

      return {
        uploadId,
        trackId: track.id,
        status: 'COMPLETED',
        track: { id: track.id, title: track.title, status: track.status },
      };
    } catch (error) {
      await unlink(tmpPath).catch(() => {});
      await prisma.upload.update({
        where: { id: uploadId },
        data: {
          status: 'FAILED',
          errorMessage:
            error instanceof Error ? error.message : 'Erro ao processar upload.',
        },
      });
      throw error instanceof AppError
        ? error
        : new AppError('Erro ao processar o arquivo de áudio.', 500, 'PROCESSING_ERROR');
    }
  },

  async getUploadStatus(uploadId: string, userId: string) {
    const upload = await prisma.upload.findFirst({
      where: { id: uploadId, userId },
      select: {
        id: true,
        status: true,
        originalName: true,
        mimeType: true,
        sizeBytes: true,
        checksum: true,
        errorMessage: true,
        createdAt: true,
        completedAt: true,
        trackId: true,
      },
    });

    if (!upload) {
      throw new AppError('Upload não encontrado.', 404, 'UPLOAD_NOT_FOUND');
    }

    return upload;
  },

  async cancelUpload(uploadId: string, userId: string) {
    const upload = await prisma.upload.findFirst({
      where: { id: uploadId, userId },
    });

    if (!upload) {
      throw new AppError('Upload não encontrado.', 404, 'UPLOAD_NOT_FOUND');
    }

    if (!['PENDING', 'PROCESSING'].includes(upload.status)) {
      throw new AppError('Upload não pode ser cancelado neste estado.', 400, 'CANNOT_CANCEL');
    }

    await unlink(getTempFilePath(uploadId)).catch(() => {});
    await unlink(getMetaFilePath(uploadId)).catch(() => {});

    await prisma.upload.update({
      where: { id: uploadId },
      data: { status: 'FAILED', errorMessage: 'Cancelado pelo usuário.' },
    });

    return { uploadId, cancelled: true };
  },
};
