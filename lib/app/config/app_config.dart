import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const appName = 'Betooth';
  static const packageName = 'com.betooth.app';
  static const androidMinSdk = 21;
  static const iosMinVersion = '13.0';

  static String get apiBaseUrl {
    if (kIsWeb) {
      return const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:3333/api/v1',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://10.0.2.2:3333/api/v1',
        );
      default:
        return const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://localhost:3333/api/v1',
        );
    }
  }
}