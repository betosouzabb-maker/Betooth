import fs from 'fs';
import path from 'path';
import { env } from '../../config/env';

export interface ReleaseInfo {
  version: string;
  buildNumber: number;
  releaseDate: string;
  android: {
    available: boolean;
    fileName: string;
    downloadUrl: string;
    sizeBytes: number | null;
    minSdkVersion: number;
    checksum: string | null;
  };
  ios: {
    available: boolean;
    fileName: string;
    downloadUrl: string;
    manifestUrl: string;
    sizeBytes: number | null;
    minOsVersion: string;
    checksum: string | null;
  };
  releaseNotes: string;
}

const RELEASES_DIR = path.resolve(process.cwd(), '..', 'releases');
const ANDROID_APK = path.join(RELEASES_DIR, 'android', 'betooth-latest.apk');
const IOS_IPA = path.join(RELEASES_DIR, 'ios', 'betooth-latest.ipa');

function fileSizeOrNull(filePath: string): number | null {
  try {
    return fs.statSync(filePath).size;
  } catch {
    return null;
  }
}

function fileExistsAndReadable(filePath: string): boolean {
  try {
    fs.accessSync(filePath, fs.constants.R_OK);
    return true;
  } catch {
    return false;
  }
}

export const appReleaseService = {
  getLatestRelease(): ReleaseInfo {
    const baseUrl = env.APP_URL;
    const androidAvailable = fileExistsAndReadable(ANDROID_APK);
    const iosAvailable = fileExistsAndReadable(IOS_IPA);

    return {
      version: '1.0.0',
      buildNumber: 1,
      releaseDate: '2025-01-01T00:00:00Z',
      android: {
        available: androidAvailable,
        fileName: 'betooth-latest.apk',
        downloadUrl: `${baseUrl}/api/v1/app-release/android`,
        sizeBytes: fileSizeOrNull(ANDROID_APK),
        minSdkVersion: 21,
        checksum: null,
      },
      ios: {
        available: iosAvailable,
        fileName: 'betooth-latest.ipa',
        downloadUrl: `${baseUrl}/api/v1/app-release/ios`,
        manifestUrl: `${baseUrl}/api/v1/app-release/ios/manifest`,
        sizeBytes: fileSizeOrNull(IOS_IPA),
        minOsVersion: '13.0',
        checksum: null,
      },
      releaseNotes: 'Versão inicial do Betooth. Streaming de música, playlists, sincronização offline e assinatura VIP.',
    };
  },

  getAndroidFilePath(): string {
    return ANDROID_APK;
  },

  getIosFilePath(): string {
    return IOS_IPA;
  },

  getReleasesDir(): string {
    return RELEASES_DIR;
  },
};
