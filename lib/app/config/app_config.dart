import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const appName = 'Betooth';
  static const packageName = 'com.betooth.app';
  static const androidMinSdk = 21;
  static const iosMinVersion = '13.0';

  static String get apiBaseUrl {
    const productionUrl = 'https://betooth-simple-backend.onrender.com/api/v1';

    if (kIsWeb) {
      return const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: productionUrl,
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: productionUrl,
        );
      default:
        return const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: productionUrl,
        );
    }
  }
}