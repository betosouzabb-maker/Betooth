import { Router } from 'express';
import { appReleaseController } from './app-release.controller';

export const appReleaseRoutes = Router();

// Metadados da versão mais recente
appReleaseRoutes.get('/latest', appReleaseController.getLatest);

// Download direto do APK (Android)
appReleaseRoutes.get('/android', appReleaseController.downloadAndroid);

// Download direto do IPA (iOS)
appReleaseRoutes.get('/ios', appReleaseController.downloadIos);

// Manifest OTA para iOS (itms-services://)
appReleaseRoutes.get('/ios/manifest', appReleaseController.iosManifest);
