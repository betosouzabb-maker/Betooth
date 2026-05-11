import fs from 'fs';
import path from 'path';
import { NextFunction, Request, Response } from 'express';
import { sendSuccess, sendError } from '../../common/utils/response';
import { appReleaseService } from './app-release.service';
import { env } from '../../config/env';

export const appReleaseController = {
  /**
   * GET /api/v1/app-release/latest
   * Retorna metadados da versão mais recente do app (Android e iOS).
   */
  async getLatest(_req: Request, res: Response, next: NextFunction) {
    try {
      const release = appReleaseService.getLatestRelease();
      return sendSuccess(res, 200, release);
    } catch (error) {
      return next(error);
    }
  },

  /**
   * GET /api/v1/app-release/android
   * Faz download do APK mais recente.
   */
  async downloadAndroid(_req: Request, res: Response, next: NextFunction) {
    try {
      const filePath = appReleaseService.getAndroidFilePath();

      if (!fs.existsSync(filePath)) {
        return sendError(res, 404, 'APK não encontrado. Execute o build primeiro.', 'APK_NOT_FOUND');
      }

      const stat = fs.statSync(filePath);
      const fileName = path.basename(filePath);

      res.setHeader('Content-Type', 'application/vnd.android.package-archive');
      res.setHeader('Content-Disposition', `attachment; filename="${fileName}"`);
      res.setHeader('Content-Length', stat.size);

      const stream = fs.createReadStream(filePath);
      stream.on('error', next);
      return stream.pipe(res);
    } catch (error) {
      return next(error);
    }
  },

  /**
   * GET /api/v1/app-release/ios
   * Faz download do IPA mais recente.
   */
  async downloadIos(_req: Request, res: Response, next: NextFunction) {
    try {
      const filePath = appReleaseService.getIosFilePath();

      if (!fs.existsSync(filePath)) {
        return sendError(
          res,
          404,
          'IPA não encontrado. Execute o build em um Mac com Xcode e copie o arquivo para releases/ios/.',
          'IPA_NOT_FOUND'
        );
      }

      const stat = fs.statSync(filePath);
      const fileName = path.basename(filePath);

      res.setHeader('Content-Type', 'application/octet-stream');
      res.setHeader('Content-Disposition', `attachment; filename="${fileName}"`);
      res.setHeader('Content-Length', stat.size);

      const stream = fs.createReadStream(filePath);
      stream.on('error', next);
      return stream.pipe(res);
    } catch (error) {
      return next(error);
    }
  },

  /**
   * GET /api/v1/app-release/ios/manifest
   * Retorna o manifest.plist para instalação OTA no iOS (itms-services://).
   */
  async iosManifest(_req: Request, res: Response, next: NextFunction) {
    try {
      const release = appReleaseService.getLatestRelease();
      const ipaUrl = release.ios.downloadUrl;
      const baseUrl = env.APP_URL;

      const plist = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>items</key>
  <array>
    <dict>
      <key>assets</key>
      <array>
        <dict>
          <key>kind</key>
          <string>software-package</string>
          <key>url</key>
          <string>${ipaUrl}</string>
        </dict>
        <dict>
          <key>kind</key>
          <string>display-image</string>
          <key>url</key>
          <string>${baseUrl}/download/icon-57.png</string>
        </dict>
        <dict>
          <key>kind</key>
          <string>full-size-image</string>
          <key>url</key>
          <string>${baseUrl}/download/icon-512.png</string>
        </dict>
      </array>
      <key>metadata</key>
      <dict>
        <key>bundle-identifier</key>
        <string>com.betooth.app</string>
        <key>bundle-version</key>
        <string>${release.version}</string>
        <key>kind</key>
        <string>software</string>
        <key>title</key>
        <string>Betooth</string>
      </dict>
    </dict>
  </array>
</dict>
</plist>`;

      res.setHeader('Content-Type', 'application/xml');
      return res.send(plist);
    } catch (error) {
      return next(error);
    }
  },
};
