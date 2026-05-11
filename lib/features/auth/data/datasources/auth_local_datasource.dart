import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../models/auth_tokens_model.dart';

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final secureStorageServiceProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(ref.watch(flutterSecureStorageProvider)),
);

final authLocalDatasourceProvider = Provider<AuthLocalDatasource>(
  (ref) => AuthLocalDatasource(ref.watch(secureStorageServiceProvider)),
);

class AuthLocalDatasource {
  AuthLocalDatasource(this._storageService);

  final SecureStorageService _storageService;

  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storageService.write(_accessTokenKey, accessToken);
    await _storageService.write(_refreshTokenKey, refreshToken);
  }

  Future<AuthTokensModel?> getTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();

    if (accessToken == null || refreshToken == null) {
      return null;
    }

    return AuthTokensModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<String?> getAccessToken() {
    return _storageService.read(_accessTokenKey);
  }

  Future<String?> getRefreshToken() {
    return _storageService.read(_refreshTokenKey);
  }

  Future<void> clearTokens() {
    return _storageService.deleteAll();
  }
}